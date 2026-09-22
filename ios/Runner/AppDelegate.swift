import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Screen Time / soft-nudge channel
    // Full FamilyControls requires paid Apple Developer account + entitlements.
    // This channel provides a safe stub so Flutter side works without crashing.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sweatlock/screen_time",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { (call, result) in
        switch call.method {
        case "requestAuthorization":
          // Return false until FamilyControls entitlement is configured
          result(false)

        case "selectApps":
          // Placeholder: return empty list until native picker is wired
          // with FamilyActivityPicker + company entitlement
          result([])

        case "getAppUsage":
          // Placeholder usage data
          result([])

        case "resetUsage":
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
