import Cocoa
import FlutterMacOS
import ServiceManagement
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  /// Configures the window to host a Flutter view controller and ensures Flutter plugins are registered for this and any subsequently created windows.
  ///
  /// Sets the window's content view controller to a new `FlutterViewController`, preserves the current window frame, registers generated plugins for the initial Flutter controller, installs the `launch_at_startup` method-channel handler, and installs a callback that registers generated plugins for any new window controllers created at runtime.
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerLaunchAtStartupChannel(flutterViewController)

    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      // Register all plugins for the new window
      RegisterGeneratedPlugins(registry: controller)
    }

    super.awakeFromNib()
  }

  /// Backs the `launch_at_startup` plugin's method channel.
  ///
  /// The plugin has no macOS implementation; it expects the host app to handle
  /// the channel. We use `SMAppService` (macOS 13+) so no extra dependency is
  /// needed; on older systems the feature reports as unavailable instead of
  /// throwing a MissingPluginException.
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
