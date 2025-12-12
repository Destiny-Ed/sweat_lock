import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit
import UserNotifications

/// Global variable to store the current method being called
var globalMethodCall = ""

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let channel = "com.sweat.lock/requests"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Setup MethodChannel
        let controller = window?.rootViewController as! FlutterViewController
        let flutterChannel = FlutterMethodChannel(
            name: channel, binaryMessenger: controller.binaryMessenger)

        flutterChannel.setMethodCallHandler { (call, result) in
            if call.method == "getPendingRequest" {
                let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!
                let timestamp = shared.double(forKey: "requestTimestamp")
                let bundleId = shared.string(forKey: "requestedAppBundleID") ?? "unknown"
                let appName = shared.string(forKey: "requestedAppName") ?? "Unknown App"
                let appToken = shared.string(forKey: "requestedAppToken") ?? "Unknown Token"
               
                print("time stamp : \(timestamp)")
                print("app Name : \(appName)")
               
                if timestamp > 0 {
                    result([
                        "timestamp": timestamp,
                        "bundleId": bundleId,
                        "appName": appName,
                        "appToken" : appToken
                    ])
                    shared.removeObject(forKey: "requestTimestamp")
                    shared.removeObject(forKey: "requestedAppBundleID")
                    shared.removeObject(forKey: "requestedAppName")
                    shared.removeObject(forKey: "appToken")
                } else {
                    result(nil)
                }

            } else if call.method == "getPlatformVersion" {
                result("iOS " + UIDevice.current.systemVersion)

            } else if call.method == "requestPermission" {
                if #available(iOS 16.0, *) {
                    self.requestPermission(result: result)
                } else {
                    result(FlutterError(code: "UNSUPPORTED", message: "iOS 16+ required", details: nil))
                }

            } else if call.method == "blockApp" {
                if #available(iOS 16.0, *) {
                    self.handleAppSelection(method: "selectAppsToDiscourage", result: result)
                } else {
                    result(FlutterError(code: "UNSUPPORTED", message: "iOS 16+ required", details: nil))
                }

            
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            if let error = error {
                print("Notification permission error: $error)")
            } else {
                print("Notification permission granted: $granted)")
            }
        }

        // Notification setup
        let openAction = UNNotificationAction(
            identifier: "OPEN_APP_ACTION", title: "Open Sweat Lock", options: [.foreground])
        let category = UNNotificationCategory(
            identifier: "OPEN_APP_CATEGORY", actions: [openAction], intentIdentifiers: [],
            options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // When user taps notification
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "OPEN_APP_ACTION"
            || response.notification.request.content.categoryIdentifier == "OPEN_APP_CATEGORY"
        {
            // App is opening — Flutter will check
        }
        completionHandler()
    }

    @available(iOS 16.0, *)
    private func handleAppSelection(method: String, result: @escaping FlutterResult) {
        let status = AuthorizationCenter.shared.authorizationStatus

        if status == .approved {
            self.presentContentView(method: method) {
                // After picker is dismissed — return the saved tokens
                self.returnBlockedTokens(to: result)
            }
            // result(nil) // We return later
        } else {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let newStatus = AuthorizationCenter.shared.authorizationStatus
                    if newStatus == .approved {
                        self.presentContentView(method: method) {
                            self.returnBlockedTokens(to: result)
                        }
                        result(nil)
                    } else {
                        result(
                            FlutterError(
                                code: "PERMISSION_DENIED", message: "User denied permission",
                                details: nil))
                    }
                } catch {
                    result(
                        FlutterError(
                            code: "AUTH_ERROR", message: "Failed to request authorization",
                            details: error.localizedDescription))
                }
            }
        }
    }

    // NEW: Present picker and call completion when done
    private func presentContentView(method: String, completion: @escaping () -> Void = {}) {
        guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
            print("Root view controller not found")
            completion()
            return
        }

        globalMethodCall = method
        let vc: UIViewController

        if #available(iOS 15.0, *) {
            vc = UIHostingController(
                rootView: ContentView()
                    .environmentObject(MyModel.shared)
                    .onDisappear {
                        // Picker dismissed → return tokens
                        completion()
                    }
            )
        } else {
            vc = UIViewController()
            completion()
        }

        rootVC.present(vc, animated: true, completion: nil)
    }

    // NEW: Read saved tokens from App Group and return to Flutter
    private func returnBlockedTokens(to result: @escaping FlutterResult) {
        let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!
        let tokens = shared.stringArray(forKey: "blocked_app_tokens") ?? []

        print("Returning \(tokens.count) blocked tokens to Flutter")
        result(["blockedTokens": tokens])
    }

    @available(iOS 16.0, *)
    private func requestPermission(result: @escaping FlutterResult) {
        let status = AuthorizationCenter.shared.authorizationStatus

        if status == .approved {
            result(true)
        } else {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    let newStatus = AuthorizationCenter.shared.authorizationStatus
                    result(newStatus == .approved)
                } catch {
                    result(FlutterError(code: "AUTH_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}
