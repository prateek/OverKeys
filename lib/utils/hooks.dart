import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'key_code.dart';
import 'logger.dart';

/// Low-level global keyboard hook implementations.
///
/// Windows uses a Win32 low-level keyboard hook. macOS uses a Core Graphics
/// event tap and normalizes hardware key codes to the same virtual key codes
/// used by the Windows path.

/// Logger instance for hooks
final _log = SimplePrintLogger('Hooks');

/// Pointer to the keyboard hook procedure
final keyboardProc = Pointer.fromFunction<HOOKPROC>(lowLevelKeyboardProc, 0);

/// Pointer to the session notification window procedure
final sessionProc = Pointer.fromFunction<WNDPROC>(sessionNotificationProc, 0);
int? hookId;
int? sessionWindowHandle;
SendPort? sendPort;

typedef _CGEventTapCallbackNative = Pointer<Void> Function(
  Pointer<Void> proxy,
  Uint32 type,
  Pointer<Void> event,
  Pointer<Void> refcon,
);

final _macKeyboardProc =
    Pointer.fromFunction<_CGEventTapCallbackNative>(macKeyboardProc);

DynamicLibrary? _applicationServicesLibrary;
DynamicLibrary? _coreFoundationLibrary;
Pointer<Void>? _macEventTap;
Pointer<Void>? _macRunLoopSource;
Pointer<Void>? _macRunLoop;
final _macModifierStateTracker = MacOSModifierStateTracker();

DynamicLibrary get _applicationServices =>
    _applicationServicesLibrary ??= DynamicLibrary.open(
      '/System/Library/Frameworks/ApplicationServices.framework/'
      'ApplicationServices',
    );

DynamicLibrary get _coreFoundation => _coreFoundationLibrary ??=
    DynamicLibrary.open('/System/Library/Frameworks/CoreFoundation.framework/'
        'CoreFoundation');

final _cgEventTapCreate = _applicationServices.lookupFunction<
    Pointer<Void> Function(
      Uint32 tap,
      Uint32 place,
      Uint32 options,
      Uint64 eventsOfInterest,
      Pointer<NativeFunction<_CGEventTapCallbackNative>> callback,
      Pointer<Void> userInfo,
    ),
    Pointer<Void> Function(
      int tap,
      int place,
      int options,
      int eventsOfInterest,
      Pointer<NativeFunction<_CGEventTapCallbackNative>> callback,
      Pointer<Void> userInfo,
    )>('CGEventTapCreate');

final _cgEventTapEnable = _applicationServices.lookupFunction<
    Void Function(Pointer<Void> tap, Bool enable),
    void Function(Pointer<Void> tap, bool enable)>('CGEventTapEnable');

final _cgEventGetIntegerValueField = _applicationServices.lookupFunction<
    Int64 Function(Pointer<Void> event, Uint32 field),
    int Function(
        Pointer<Void> event, int field)>('CGEventGetIntegerValueField');

final _cgEventGetFlags = _applicationServices.lookupFunction<
    Uint64 Function(Pointer<Void> event),
    int Function(Pointer<Void> event)>('CGEventGetFlags');

final _cgPreflightListenEventAccess =
    _applicationServices.lookupFunction<Bool Function(), bool Function()>(
        'CGPreflightListenEventAccess');

final _cgRequestListenEventAccess =
    _applicationServices.lookupFunction<Bool Function(), bool Function()>(
        'CGRequestListenEventAccess');

final _cfMachPortCreateRunLoopSource = _coreFoundation.lookupFunction<
    Pointer<Void> Function(
      Pointer<Void> allocator,
      Pointer<Void> port,
      IntPtr order,
    ),
    Pointer<Void> Function(
      Pointer<Void> allocator,
      Pointer<Void> port,
      int order,
    )>('CFMachPortCreateRunLoopSource');

final _cfRunLoopAddSource = _coreFoundation.lookupFunction<
    Void Function(
      Pointer<Void> runLoop,
      Pointer<Void> source,
      Pointer<Void> mode,
    ),
    void Function(
      Pointer<Void> runLoop,
      Pointer<Void> source,
      Pointer<Void> mode,
    )>('CFRunLoopAddSource');

