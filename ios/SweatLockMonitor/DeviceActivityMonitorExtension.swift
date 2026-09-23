import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Screen Time usage thresholds only (no wall-clock).
/// Each monitored app has its own activity; only that app is shielded.
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
    let name = event.rawValue
    NSLog("SweatLockMonitor: threshold \(name)")

    let appName = defaults?.string(forKey: "display_app_name") ?? "This app"

    if name.contains("warning") {
      postNotification(
        id: "sweatlock_warning",
        title: "SweatLock",
        body: "Almost out of free time on \(appName)."
      )
      return
    }

    let applied = applyShieldForEvent(name)
    NSLog("SweatLockMonitor: per-app shield applied=\(applied) event=\(name)")

    defaults?.set(true, forKey: "force_shield")
    defaults?.set(true, forKey: "pending_workout_open")
    defaults?.synchronize()

    postNotification(
      id: "sweatlock_lock",
      title: "SweatLock — \(appName) locked",
      body: "Screen Time limit reached on \(appName). Open SweatLock and complete a workout to unlock.",
      openWorkout: true
    )
  }

  override func eventWillReachThresholdWarning(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventWillReachThresholdWarning(event, activity: activity)
    let appName = defaults?.string(forKey: "display_app_name") ?? "This app"
    postNotification(
      id: "sweatlock_warning",
      title: "SweatLock",
      body: "\(appName) will be locked soon."
    )
  }

  /// event name: sweatlock.threshold.app.N or sweatlock.threshold.cat.N
  @discardableResult
  private func applyShieldForEvent(_ eventName: String) -> Bool {
    guard let defaults else {
      NSLog("SweatLockMonitor: App Group nil")
      return false
    }

    if let idx = parseIndex(eventName, prefix: "threshold.app.") {
      guard let data = defaults.data(forKey: "token_app_\(idx)"),
            let token = try? PropertyListDecoder().decode(ApplicationToken.self, from: data)
      else {
        NSLog("SweatLockMonitor: missing token_app_\(idx)")
        return applyAllFallback()
      }
      var set = store.shield.applications ?? Set<ApplicationToken>()
      set.insert(token)
      store.shield.applications = set
      NSLog("SweatLockMonitor: SHIELD app index=\(idx) total=\(set.count)")
      return true
    }

    if let idx = parseIndex(eventName, prefix: "threshold.cat.") {
      guard let data = defaults.data(forKey: "token_cat_\(idx)"),
            let token = try? PropertyListDecoder().decode(ActivityCategoryToken.self, from: data)
      else {
        return applyAllFallback()
      }
      // Current SDK: .specific is (Set, except:) — set category without reading back
      store.shield.applicationCategories = .specific(Set([token]))
      NSLog("SweatLockMonitor: SHIELD category index=\(idx)")
      return true
    }

    return applyAllFallback()
  }

  private func parseIndex(_ name: String, prefix: String) -> Int? {
    guard let r = name.range(of: prefix) else { return nil }
    return Int(name[r.upperBound...])
  }

  private func applyAllFallback() -> Bool {
    guard let data = defaults?.data(forKey: "family_selection"),
          let selection = try? PropertyListDecoder().decode(
            FamilyActivitySelection.self, from: data
          ) else { return false }
    let apps = selection.applicationTokens
    let cats = selection.categoryTokens
    if !apps.isEmpty { store.shield.applications = apps }
    if !cats.isEmpty { store.shield.applicationCategories = .specific(cats) }
    return !apps.isEmpty || !cats.isEmpty
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
