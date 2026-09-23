import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Custom SweatLock shield UI (replaces generic "Restricted").
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

  private let primaryGreen = UIColor(red: 0.08, green: 0.93, blue: 0.36, alpha: 1)
  private let bgGreen = UIColor(red: 0.06, green: 0.13, blue: 0.09, alpha: 1)

  override func configuration(shielding application: Application) -> ShieldConfiguration {
    makeConfig()
  }

  override func configuration(
    shielding application: Application,
    in category: ActivityCategory
  ) -> ShieldConfiguration {
    makeConfig()
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    makeConfig()
  }

  override func configuration(
    shielding webDomain: WebDomain,
    in category: ActivityCategory
  ) -> ShieldConfiguration {
    makeConfig()
  }

  private func makeConfig() -> ShieldConfiguration {
    ShieldConfiguration(
      backgroundBlurStyle: .systemChromeMaterialDark,
      backgroundColor: bgGreen,
      icon: UIImage(systemName: "lock.circle.fill"),
      title: ShieldConfiguration.Label(text: "SweatLock", color: .white),
      subtitle: ShieldConfiguration.Label(
        text: "This app is locked.\nComplete a workout to unlock.",
        color: UIColor.white.withAlphaComponent(0.75)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: "Start Workout",
        color: .black
      ),
      primaryButtonBackgroundColor: primaryGreen,
      secondaryButtonLabel: ShieldConfiguration.Label(
        text: "Not now",
        color: UIColor.white.withAlphaComponent(0.55)
      )
    )
  }
}
