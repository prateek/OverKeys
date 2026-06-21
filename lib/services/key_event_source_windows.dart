import 'dart:isolate';

import '../utils/hooks.dart';
import '../utils/logger.dart';
import 'key_event_source.dart';

/// Windows event source: runs the Win32 `SetWindowsHookEx` low-level keyboard
/// hook in a background isolate (see `hooks.dart`) and forwards everything it
/// sends over the [SendPort], unchanged.
class WindowsKeyEventSource implements KeyEventSource {
  final _log = SimplePrintLogger('WindowsKeyEventSource');

  /// Factory for the receive port, overridable for tests.
  final ReceivePort Function() _createReceivePort;
  ReceivePort? _receivePort;

  WindowsKeyEventSource({ReceivePort Function()? createReceivePort})
      : _createReceivePort = createReceivePort ?? ReceivePort.new;

  @override
  void start(void Function(dynamic) onEvent) {
    final port = _createReceivePort();
    _receivePort = port;
    Isolate.spawn(setHook, port.sendPort).then((_) {
      // Only attach the listener after the isolate spawns successfully.
      port.listen(onEvent);
    }).catchError((error) {
      port.close();
      _receivePort = null;
      _log.error('Error spawning keyboard hook isolate', error: error);
      throw error;
    });
  }

  @override
  void dispose() {
    unhook();
    _receivePort?.close();
    _receivePort = null;
  }
}
