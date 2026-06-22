import 'dart:async';

import 'package:flutter/services.dart';

import '../utils/logger.dart';
import '../utils/mac_key_code.dart';
import 'key_event_source.dart';

/// macOS event source: listens to the native CGEvent tap over an
/// [EventChannel] and normalizes its raw `[keyCode, kind, flags]` triples into
/// the shared Windows contract. The native side is kept thin on purpose — all
/// translation happens here in pure Dart (see `mac_key_code.dart`).
///
/// Session lock/unlock arrive on the same channel as a `['session_lock']` /
/// `['session_unlock']` list and are forwarded in the Windows contract shape.
class MacOsKeyEventSource implements KeyEventSource {
  /// Must match the channel name registered in `MainFlutterWindow.swift`.
  static const EventChannel _defaultChannel =
      EventChannel('com.overkeys/key_events');

  final _log = SimplePrintLogger('MacOsKeyEventSource');
  final EventChannel _eventChannel;
  StreamSubscription<dynamic>? _subscription;

  MacOsKeyEventSource({EventChannel? eventChannel})
      : _eventChannel = eventChannel ?? _defaultChannel;

  @override
  void start(void Function(dynamic) onEvent) {
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (raw) => _dispatch(raw, onEvent),
      onError: (Object error) {
        // Fail Fast: surface tap/permission failures instead of leaving a
        // silent, dead overlay. The native side also prompts the user.
        _log.error('macOS keyboard monitor error', error: error);
        onEvent(['hook_error', _errorCode(error)]);
      },
    );
  }

  String _errorCode(Object error) {
    if (error is PlatformException) {
      return error.code;
    }
    return 'keyboard_monitor_error';
  }

  void _dispatch(dynamic raw, void Function(dynamic) onEvent) {
    if (raw is! List || raw.isEmpty) return;

    final first = raw[0];
    if (first is String) {
      // Session events mirror the Windows contract: ['session_unlock', true].
      onEvent([first, true]);
      return;
    }

    if (first is! int || raw.length < 3) return;
    final keyCode = raw[0] as int;
    final kind = raw[1] as int;
    final flags = raw[2] as int;
    for (final event in macEventToContract(keyCode, kind, flags)) {
      onEvent(event);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
