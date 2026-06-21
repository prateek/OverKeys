import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';
import 'package:overkeys/utils/mac_key_code.dart';
import 'package:overkeys/utils/key_code.dart';

/// Resolves a raw macOS event all the way to the displayed glyph, exercising the
/// same path the running app uses: macEventToContract -> getKeyFromKeyCodeShift.
String? glyphFor(int keyCode, int kind, int flags) {
  final events = macEventToContract(keyCode, kind, flags);
  if (events.isEmpty) return null;
  final first = events.first;
  return getKeyFromKeyCodeShift(first[0] as int, first[2] as bool);
}

void main() {
  group('macEventToContract — letters and digits', () {
    test('letter keyDown maps to the Windows VK and glyph', () {
      expect(macEventToContract(0x00, macEventKindKeyDown, 0), [
        [VK_A, true, false],
      ]);
      expect(glyphFor(0x00, macEventKindKeyDown, 0), 'A');
    });

    test('digit resolves shifted and unshifted glyphs (symbols)', () {
      // '1' key (kVK_ANSI_1 = 0x12)
      expect(glyphFor(0x12, macEventKindKeyDown, 0), '1');
      expect(glyphFor(0x12, macEventKindKeyDown, cgEventFlagMaskShift), '!');
    });

    test('OEM symbol key resolves shifted variant', () {
      // '/' key (kVK_ANSI_Slash = 0x2C) -> VK_OEM_2 -> '/' or '?'
      expect(glyphFor(0x2C, macEventKindKeyDown, 0), '/');
      expect(glyphFor(0x2C, macEventKindKeyDown, cgEventFlagMaskShift), '?');
    });
  });

  group('macEventToContract — left/right modifiers via device masks', () {
    test('LShift and RShift are distinguished', () {
      // Left Shift press: aggregate shift + left-shift device bit (0x02).
      expect(
          glyphFor(0x38, macEventKindFlagsChanged, 0x20000 | 0x02), 'LShift');
      // Right Shift press: aggregate shift + right-shift device bit (0x04).
      expect(
          glyphFor(0x3C, macEventKindFlagsChanged, 0x20000 | 0x04), 'RShift');
    });

    test('releasing LShift while RShift is still held reports LShift release',
        () {
      // Aggregate shift is STILL set (RShift held) but the LShift device bit is
      // clear — the device mask must drive the press/release decision, not the
      // aggregate flag.
      final events =
          macEventToContract(0x38, macEventKindFlagsChanged, 0x20000 | 0x04);
      expect(events.first, [VK_LSHIFT, false, true]);
    });

    test('left/right Control map distinctly', () {
      expect(glyphFor(0x3B, macEventKindFlagsChanged, 0x40000 | 0x01),
          'LControl'); // maskControl | LCtrl device
      expect(glyphFor(0x3E, macEventKindFlagsChanged, 0x40000 | 0x2000),
          'RControl'); // maskControl | RCtrl device
    });

    test('Command maps to the Windows key for trigger parity', () {
      expect(glyphFor(0x37, macEventKindFlagsChanged, 0x100000 | 0x08),
          'Win'); // Left Cmd
      expect(glyphFor(0x36, macEventKindFlagsChanged, 0x100000 | 0x10),
          'RWin'); // Right Cmd
    });

    test('left/right Option map to LAlt/RAlt', () {
      expect(glyphFor(0x3A, macEventKindFlagsChanged, 0x80000 | 0x20), 'LAlt');
      expect(glyphFor(0x3D, macEventKindFlagsChanged, 0x80000 | 0x40), 'RAlt');
    });

    test('Caps Lock follows the LED state', () {
      // LED on.
      expect(
          glyphFor(0x39, macEventKindFlagsChanged, cgEventFlagMaskAlphaShift),
          'CapsLock');
      // LED off -> release; the press tuple still carries the glyph.
      final off = macEventToContract(0x39, macEventKindFlagsChanged, 0);
      expect(off.first, [VK_CAPITAL, false, false]);
    });
  });

  group('macEventToContract — release double-send mirrors hooks.dart', () {
    test('letter release clears both shift variants', () {
      expect(macEventToContract(0x00, macEventKindKeyUp, 0), [
        [VK_A, false, false],
        [VK_A, false, true],
      ]);
    });

    test('digit released while shift held clears both glyphs', () {
      // Releasing '1' with shift down must clear both '!' and '1'.
      final events =
          macEventToContract(0x12, macEventKindKeyUp, cgEventFlagMaskShift);
      expect(events, [
        [0x31, false, true],
        [0x31, false, false],
      ]);
      expect(getKeyFromKeyCodeShift(0x31, true), '!');
      expect(getKeyFromKeyCodeShift(0x31, false), '1');
    });

    test('press emits a single tuple (no double-send)', () {
      expect(macEventToContract(0x00, macEventKindKeyDown, 0).length, 1);
    });
  });

  group('macEventToContract — non-US and unknown keys', () {
    test('ISO section key maps to VK_OEM_102 (Windows parity)', () {
      expect(macKeyCodeToVk[0x0A], VK_OEM_102);
      // Neither base layout renders VK_OEM_102, exactly as on Windows.
      expect(getKeyFromKeyCodeShift(VK_OEM_102, false), '');
    });

    test('unmapped key code yields no events', () {
      // fn key (0x3F) is not mapped.
      expect(macEventToContract(0x3F, macEventKindFlagsChanged, 0), isEmpty);
      // An arbitrary out-of-range code.
      expect(macEventToContract(0xFF, macEventKindKeyDown, 0), isEmpty);
    });
  });
}
