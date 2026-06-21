import Cocoa
import FlutterMacOS
import ServiceManagement
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  private let keyboardMonitor = KeyboardMonitor()
  private weak var flutterViewController: FlutterViewController?
  private var windowMethodChannel: FlutterMethodChannel?
  private var isKeyboardOverlayWindow = false

  override var canBecomeKey: Bool {
    return !isKeyboardOverlayWindow
  }

  override var canBecomeMain: Bool {
    return !isKeyboardOverlayWindow
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.flutterViewController = flutterViewController

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      RegisterGeneratedPlugins(registry: controller)
    }

    let keyEventChannel = FlutterEventChannel(
      name: "com.overkeys/key_events",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    keyEventChannel.setStreamHandler(keyboardMonitor)

    registerWindowChannel(flutterViewController)
    registerLaunchAtStartupChannel(flutterViewController)

    DispatchQueue.main.async { [weak self] in
      self?.configurePreferencesMenu()
    }

    super.awakeFromNib()
  }

  private func registerWindowChannel(_ controller: FlutterViewController) {
    let windowMethodChannel = FlutterMethodChannel(
      name: "overkeys/window",
      binaryMessenger: controller.engine.binaryMessenger
    )
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
  }

  private func registerLaunchAtStartupChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: controller.engine.binaryMessenger
    )
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
            details: nil
          ))
          return
        }

        let enabled = (call.arguments as? [String: Any])?["setEnabledValue"] as? Bool ?? false
        do {
          if enabled {
            if SMAppService.mainApp.status != .enabled {
              try SMAppService.mainApp.register()
            }
          } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
          }
          result(nil)
        } catch {
          result(FlutterError(
            code: "error",
            message: error.localizedDescription,
            details: nil
          ))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

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
}
