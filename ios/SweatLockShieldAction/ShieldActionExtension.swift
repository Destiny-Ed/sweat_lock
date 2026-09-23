import ManagedSettings
import Foundation
import UIKit

/// Handles taps on the custom shield buttons.
class ShieldActionExtension: ShieldActionDelegate {

  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handleAction(action, completionHandler: completionHandler)
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handleAction(action, completionHandler: completionHandler)
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handleAction(action, completionHandler: completionHandler)
  }

  private func handleAction(
    _ action: ShieldAction,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      // Mark intent for Flutter when app becomes active
      let defaults = UserDefaults(suiteName: "group.sweatlock.shared")
      defaults?.set(true, forKey: "pending_workout_open")
      defaults?.set(Date().timeIntervalSince1970, forKey: "pending_workout_at")
      defaults?.synchronize()

      // Open host app via URL scheme (extension-safe)
      openSweatLockApp()

      // .close dismisses shield briefly; host app should be in foreground
      completionHandler(.close)

    case .secondaryButtonPressed:
      completionHandler(.close)

    @unknown default:
      completionHandler(.close)
    }
  }

  /// Opens sweatlock://workout from an app extension context.
  private func openSweatLockApp() {
    guard let url = URL(string: "sweatlock://workout") else { return }

    // UIApplication.shared is unavailable in extensions; use runtime lookup.
    let selector = NSSelectorFromString("sharedApplication")
    guard let appType = NSClassFromString("UIApplication") as? NSObject.Type,
          appType.responds(to: selector),
          let unmanaged = appType.perform(selector),
          let app = unmanaged.takeUnretainedValue() as? UIApplication else {
      // Fallback: Darwin notification so a background process could wake — flag is enough
      return
    }

    if app.responds(to: #selector(UIApplication.open(_:options:completionHandler:))) {
      app.open(url, options: [:], completionHandler: nil)
    } else {
      app.perform(NSSelectorFromString("openURL:"), with: url)
    }
  }
}
