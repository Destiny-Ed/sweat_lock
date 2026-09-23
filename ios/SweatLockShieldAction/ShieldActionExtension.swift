import ManagedSettings
import Foundation
import UserNotifications

/// Primary button → notification "Tap to open SweatLock" (reliable on iOS).
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

      // Extensions cannot reliably open the host app; notify user to tap.
      postOpenAppNotification()
      completionHandler(.close)

    case .secondaryButtonPressed:
      completionHandler(.close)

    @unknown default:
      completionHandler(.close)
    }
  }

  private func postOpenAppNotification() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
      guard granted else { return }

      let content = UNMutableNotificationContent()
      content.title = "SweatLock"
      content.body = "Tap to open SweatLock and start your workout"
      content.sound = .default
      content.userInfo = [
        "openWorkout": true,
        "deeplink": "sweatlock://workout",
      ]

      let req = UNNotificationRequest(
        identifier: "sweatlock_open_app",
        content: content,
        trigger: nil
      )
      center.add(req, withCompletionHandler: nil)
    }
  }
}
