import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Active usage threshold → apply shield + notification (with app name).
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let appGroupId = "group.com.sweat.lock.shield"

  private var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    NSLog("SweatLockMonitor: intervalDidStart \(activity.rawValue)")
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
  }

  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)
    NSLog("SweatLockMonitor: threshold \(event.rawValue)")

    let appName = defaults?.string(forKey: "display_app_name") ?? "Selected apps"
    let name = event.rawValue

    if name.contains("warning") {
      postNotification(
        id: "sweatlock_warning",
        title: "SweatLock",
        body: "Almost out of free time on \(appName)."
      )
      return
    }

    // LOCK immediately
    let applied = applyShield()
    NSLog("SweatLockMonitor: shield applied=\(applied)")

    defaults?.set(true, forKey: "pending_workout_open")
    defaults?.set(true, forKey: "force_shield")
    defaults?.synchronize()

    postNotification(
      id: "sweatlock_lock",
      title: "SweatLock — \(appName) locked",
      body: "Your free time on \(appName) is up. Open SweatLock and complete a workout to unlock.",
      openWorkout: true
    )
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    let appName = defaults?.string(forKey: "display_app_name") ?? "Selected apps"
    postNotification(
      id: "sweatlock_warning",
      title: "SweatLock",
      body: "\(appName) will be locked soon."
    )
  }

  @discardableResult
  private func applyShield() -> Bool {
    guard let defaults else {
      NSLog("SweatLockMonitor: App Group defaults nil — check entitlement group.com.sweat.lock.shield")
      return false
    }

    guard let data = defaults.data(forKey: "family_selection") else {
      NSLog("SweatLockMonitor: no family_selection data in App Group")
      return false
    }

    guard let selection = try? PropertyListDecoder().decode(
      FamilyActivitySelection.self,
      from: data
    ) else {
      NSLog("SweatLockMonitor: failed to decode FamilyActivitySelection")
      return false
    }

    let apps = selection.applicationTokens
    let cats = selection.categoryTokens

    if apps.isEmpty && cats.isEmpty {
      NSLog("SweatLockMonitor: selection empty")
      return false
    }

    if !apps.isEmpty {
      store.shield.applications = apps
    }
    if !cats.isEmpty {
      store.shield.applicationCategories = .specific(cats)
    }

    NSLog("SweatLockMonitor: SHIELD ON apps=\(apps.count) cats=\(cats.count)")
    return true
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
      if openWorkout {
        content.userInfo = ["openWorkout": true, "deeplink": "sweatlock://workout"]
      }
      center.add(
        UNNotificationRequest(identifier: id, content: content, trigger: nil),
        withCompletionHandler: nil
      )
    }
  }
}
