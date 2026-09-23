import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Runs even when SweatLock is killed or after reboot (once monitoring is registered).
/// Applies ManagedSettings shields when usage threshold is reached.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let defaults = UserDefaults(suiteName: "group.sweatlock.shared")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
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
    if name == "sweatlock.threshold" || name == "threshold" {
      applyShieldFromDefaults()
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
      return
    }

    let apps = selection.applicationTokens
    let cats = selection.categoryTokens
    store.shield.applications = apps.isEmpty ? nil : apps
    store.shield.applicationCategories = cats.isEmpty ? nil : .specific(cats)
  }
}
