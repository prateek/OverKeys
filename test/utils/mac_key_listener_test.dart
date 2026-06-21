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
      // metaLeft maps to the 'Win' key name used across layouts/aliases.
      expect(resolve(PhysicalKeyboardKey.metaLeft), 'Win');
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
