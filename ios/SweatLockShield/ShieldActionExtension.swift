import ManagedSettings
import UIKit

/// Handles taps on the custom shield buttons.
class ShieldActionExtension: ShieldActionDelegate {

  override func handle(
    action: ShieldAction,
    for application: Application,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      // Open SweatLock so user can start workout
      openSweatLock()
      completionHandler(.defer)
    case .secondaryButtonPressed:
      completionHandler(.close)
    @unknown default:
      completionHandler(.close)
    }
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomain,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      openSweatLock()
      completionHandler(.defer)
    case .secondaryButtonPressed:
      completionHandler(.close)
    @unknown default:
      completionHandler(.close)
    }
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategory,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      openSweatLock()
      completionHandler(.defer)
    case .secondaryButtonPressed:
      completionHandler(.close)
    @unknown default:
      completionHandler(.close)
    }
  }

  private func openSweatLock() {
    // Deep link into main app workout flow
    guard let url = URL(string: "sweatlock://workout") else { return }
    // Extension open is limited; system returns control to host app via .defer
    // Main app should handle sweatlock://workout in AppDelegate
    let defaults = UserDefaults(suiteName: "group.sweatlock.shared")
    defaults?.set(true, forKey: "pending_workout_open")
    defaults?.synchronize()
  }
}
