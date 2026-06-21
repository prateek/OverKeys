// ignore_for_file: deprecated_member_use

import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:hid_listener/hid_listener.dart';
import 'package:win32/win32.dart';
import 'logger.dart';

/// Global keyboard listener for macOS, built on top of [hid_listener].
///
/// OverKeys' key pipeline speaks Windows virtual-key codes: events travel
/// through the app as `[vkCode, isPressed, isShiftDown]` and are resolved to
/// display names by `getKeyFromKeyCodeShift`. To reuse that pipeline unchanged,
/// this listener translates each physical key reported by hid_listener into the
/// equivalent Windows virtual-key code, then forwards it to the same
/// [SendPort]/[ReceivePort] the Windows hook uses.
///
/// The translation keys off the event's *physical* key rather than the
/// character it produces, so a key is identified by its position on the board
/// independent of the active OS layout. That matches the Windows low-level hook,
/// which reports layout-independent virtual-key codes, and keeps the rendered
/// overlay consistent across platforms.
///
/// On macOS the underlying event tap requires the app to be granted Accessibility
/// / Input Monitoring permission (System Settings -> Privacy & Security). Without
/// it the listener registers but never receives events.
class MacKeyListener {
  MacKeyListener(this._sendPort);

  final SendPort _sendPort;
  final _log = SimplePrintLogger('MacKeyListener');
  int? _listenerId;

  /// Installs the global keyboard listener. Returns true on success.
  bool start() {
    final backend = getListenerBackend();
    if (backend == null) {
      _log.error('No hid_listener backend available for this platform');
      return false;
    }
    if (!backend.initialize()) {
      _log.error('Failed to initialize hid_listener backend');
      return false;
    }
    _listenerId = backend.addKeyboardListener(_onKeyEvent);
    if (_listenerId == null) {
      _log.error('Failed to register keyboard listener. '
          'Grant Accessibility / Input Monitoring permission to OverKeys.');
      return false;
    }
    return true;
  }

  /// Removes the global keyboard listener.
  void stop() {
    final id = _listenerId;
    if (id != null) {
      getListenerBackend()?.removeKeyboardListener(id);
      _listenerId = null;
    }
  }

  void _onKeyEvent(RawKeyEvent event) {
    final vkCode = virtualKeyForPhysicalKey(event.physicalKey);
    if (vkCode == null) return;

    final isPressed = event is RawKeyDownEvent;
    final isShiftDown = event.isShiftPressed;

    _sendPort.send([vkCode, isPressed, isShiftDown]);

    // Mirror the Windows hook: on release, also clear the opposite shift
    // variant so a symbol typed with Shift held (e.g. '{') does not stay
    // highlighted after both keys are released.
    if (!isPressed) {
      _sendPort.send([vkCode, false, !isShiftDown]);
    }
  }
}

/// Returns the Windows virtual-key code OverKeys uses for [key], or null if the
/// physical key has no mapping. Exposed for testing the cross-platform parity
/// contract: a physical key must resolve to the same display name on macOS as
/// its virtual-key code does on Windows.
int? virtualKeyForPhysicalKey(PhysicalKeyboardKey key) => _physicalKeyToVk[key];

