import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let center = AuthorizationCenter.shared
  private let store = ManagedSettingsStore()
  private var selection = FamilyActivitySelection()
  private var pendingResult: FlutterResult?

  static var sharedSelection = FamilyActivitySelection()

  private let selectionKey = "sweatlock_family_selection"
  private let sessionStartKey = "sweatlock_session_start"
  private let unlockUntilKey = "sweatlock_unlock_until"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self
    requestNotificationPermission()

    if let registrar = self.registrar(forPlugin: "SweatLockSelectedApps") {
      registrar.register(
        SelectedAppsViewFactory(messenger: registrar.messenger()),
        withId: "sweatlock/ios_selected_apps"
      )
    }

    loadPersistedSelection()

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "sweatlock/screen_time",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }

        switch call.method {
        case "requestAuthorization":
          self.requestAuth(result: result)

        case "selectApps":
          self.presentPicker(from: controller, result: result)

        case "applyShield":
          // System-level block — works while user is in TikTok without opening SweatLock
          self.applyShield()
          result(true)

        case "clearShield":
          self.clearShield()
          result(true)

        case "startTimedLock":
          // args: warningMinutes, lockMinutes
          let args = call.arguments as? [String: Any]
          let warning = args?["warningMinutes"] as? Int ?? 3
          let lock = args?["lockMinutes"] as? Int ?? 5
          self.startTimedLock(warningMinutes: warning, lockMinutes: lock)
          result(true)

        case "cancelTimedLock":
          self.cancelTimedLock()
          result(true)

        case "grantTemporaryUnlock":
          let args = call.arguments as? [String: Any]
          let minutes = args?["minutes"] as? Int ?? 30
          self.grantTemporaryUnlock(minutes: minutes)
          result(true)

        case "restartMonitoring":
          let args = call.arguments as? [String: Any]
          let warning = args?["warningMinutes"] as? Int ?? 3
          let lock = args?["lockMinutes"] as? Int ?? 5
          self.restartMonitoring(warningMinutes: warning, lockMinutes: lock)
          result(true)

        case "isShieldActive":
          result(self.store.shield.applications != nil && !(self.store.shield.applications?.isEmpty ?? true))

        case "getAppUsage":
          result([])

        case "resetUsage":
          result(nil)

        case "getAuthorizationStatus":
          result(self.authStatusString())

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // On launch: if free window expired and not in unlock window → re-apply shield
    enforceShieldIfNeeded()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    enforceShieldIfNeeded()
  }

  // MARK: - Auth

  private func authStatusString() -> String {
    switch center.authorizationStatus {
    case .notDetermined: return "notDetermined"
    case .denied: return "denied"
    case .approved: return "approved"
    @unknown default: return "unknown"
    }
  }

  private func requestAuth(result: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      Task {
        do {
          try await center.requestAuthorization(for: .individual)
          DispatchQueue.main.async {
            result(self.center.authorizationStatus == .approved)
          }
        } catch {
          DispatchQueue.main.async { result(false) }
        }
      }
    } else {
      result(false)
    }
  }

  private func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
  }

  // MARK: - Selection persist

  private func persistSelection() {
    // FamilyActivitySelection is Codable on modern iOS
    if #available(iOS 15.0, *) {
      if let data = try? PropertyListEncoder().encode(selection) {
        UserDefaults.standard.set(data, forKey: selectionKey)
      }
      AppDelegate.sharedSelection = selection
    }
  }

  private func loadPersistedSelection() {
    if #available(iOS 15.0, *) {
      guard let data = UserDefaults.standard.data(forKey: selectionKey),
            let saved = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else {
        return
      }
      selection = saved
      AppDelegate.sharedSelection = saved
    }
  }

  // MARK: - ManagedSettings shield (system-wide block)

  /// Applies Apple's system shield on selected apps.
  /// Once applied, TikTok/etc. stay blocked even if SweatLock is closed.
  private func applyShield() {
    if #available(iOS 15.0, *) {
      loadPersistedSelection()
      let apps = selection.applicationTokens
      let cats = selection.categoryTokens
      if apps.isEmpty && cats.isEmpty {
        print("SweatLock: no tokens to shield")
        return
      }
      store.shield.applications = apps.isEmpty ? nil : apps
      store.shield.applicationCategories = cats.isEmpty
        ? nil
        : .specific(cats)
      print("SweatLock: shield applied")
    }
  }

  private func clearShield() {
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    print("SweatLock: shield cleared")
  }

  /// Temporary unlock after workout, then auto re-lock
  private func grantTemporaryUnlock(minutes: Int) {
    clearShield()
    cancelTimedLock()

    let until = Date().addingTimeInterval(TimeInterval(minutes * 60))
    UserDefaults.standard.set(until.timeIntervalSince1970, forKey: unlockUntilKey)

    // Schedule re-shield when unlock window ends
    scheduleNotification(
      id: "sweatlock_relock",
      title: "SweatLock",
      body: "Unlock time is over. Selected apps are locked again.",
      afterSeconds: minutes * 60
    )

    // Also schedule local re-apply attempt
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes * 60)) { [weak self] in
      self?.applyShield()
    }
  }

  private func startTimedLock(warningMinutes: Int, lockMinutes: Int) {
    cancelTimedLock()
    let now = Date()
    UserDefaults.standard.set(now.timeIntervalSince1970, forKey: sessionStartKey)
    UserDefaults.standard.removeObject(forKey: unlockUntilKey)

    // Warning: 2 minutes before lock → at (lock - warning) minutes
    let warnAt = max(lockMinutes - warningMinutes, 1)
    scheduleNotification(
      id: "sweatlock_warning",
      title: "SweatLock",
      body: "Selected apps will be locked in \(warningMinutes) minutes. Finish up!",
      afterSeconds: warnAt * 60
    )

    scheduleNotification(
      id: "sweatlock_lock",
      title: "SweatLock — Apps locked",
      body: "Complete a workout in SweatLock to unlock.",
      afterSeconds: lockMinutes * 60
    )

    // Apply shield when timer fires while process is still alive
    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(lockMinutes * 60)) { [weak self] in
      self?.applyShield()
    }

    print("SweatLock: timed lock armed warn@\(warnAt)m lock@\(lockMinutes)m")
  }

  private func restartMonitoring(warningMinutes: Int, lockMinutes: Int) {
    clearShield()
    startTimedLock(warningMinutes: warningMinutes, lockMinutes: lockMinutes)
  }

  private func cancelTimedLock() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: ["sweatlock_warning", "sweatlock_lock", "sweatlock_relock"]
    )
  }

  private func scheduleNotification(id: String, title: String, body: String, afterSeconds: Int) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(
      timeInterval: TimeInterval(max(afterSeconds, 1)),
      repeats: false
    )
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  /// Called on launch / foreground — enforce shield if free window or unlock window expired
  private func enforceShieldIfNeeded() {
    if #available(iOS 15.0, *) {
      loadPersistedSelection()
      if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
        return
      }

      // Still in temporary unlock window?
      if let until = UserDefaults.standard.object(forKey: unlockUntilKey) as? Double {
        if Date().timeIntervalSince1970 < until {
          clearShield()
          return
        }
      }

      // Free session window still active?
      if let start = UserDefaults.standard.object(forKey: sessionStartKey) as? Double {
        let elapsed = Date().timeIntervalSince1970 - start
        // 5 minutes free window default mirrored in Flutter constants
        if elapsed < 5 * 60 {
          return
        }
      }

      applyShield()
    }
  }

  // MARK: - Picker

  private func presentPicker(from controller: UIViewController, result: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      self.pendingResult = result

      let pickerView = FamilyActivityPickerView(
        selection: Binding(
          get: { self.selection },
          set: { self.selection = $0 }
        ),
        onComplete: { [weak self] in
          guard let self = self else { return }
          self.persistSelection()
          let apps = self.serializeSelection()
          self.pendingResult?(apps)
          self.pendingResult = nil
          controller.dismiss(animated: true)
        },
        onCancel: { [weak self] in
          self?.pendingResult?([])
          self?.pendingResult = nil
          controller.dismiss(animated: true)
        }
      )

      let host = UIHostingController(rootView: pickerView)
      host.modalPresentationStyle = .formSheet
      controller.present(host, animated: true)
    } else {
      result(FlutterError(code: "UNSUPPORTED", message: "Requires iOS 15+", details: nil))
    }
  }

  private func serializeSelection() -> [[String: Any]] {
    var list: [[String: Any]] = []
    var index = 0

    for token in selection.applicationTokens {
      index += 1
      let tokenData = try? PropertyListEncoder().encode(token)
      let tokenBase64 = tokenData?.base64EncodedString() ?? UUID().uuidString
      list.append([
        "id": String(tokenBase64.prefix(32)),
        "appName": "Selected App \(index)",
        "bundleId": tokenBase64,
        "token": tokenBase64,
        "requiredReps": 20,
        "exerciseType": "push-ups",
      ])
    }

    for token in selection.categoryTokens {
      index += 1
      let tokenData = try? PropertyListEncoder().encode(token)
      let tokenBase64 = tokenData?.base64EncodedString() ?? UUID().uuidString
      list.append([
        "id": String(tokenBase64.prefix(32)),
        "appName": "Category \(index)",
        "bundleId": tokenBase64,
        "token": tokenBase64,
        "requiredReps": 20,
        "exerciseType": "push-ups",
      ])
    }

    return list
  }
}