final _cfRunLoopGetCurrent = _coreFoundation.lookupFunction<
    Pointer<Void> Function(), Pointer<Void> Function()>('CFRunLoopGetCurrent');

final _cfRunLoopRemoveSource = _coreFoundation.lookupFunction<
    Void Function(
      Pointer<Void> runLoop,
      Pointer<Void> source,
      Pointer<Void> mode,
    ),
    void Function(
      Pointer<Void> runLoop,
      Pointer<Void> source,
      Pointer<Void> mode,
    )>('CFRunLoopRemoveSource');

final _cfRunLoopRunInMode = _coreFoundation.lookupFunction<
    Int32 Function(
        Pointer<Void> mode, Double seconds, Uint8 returnAfterSourceHandled),
    int Function(Pointer<Void> mode, double seconds,
        int returnAfterSourceHandled)>('CFRunLoopRunInMode');

final _cfRunLoopStop = _coreFoundation.lookupFunction<
    Void Function(Pointer<Void> runLoop),
    void Function(Pointer<Void> runLoop)>('CFRunLoopStop');

final _cfMachPortInvalidate = _coreFoundation.lookupFunction<
    Void Function(Pointer<Void> port),
    void Function(Pointer<Void> port)>('CFMachPortInvalidate');

final _cfRelease = _coreFoundation.lookupFunction<
    Void Function(Pointer<Void> cf),
    void Function(Pointer<Void> cf)>('CFRelease');

Pointer<Void> get _cfRunLoopDefaultMode =>
    _coreFoundation.lookup<Pointer<Void>>('kCFRunLoopDefaultMode').value;

const int _kCGSessionEventTap = 1;
const int _kCGHeadInsertEventTap = 0;
const int _kCGEventTapOptionListenOnly = 1;
const int _kCGEventKeyDown = 10;
const int _kCGEventKeyUp = 11;
const int _kCGEventFlagsChanged = 12;
const int _kCGEventTapDisabledByTimeout = 0xFFFFFFFE;
const int _kCGEventTapDisabledByUserInput = 0xFFFFFFFF;
const int _kCGKeyboardEventKeycode = 9;
const int _kCFRunLoopRunFinished = 1;

bool _hookShutdownRequested = false;

int lowLevelKeyboardProc(
  int nCode,
  int wParam,
  int lParam,
) {
  if (nCode >= 0 &&
      (wParam == WM_KEYDOWN ||
          wParam == WM_KEYUP ||
          wParam == WM_SYSKEYDOWN ||
          wParam == WM_SYSKEYUP)) {
    final keyStruct = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam).ref;
    int keyCode = keyStruct.vkCode;
    bool isPressed = !((keyStruct.flags & LLKHF_UP) != 0);
    bool isShiftDown = GetKeyState(VK_SHIFT) & 0x8000 != 0;

    sendPort?.send([keyCode, isPressed, isShiftDown]);

    if (!isPressed) {
      final oppositeShiftState = !isShiftDown;
      sendPort?.send([keyCode, false, oppositeShiftState]);
    }
  }
  return CallNextHookEx(hookId ?? 0, nCode, wParam, lParam);
}

int sessionNotificationProc(int hwnd, int message, int wParam, int lParam) {
  if (message == WM_WTSSESSION_CHANGE) {
    switch (wParam) {
      case WTS_SESSION_LOCK:
        sendPort?.send(['session_lock', true]);
        break;
      case WTS_SESSION_UNLOCK:
        sendPort?.send(['session_unlock', true]);
        break;
    }
  }
  return DefWindowProc(hwnd, message, wParam, lParam);
}

void registerSessionNotification(int hwnd) {
  final result = WTSRegisterSessionNotification(hwnd, NOTIFY_FOR_THIS_SESSION);
  if (result == 0) {
    throw StateError('Failed to register session notification.');
  }
}

bool unregisterSessionNotification(int hwnd) {
  return WTSUnRegisterSessionNotification(hwnd) != 0;
}

