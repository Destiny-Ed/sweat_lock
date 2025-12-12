////
////  ShieldActionExtension.swift
////  MyAppBlockAction
////
////  Created by Destiny Dikeocha on 12/11/25.
////

// ShieldActionExtension.swift
import ManagedSettings
import UserNotifications

extension ApplicationToken {
    var tokenKey: String {
        String(describing: self)  // Stable key for lookup
    }
}

class ShieldActionExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for applicationToken: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        if action == .primaryButtonPressed {

            // NEW: Look up pre-stored details
            let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!

            let app = Application(token: applicationToken)

            let appName = app.localizedDisplayName ?? "Unknown App"
            let bundleId = app.bundleIdentifier ?? "unknown"
            let tokenKey = applicationToken.tokenKey

            shared.set(appName, forKey: "requestedAppName")
            shared.set(bundleId, forKey: "requestedAppBundleID")
            shared.set(Date().timeIntervalSince1970, forKey: "requestTimestamp")
            shared.set(tokenKey, forKey: "requestedAppToken")
            shared.synchronize()

            // Send notification with real app name
            let content = UNMutableNotificationContent()
            content.title = "Grant Access Request"
            content.body = "Tap to open Sweat Lock and approve"
            content.sound = .default
            content.categoryIdentifier = "OPEN_APP_CATEGORY"

            let request = UNNotificationRequest(
                identifier: "access_\(tokenKey)", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }

        completionHandler(.close)
    }
}
