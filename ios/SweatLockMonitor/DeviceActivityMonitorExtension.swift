import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Counts **active minutes** on selected apps (Screen Time).
/// When the threshold is reached, applies the ManagedSettings shield.
/// This runs even if SweatLock is killed — unlike Flutter timers.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let defaults = UserDefaults(suiteName: "group.sweatlock.shared")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    NSLog("SweatLockMonitor: intervalDidStart \(activity.rawValue)")
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    NSLog("SweatLockMonitor: intervalDidEnd \(activity.rawValue)")
  }

  /// Called when selected apps have been used for `threshold` minutes
  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)
    NSLog("SweatLockMonitor: eventDidReachThreshold \(event.rawValue)")

    let name = event.rawValue

    if name.contains("warning") {
      postNotification(
        id: "sweatlock_warning",
        title: "SweatLock",
        body: "You're almost out of free time on locked apps."
      )
      return
    }

    // Main lock threshold
    applyShield()
    postNotification(
      id: "sweatlock_lock",
      title: "SweatLock — Apps locked",
      body: "Open SweatLock and complete a workout to unlock."
    )
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    postNotification(
      id: "sweatlock_warning",
      title: "SweatLock",
      body: "Locked apps will be restricted soon."
    )
  }

  private func applyShield() {
    // Prefer tokens from App Group selection
    if let data = defaults?.data(forKey: "family_selection"),
       let selection = try? PropertyListDecoder().decode(
         FamilyActivitySelection.self,
         from: data
       ) {
      let apps = selection.applicationTokens
      let cats = selection.categoryTokens
      if !apps.isEmpty {
        store.shield.applications = apps
      }
      if !cats.isEmpty {
        store.shield.applicationCategories = .specific(cats)
      }
      NSLog("SweatLockMonitor: shield applied apps=\(apps.count) cats=\(cats.count)")
      return
    }

    NSLog("SweatLockMonitor: no family_selection in App Group — cannot shield")
  }

  private func postNotification(id: String, title: String, body: String) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
      guard granted else { return }
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      let req = UNNotificationRequest(
        identifier: id,
        content: content,
        trigger: nil
      )
      center.add(req, withCompletionHandler: nil)
    }
  }
}
