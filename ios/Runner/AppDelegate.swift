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
  private let store = ManagedSettingsStore(named: .init("sweatlock"))
  private let activityCenter = DeviceActivityCenter()
  private var selection = FamilyActivitySelection()
  private var pendingResult: FlutterResult?

  static var sharedSelection = FamilyActivitySelection()

  private let selectionKey = "sweatlock_family_selection"
  private let sessionStartKey = "sweatlock_session_start"
  private let unlockUntilKey = "sweatlock_unlock_until"
  private let modeKey = "sweatlock_block_mode"
  private let appGroupId = "group.com.sweat.lock.shield"

  private var sharedDefaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self
    requestNotificationPermission()
    loadPersistedSelection()

    if let registrar = self.registrar(forPlugin: "SweatLockSelectedApps") {
      registrar.register(
        SelectedAppsViewFactory(messenger: registrar.messenger()),
        withId: "sweatlock/ios_selected_apps"
      )
    }

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
          self.applyShield()
          result(true)

        case "clearShield":
          self.clearShield()
          result(true)

        case "startTimedLock":
          let args = call.arguments as? [String: Any]
          let warning = args?["warningMinutes"] as? Int ?? 2
          let lock = args?["lockMinutes"] as? Int ?? 5
          let mode = args?["mode"] as? String ?? "timed"
          let appName = args?["appName"] as? String ?? "Selected apps"
          self.startTimedLock(
            warningMinutes: warning,
            lockMinutes: lock,
            mode: mode,
            appName: appName
          )
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
          let warning = args?["warningMinutes"] as? Int ?? 2
          let lock = args?["lockMinutes"] as? Int ?? 5
          let mode = args?["mode"] as? String ?? "timed"
          let appName = args?["appName"] as? String ?? "Selected apps"
          self.restartMonitoring(
            warningMinutes: warning,
            lockMinutes: lock,
            mode: mode,
            appName: appName
          )
          result(true)

        case "setBlockMode":
          let args = call.arguments as? [String: Any]
          let mode = args?["mode"] as? String ?? "timed"
          let warning = args?["warningMinutes"] as? Int ?? 2
          let lock = args?["lockMinutes"] as? Int ?? 5
          let appName = args?["appName"] as? String ?? "Selected apps"
          self.applyBlockMode(
            mode: mode,
            warningMinutes: warning,
            lockMinutes: lock,
            appName: appName
          )
          result(true)

        case "isShieldActive":
          let active = self.store.shield.applications != nil
            && !(self.store.shield.applications?.isEmpty ?? true)
          result(active)

        case "getAuthorizationStatus":
          result(self.authStatusString())

        case "getAppUsage":
          result([])

        case "resetUsage":
          result(nil)

        case "consumePendingWorkout":
          let opened = self.consumePendingWorkoutIfNeeded()
          result(opened)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    enforceShieldIfNeeded()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "sweatlock" {
      // Only set pending — resume/Flutter consume opens once
      sharedDefaults?.set(true, forKey: "pending_workout_open")
      sharedDefaults?.synchronize()
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    enforceShieldIfNeeded()
    _ = consumePendingWorkoutIfNeeded()
  }

  @discardableResult
  private func consumePendingWorkoutIfNeeded() -> Bool {
    guard sharedDefaults?.bool(forKey: "pending_workout_open") == true else {
      return false
    }
    sharedDefaults?.set(false, forKey: "pending_workout_open")
    sharedDefaults?.synchronize()
    let last = sharedDefaults?.double(forKey: "last_open_workout_ts") ?? 0
    let now = Date().timeIntervalSince1970
    if now - last < 2.0 {
      print("SweatLock: skip openWorkout (cooldown)")
      return false
    }
    sharedDefaults?.set(now, forKey: "last_open_workout_ts")
    sharedDefaults?.synchronize()
    notifyFlutterOpenWorkout()
    return true
  }

  private func notifyFlutterOpenWorkout() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      sharedDefaults?.set(true, forKey: "pending_workout_open")
      return
    }
    let channel = FlutterMethodChannel(
      name: "sweatlock/screen_time",
      binaryMessenger: controller.binaryMessenger
    )
    channel.invokeMethod("openWorkout", arguments: nil)
    print("SweatLock: notified Flutter openWorkout")
  }

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
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
  }

  private func persistSelection() {
    if #available(iOS 15.0, *) {
      if let data = try? PropertyListEncoder().encode(selection) {
        UserDefaults.standard.set(data, forKey: selectionKey)
        sharedDefaults?.set(data, forKey: "family_selection")
        sharedDefaults?.synchronize()
      }
      AppDelegate.sharedSelection = selection
    }
  }

  private func loadPersistedSelection() {
    if #available(iOS 15.0, *) {
      let data = UserDefaults.standard.data(forKey: selectionKey)
        ?? sharedDefaults?.data(forKey: "family_selection")
      guard let data,
            let saved = try? PropertyListDecoder().decode(
              FamilyActivitySelection.self, from: data
            ) else { return }
      selection = saved
      AppDelegate.sharedSelection = saved
    }
  }

  private func applyShield() {
    if #available(iOS 15.0, *) {
      loadPersistedSelection()
      let apps = selection.applicationTokens
      let cats = selection.categoryTokens
      if apps.isEmpty && cats.isEmpty {
        clearShield()
        return
      }
      store.shield.applications = apps.isEmpty ? nil : apps
      store.shield.applicationCategories = cats.isEmpty ? nil : .specific(cats)
      print("SweatLock: shield APPLIED apps=\(apps.count)")
    }
  }

  private func clearShield() {
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
    sharedDefaults?.set(false, forKey: "force_shield")
    print("SweatLock: shield CLEARED")
  }

  private func resolvedFreeMinutes() -> Int {
    let v = sharedDefaults?.integer(forKey: "free_minutes") ?? 0
    if v >= 1 { return v }
    return 5
  }

  private func resolvedWarningMinutes() -> Int {
    let free = resolvedFreeMinutes()
    let v = sharedDefaults?.integer(forKey: "warning_minutes") ?? 0
    if v >= 1 { return min(v, max(free - 1, 1)) }
    return min(2, max(free - 1, 1))
  }

  private func applyBlockMode(
    mode: String,
    warningMinutes: Int,
    lockMinutes: Int,
    appName: String
  ) {
    UserDefaults.standard.set(mode, forKey: modeKey)
    sharedDefaults?.set(mode, forKey: modeKey)
    sharedDefaults?.set(appName, forKey: "display_app_name")
    sharedDefaults?.set(max(lockMinutes, 1), forKey: "free_minutes")
    sharedDefaults?.set(max(warningMinutes, 0), forKey: "warning_minutes")
    sharedDefaults?.synchronize()
    clearShield()
    cancelTimedLock()
    UserDefaults.standard.removeObject(forKey: unlockUntilKey)

    loadPersistedSelection()
    if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
      return
    }

    startTimedLock(
      warningMinutes: max(warningMinutes, 0),
      lockMinutes: max(lockMinutes, 1),
      mode: mode,
      appName: appName
    )
  }

  private func grantTemporaryUnlock(minutes: Int) {
    clearShield()
    cancelTimedLock()

    let until = Date().addingTimeInterval(TimeInterval(minutes * 60))
    UserDefaults.standard.set(until.timeIntervalSince1970, forKey: unlockUntilKey)
    sharedDefaults?.set(until.timeIntervalSince1970, forKey: unlockUntilKey)

    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes * 60)) { [weak self] in
      guard let self = self else { return }
      let mode = UserDefaults.standard.string(forKey: self.modeKey) ?? "immediate"
      if mode == "immediate" {
        self.applyShield()
      } else {
        self.startDeviceActivityMonitoring(
          lockMinutes: self.resolvedFreeMinutes(),
          warningMinutes: self.resolvedWarningMinutes()
        )
      }
    }
  }

  private func startTimedLock(
    warningMinutes: Int,
    lockMinutes: Int,
    mode: String,
    appName: String
  ) {
    cancelTimedLock()
    loadPersistedSelection()
    persistSelection()

    UserDefaults.standard.set(mode, forKey: modeKey)
    sharedDefaults?.set(mode, forKey: modeKey)

    if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
      clearShield()
      return
    }

    let now = Date()
    UserDefaults.standard.set(now.timeIntervalSince1970, forKey: sessionStartKey)
    UserDefaults.standard.removeObject(forKey: unlockUntilKey)
    sharedDefaults?.set(now.timeIntervalSince1970, forKey: sessionStartKey)
    sharedDefaults?.set(max(lockMinutes, 1), forKey: "free_minutes")
    sharedDefaults?.set(max(warningMinutes, 0), forKey: "warning_minutes")
    sharedDefaults?.set(appName, forKey: "display_app_name")
    sharedDefaults?.removeObject(forKey: unlockUntilKey)
    sharedDefaults?.synchronize()

    if mode == "immediate" {
      applyShield()
      return
    }

    clearShield()
    startDeviceActivityMonitoring(lockMinutes: lockMinutes, warningMinutes: warningMinutes)
    print("SweatLock: TIMED Screen Time \(lockMinutes)m for \(appName)")
  }

  /// One DeviceActivity per app — threshold is that app's Screen Time only.
  private func startDeviceActivityMonitoring(lockMinutes: Int, warningMinutes: Int) {
    if #available(iOS 15.0, *) {
      loadPersistedSelection()
      persistSelection()

      let apps = Array(selection.applicationTokens)
      let cats = Array(selection.categoryTokens)
      if apps.isEmpty && cats.isEmpty {
        print("SweatLock: DeviceActivity skip — no tokens")
        return
      }

      let free = max(lockMinutes, 1)
      let warn = max(min(warningMinutes, free - 1), 0)

      sharedDefaults?.set(free, forKey: "free_minutes")
      sharedDefaults?.set(warn, forKey: "warning_minutes")
      sharedDefaults?.synchronize()

      let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
        repeats: true
      )

      var toStop: [DeviceActivityName] = [.init("sweatlock.daily")]
      let prevCount = sharedDefaults?.integer(forKey: "monitored_app_count") ?? 0
      for i in 0..<max(prevCount, apps.count + cats.count + 5) {
        toStop.append(.init("sweatlock.app.\(i)"))
        toStop.append(.init("sweatlock.cat.\(i)"))
      }
      activityCenter.stopMonitoring(toStop)

      if let defaults = sharedDefaults {
        for i in 0..<20 {
          defaults.removeObject(forKey: "token_app_\(i)")
          defaults.removeObject(forKey: "token_cat_\(i)")
        }
        for (i, token) in apps.enumerated() {
          if let data = try? PropertyListEncoder().encode(token) {
            defaults.set(data, forKey: "token_app_\(i)")
          }
        }
        for (i, token) in cats.enumerated() {
          if let data = try? PropertyListEncoder().encode(token) {
            defaults.set(data, forKey: "token_cat_\(i)")
          }
        }
        defaults.set(apps.count, forKey: "monitored_app_count")
        defaults.set(cats.count, forKey: "monitored_cat_count")
        defaults.synchronize()
      }

      do {
        for (i, token) in apps.enumerated() {
          var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
          if #available(iOS 17.4, *) {
            events[.init("sweatlock.threshold.app.\(i)")] = DeviceActivityEvent(
              applications: Set([token]),
              threshold: DateComponents(minute: free),
              includesPastActivity: false
            )
            if warn > 0 && warn < free {
              events[.init("sweatlock.warning.app.\(i)")] = DeviceActivityEvent(
                applications: Set([token]),
                threshold: DateComponents(minute: warn),
                includesPastActivity: false
              )
            }
          } else {
            events[.init("sweatlock.threshold.app.\(i)")] = DeviceActivityEvent(
              applications: Set([token]),
              threshold: DateComponents(minute: free)
            )
          }
          try activityCenter.startMonitoring(
            .init("sweatlock.app.\(i)"),
            during: schedule,
            events: events
          )
        }

        for (i, token) in cats.enumerated() {
          var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
          if #available(iOS 17.4, *) {
            events[.init("sweatlock.threshold.cat.\(i)")] = DeviceActivityEvent(
              categories: Set([token]),
              threshold: DateComponents(minute: free),
              includesPastActivity: false
            )
          } else {
            events[.init("sweatlock.threshold.cat.\(i)")] = DeviceActivityEvent(
              categories: Set([token]),
              threshold: DateComponents(minute: free)
            )
          }
          try activityCenter.startMonitoring(
            .init("sweatlock.cat.\(i)"),
            during: schedule,
            events: events
          )
        }

        print("SweatLock: per-app DeviceActivity free=\(free)m warn=\(warn)m apps=\(apps.count)")
      } catch {
        print("SweatLock: DeviceActivity start failed: \(error)")
      }
    }
  }

  private func restartMonitoring(
    warningMinutes: Int,
    lockMinutes: Int,
    mode: String,
    appName: String
  ) {
    clearShield()
    startTimedLock(
      warningMinutes: warningMinutes,
      lockMinutes: lockMinutes,
      mode: mode,
      appName: appName
    )
  }

  private func cancelTimedLock() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: ["sweatlock_warning", "sweatlock_lock", "sweatlock_relock", "sweatlock_open_app"]
    )
    var names: [DeviceActivityName] = [.init("sweatlock.daily")]
    let n = sharedDefaults?.integer(forKey: "monitored_app_count") ?? 0
    let c = sharedDefaults?.integer(forKey: "monitored_cat_count") ?? 0
    for i in 0..<max(n, 20) { names.append(.init("sweatlock.app.\(i)")) }
    for i in 0..<max(c, 10) { names.append(.init("sweatlock.cat.\(i)")) }
    activityCenter.stopMonitoring(names)
  }

  private func enforceShieldIfNeeded() {
    if #available(iOS 15.0, *) {
      loadPersistedSelection()

      if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
        clearShield()
        return
      }

      if let until = UserDefaults.standard.object(forKey: unlockUntilKey) as? Double {
        if Date().timeIntervalSince1970 < until {
          clearShield()
          return
        }
      }

      // Per-app shield already set by extension — do not re-apply full selection
      if sharedDefaults?.bool(forKey: "force_shield") == true {
        return
      }

      let mode = UserDefaults.standard.string(forKey: modeKey) ?? "immediate"

      if mode == "immediate" {
        applyShield()
        return
      }

      return
    }
  }

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

          if self.selection.applicationTokens.isEmpty
              && self.selection.categoryTokens.isEmpty {
            self.clearShield()
            self.cancelTimedLock()
          } else {
            let mode = UserDefaults.standard.string(forKey: self.modeKey) ?? "immediate"
            if mode == "immediate" {
              self.applyShield()
            } else {
              self.clearShield()
              let free = self.resolvedFreeMinutes()
              let warn = self.resolvedWarningMinutes()
              self.startTimedLock(
                warningMinutes: warn,
                lockMinutes: free,
                mode: "timed",
                appName: self.sharedDefaults?.string(forKey: "display_app_name") ?? "Selected apps"
              )
            }
          }

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
        "appName": "App \(index)",
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

extension AppDelegate {
  open override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.identifier == "sweatlock_relock" {
      let mode = UserDefaults.standard.string(forKey: modeKey) ?? "immediate"
      if mode == "immediate" { applyShield() }
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
    let id = response.notification.request.identifier
    let info = response.notification.request.content.userInfo
    if id == "sweatlock_open_app" || info["openWorkout"] as? Bool == true {
      sharedDefaults?.set(true, forKey: "pending_workout_open")
      notifyFlutterOpenWorkout()
    } else if id == "sweatlock_lock" || id == "sweatlock_relock" {
      sharedDefaults?.set(true, forKey: "pending_workout_open")
      notifyFlutterOpenWorkout()
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