int createSessionNotificationWindow() {
  final wc = calloc<WNDCLASS>();
  try {
    wc.ref.lpfnWndProc = sessionProc;
    wc.ref.hInstance = GetModuleHandle(nullptr);
    wc.ref.lpszClassName = TEXT('SessionNotificationWindow');

    RegisterClass(wc);
    final hwnd = CreateWindowEx(
      0,
      TEXT('SessionNotificationWindow'),
      TEXT('Session Notification Window'),
      0,
      0,
      0,
      0,
      0,
      HWND_MESSAGE,
      NULL,
      GetModuleHandle(nullptr),
      nullptr,
    );

    if (hwnd == 0) {
      throw StateError(
          'Failed to create notification window: ${GetLastError()}');
    }

    return hwnd;
  } finally {
    calloc.free(wc);
  }
}

Future<void> setHook(SendPort port) async {
  sendPort = port;

  if (Platform.isWindows) {
    _setWindowsHook();
    return;
  }

  if (Platform.isMacOS) {
    await _setMacOSHook();
    return;
  }

  _log.warning('Global keyboard hook is not supported on '
      '${Platform.operatingSystem}.');
  sendPort?.send(['hook_error', 'unsupported_platform']);
}

void startHookIsolate(SendPort port) {
  unawaited(_startHookIsolate(port));
}

Future<void> _startHookIsolate(SendPort port) async {
  _hookShutdownRequested = false;
  final controlPort = ReceivePort();
  controlPort.listen((message) {
    if (message == 'shutdown') {
      _hookShutdownRequested = true;
      unhook();
    }
  });
  port.send(['hook_control', controlPort.sendPort]);

  try {
    await setHook(port);
  } catch (error, stackTrace) {
    _log.error(
      'Unhandled keyboard hook setup error',
      error: error,
      stackTrace: stackTrace,
    );
    port.send(['hook_error', 'hook_exception']);
  } finally {
    controlPort.close();
  }
}

void _setWindowsHook() {
  // Set up keyboard hook
  final currentHookId = SetWindowsHookEx(
      WH_KEYBOARD_LL, keyboardProc, GetModuleHandle(nullptr), 0);
  if (currentHookId == 0) {
    _log.error('Failed to install hook.');
    sendPort?.send(['hook_error', 'windows_hook_unavailable']);
    return;
  }
  hookId = currentHookId;

  try {
    // Set up session notification window
    final currentSessionWindowHandle = createSessionNotificationWindow();
    sessionWindowHandle = currentSessionWindowHandle;
    registerSessionNotification(currentSessionWindowHandle);
    sendPort?.send(['hook_ready', 'windows', GetCurrentThreadId()]);

    final msg = calloc<MSG>();
    try {
      while (GetMessage(msg, NULL, 0, 0) != 0) {
        TranslateMessage(msg);
        DispatchMessage(msg);
        sendPort?.send(msg);
      }
    } finally {
      calloc.free(msg);
    }
  } finally {
    unhook();
  }
}

Future<void> _setMacOSHook() async {
  if (!_ensureMacOSInputMonitoringAccess()) {
    _log.warning('Input Monitoring permission is required for OverKeys to '
        'listen to global key events on macOS.');
    sendPort?.send(['hook_error', 'input_monitoring_permission']);
    return;
  }

  final eventsOfInterest = (1 << _kCGEventKeyDown) |
      (1 << _kCGEventKeyUp) |
      (1 << _kCGEventFlagsChanged);

  _macEventTap = _cgEventTapCreate(
    _kCGSessionEventTap,
    _kCGHeadInsertEventTap,
    _kCGEventTapOptionListenOnly,
    eventsOfInterest,
    _macKeyboardProc,
    nullptr,
  );

  final eventTap = _macEventTap;
  if (eventTap == null || eventTap == nullptr) {
    _log.error('Failed to create macOS keyboard event tap.');
    sendPort?.send(['hook_error', 'event_tap_unavailable']);
    return;
  }

  _macRunLoopSource = _cfMachPortCreateRunLoopSource(nullptr, eventTap, 0);
  final runLoopSource = _macRunLoopSource;
  if (runLoopSource == null || runLoopSource == nullptr) {
    _log.error('Failed to create macOS keyboard event tap run loop source.');
    sendPort?.send(['hook_error', 'event_tap_run_loop_unavailable']);
    _cfRelease(eventTap);
    _macEventTap = null;
    return;
  }

  _macRunLoop = _cfRunLoopGetCurrent();
  final runLoop = _macRunLoop!;
  _cfRunLoopAddSource(runLoop, runLoopSource, _cfRunLoopDefaultMode);
  _cgEventTapEnable(eventTap, true);
  sendPort?.send(['hook_ready', 'macos']);

  try {
    while (!_hookShutdownRequested) {
      final result = _cfRunLoopRunInMode(_cfRunLoopDefaultMode, 0.1, 0);
      if (result == _kCFRunLoopRunFinished) {
        break;
      }
      await Future<void>.delayed(Duration.zero);
    }
  } finally {
    _disposeMacOSHookResources(runLoop, runLoopSource, eventTap);
  }
}