// Show notifications while app is foregrounded
extension AppDelegate {
  open override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.identifier == "sweatlock_lock"
        || notification.request.identifier == "sweatlock_relock" {
      applyShield()
    }
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  open override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.notification.request.identifier == "sweatlock_lock"
        || response.notification.request.identifier == "sweatlock_relock" {
      applyShield()
    }
    completionHandler()
  }
}

@available(iOS 15.0, *)
struct FamilyActivityPickerView: View {
  @Binding var selection: FamilyActivitySelection
  var onComplete: () -> Void
  var onCancel: () -> Void

  var body: some View {
    NavigationView {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Select Apps")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { onCancel() }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { onComplete() }
          }
        }
    }
  }
}

class SelectedAppsViewFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    return SelectedAppsPlatformView(frame: frame)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

class SelectedAppsPlatformView: NSObject, FlutterPlatformView {
  private var _view: UIView

  init(frame: CGRect) {
    if #available(iOS 15.0, *) {
      let host = UIHostingController(rootView: SelectedAppsLabelList())
      host.view.frame = frame
      host.view.backgroundColor = .clear
      _view = host.view
    } else {
      _view = UIView(frame: frame)
    }
    super.init()
  }

  func view() -> UIView { _view }
}

@available(iOS 15.0, *)
struct SelectedAppsLabelList: View {
  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(Array(AppDelegate.sharedSelection.applicationTokens.enumerated()), id: \.offset) { _, token in
          Label(token)
            .labelStyle(.titleAndIcon)
            .padding(8)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(12)
        }
      }
      .padding(.horizontal, 4)
    }
    .frame(height: 100)
  }
}
