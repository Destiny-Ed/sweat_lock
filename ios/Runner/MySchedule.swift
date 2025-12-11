//
//  MySchedule.swift
//  Runner
//
//  Created by Destiny Dikeocha on 12/11/25.
//


import Foundation
import DeviceActivity

@available(iOS 15.0, *)
extension DeviceActivityName {
    static let daily = Self("daily")
}

@available(iOS 15.0, *)
extension DeviceActivityEvent.Name {
    static let encouraged = Self("encouraged")
}

@available(iOS 15.0, *)
let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 15, minute: 08),
    intervalEnd: DateComponents(hour: 16, minute: 08),
    repeats: false,
    warningTime: nil
)

@available(iOS 15.0, *)
class MySchedule {
    static public func unsetSchedule() {
        let center = DeviceActivityCenter()
        if center.activities.isEmpty {
            return
        }
        center.stopMonitoring(center.activities)
    }

    static public func setSchedule() {
        let applications = MyModel.shared.selectionToEncourage
        if applications.applicationTokens.isEmpty {
            print("empty applicationTokens")
        }
        if applications.categoryTokens.isEmpty {
            print("empty categoryTokens")
        }

        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            .encouraged: DeviceActivityEvent(
                applications: applications.applicationTokens,
                categories: applications.categoryTokens,
                threshold: DateComponents(minute: 1)
            )
        ]

        let center = DeviceActivityCenter()
        do {
            try center.startMonitoring(.daily, during: schedule, events: events)
        } catch {
            print("Error monitoring schedule: ", error)
        }
    }
}
