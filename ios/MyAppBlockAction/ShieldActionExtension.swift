////
////  ShieldActionExtension.swift
////  MyAppBlockAction
////
////  Created by Destiny Dikeocha on 12/11/25.
////

//
//import ManagedSettings
//import UserNotifications
//
//class ShieldActionExtension: ShieldActionDelegate {
//
//    override func handle(
//        action: ShieldAction,
//        for application: ApplicationToken,
//        completionHandler: @escaping (ShieldActionResponse) -> Void
//    ) {
//        if action == .primaryButtonPressed {
//            // Tell your main app: "someone wants to unblock!"
//            let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!
//            shared.set(Date().timeIntervalSince1970, forKey: "requestTime")
////            shared.set(application.bundleIdentifier ?? "", forKey: "requestedApp")
//
//            // Optional: send a local notification so user sees something instantly
//            let content = UNMutableNotificationContent()
//            content.title = "Request received!"
//            content.body = "Open Sweat Lock to approve"
//            content.sound = .default
//            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
//            UNUserNotificationCenter.current().add(request)
//        }
//
//        // Always allow the app to open when they press the button
//        completionHandler(.close)
//    }
//}

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
            let tokenMap =
                shared.dictionary(forKey: "appTokenMappings") as? [String: [String: String]] ?? [:]

            let tokenKey = applicationToken.tokenKey
           

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
