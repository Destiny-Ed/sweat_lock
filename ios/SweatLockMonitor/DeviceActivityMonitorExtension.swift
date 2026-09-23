import DeviceActivity
import ManagedSettings
import Foundation

/// Runs even when SweatLock is killed. Applies / clears system shields.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  // Must match App Group + name used in AppDelegate
  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let defaults = UserDefaults(suiteName: "group.sweatlock.shared")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    // Optional: clear or apply depending on schedule design
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
  }

  /// Called when usage threshold is reached (e.g. 5 minutes on selected apps)
  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, activity: activity)

    if event.rawValue == "sweatlock.threshold" || event.rawValue == "threshold" {
      applyShieldFromDefaults()
      postLocalNotification(
        title: "SweatLock — Apps locked",
        body: "Complete a workout in SweatLock to unlock."
      )
    }

    if event.rawValue == "sweatlock.warning" || event.rawValue == "warning" {
      postLocalNotification(
        title: "SweatLock",
        body: "Selected apps will be locked soon. Finish up!"
      )
    }
  }

  override func intervalWillStartWarning(for activity: DeviceActivityName) {
    super.intervalWillStartWarning(for: activity)
  }

  override func intervalWillEndWarning(for activity: DeviceActivityName) {
    super.intervalWillEndWarning(for: activity)
  }

  private func applyShieldFromDefaults() {
    guard let data = defaults?.data(forKey: "family_selection"),
          let selection = try? PropertyListDecoder().decode(
            FamilyActivitySelection.self,
            from: data
          ) else {
      // Fallback: if tokens stored as raw application set is unavailable,
      // main app should have mirrored tokens into the store already.
      return
    }

    let apps = selection.applicationTokens
    let cats = selection.categoryTokens
    store.shield.applications = apps.isEmpty ? nil : apps
    store.shield.applicationCategories = cats.isEmpty ? nil : .specific(cats)
  }

  private func postLocalNotification(title: String, body: String) {
    // Extension notifications require proper setup; main app also schedules.
    // Left minimal to avoid entitlement issues in extension-only context.
  }
}

import FamilyControls
