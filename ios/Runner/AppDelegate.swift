import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate {

  private let center = AuthorizationCenter.shared
  private var selection = FamilyActivitySelection()
  private var pendingResult: FlutterResult?

  // Shared so platform views can render Label(token)
  static var sharedSelection = FamilyActivitySelection()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register platform view for Label(ApplicationToken) display
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
          AppDelegate.sharedSelection = self.selection
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

// MARK: - Platform view: Label(token) for real app icons/names

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
          // Label(token) shows the real system icon + localized name
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