void _disposeMacOSHookResources(
  Pointer<Void> runLoop,
  Pointer<Void> runLoopSource,
  Pointer<Void> eventTap,
) {
  _cgEventTapEnable(eventTap, false);
  _cfRunLoopRemoveSource(runLoop, runLoopSource, _cfRunLoopDefaultMode);
  _cfMachPortInvalidate(eventTap);
  _cfRelease(runLoopSource);
  _cfRelease(eventTap);
  _macRunLoopSource = null;
  _macEventTap = null;
  _macRunLoop = null;
}

bool _ensureMacOSInputMonitoringAccess() {
  try {
    if (_cgPreflightListenEventAccess()) {
      return true;
    }
    return _cgRequestListenEventAccess();
  } on ArgumentError catch (error) {
    _log.warning(
      'Could not preflight macOS Input Monitoring permission: $error',
    );
    return true;
  }
}

Pointer<Void> macKeyboardProc(
  Pointer<Void> proxy,
  int type,
  Pointer<Void> event,
  Pointer<Void> refcon,
) {
  if (type == _kCGEventTapDisabledByTimeout ||
      type == _kCGEventTapDisabledByUserInput) {
    final eventTap = _macEventTap;
    if (eventTap != null && eventTap != nullptr) {
      _cgEventTapEnable(eventTap, true);
    }
    return event;
  }

  if (type != _kCGEventKeyDown &&
      type != _kCGEventKeyUp &&
      type != _kCGEventFlagsChanged) {
    return event;
  }

  final macKeyCode =
      _cgEventGetIntegerValueField(event, _kCGKeyboardEventKeycode);
  final keyCode = normalizeMacOSKeyCode(macKeyCode);
  if (keyCode == null) {
    return event;
  }

  final flags = _cgEventGetFlags(event);
  final isShiftDown = isMacOSShiftDown(flags);
  final isPressed = type == _kCGEventFlagsChanged
      ? _macModifierStateTracker.updateForFlagsChanged(macKeyCode, flags)
      : type == _kCGEventKeyDown;

  if (isPressed == null) {
    return event;
  }

  sendPort?.send([keyCode, isPressed, isShiftDown]);

  if (!isPressed) {
    final oppositeShiftState = !isShiftDown;
    sendPort?.send([keyCode, false, oppositeShiftState]);
  }

  return event;
}

void unhook() {
  if (Platform.isWindows) {
    final currentHookId = hookId;
    if (currentHookId != null) {
      UnhookWindowsHookEx(currentHookId);
      hookId = null;
    }

    final currentSessionWindowHandle = sessionWindowHandle;
    if (currentSessionWindowHandle != null) {
      unregisterSessionNotification(currentSessionWindowHandle);
      DestroyWindow(currentSessionWindowHandle);
      UnregisterClass(
          TEXT('SessionNotificationWindow'), GetModuleHandle(nullptr));
      sessionWindowHandle = null;
    }
    return;
  }

  if (Platform.isMacOS) {
    final eventTap = _macEventTap;
    if (eventTap != null && eventTap != nullptr) {
      _cgEventTapEnable(eventTap, false);
    }

    final runLoop = _macRunLoop;
    if (runLoop != null && runLoop != nullptr) {
      _cfRunLoopStop(runLoop);
    }
  }
}

void requestWindowsHookShutdown(int threadId) {
  if (Platform.isWindows) {
    PostThreadMessage(threadId, WM_QUIT, 0, 0);
  }
}
