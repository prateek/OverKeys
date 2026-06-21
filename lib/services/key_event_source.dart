/// Platform-agnostic source of global keyboard events.
///
/// This is the single seam that isolates the only hard platform lock in the
/// app: capturing keystrokes. Implementations deliver events in one shared
/// contract so that [KeyEventService] and every downstream provider are
/// identical across platforms:
///
/// - Key events: `[winVkCode:int, isPressed:bool, isShiftDown:bool]`
/// - Session events: `['session_lock' | 'session_unlock', true]`
///
/// On Windows the contract comes straight from the Win32 low-level hook; on
/// macOS the native CGEvent tap is normalized into the same shape (see
/// `mac_key_code.dart`).
abstract class KeyEventSource {
  /// Begins delivering events to [onEvent]. Implementations may start
  /// asynchronously; [onEvent] is invoked once delivery is live.
  void start(void Function(dynamic message) onEvent);

  /// Stops delivery and releases all native resources. Safe to call even if
  /// [start] never completed.
  void dispose();
}
