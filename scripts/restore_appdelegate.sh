#!/bin/bash
# Run from repo root: bash scripts/restore_appdelegate.sh
set -e
FILE=ios/Runner/AppDelegate.swift
curl -sL "https://raw.githubusercontent.com/Destiny-Ed/sweat_lock/c0bdd0e1767be5e1708690ee3efdbba07c1eb444/ios/Runner/AppDelegate.swift" -o "$FILE"
python3 - << 'PY'
from pathlib import Path
t = Path("ios/Runner/AppDelegate.swift").read_text()
t = t.replace(
'''  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "sweatlock" {
      sharedDefaults?.set(true, forKey: "pending_workout_open")
      sharedDefaults?.synchronize()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.notifyFlutterOpenWorkout()
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }''',
'''  override func application(
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
  }''')
t = t.replace(
'''  @discardableResult
  private func consumePendingWorkoutIfNeeded() -> Bool {
    guard sharedDefaults?.bool(forKey: "pending_workout_open") == true else {
      return false
    }
    sharedDefaults?.set(false, forKey: "pending_workout_open")
    sharedDefaults?.synchronize()
    notifyFlutterOpenWorkout()
    return true
  }''',
'''  @discardableResult
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
  }''')
Path("ios/Runner/AppDelegate.swift").write_text(t)
print("AppDelegate restored + double-open fix applied")
PY
