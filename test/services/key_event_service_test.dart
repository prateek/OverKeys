import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';

import 'package:overkeys/models/keyboard_layouts.dart';
import 'package:overkeys/providers/app_state_provider.dart';
import 'package:overkeys/providers/keyboard_provider.dart';
import 'package:overkeys/providers/preferences_provider.dart';
import 'package:overkeys/services/key_event_service.dart';
import 'package:overkeys/services/key_event_source.dart';
import 'package:overkeys/utils/mac_key_code.dart';

/// A test double that lets a test drive synthetic events through the seam.
///
/// The tuples emitted here are exactly what `hooks.dart` produces on Windows
/// and what `macEventToContract` produces on macOS, so asserting on them proves
/// both platforms share one behaviour.
class FakeKeyEventSource implements KeyEventSource {
  void Function(dynamic message)? _onEvent;
  bool disposed = false;

  @override
  void start(void Function(dynamic message) onEvent) => _onEvent = onEvent;

  @override
  void dispose() {
    disposed = true;
    _onEvent = null;
  }

  void emit(dynamic message) => _onEvent?.call(message);

  /// Emits the contract tuples a raw macOS event would normalize to, exercising
  /// the full macOS path (mapping + normalization + handler).
  void emitMac(int keyCode, int kind, int flags) {
    for (final event in macEventToContract(keyCode, kind, flags)) {
      emit(event);
    }
  }
}

/// Pumps a minimal consumer and returns its [WidgetRef] for seeding/asserting
/// provider state.
Future<WidgetRef> pumpRef(WidgetTester tester) async {
  late WidgetRef ref;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (context, r, _) {
          ref = r;
          return const SizedBox();
        }),
      ),
    ),
  );
  return ref;
}

void main() {
  late KeyEventService service;
  late FakeKeyEventSource fake;
  late bool fadeInCalled;
  late bool autoHideReset;

  /// Wires the service to the fake source with the real handler.
  void wire(WidgetRef ref) {
    fadeInCalled = false;
    autoHideReset = false;
    service.setupKeyListener(
      (message) => service.handleKeyEvent(
        message,
        ref,
        () => fadeInCalled = true,
        () => autoHideReset = true,
        () {},
      ),
      source: fake,
    );
  }

  setUp(() {
    service = KeyEventService();
    fake = FakeKeyEventSource();
  });

  group('key press state through the seam', () {
    testWidgets('press then release toggles the glyph', (tester) async {
      final ref = await pumpRef(tester);
      wire(ref);

      fake.emit([VK_A, true, false]);
      expect(ref.read(keyboardProvider).keyPressStates['A'], true);

      // Release double-send (as both platforms emit) clears it.
      fake.emit([VK_A, false, false]);
      fake.emit([VK_A, false, true]);
      expect(ref.read(keyboardProvider).keyPressStates['A'], false);
    });

    testWidgets('shift resolves the shifted glyph', (tester) async {
      final ref = await pumpRef(tester);
      wire(ref);

      // '1' key (VK code 0x31) with shift held -> '!'.
      fake.emit([0x31, true, true]);
      expect(ref.read(keyboardProvider).keyPressStates['!'], true);
      expect(ref.read(keyboardProvider).keyPressStates['1'], isNot(true));
    });

    testWidgets('raw macOS event highlights the same key as Windows',
        (tester) async {
      final ref = await pumpRef(tester);
      wire(ref);

      // Raw macOS 'A' key (kVK_ANSI_A = 0x00) keyDown.
      fake.emitMac(0x00, macEventKindKeyDown, 0);
      expect(ref.read(keyboardProvider).keyPressStates['A'], true);

      // Raw macOS LShift flagsChanged (kVK_Shift = 0x38) press.
      fake.emitMac(0x38, macEventKindFlagsChanged, 0x20000 | 0x02);
      expect(ref.read(keyboardProvider).keyPressStates['LShift'], true);
    });
  });

  group('session events', () {
    testWidgets('unlock clears all key press states', (tester) async {
      final ref = await pumpRef(tester);
      wire(ref);

      fake.emit([VK_A, true, false]);
      fake.emit([VK_S, true, false]);
      expect(ref.read(keyboardProvider).keyPressStates.isNotEmpty, true);

      fake.emit(['session_unlock', true]);
      expect(ref.read(keyboardProvider).keyPressStates, isEmpty);
    });
  });

  group('user layer switching', () {
    const heldLayer = KeyboardLayout(
      name: 'NumLayer',
      keys: [
        ['1', '2', '3']
      ],
      trigger: 'J',
      type: 'held',
    );

    testWidgets('held trigger switches layer and reverts on release',
        (tester) async {
      final ref = await pumpRef(tester);
      // Seed: user layout active with the held layer configured.
      ref.read(preferencesProvider.notifier)
        ..updateUseUserLayout(true)
        ..updateAdvancedSettingsEnabled(true)
        ..updateUserLayers([heldLayer]);
      wire(ref);

      expect(ref.read(keyboardProvider).layout.name, 'QWERTY');

      // Press the trigger key 'J' (VK_J).
      fake.emit([VK_J, true, false]);
      expect(ref.read(keyboardProvider).layout.name, 'NumLayer');

      // Release 'J' (with the double-send both platforms emit) reverts.
      fake.emit([VK_J, false, false]);
      fake.emit([VK_J, false, true]);
      expect(ref.read(keyboardProvider).layout.name, 'QWERTY');
    });
  });

  group('auto-hide', () {
    testWidgets('a keypress fades the overlay back in when hidden',
        (tester) async {
      final ref = await pumpRef(tester);
      ref.read(preferencesProvider.notifier).updateAutoHideEnabled(true);
      ref.read(appStateProvider.notifier).updateIsWindowVisible(false);
      wire(ref);

      fake.emit([VK_A, true, false]);
      expect(fadeInCalled, true);
    });

    testWidgets('a keypress on the default layer resets the hide timer',
        (tester) async {
      final ref = await pumpRef(tester);
      ref.read(preferencesProvider.notifier).updateAutoHideEnabled(true);
      // Window already visible, on the default layer.
      wire(ref);

      fake.emit([VK_A, true, false]);
      expect(autoHideReset, true);
    });
  });

  group('lifecycle', () {
    testWidgets('dispose releases the source', (tester) async {
      final ref = await pumpRef(tester);
      wire(ref);
      service.dispose();
      expect(fake.disposed, true);
    });
  });
}
