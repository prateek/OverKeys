import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overkeys/utils/key_code.dart';
import 'package:overkeys/utils/mac_key_listener.dart';

/// Resolves a physical key the way the macOS listener does: translate it to a
/// virtual-key code, then resolve that to a display name through the shared
/// key-code pipeline. This is the cross-platform parity contract.
String resolve(PhysicalKeyboardKey key, {bool shift = false}) {
  final vk = virtualKeyForPhysicalKey(key);
  expect(vk, isNotNull, reason: 'no virtual-key mapping for $key');
  return getKeyFromKeyCodeShift(vk!, shift);
}

void main() {
  group('macOS physical key mapping', () {
    setUp(() {
      activeKeyCodeShiftMap =
          Map<(int, bool), String>.from(defaultKeyCodeShiftMap);
    });

    test('letters resolve to their display name', () {
      expect(resolve(PhysicalKeyboardKey.keyA), 'A');
      expect(resolve(PhysicalKeyboardKey.keyZ), 'Z');
      // Letters are positional, independent of the produced character.
      expect(resolve(PhysicalKeyboardKey.keyA, shift: true), 'A');
    });

    test('top-row digits resolve to digit and shifted symbol', () {
      expect(resolve(PhysicalKeyboardKey.digit1), '1');
      expect(resolve(PhysicalKeyboardKey.digit1, shift: true), '!');
      expect(resolve(PhysicalKeyboardKey.digit0), '0');
      expect(resolve(PhysicalKeyboardKey.digit0, shift: true), ')');
    });

    test('punctuation resolves to unshifted and shifted variants', () {
      expect(resolve(PhysicalKeyboardKey.comma), ',');
      expect(resolve(PhysicalKeyboardKey.comma, shift: true), '<');
      expect(resolve(PhysicalKeyboardKey.semicolon), ';');
      expect(resolve(PhysicalKeyboardKey.semicolon, shift: true), ':');
      expect(resolve(PhysicalKeyboardKey.slash), '/');
      expect(resolve(PhysicalKeyboardKey.slash, shift: true), '?');
      expect(resolve(PhysicalKeyboardKey.bracketLeft), '[');
      expect(resolve(PhysicalKeyboardKey.bracketLeft, shift: true), '{');
      expect(resolve(PhysicalKeyboardKey.equal), '=');
      expect(resolve(PhysicalKeyboardKey.equal, shift: true), '+');
      expect(resolve(PhysicalKeyboardKey.minus), '-');
      expect(resolve(PhysicalKeyboardKey.minus, shift: true), '_');
    });

    test('modifiers keep the left/right distinction the app expects', () {
      expect(resolve(PhysicalKeyboardKey.shiftLeft), 'LShift');
      expect(resolve(PhysicalKeyboardKey.shiftRight), 'RShift');
      expect(resolve(PhysicalKeyboardKey.controlLeft), 'LControl');
      expect(resolve(PhysicalKeyboardKey.controlRight), 'RControl');
      expect(resolve(PhysicalKeyboardKey.altLeft), 'LAlt');
      expect(resolve(PhysicalKeyboardKey.altRight), 'RAlt');
      // metaLeft/metaRight map to the 'Win'/'RWin' names used across
      // layouts and the custom-alias logic.
      expect(resolve(PhysicalKeyboardKey.metaLeft), 'Win');
      expect(resolve(PhysicalKeyboardKey.metaRight), 'RWin');
    });

    test('numpad keys share state with their digit/operator names', () {
      expect(resolve(PhysicalKeyboardKey.numpad0), '0');
      expect(resolve(PhysicalKeyboardKey.numpad9), '9');
      expect(resolve(PhysicalKeyboardKey.numpadAdd), '+');
      expect(resolve(PhysicalKeyboardKey.numpadSubtract), '-');
      expect(resolve(PhysicalKeyboardKey.numpadMultiply), '*');
      expect(resolve(PhysicalKeyboardKey.numpadDivide), '/');
      expect(resolve(PhysicalKeyboardKey.numpadDecimal), '.');
      // Both Enter keys resolve to 'Enter', matching Windows.
      expect(resolve(PhysicalKeyboardKey.numpadEnter), 'Enter');
    });

    test('high function keys and lock keys resolve', () {
      expect(resolve(PhysicalKeyboardKey.f13), 'F13');
      expect(resolve(PhysicalKeyboardKey.f24), 'F24');
      expect(resolve(PhysicalKeyboardKey.numLock), 'NumLock');
      expect(resolve(PhysicalKeyboardKey.scrollLock), 'ScrollLock');
    });

    test('media keys resolve to their names', () {
      expect(resolve(PhysicalKeyboardKey.audioVolumeMute), 'Mute');
      expect(resolve(PhysicalKeyboardKey.audioVolumeUp), 'VolumeUp');
      expect(resolve(PhysicalKeyboardKey.mediaTrackNext), 'NextTrack');
      expect(resolve(PhysicalKeyboardKey.mediaPlayPause), 'PlayPause');
    });
  });

  group('keyEventMessages (Windows-hook parity)', () {
    test('key-down emits a single primary message', () {
      final vk = virtualKeyForPhysicalKey(PhysicalKeyboardKey.keyA)!;
      expect(
        keyEventMessages(PhysicalKeyboardKey.keyA, true, false),
        [
          [vk, true, false]
        ],
      );
    });

    test('key-up also emits the opposite-shift release', () {
      // Mirrors lib/utils/hooks.dart: on release, clear both shift variants so
      // a shifted symbol does not stay highlighted.
      final vk = virtualKeyForPhysicalKey(PhysicalKeyboardKey.digit1)!;
      expect(
        keyEventMessages(PhysicalKeyboardKey.digit1, false, true),
        [
          [vk, false, true],
          [vk, false, false],
        ],
      );
    });

    test('unmapped keys emit nothing', () {
      expect(keyEventMessages(PhysicalKeyboardKey.fn, true, false), isEmpty);
    });

    test('special and navigation keys resolve correctly', () {
      expect(resolve(PhysicalKeyboardKey.space), ' ');
      expect(resolve(PhysicalKeyboardKey.enter), 'Enter');
      expect(resolve(PhysicalKeyboardKey.tab), 'Tab');
      expect(resolve(PhysicalKeyboardKey.backspace), 'Backspace');
      expect(resolve(PhysicalKeyboardKey.escape), 'Escape');
      expect(resolve(PhysicalKeyboardKey.arrowLeft), 'Left');
      expect(resolve(PhysicalKeyboardKey.capsLock), 'CapsLock');
      expect(resolve(PhysicalKeyboardKey.f1), 'F1');
    });

    test('unmapped physical keys return null', () {
      expect(virtualKeyForPhysicalKey(PhysicalKeyboardKey.fn), isNull);
    });

    test('custom key overrides flow through to macOS events', () {
      // The user remap config keys on virtual-key codes; macOS events reuse it.
      final vk = virtualKeyForPhysicalKey(PhysicalKeyboardKey.semicolon)!;
      activeKeyCodeShiftMap[(vk, false)] = 'custom';
      expect(getKeyFromKeyCodeShift(vk, false), 'custom');
    });
  });
}
