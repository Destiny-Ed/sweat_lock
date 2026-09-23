# SweatLock iOS — Xcode setup (required)

Timed blocking and the custom SweatLock shield **only work** after these extension targets exist and share the same App Group + Family Controls entitlement.

---

## 1. App Group (Developer Portal + Xcode)

1. [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list) → App Groups → create:
   - `group.sweatlock.shared`
2. Add that group to your app’s App ID and to each extension App ID.
3. In Xcode → **Runner** target → Signing & Capabilities → **+ Capability** → **App Groups** → check `group.sweatlock.shared`.
4. Repeat App Groups on every extension target you create below.

Also ensure **Family Controls** is enabled on Runner and each extension.

---

## 2. Device Activity Monitor extension (usage-based timer)

This is what counts **minutes spent inside locked apps** (not a wall-clock timer).

1. Xcode menu: **File → New → Target…**
2. Choose **Device Activity Monitor Extension**
3. Product Name: `SweatLockMonitor`
4. Language: Swift · Finish · **Activate** scheme if asked
5. Delete the template Swift file Xcode created
6. In the project navigator, **add existing files**:
   - `ios/SweatLockMonitor/DeviceActivityMonitorExtension.swift`
   - `ios/SweatLockMonitor/Info.plist` (set as the target’s Info.plist)
   - `ios/SweatLockMonitor/SweatLockMonitor.entitlements` (Signing → Code Signing Entitlements)
7. Target settings:
   - **Deployment**: iOS 16+
   - **Bundle ID**: `YOUR_MAIN_BUNDLE_ID.SweatLockMonitor`
   - Capabilities: **Family Controls**, **App Groups** (`group.sweatlock.shared`)
8. **Runner** target → General → **Frameworks, Libraries, and Embedded Content**  
   → add `SweatLockMonitor.appex` → **Embed & Sign**

---

## 3. Shield Configuration extension (custom SweatLock UI)

Replaces the generic “Restricted” screen.

1. **File → New → Target…** → **Shield Configuration Extension**
2. Product Name: `SweatLockShieldConfig`
3. Replace template with:
   - `ios/SweatLockShield/ShieldConfigurationExtension.swift`
   - Info: use `ios/SweatLockShield/Info-Configuration.plist` (or copy its `NSExtension` keys)
4. Entitlements: Family Controls + App Group
5. Bundle ID: `YOUR_MAIN_BUNDLE_ID.SweatLockShieldConfig`
6. Embed in Runner (**Embed & Sign**)

---

## 4. Shield Action extension (Start Workout button)

1. **File → New → Target…** → **Shield Action Extension**
2. Product Name: `SweatLockShieldAction`
3. Use:
   - `ios/SweatLockShield/ShieldActionExtension.swift`
   - `ios/SweatLockShield/Info-Action.plist`
4. Entitlements: Family Controls + App Group
5. Bundle ID: `YOUR_MAIN_BUNDLE_ID.SweatLockShieldAction`
6. Embed in Runner (**Embed & Sign**)

---

## 5. Verify Runner

| Setting | Value |
|--------|--------|
| Family Controls | On |
| App Group | `group.sweatlock.shared` |
| URL Types | Scheme `sweatlock` (already in Info.plist) |
| Embedded extensions | Monitor + ShieldConfig + ShieldAction |

Clean build folder (⇧⌘K) → run on a **physical device** (extensions do not work properly in Simulator for Screen Time).

---

## 6. How timed blocking works after this

| Mode | Behavior |
|------|----------|
| **Immediate** | Shield applied as soon as apps are selected |
| **Timed** | No wall-clock timer. **DeviceActivity** counts only **active time** inside selected apps. When usage ≥ free minutes → monitor extension applies shield + notification |

If the locked app is **not open**, time does **not** count toward the limit.

After workout unlock, monitoring is stopped and restarted so the usage counter resets.

---

## Troubleshooting timed mode

1. Monitor extension must be embedded and signed with Family Controls.
2. App Group must match on Runner + Monitor (`group.sweatlock.shared`).
3. Selection must be persisted (open Family Picker → Done once after updating).
4. Authorization status must be **approved**.
5. Check device Console for `SweatLock: DeviceActivity monitoring started`.
