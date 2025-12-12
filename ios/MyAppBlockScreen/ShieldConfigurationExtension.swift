//
//  ShieldConfigurationExtension.swift
//  MyAppBlockScreen
//
//  Created by Destiny Dikeocha on 12/11/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appName = application.localizedDisplayName ?? "App"

        // This is the ONLY method you need now
        return ShieldConfiguration(
            backgroundColor: .black,
            icon: UIImage(named: "google.png"),
            title: .init(ShieldConfiguration.Label(text: "\(appName) Blocked", color: .white)),
            subtitle: .init(
                ShieldConfiguration.Label(text: "Open Sweat Lock to continue", color: .white)),
            primaryButtonLabel: .init(
                ShieldConfiguration.Label(text: "Open Sweat Lock", color: .white)),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: .init(ShieldConfiguration.Label(text: "Close", color: .white))
        )
    }

    // Optional: same for categories
    override func configuration(shielding application: Application, in category: ActivityCategory)
        -> ShieldConfiguration
    {
        // Customize the shield as needed for applications shielded because of their category.
        ShieldConfiguration()
    }
}
