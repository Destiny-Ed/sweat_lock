//import Flutter
//import UIKit
//
//@main
//@objc class AppDelegate: FlutterAppDelegate {
//  override func application(
//    _ application: UIApplication,
//    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//  ) -> Bool {
//    GeneratedPluginRegistrant.register(with: self)
//    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//  }
//}

import UIKit
import Flutter
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private let channel = "com.sweat.lock/requests"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Setup MethodChannel
        let controller = window?.rootViewController as! FlutterViewController
        let flutterChannel = FlutterMethodChannel(name: channel, binaryMessenger: controller.binaryMessenger)
        
        flutterChannel.setMethodCallHandler { (call, result) in
            if call.method == "getPendingRequest" {
                let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!
                let timestamp = shared.double(forKey: "requestTimestamp")
                let appId = shared.string(forKey: "requestedAppId") ?? "unknown"
                
                if timestamp > 0 {
                    result(["timestamp": timestamp, "appId": appId])
                    // Clear after reading
                    shared.removeObject(forKey: "requestTimestamp")
                    shared.removeObject(forKey: "requestedAppId")
                } else {
                    result(nil)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Notification setup
        let openAction = UNNotificationAction(identifier: "OPEN_APP_ACTION", title: "Open Sweat Lock", options: [.foreground])
        let category = UNNotificationCategory(identifier: "OPEN_APP_CATEGORY", actions: [openAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // When user taps notification
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "OPEN_APP_ACTION" || response.notification.request.content.categoryIdentifier == "OPEN_APP_CATEGORY" {
            // App is now opening — Flutter will check in init
        }
        completionHandler()
    }
}
