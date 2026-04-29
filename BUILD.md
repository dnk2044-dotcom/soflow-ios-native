# SOFLOW iOS Native — build guide

This is a **Swift / SwiftUI starter project** that ports the *core*
of the SO ONE-PLUS and Modify BLE Name Android apps to iOS:

- `BLEConstants.swift` — every BLE UUID and the 3-vendor factory map
  (KING-METER / Nordic UART / Walkiz). 100% complete.
- `HexParser.swift` — hex/byte/checksum utilities. 100% complete.
- `DigestAES.swift` — AES-ECB-NoPadding encrypt/decrypt. 100% complete.
- `BLEManager.swift` — CoreBluetooth scan/connect/write/notify. 80% — works,
  needs the AES key handshake step ported.
- `Operations.swift` — 4 of the 4 command builders ported (speedMax,
  speedSetting, switchOnOff, switchFlowMiles). 100% of operate/.
- `APIClient.swift` — empty shell. The actual login/token flow is in
  the SO ONE-PLUS `LoginActivity` and `inuker.bluetooth.bledata.network.ApiImpl*`
  classes — each endpoint needs ~10 lines of Swift.
- `Views/ScannerView.swift`, `DashboardView.swift`, `ModifyBleNameView.swift` —
  SwiftUI replacements for the main Android Activities.

## What's NOT done yet (be honest)

Roughly 70% of the Android app remains to be ported:

1. **Per-device AES key handshake.** The Android side calls
   `DataConstant.setKey(...)` after a brief exchange over the shield
   service. Needs disassembly of `inuker/library/connect/IKey*` to
   match exactly.
2. **All 7 notify-frame parsers** in `mpControlData/parser/` (live state,
   battery, switches, eco mode, XH state). Each is a fixed-offset hex
   slice — easy but tedious. Estimate: 1–2 hours of mechanical translation.
3. **DT (diagnostic tool)** subsystem — `DTActivity`, `DTparser`,
   register-fingerprint flow. ~500 lines.
4. **Helmet** subsystem — `HelmetActivity`, `Helmetparser`. ~300 lines.
5. **TPMS** (tire-pressure monitoring) — `TPMSActivity`. ~200 lines.
6. **OTA / FOTA** — see the sister project `../SOFLOW-FOTA-Cordova/`
   for the easy way; or rewrite in Swift using the FOTA UUIDs.
7. **Login / signup / SMS code / token refresh** against
   `http://47.52.238.166:8080/`. Needs to be reverse-engineered from
   `LoginActivity` and `ApiImpl*.java` — those weren't decompiled in
   the analysis pass because of jadx timeout. Re-run jadx without
   timeout on a Mac to get the full source.
8. **Excel-driven lock data** — `assets/lock.xls` and `lock1.xls` are
   loaded at runtime (jxl library). Their structure isn't documented;
   if you need full feature parity, open them with a spreadsheet app
   and inspect what the Android `com.ble.soflow.excel.*` classes read.
9. **All UI layouts** beyond the basic 3 SwiftUI views — including
   QR-code scanner (use AVCaptureSession or one of the well-maintained
   SwiftUI QR libraries), unlock-records list, fault list.
10. **Localization** — Android app has Chinese, English, German, French,
    Spanish, Dutch, Danish properties files. Port each `functions_*.properties`
    to `Localizable.strings`.

Realistic time estimate for full feature parity:
- Solo iOS dev: 4–8 weeks
- Starting from this scaffold and using jadx output as reference: 3–5 weeks

## How to use this scaffold

This isn't a finished Xcode project — it's a Swift Package that you
embed in a new app. On your Mac:

1. Open Xcode → File → New → Project → iOS → App.
   - Product Name: `SOFLOW`
   - Bundle Identifier: `com.dean.soflow`
   - Interface: SwiftUI; Language: Swift; Storage: None.
2. Drag this `SOFLOWCore` folder into the project navigator.
3. In `SOFLOWApp.swift` replace the body with:
   ```swift
   import SwiftUI
   import SOFLOWCore   // or copy files directly into the app target

   @main struct SOFLOWApp: App {
       var body: some Scene { WindowGroup { ScannerView() } }
   }
   ```
4. In Info.plist add:
   - `NSBluetoothAlwaysUsageDescription` = "Used to talk to your scooter."
   - `NSBluetoothPeripheralUsageDescription` = same.
   - `NSAppTransportSecurity → NSExceptionDomains → 47.52.238.166 → NSExceptionAllowsInsecureHTTPLoads = YES`
     (only if you wire up `APIClient` against the SOFLOW backend).
5. Signing → Team = your Apple ID. Run on device.

## Testing without a scooter

The 4 frame builders in `Operations.swift` are pure functions — write
unit tests against the known-good hex from running the Android APK
in Android Studio's debugger. Example test target stub is in `Tests/`.

## Sideload / install on iPhone 16

Same as the Cordova project — see `../SOFLOW-FOTA-Cordova/BUILD.md`
for the three signing options (free 7-day, $99/yr Apple Developer,
AltStore/SideStore).
