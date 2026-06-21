import 'package:win32/win32.dart';
import '../services/config_service.dart';

/// Key code mapping utilities for converting platform key codes to displayable
/// key names and handling shift key variations.
/// Reference: https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes

/// Default mapping from virtual key codes to key names
final Map<int, String> defaultKeyCodeMap = {
  VK_A: 'A',
  VK_B: 'B',
  VK_C: 'C',
  VK_D: 'D',
  VK_E: 'E',
  VK_F: 'F',
  VK_G: 'G',
  VK_H: 'H',
  VK_I: 'I',
  VK_J: 'J',
  VK_K: 'K',
  VK_L: 'L',
  VK_M: 'M',
  VK_N: 'N',
  VK_O: 'O',
  VK_P: 'P',
  VK_Q: 'Q',
  VK_R: 'R',
  VK_S: 'S',
  VK_T: 'T',
  VK_U: 'U',
  VK_V: 'V',
  VK_W: 'W',
  VK_X: 'X',
  VK_Y: 'Y',
  VK_Z: 'Z',
  VK_F1: 'F1',
  VK_F2: 'F2',
  VK_F3: 'F3',
  VK_F4: 'F4',
  VK_F5: 'F5',
  VK_F6: 'F6',
  VK_F7: 'F7',
  VK_F8: 'F8',
  VK_F9: 'F9',
  VK_F10: 'F10',
  VK_F11: 'F11',
  VK_F12: 'F12',
  VK_F13: 'F13',
  VK_F14: 'F14',
  VK_F15: 'F15',
  VK_F16: 'F16',
  VK_F17: 'F17',
  VK_F18: 'F18',
  VK_F19: 'F19',
  VK_F20: 'F20',
  VK_F21: 'F21',
  VK_F22: 'F22',
  VK_F23: 'F23',
  VK_F24: 'F24',
  VK_RETURN: 'Enter',
  VK_TAB: 'Tab',
  VK_BACK: 'Backspace',
  VK_ESCAPE: 'Escape',
  VK_DELETE: 'Delete',
  VK_INSERT: 'Insert',
  VK_HOME: 'Home',
  VK_END: 'End',
  VK_PRIOR: 'PageUp',
  VK_NEXT: 'PageDown',
  VK_LEFT: 'Left',
  VK_RIGHT: 'Right',
  VK_UP: 'Up',
  VK_DOWN: 'Down',
  VK_LSHIFT: 'LShift',
  VK_RSHIFT: 'RShift',
  VK_LCONTROL: 'LControl',
  VK_RCONTROL: 'RControl',
  VK_LMENU: 'LAlt',
  VK_RMENU: 'RAlt',
  VK_LWIN: 'Win',
  VK_RWIN: 'RWin',
  VK_CAPITAL: 'CapsLock',
  VK_NUMLOCK: 'NumLock',
  VK_SCROLL: 'ScrollLock',
  VK_SPACE: ' ',
  // Numpad keys share state with regular keys
  VK_NUMPAD0: '0',
  VK_NUMPAD1: '1',
  VK_NUMPAD2: '2',
  VK_NUMPAD3: '3',
  VK_NUMPAD4: '4',
  VK_NUMPAD5: '5',
  VK_NUMPAD6: '6',
  VK_NUMPAD7: '7',
  VK_NUMPAD8: '8',
  VK_NUMPAD9: '9',
  VK_MULTIPLY: '*',
  VK_ADD: '+',
  VK_SUBTRACT: '-',
  VK_DECIMAL: '.',
  VK_DIVIDE: '/',
  VK_PAUSE: 'Pause',
  VK_APPS: 'Apps',
  VK_SLEEP: 'Sleep',
  VK_SNAPSHOT: 'PrintScreen',
  VK_BROWSER_BACK: 'BrowserBack',
  VK_BROWSER_FORWARD: 'BrowserForward',
  VK_BROWSER_REFRESH: 'BrowserRefresh',
  VK_BROWSER_STOP: 'BrowserStop',
  VK_BROWSER_SEARCH: 'BrowserSearch',
  VK_BROWSER_FAVORITES: 'BrowserFavorites',
  VK_BROWSER_HOME: 'BrowserHome',
  VK_VOLUME_MUTE: 'Mute',
  VK_VOLUME_DOWN: 'VolumeDown',
  VK_VOLUME_UP: 'VolumeUp',
  VK_MEDIA_NEXT_TRACK: 'NextTrack',
  VK_MEDIA_PREV_TRACK: 'PrevTrack',
  VK_MEDIA_STOP: 'Stop',
  VK_MEDIA_PLAY_PAUSE: 'PlayPause',
  VK_LAUNCH_MAIL: 'LaunchMail',
  VK_LAUNCH_MEDIA_SELECT: 'LaunchMediaSelect',
  VK_LAUNCH_APP1: 'LaunchApp1',
  VK_LAUNCH_APP2: 'LaunchApp2',
  VK_HELP: 'Help',
  VK_SELECT: 'Select',
  VK_PRINT: 'Print',
  VK_EXECUTE: 'Execute',
  VK_CLEAR: 'Clear',
};

