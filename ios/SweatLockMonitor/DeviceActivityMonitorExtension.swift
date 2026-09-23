import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Counts **active minutes** on selected apps (Screen Time).
/// When the free-time threshold is reached:
/// 1. Apply ManagedSettings shield (lock apps immediately)
/// 2. Send a local notification
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let defaults = UserDefaults(suiteName: "group.sweatlock.shared")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    NSLog("SweatLockMonitor: intervalDidStart \(activity.rawValue)")
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
  }

  /// Free-time threshold reached → lock apps + notify
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

    // Lock immediately
    applyShield()

    defaults?.set(true, forKey: "pending_workout_open")
    defaults?.synchronize()

    postNotification(
      id: "sweatlock_lock",
      title: "SweatLock — Apps locked",
      body: "Your free time is up. Open SweatLock and complete a workout to unlock.",
      openWorkout: true
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
    guard let data = defaults?.data(forKey: "family_selection"),
          let selection = try? PropertyListDecoder().decode(
            FamilyActivitySelection.self,
            from: data
          ) else {
      NSLog("SweatLockMonitor: no family_selection — cannot shield")
      return
    }

    let apps = selection.applicationTokens
    let cats = selection.categoryTokens

    if !apps.isEmpty {
      store.shield.applications = apps
    }
    if !cats.isEmpty {
      store.shield.applicationCategories = .specific(cats)
    }

    NSLog("SweatLockMonitor: shield APPLIED apps=\(apps.count) cats=\(cats.count)")
  }

  private func postNotification(
    id: String,
    title: String,
    body: String,
    openWorkout: Bool = false
  ) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
      guard granted else { return }

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      content.categoryIdentifier = "SWEATLOCK_WORKOUT"
      if openWorkout {
        content.userInfo = ["openWorkout": true, "deeplink": "sweatlock://workout"]
      }

      let req = UNNotificationRequest(
        identifier: id,
        content: content,
        trigger: nil
      )
      center.add(req, withCompletionHandler: nil)
    }
  }
}
