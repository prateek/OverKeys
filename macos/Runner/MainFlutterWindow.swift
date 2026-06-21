import Cocoa
import FlutterMacOS
import ServiceManagement
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  /// Strongly retains the keyboard monitor for the lifetime of the window.
  private var keyboardMonitor: KeyboardMonitor?
  private weak var flutterViewController: FlutterViewController?
  private var windowMethodChannel: FlutterMethodChannel?

  /// True once Dart marks this as the click-through overlay window. The overlay
  /// must never become key/main so it can't steal focus from Preferences.
  private var isKeyboardOverlayWindow = false

  override var canBecomeKey: Bool {
    return !isKeyboardOverlayWindow
  }

  override var canBecomeMain: Bool {
    return !isKeyboardOverlayWindow
  }

  /// Hosts the Flutter view controller, registers plugins for this and future
  /// windows, wires the listen-only keyboard monitor and window channel, routes
  /// the Settings menu item to Preferences, and backs launch-at-startup.
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.flutterViewController = flutterViewController
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register all plugins for windows created at runtime (e.g. Preferences).
      RegisterGeneratedPlugins(registry: controller)
    }

    let messenger = flutterViewController.engine.binaryMessenger

    // Wire the listen-only keyboard monitor. The channel name must match
    // MacOsKeyEventSource in lib/services/key_event_source_macos.dart.
    let monitor = KeyboardMonitor()
    let keyEventChannel = FlutterEventChannel(
      name: "com.overkeys/key_events",
      binaryMessenger: messenger)
    keyEventChannel.setStreamHandler(monitor)
    self.keyboardMonitor = monitor

    // Window channel: lets Dart mark this window as the click-through overlay.
    let windowMethodChannel = FlutterMethodChannel(
      name: "overkeys/window",
      binaryMessenger: messenger)
    self.windowMethodChannel = windowMethodChannel
    windowMethodChannel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "configureKeyboardOverlay":
        self?.configureKeyboardOverlay()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // The app menu isn't populated yet at awakeFromNib; defer wiring Settings.
    DispatchQueue.main.async { [weak self] in
      self?.configurePreferencesMenu()
    }

    registerLaunchAtStartupChannel(messenger)

    super.awakeFromNib()
  }

  /// Marks this window as the click-through keyboard overlay: transparent,
  /// shadow-less, present on all spaces, and never key/main. Invoked from Dart
  /// for the main window only (see `_configureNativeKeyboardOverlay` in main.dart),
  /// which keeps the separate Preferences window focusable.
  private func configureKeyboardOverlay() {
    isKeyboardOverlayWindow = true
    backgroundColor = NSColor.clear
    isOpaque = false
    hasShadow = false
    collectionBehavior.insert(.canJoinAllSpaces)
    collectionBehavior.insert(.fullScreenAuxiliary)

    flutterViewController?.backgroundColor = NSColor.clear
    flutterViewController?.view.wantsLayer = true
    flutterViewController?.view.layer?.backgroundColor = NSColor.clear.cgColor
    flutterViewController?.view.layer?.isOpaque = false
  }

  /// Retargets the standard AppKit "Settings…" (⌘,) menu item at our handler so
  /// it opens Preferences. The item is otherwise dead on macOS because Flutter
  /// never receives the action.
  private func configurePreferencesMenu(retryCount: Int = 1) {
    guard let appMenu = NSApp.mainMenu?.items.first?.submenu else {
      retryConfigurePreferencesMenu(retryCount: retryCount)
      return
    }

    if let preferencesItem = appMenu.items.first(where: { $0.keyEquivalent == "," }) {
      preferencesItem.target = self
      preferencesItem.action = #selector(openPreferencesFromMenu(_:))
      preferencesItem.isEnabled = true
    } else {
      NSLog("OverKeys: could not find Preferences menu item to wire Settings")
    }
  }

  private func retryConfigurePreferencesMenu(retryCount: Int) {
    guard retryCount > 0 else {
      NSLog("OverKeys: app menu was unavailable while wiring Settings")
      return
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.configurePreferencesMenu(retryCount: retryCount - 1)
    }
  }

  @objc private func openPreferencesFromMenu(_ sender: Any?) {
    windowMethodChannel?.invokeMethod("openPreferences", arguments: nil) { result in
      if let error = result as? FlutterError {
        NSLog("OverKeys: Settings menu failed to open Preferences: \(error.message ?? error.code)")
      } else if let value = result as? NSObject, value == FlutterMethodNotImplemented {
        NSLog("OverKeys: Settings menu handler is not registered in Flutter")
      }
    }
  }

  /// Backs the `launch_at_startup` plugin's method channel.
  ///
  /// The plugin has no macOS implementation; it expects the host app to handle
  /// the channel. We use `SMAppService` (macOS 13+) so no extra dependency is
  /// needed; on older systems the feature reports as unavailable instead of
  /// throwing a MissingPluginException.
  private func registerLaunchAtStartupChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "launchAtStartupIsEnabled":
        if #available(macOS 13.0, *) {
          result(SMAppService.mainApp.status == .enabled)
        } else {
          result(false)
        }
      case "launchAtStartupSetEnabled":
        guard #available(macOS 13.0, *) else {
          result(FlutterError(
            code: "unsupported",
            message: "Launch at startup requires macOS 13 or later.",
            details: nil))
          return
        }
        let enabled = (call.arguments as? [String: Any])?["setEnabledValue"] as? Bool ?? false
        do {
          if enabled {
            if SMAppService.mainApp.status != .enabled {
              try SMAppService.mainApp.register()
            }
          } else {
            if SMAppService.mainApp.status == .enabled {
              try SMAppService.mainApp.unregister()
            }
          }
          result(nil)
        } catch {
          result(FlutterError(
            code: "error", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
