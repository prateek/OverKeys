import 'package:win32/win32.dart';

/// macOS event source normalization.
///
/// The native CGEvent tap (see `macos/Runner/KeyboardMonitor.swift`) is kept
/// deliberately thin: it forwards raw `[keyCode, kind, flags]` triples. All the
/// interesting logic lives here as pure, table-driven Dart so it can be unit
/// tested without the platform channel.
///
/// The job of this file is to translate a macOS hardware event into the exact
/// same contract the Windows hook emits (`[winVkCode, isPressed, isShiftDown]`),
/// so that `key_code.dart`, `key_event_service.dart`, and every downstream
/// provider stay untouched and behave identically on both platforms.
///
/// References:
/// - Carbon `kVK_*` virtual key codes (HIToolbox/Events.h)
/// - IOKit device-dependent modifier masks (IOKit/hidsystem/IOLLEvent.h)
/// - Win32 virtual key codes:
///   https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes

/// Event kinds sent by the native tap. Must stay in sync with the `kind`
/// values produced in `KeyboardMonitor.swift`.
const int macEventKindKeyDown = 0;
const int macEventKindKeyUp = 1;
const int macEventKindFlagsChanged = 2;

/// `CGEventFlags` bit for any Shift key being held. Used to derive the
/// `isShiftDown` element of the contract for every event.
const int cgEventFlagMaskShift = 0x20000; // kCGEventFlagMaskShift (1 << 17)

/// `CGEventFlags` bit reflecting the Caps Lock LED state.
const int cgEventFlagMaskAlphaShift = 0x10000; // kCGEventFlagMaskAlphaShift

/// IOKit device-dependent modifier masks (low byte of `CGEventFlags`).
///
/// Unlike the aggregate masks (`maskShift` etc.), these distinguish the left
/// and right physical modifier keys, which is what lets us report `LShift`
/// versus `RShift` correctly. Hardware-generated events carry these bits.
const int _nxDeviceLCtrl = 0x00000001;
const int _nxDeviceLShift = 0x00000002;
const int _nxDeviceRShift = 0x00000004;
const int _nxDeviceLCmd = 0x00000008;
const int _nxDeviceRCmd = 0x00000010;
const int _nxDeviceLAlt = 0x00000020;
const int _nxDeviceRAlt = 0x00000040;
const int _nxDeviceRCtrl = 0x00002000;

