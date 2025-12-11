//
//  ShieldConfigurationExtension.swift
//  MyAppBlockScreen
//
//  Created by Destiny Dikeocha on 12/11/25.
//

//import ManagedSettings
//import ManagedSettingsUI
//import UIKit
//
//// Override the functions below to customize the shields used in various situations.
//// The system provides a default appearance for any methods that your subclass doesn't override.
//// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
//class ShieldConfigurationExtension: ShieldConfigurationDataSource {
//    override func configuration(shielding application: Application) -> ShieldConfiguration {
//        // Customize the shield as needed for applications.
//        ShieldConfiguration()
//    }
//
//    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
//        // Customize the shield as needed for applications shielded because of their category.
//        ShieldConfiguration()
//    }
//
//    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
//        // Customize the shield as needed for web domains.
//        ShieldConfiguration()
//    }
//
//    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
//        // Customize the shield as needed for web domains shielded because of their category.
//        ShieldConfiguration()
//    }
//}

// ShieldConfigurationExtension.swift
// This works on iOS 17, 18, 19 (2025+)

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

//    let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appName = application.localizedDisplayName ?? "App"

//        let bundleId = application.bundleIdentifier ?? "unknown bundleId"
//        let appToken = application.token
//
//        print("Calling configuration \(bundleId)")
//
//        // Save resolved info
//        shared.set(Date().timeIntervalSince1970, forKey: "requestTimestamp")
//        shared.set(bundleId, forKey: "requestedAppBundleID")
//        shared.set(appName, forKey: "requestedAppName")
//        shared.set(appToken ?? "unknown token", forKey: "requestedAppToken")
//        shared.synchronize()
        // This is the ONLY method you need now
        return ShieldConfiguration(
            backgroundColor: .black,
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
