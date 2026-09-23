import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Counts **active minutes** on selected apps (Screen Time).
/// Timed mode: on threshold → **notification only** (no ManagedSettings shield).
/// Immediate mode still shields from the main app.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  private let defaults = UserDefaults(suiteName: "group.sweatlock.shared")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    NSLog("SweatLockMonitor: intervalDidStart \(activity.rawValue)")
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
  }

  /// Timed free window ended (active usage threshold reached)
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
        body: "You're almost out of free time on locked apps. Finish up or complete a workout soon."
      )
      return
    }

    // Threshold reached: notify only — do NOT apply system shield
    defaults?.set(true, forKey: "pending_workout_open")
    defaults?.synchronize()

    postNotification(
      id: "sweatlock_lock",
      title: "SweatLock — Time's up",
      body: "You've used your free time. Open SweatLock and complete a workout to unlock more time.",
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
      body: "Locked apps free time is almost over."
    )
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

      // Tapping the notification opens the app (URL handled in AppDelegate)
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
