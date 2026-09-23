import ManagedSettings
import Foundation

/// Handles taps on the custom shield buttons.
class ShieldActionExtension: ShieldActionDelegate {

  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      // Flag main app to open workout flow
      UserDefaults(suiteName: "group.sweatlock.shared")?
        .set(true, forKey: "pending_workout_open")
      completionHandler(.defer)
    case .secondaryButtonPressed:
      completionHandler(.close)
    @unknown default:
      completionHandler(.close)
    }
  }

  override func handle(
    action: ShieldAction,
    for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      UserDefaults(suiteName: "group.sweatlock.shared")?
        .set(true, forKey: "pending_workout_open")
      completionHandler(.defer)
    default:
      completionHandler(.close)
    }
  }

  override func handle(
    action: ShieldAction,
    for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      UserDefaults(suiteName: "group.sweatlock.shared")?
        .set(true, forKey: "pending_workout_open")
      completionHandler(.defer)
    default:
      completionHandler(.close)
    }
  }
}
