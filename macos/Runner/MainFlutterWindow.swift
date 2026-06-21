import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  /// Strongly retains the keyboard monitor for the lifetime of the window.
  private var keyboardMonitor: KeyboardMonitor?

  /// Configures the window to host a Flutter view controller, registers plugins
  /// for this and future windows, makes the overlay transparent/shadow-less, and
  /// wires the listen-only keyboard monitor to its EventChannel.
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame

    // Transparent, shadow-less overlay to match the Windows overlay window.
    flutterViewController.backgroundColor = NSColor.clear
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    self.hasShadow = false
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.backgroundColor = NSColor.clear.cgColor

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register all plugins for windows created at runtime (e.g. Preferences).
      RegisterGeneratedPlugins(registry: controller)
    }

    // Wire the listen-only keyboard monitor. The channel name must match
    // MacOsKeyEventSource in lib/services/key_event_source_macos.dart.
    let monitor = KeyboardMonitor()
    let keyEventChannel = FlutterEventChannel(
      name: "com.overkeys/key_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    keyEventChannel.setStreamHandler(monitor)
    self.keyboardMonitor = monitor

    super.awakeFromNib()
  }
}