/// Maps a Flutter [PhysicalKeyboardKey] to the Windows virtual-key code OverKeys
/// uses internally. Top-row digits use their literal codes (0x30-0x39); there
/// are no `VK_0`..`VK_9` constants in the win32 package.
final Map<PhysicalKeyboardKey, int> _physicalKeyToVk = {
  // Letters
  PhysicalKeyboardKey.keyA: VK_A,
  PhysicalKeyboardKey.keyB: VK_B,
  PhysicalKeyboardKey.keyC: VK_C,
  PhysicalKeyboardKey.keyD: VK_D,
  PhysicalKeyboardKey.keyE: VK_E,
  PhysicalKeyboardKey.keyF: VK_F,
  PhysicalKeyboardKey.keyG: VK_G,
  PhysicalKeyboardKey.keyH: VK_H,
  PhysicalKeyboardKey.keyI: VK_I,
  PhysicalKeyboardKey.keyJ: VK_J,
  PhysicalKeyboardKey.keyK: VK_K,
  PhysicalKeyboardKey.keyL: VK_L,
  PhysicalKeyboardKey.keyM: VK_M,
  PhysicalKeyboardKey.keyN: VK_N,
  PhysicalKeyboardKey.keyO: VK_O,
  PhysicalKeyboardKey.keyP: VK_P,
  PhysicalKeyboardKey.keyQ: VK_Q,
  PhysicalKeyboardKey.keyR: VK_R,
  PhysicalKeyboardKey.keyS: VK_S,
  PhysicalKeyboardKey.keyT: VK_T,
  PhysicalKeyboardKey.keyU: VK_U,
  PhysicalKeyboardKey.keyV: VK_V,
  PhysicalKeyboardKey.keyW: VK_W,
  PhysicalKeyboardKey.keyX: VK_X,
  PhysicalKeyboardKey.keyY: VK_Y,
  PhysicalKeyboardKey.keyZ: VK_Z,

  // Top-row digits
  PhysicalKeyboardKey.digit0: 0x30,
  PhysicalKeyboardKey.digit1: 0x31,
  PhysicalKeyboardKey.digit2: 0x32,
  PhysicalKeyboardKey.digit3: 0x33,
  PhysicalKeyboardKey.digit4: 0x34,
  PhysicalKeyboardKey.digit5: 0x35,
  PhysicalKeyboardKey.digit6: 0x36,
  PhysicalKeyboardKey.digit7: 0x37,
  PhysicalKeyboardKey.digit8: 0x38,
  PhysicalKeyboardKey.digit9: 0x39,

  // Function keys
  PhysicalKeyboardKey.f1: VK_F1,
  PhysicalKeyboardKey.f2: VK_F2,
  PhysicalKeyboardKey.f3: VK_F3,
  PhysicalKeyboardKey.f4: VK_F4,
  PhysicalKeyboardKey.f5: VK_F5,
  PhysicalKeyboardKey.f6: VK_F6,
  PhysicalKeyboardKey.f7: VK_F7,
  PhysicalKeyboardKey.f8: VK_F8,
  PhysicalKeyboardKey.f9: VK_F9,
  PhysicalKeyboardKey.f10: VK_F10,
  PhysicalKeyboardKey.f11: VK_F11,
  PhysicalKeyboardKey.f12: VK_F12,
  PhysicalKeyboardKey.f13: VK_F13,
  PhysicalKeyboardKey.f14: VK_F14,
  PhysicalKeyboardKey.f15: VK_F15,
  PhysicalKeyboardKey.f16: VK_F16,
  PhysicalKeyboardKey.f17: VK_F17,
  PhysicalKeyboardKey.f18: VK_F18,
  PhysicalKeyboardKey.f19: VK_F19,
  PhysicalKeyboardKey.f20: VK_F20,
  PhysicalKeyboardKey.f21: VK_F21,
  PhysicalKeyboardKey.f22: VK_F22,
  PhysicalKeyboardKey.f23: VK_F23,
  PhysicalKeyboardKey.f24: VK_F24,

  // Editing / navigation
  PhysicalKeyboardKey.enter: VK_RETURN,
  PhysicalKeyboardKey.numpadEnter: VK_RETURN,
  PhysicalKeyboardKey.tab: VK_TAB,
  PhysicalKeyboardKey.backspace: VK_BACK,
  PhysicalKeyboardKey.escape: VK_ESCAPE,
  PhysicalKeyboardKey.delete: VK_DELETE,
  PhysicalKeyboardKey.insert: VK_INSERT,
  PhysicalKeyboardKey.home: VK_HOME,
  PhysicalKeyboardKey.end: VK_END,
  PhysicalKeyboardKey.pageUp: VK_PRIOR,
  PhysicalKeyboardKey.pageDown: VK_NEXT,
  PhysicalKeyboardKey.arrowLeft: VK_LEFT,
  PhysicalKeyboardKey.arrowRight: VK_RIGHT,
  PhysicalKeyboardKey.arrowUp: VK_UP,
  PhysicalKeyboardKey.arrowDown: VK_DOWN,

  // Modifiers
  PhysicalKeyboardKey.shiftLeft: VK_LSHIFT,
  PhysicalKeyboardKey.shiftRight: VK_RSHIFT,
  PhysicalKeyboardKey.controlLeft: VK_LCONTROL,
  PhysicalKeyboardKey.controlRight: VK_RCONTROL,
  PhysicalKeyboardKey.altLeft: VK_LMENU,
  PhysicalKeyboardKey.altRight: VK_RMENU,
  PhysicalKeyboardKey.metaLeft: VK_LWIN,
  PhysicalKeyboardKey.metaRight: VK_RWIN,
  PhysicalKeyboardKey.capsLock: VK_CAPITAL,
  PhysicalKeyboardKey.numLock: VK_NUMLOCK,
  PhysicalKeyboardKey.scrollLock: VK_SCROLL,

  // Space
  PhysicalKeyboardKey.space: VK_SPACE,

  // Numpad
  PhysicalKeyboardKey.numpad0: VK_NUMPAD0,
  PhysicalKeyboardKey.numpad1: VK_NUMPAD1,
  PhysicalKeyboardKey.numpad2: VK_NUMPAD2,
  PhysicalKeyboardKey.numpad3: VK_NUMPAD3,
  PhysicalKeyboardKey.numpad4: VK_NUMPAD4,
  PhysicalKeyboardKey.numpad5: VK_NUMPAD5,
  PhysicalKeyboardKey.numpad6: VK_NUMPAD6,
  PhysicalKeyboardKey.numpad7: VK_NUMPAD7,
  PhysicalKeyboardKey.numpad8: VK_NUMPAD8,
  PhysicalKeyboardKey.numpad9: VK_NUMPAD9,
  PhysicalKeyboardKey.numpadMultiply: VK_MULTIPLY,
  PhysicalKeyboardKey.numpadAdd: VK_ADD,
  PhysicalKeyboardKey.numpadSubtract: VK_SUBTRACT,
  PhysicalKeyboardKey.numpadDecimal: VK_DECIMAL,
  PhysicalKeyboardKey.numpadDivide: VK_DIVIDE,

  // Punctuation / OEM keys
  PhysicalKeyboardKey.comma: VK_OEM_COMMA,
  PhysicalKeyboardKey.period: VK_OEM_PERIOD,
  PhysicalKeyboardKey.semicolon: VK_OEM_1,
  PhysicalKeyboardKey.slash: VK_OEM_2,
  PhysicalKeyboardKey.bracketLeft: VK_OEM_4,
  PhysicalKeyboardKey.bracketRight: VK_OEM_6,
  PhysicalKeyboardKey.backslash: VK_OEM_5,
  PhysicalKeyboardKey.backquote: VK_OEM_3,
  PhysicalKeyboardKey.quote: VK_OEM_7,
  PhysicalKeyboardKey.equal: VK_OEM_PLUS,
  PhysicalKeyboardKey.minus: VK_OEM_MINUS,

  // Media / system
  PhysicalKeyboardKey.audioVolumeMute: VK_VOLUME_MUTE,
  PhysicalKeyboardKey.audioVolumeUp: VK_VOLUME_UP,
  PhysicalKeyboardKey.audioVolumeDown: VK_VOLUME_DOWN,
  PhysicalKeyboardKey.mediaTrackNext: VK_MEDIA_NEXT_TRACK,
  PhysicalKeyboardKey.mediaTrackPrevious: VK_MEDIA_PREV_TRACK,
  PhysicalKeyboardKey.mediaPlayPause: VK_MEDIA_PLAY_PAUSE,
  PhysicalKeyboardKey.mediaStop: VK_MEDIA_STOP,
  PhysicalKeyboardKey.contextMenu: VK_APPS,
  PhysicalKeyboardKey.printScreen: VK_SNAPSHOT,
  PhysicalKeyboardKey.pause: VK_PAUSE,
};
