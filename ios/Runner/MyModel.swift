//
//  MyModel.swift
//
//
//  Created by Destiny Dikeocha on 12/11/25.
//

import FamilyControls
import Foundation
import ManagedSettings

@available(iOS 15.0, *)
private let _MyModel = MyModel()

@available(iOS 15.0, *)
class MyModel: ObservableObject {
    let store = ManagedSettingsStore()

    @Published var selectionToDiscourage: FamilyActivitySelection
    @Published var selectionToEncourage: FamilyActivitySelection

    init() {
        selectionToDiscourage = FamilyActivitySelection()
        selectionToEncourage = FamilyActivitySelection()
    }

    class var shared: MyModel {
        return _MyModel
    }

    func setShieldRestrictions() {
        print("setShieldRestrictions")
        let applications = MyModel.shared.selectionToDiscourage

        if applications.applicationTokens.isEmpty {
            print("empty applicationTokens")
        }
        if applications.categoryTokens.isEmpty {
            print("empty categoryTokens")
        }

        store.shield.applications =
            applications.applicationTokens.isEmpty ? nil : applications.applicationTokens
        store.shield.applicationCategories =
            applications.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(applications.categoryTokens)

        // Save tokens as strings to App Group → Flutter can read this
        let shared = UserDefaults(suiteName: "group.com.sweat.lock.shield")!

        // Convert tokens to stable string keys
        let appTokenStrings = applications.applicationTokens.map { String(describing: $0) }
        let categoryTokenStrings = applications.categoryTokens.map { String(describing: $0) }

        let allBlockedTokens = appTokenStrings + categoryTokenStrings

        // Save as array
        shared.set(allBlockedTokens, forKey: "blocked_app_tokens")
        shared.synchronize()

        print("Saved \(allBlockedTokens.count) blocked tokens to App Group")
        print("Tokens: \(allBlockedTokens)")

    }

    
}