/// Mapping of (keyCode, isShiftDown) to display character
/// Handles shifted vs unshifted characters (e.g., 1 vs !, [ vs {)
Map<(int, bool), String> defaultKeyCodeShiftMap = {
  (0x30, false): '0',
  (0x30, true): ')',
  (0x31, false): '1',
  (0x31, true): '!',
  (0x32, false): '2',
  (0x32, true): '@',
  (0x33, false): '3',
  (0x33, true): '#',
  (0x34, false): '4',
  (0x34, true): '\$',
  (0x35, false): '5',
  (0x35, true): '%',
  (0x36, false): '6',
  (0x36, true): '^',
  (0x37, false): '7',
  (0x37, true): '&',
  (0x38, false): '8',
  (0x38, true): '*',
  (0x39, false): '9',
  (0x39, true): '(',
  (VK_OEM_COMMA, false): ',',
  (VK_OEM_COMMA, true): '<',
  (VK_OEM_PERIOD, false): '.',
  (VK_OEM_PERIOD, true): '>',
  (VK_OEM_1, false): ';',
  (VK_OEM_1, true): ':',
  (VK_OEM_2, false): '/',
  (VK_OEM_2, true): '?',
  (VK_OEM_4, false): '[',
  (VK_OEM_4, true): '{',
  (VK_OEM_6, false): ']',
  (VK_OEM_6, true): '}',
  (VK_OEM_5, false): '\\',
  (VK_OEM_5, true): '|',
  (VK_OEM_3, false): '`',
  (VK_OEM_3, true): '~',
  (VK_OEM_7, false): "'",
  (VK_OEM_7, true): '"',
  (VK_OEM_PLUS, false): '=',
  (VK_OEM_PLUS, true): '+',
  (VK_OEM_MINUS, false): '-',
  (VK_OEM_MINUS, true): '_',
};

/// Active key code mapping that can be overridden by user configuration
Map<(int, bool), String> activeKeyCodeShiftMap =
    Map<(int, bool), String>.from(defaultKeyCodeShiftMap);