/// Maps a macOS Carbon virtual key code to its Win32 virtual key code, so the
/// existing `getKeyFromKeyCodeShift` mapping is reused verbatim.
///
/// Digits are mapped to their raw `0x30`-`0x39` codes to match the keys used in
/// `defaultKeyCodeShiftMap`. The keypad shares state with the main keys, mirroring
/// the Windows behaviour where `VK_NUMPAD*` resolve to the same glyphs.
const Map<int, int> macKeyCodeToVk = {
  // Letters
  0x00: VK_A, 0x0B: VK_B, 0x08: VK_C, 0x02: VK_D, 0x0E: VK_E, 0x03: VK_F,
  0x05: VK_G, 0x04: VK_H, 0x22: VK_I, 0x26: VK_J, 0x28: VK_K, 0x25: VK_L,
  0x2E: VK_M, 0x2D: VK_N, 0x1F: VK_O, 0x23: VK_P, 0x0C: VK_Q, 0x0F: VK_R,
  0x01: VK_S, 0x11: VK_T, 0x20: VK_U, 0x09: VK_V, 0x0D: VK_W, 0x07: VK_X,
  0x10: VK_Y, 0x06: VK_Z,

  // Number row (raw VK codes, matching defaultKeyCodeShiftMap)
  0x1D: 0x30, 0x12: 0x31, 0x13: 0x32, 0x14: 0x33, 0x15: 0x34,
  0x17: 0x35, 0x16: 0x36, 0x1A: 0x37, 0x1C: 0x38, 0x19: 0x39,

  // Symbols / OEM keys
  0x2B: VK_OEM_COMMA, // ,
  0x2F: VK_OEM_PERIOD, // .
  0x29: VK_OEM_1, // ;
  0x2C: VK_OEM_2, // /
  0x21: VK_OEM_4, // [
  0x1E: VK_OEM_6, // ]
  0x2A: VK_OEM_5, // backslash
  0x32: VK_OEM_3, // `
  0x27: VK_OEM_7, // '
  0x18: VK_OEM_PLUS, // =
  0x1B: VK_OEM_MINUS, // -
  // Non-US: the extra key next to Left Shift on ISO keyboards. Maps to the same
  // VK_OEM_102 Windows reports; neither base layout renders it, preserving parity.
  0x0A: VK_OEM_102,

  // Function keys
  0x7A: VK_F1, 0x78: VK_F2, 0x63: VK_F3, 0x76: VK_F4, 0x60: VK_F5,
  0x61: VK_F6, 0x62: VK_F7, 0x64: VK_F8, 0x65: VK_F9, 0x6D: VK_F10,
  0x67: VK_F11, 0x6F: VK_F12, 0x69: VK_F13, 0x6B: VK_F14, 0x71: VK_F15,
  0x6A: VK_F16, 0x40: VK_F17, 0x4F: VK_F18, 0x50: VK_F19, 0x5A: VK_F20,

  // Navigation / editing
  0x24: VK_RETURN,
  0x30: VK_TAB,
  0x33: VK_BACK,
  0x35: VK_ESCAPE,
  0x75: VK_DELETE,
  0x72: VK_INSERT,
  0x73: VK_HOME,
  0x77: VK_END,
  0x74: VK_PRIOR, // PageUp
  0x79: VK_NEXT, // PageDown
  0x7B: VK_LEFT,
  0x7C: VK_RIGHT,
  0x7E: VK_UP,
  0x7D: VK_DOWN,
  0x31: VK_SPACE,

  // Modifiers (left/right distinguished). Cmd maps to the Windows key for
  // layer-trigger parity ('Win' / 'RWin').
  0x38: VK_LSHIFT,
  0x3C: VK_RSHIFT,
  0x3B: VK_LCONTROL,
  0x3E: VK_RCONTROL,
  0x3A: VK_LMENU, // Left Option -> LAlt
  0x3D: VK_RMENU, // Right Option -> RAlt
  0x37: VK_LWIN, // Left Command -> Win
  0x36: VK_RWIN, // Right Command -> RWin
  0x39: VK_CAPITAL, // Caps Lock

  // Keypad (shares glyphs with the main keys, as on Windows)
  0x52: VK_NUMPAD0, 0x53: VK_NUMPAD1, 0x54: VK_NUMPAD2, 0x55: VK_NUMPAD3,
  0x56: VK_NUMPAD4, 0x57: VK_NUMPAD5, 0x58: VK_NUMPAD6, 0x59: VK_NUMPAD7,
  0x5B: VK_NUMPAD8, 0x5C: VK_NUMPAD9,
  0x43: VK_MULTIPLY,
  0x45: VK_ADD,
  0x4E: VK_SUBTRACT,
  0x41: VK_DECIMAL,
  0x4B: VK_DIVIDE,
  0x4C: VK_RETURN, // Keypad Enter
};

/// For a modifier `flagsChanged` event, the device-dependent flag bit whose
/// presence means the corresponding physical key is currently held.
const Map<int, int> _modifierStateMask = {
  0x38: _nxDeviceLShift,
  0x3C: _nxDeviceRShift,
  0x3B: _nxDeviceLCtrl,
  0x3E: _nxDeviceRCtrl,
  0x3A: _nxDeviceLAlt,
  0x3D: _nxDeviceRAlt,
  0x37: _nxDeviceLCmd,
  0x36: _nxDeviceRCmd,
  0x39: cgEventFlagMaskAlphaShift, // Caps Lock follows the LED state
};

/// Converts a raw macOS event into zero or more Windows-contract tuples
/// (`[winVkCode, isPressed, isShiftDown]`).
///
/// Returns an empty list for key codes we do not map (so unknown keys are
/// silently ignored, as on Windows). On release it emits a second tuple with
/// the shift flag flipped, mirroring `hooks.dart` so that both the shifted and
/// unshifted glyph of a key are cleared regardless of the shift state at
/// release time.
List<List<Object>> macEventToContract(int keyCode, int kind, int flags) {
  final vk = macKeyCodeToVk[keyCode];
  if (vk == null) return const [];

  final bool isShiftDown = (flags & cgEventFlagMaskShift) != 0;

  final bool isPressed;
  if (kind == macEventKindFlagsChanged) {
    final mask = _modifierStateMask[keyCode];
    if (mask == null) return const [];
    isPressed = (flags & mask) != 0;
  } else {
    isPressed = kind == macEventKindKeyDown;
  }

  final events = <List<Object>>[
    [vk, isPressed, isShiftDown],
  ];
  if (!isPressed) {
    events.add([vk, false, !isShiftDown]);
  }
  return events;
}
