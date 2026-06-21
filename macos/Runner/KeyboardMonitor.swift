import Cocoa
import FlutterMacOS
import IOKit.hid

/// Listen-only global keyboard monitor for macOS.
///
/// This is the macOS counterpart to the Windows `SetWindowsHookEx` hook. It is
/// kept deliberately thin: it forwards raw `[keyCode, kind, flags]` triples over
/// an `EventChannel` and lets the Dart side (`mac_key_code.dart`) do all the
/// translation into the shared Windows event contract.
///
/// - `kind`: 0 = keyDown, 1 = keyUp, 2 = flagsChanged (must match
///   `mac_key_code.dart`).
/// - Session lock/unlock arrive via `DistributedNotificationCenter` and are sent
///   as `["session_lock"]` / `["session_unlock"]`.
///
/// The tap is created with `.listenOnly` so OverKeys never modifies or consumes
/// keystrokes — it only observes them.
class KeyboardMonitor: NSObject, FlutterStreamHandler {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var eventSink: FlutterEventSink?
  private var isMonitoring = false

  // Event kinds — keep in sync with mac_key_code.dart.
  private let kindKeyDown = 0
  private let kindKeyUp = 1
  private let kindFlagsChanged = 2

  // MARK: - FlutterStreamHandler

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    registerSessionObservers()
    // Fail Fast: surface a permission/tap failure to Dart so it is logged
    // instead of leaving a silent, dead overlay. The error must be emitted
    // through the sink (which routes to the stream's onError); a FlutterError
    // *returned* from onListen only reaches Flutter's global console handler,
    // not the stream. The user is also prompted by the system during
    // startMonitoring().
    if let error = startMonitoring() {
      events(error)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    stopMonitoring()
    unregisterSessionObservers()
    eventSink = nil
    return nil
  }

  // MARK: - Permissions

  /// Accessibility is required for a session tap to receive key down/up events.
  private func hasAccessibility(prompt: Bool) -> Bool {
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [key: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  /// Input Monitoring (TCC ListenEvent) is required to read key codes.
  private func hasInputMonitoring(prompt: Bool) -> Bool {
    let access = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
    if access == kIOHIDAccessTypeGranted {
      return true
    }
    if prompt {
      IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }
    return false
  }

  // MARK: - Monitoring lifecycle

  private func startMonitoring() -> FlutterError? {
    guard !isMonitoring else { return nil }

    if !hasAccessibility(prompt: true) {
      return FlutterError(
        code: "ACCESSIBILITY_DENIED",
        message:
          "OverKeys needs Accessibility access to see keystrokes. Grant it in "
          + "System Settings > Privacy & Security > Accessibility, then restart OverKeys.",
        details: nil)
    }

    if !hasInputMonitoring(prompt: true) {
      return FlutterError(
        code: "INPUT_MONITORING_DENIED",
        message:
          "OverKeys needs Input Monitoring access to read keystrokes. Grant it in "
          + "System Settings > Privacy & Security > Input Monitoring, then restart OverKeys.",
        details: nil)
    }

    let mask =
      (1 << CGEventType.keyDown.rawValue)
      | (1 << CGEventType.keyUp.rawValue)
      | (1 << CGEventType.flagsChanged.rawValue)

    guard
      let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: CGEventMask(mask),
        callback: { _, type, event, refcon in
          let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!)
            .takeUnretainedValue()
          monitor.handle(type: type, event: event)
          // Listen-only: always pass the event through untouched.
          return Unmanaged.passUnretained(event)
        },
        userInfo: Unmanaged.passUnretained(self).toOpaque()
      )
    else {
      return FlutterError(
        code: "TAP_FAILED",
        message:
          "OverKeys could not create the keyboard event tap. Verify Accessibility "
          + "and Input Monitoring permissions are granted, then restart OverKeys.",
        details: nil)
    }

    eventTap = tap
    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    runLoopSource = source
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    isMonitoring = true
    return nil
  }

  private func stopMonitoring() {
    guard isMonitoring else { return }

    if let tap = eventTap {
      CGEvent.tapEnable(tap: tap, enable: false)
      CFMachPortInvalidate(tap)
    }
    if let source = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
    }
    eventTap = nil
    runLoopSource = nil
    isMonitoring = false
  }

  // MARK: - Event handling

  /// Called on the main run loop for every tapped event.
  private func handle(type: CGEventType, event: CGEvent) {
    // The system disables the tap if our callback is slow or on certain user
    // input; re-arm it so monitoring survives (see keycastr / Apple docs).
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      if let tap = eventTap {
        CGEvent.tapEnable(tap: tap, enable: true)
      }
      return
    }

    let kind: Int
    switch type {
    case .keyDown: kind = kindKeyDown
    case .keyUp: kind = kindKeyUp
    case .flagsChanged: kind = kindFlagsChanged
    default: return
    }

    let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
    let flags = Int(bitPattern: UInt(event.flags.rawValue))
    eventSink?([keyCode, kind, flags])
  }

  // MARK: - Session lock/unlock

  private func registerSessionObservers() {
    let center = DistributedNotificationCenter.default()
    center.addObserver(
      self, selector: #selector(screenLocked),
      name: NSNotification.Name("com.apple.screenIsLocked"), object: nil)
    center.addObserver(
      self, selector: #selector(screenUnlocked),
      name: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil)
  }

  private func unregisterSessionObservers() {
    DistributedNotificationCenter.default().removeObserver(self)
  }

  @objc private func screenLocked() {
    eventSink?(["session_lock"])
  }

  @objc private func screenUnlocked() {
    eventSink?(["session_unlock"])
  }
}
