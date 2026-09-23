import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Runs in the background. Counts **actual screen time** on selected apps
/// (not wall-clock). When threshold is reached → apply shield + notify.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let defaults = UserDefaults(suiteName: "group.sweatlock.shared")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
  }

  /// Fires when selected apps have been **actively used** for `threshold` minutes
  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)

    let name = event.rawValue

    if name == "sweatlock.warning" {
      postNotification(
        id: "sweatlock_warning",
        title: "SweatLock",
        body: "You're almost at your free time limit on locked apps."
      )
      return
    }

    if name == "sweatlock.threshold" || name == "threshold" {
      applyShieldFromDefaults()
      postNotification(
        id: "sweatlock_lock",
        title: "SweatLock — Apps locked",
        body: "You've used your free time. Open SweatLock and complete a workout to unlock."
      )
    }
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)
  }

  private func applyShieldFromDefaults() {
    guard let data = defaults?.data(forKey: "family_selection"),
          let selection = try? PropertyListDecoder().decode(
            FamilyActivitySelection.self,
            from: data
          ) else {
      return
    }

    let apps = selection.applicationTokens
    let cats = selection.categoryTokens
    if apps.isEmpty && cats.isEmpty { return }

    store.shield.applications = apps.isEmpty ? nil : apps
    store.shield.applicationCategories = cats.isEmpty ? nil : .specific(cats)
  }

  private func postNotification(id: String, title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    let req = UNNotificationRequest(
      identifier: id,
      content: content,
      trigger: nil // deliver immediately
    )
    UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
  }
}