/// Maps macOS hardware key codes from CGEvent taps to Windows virtual key codes.
///
/// OverKeys stores key mappings as Windows virtual key codes, so the macOS hook
/// normalizes events before they reach the rest of the app.
const Map<int, int> macOSKeyCodeToWindowsKeyCode = {
  0: VK_A,
  1: VK_S,
  2: VK_D,
  3: VK_F,
  4: VK_H,
  5: VK_G,
  6: VK_Z,
  7: VK_X,
  8: VK_C,
  9: VK_V,
  11: VK_B,
  12: VK_Q,
  13: VK_W,
  14: VK_E,
  15: VK_R,
  16: VK_Y,
  17: VK_T,
  18: 0x31,
  19: 0x32,
  20: 0x33,
  21: 0x34,
  22: 0x36,
  23: 0x35,
  24: VK_OEM_PLUS,
  25: 0x39,
  26: 0x37,
  27: VK_OEM_MINUS,
  28: 0x38,
  29: 0x30,
  30: VK_OEM_6,
  31: VK_O,
  32: VK_U,
  33: VK_OEM_4,
  34: VK_I,
  35: VK_P,
  36: VK_RETURN,
  37: VK_L,
  38: VK_J,
  39: VK_OEM_7,
  40: VK_K,
  41: VK_OEM_1,
  42: VK_OEM_5,
  43: VK_OEM_COMMA,
  44: VK_OEM_2,
  45: VK_N,
  46: VK_M,
  47: VK_OEM_PERIOD,
  48: VK_TAB,
  49: VK_SPACE,
  50: VK_OEM_3,
  51: VK_BACK,
  53: VK_ESCAPE,
  54: VK_RWIN,
  55: VK_LWIN,
  56: VK_LSHIFT,
  57: VK_CAPITAL,
  58: VK_LMENU,
  59: VK_LCONTROL,
  60: VK_RSHIFT,
  61: VK_RMENU,
  62: VK_RCONTROL,
  64: VK_F17,
  65: VK_DECIMAL,
  67: VK_MULTIPLY,
  69: VK_ADD,
  71: VK_CLEAR,
  75: VK_DIVIDE,
  76: VK_RETURN,
  78: VK_SUBTRACT,
  79: VK_F18,
  80: VK_F19,
  82: VK_NUMPAD0,
  83: VK_NUMPAD1,
  84: VK_NUMPAD2,
  85: VK_NUMPAD3,
  86: VK_NUMPAD4,
  87: VK_NUMPAD5,
  88: VK_NUMPAD6,
  89: VK_NUMPAD7,
  90: VK_F20,
  91: VK_NUMPAD8,
  92: VK_NUMPAD9,
  96: VK_F5,
  97: VK_F6,
  98: VK_F7,
  99: VK_F3,
  100: VK_F8,
  101: VK_F9,
  103: VK_F11,
  105: VK_F13,
  106: VK_F16,
  107: VK_F14,
  109: VK_F10,
  111: VK_F12,
  113: VK_F15,
  114: VK_INSERT,
  115: VK_HOME,
  116: VK_PRIOR,
  117: VK_DELETE,
  118: VK_F4,
  119: VK_END,
  120: VK_F2,
  121: VK_NEXT,
  122: VK_F1,
  123: VK_LEFT,
  124: VK_RIGHT,
  125: VK_DOWN,
  126: VK_UP,
};

/// Normalizes a macOS hardware key code to the Windows virtual key code used by
/// the rest of the app. Unknown keys pass through unchanged.
int normalizeMacOSKeyCode(int keyCode) {
  return macOSKeyCodeToWindowsKeyCode[keyCode] ?? keyCode;
}

/// Loads custom key mappings from user configuration
Future<void> loadCustomKeys() async {
  final config = await ConfigService().loadConfig();
  activeKeyCodeShiftMap = Map<(int, bool), String>.from(defaultKeyCodeShiftMap);
  if (config.customKeys != null && config.customKeys!['keyCodeMap'] != null) {
    final rawMap = config.customKeys!['keyCodeMap'] as Map;
    rawMap.forEach((key, value) {
      if (value is int) {
        activeKeyCodeShiftMap[(value, false)] = key.toString();
        activeKeyCodeShiftMap[(value, true)] = key.toString();
      }
    });
  }

  if (config.customKeys != null &&
      config.customKeys!['keyCodeShiftMap'] != null) {
    final rawMap = config.customKeys!['keyCodeShiftMap'] as Map;
    rawMap.forEach((key, value) {
      if (value is int) {
        activeKeyCodeShiftMap[(value, true)] = key.toString();
      }
    });
  }
}

/// Converts a normalized key code to a displayable key name.
/// Takes into account whether shift is pressed.
String getKeyFromKeyCodeShift(int keyCode, bool isShiftDown) {
  return activeKeyCodeShiftMap[(keyCode, isShiftDown)] ??
      defaultKeyCodeMap[keyCode] ??
      '';
}
