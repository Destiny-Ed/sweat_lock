import ManagedSettings
import Foundation
import UIKit

/// Primary button → open SweatLock workout via URL scheme.
class ShieldActionExtension: ShieldActionDelegate {

  private let appGroupId = "group.com.sweat.lock.shield"

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
      let defaults = UserDefaults(suiteName: appGroupId)
      defaults?.set(true, forKey: "pending_workout_open")
      defaults?.synchronize()
      openSweatLock()
      // .defer keeps extension lifecycle a moment so open can start
      completionHandler(.defer)
      // Also try close after short delay path — system varies by iOS version
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        // no-op; already completed
      }

    case .secondaryButtonPressed:
      completionHandler(.close)

    @unknown default:
      completionHandler(.close)
    }
  }

  private func openSweatLock() {
    guard let url = URL(string: "sweatlock://workout") else { return }

    // 1) UIApplication via runtime (extension-safe)
    if let app = UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication {
      app.open(url, options: [:], completionHandler: nil)
      return
    }

    // 2) Selector fallback
    let selector = NSSelectorFromString("sharedApplication")
    if let appType = NSClassFromString("UIApplication") as? NSObject.Type,
       appType.responds(to: selector),
       let app = appType.perform(selector)?.takeUnretainedValue() as? UIApplication {
      app.open(url, options: [:], completionHandler: nil)
    }
  }
}
