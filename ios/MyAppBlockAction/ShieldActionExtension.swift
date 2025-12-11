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

class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        if action == .primaryButtonPressed {
            let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!
            shared.set(Date().timeIntervalSince1970, forKey: "requestTimestamp")
//            shared.set(application.bundleIdentifier ?? "unknown", forKey: "requestedAppId")
            shared.synchronize()
            
            // Trigger notification
            let content = UNMutableNotificationContent()
            content.title = "Access Request"
            content.body = "Tap to open Sweat Lock"
            content.sound = .default
            content.categoryIdentifier = "OPEN_APP_CATEGORY"
            content.userInfo = ["openFlutter": true]  // marker
            
            let request = UNNotificationRequest(identifier: "openApp", content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
        completionHandler(.close)
    }
}
