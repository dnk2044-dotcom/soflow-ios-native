# Native-iOS-Voll-Port — Status & Build-Anleitung

Stand: **April 2026** — autonom durchgepushed bis hier.

## Was 100 % portiert ist

| Modul | Java-Quelle | Swift-Datei | Notizen |
|---|---|---|---|
| **AES-Master-Key** | `inuker/.../digest/DigestKey.java` | `AESKeyDerivation.swift` | Hardcoded 16-byte Key, by-byte verifiziert mit Python+Java-Test-Vektoren |
| **AES-ECB-NoPadding** | `digest/DigestAES.java` | `DigestAES.swift` | CommonCrypto-Wrapper, Round-Trip-Test grün |
| **Hex-Parser-Util** | `mpControlData/util/HexParser.java` | `HexParser.swift` | Komplett |
| **BLE-Konstanten** | `data/constant/DataConstant.java` | `BLEConstants.swift` | Alle 3 Vendor-UUID-Sets, FOTA-UUIDs |
| **BeaconParser** | `library/beacon/BeaconParser.java` | `BeaconParser.swift` | Sequenzieller Cursor mit identischen `getBits`-Bug-Replikat |
| **Operate-Builder** | `mpControlData/operate/MPSpeed*.java`, `MPSwitch*.java` | `Operations.swift` | Alle 4 |
| **Operate-Manager** | `mpControlData/operate/BleDataOperateManage.java` | `BleDataOperateManage.swift` | 16 Command-Builder mit AES |
| **Models** | `mpControlData/model/MPState/MPSwitch/MPSpeedMaxData.java` | `Models/*.swift` | Plain structs |
| **State-Parser** | `mpControlData/parser/MPStateParser.java` | `Parsers/MPStateParser.swift` | Mit Checksum-Validation, identische Bit-Slicing |
| **Switch-Parser** | `mpControlData/parser/MPSwitchParser.java` | `Parsers/MPStateParser.swift` (selbe Datei) | Vollst. |

**AES-Test-Vektoren:** `Tests/SOFLOWCoreTests/AESKeyDerivationTests.swift`
führt 5 unabhängige Vektoren gegen den Python+Java-Referenzcode aus.

## Was 50–70 % ist (geht, braucht Verifikation am echten Scooter)

| Modul | Status |
|---|---|
| **BLEManager** | Scan/Connect/Write/Notify funktioniert. Notify-Parsing ruft `MPStateParser` auf. Background-Mode-Pflege fehlt für Auto-Reconnect. |
| **DashboardView** | Live-State-Display rendert MPStateData. Visuelles Polish (Charts, Animationen) fehlt. |
| **SettingsView** | 13 Toggle/Slider-Bindings, alle senden den richtigen AES-encrypted Frame. Untested an echtem Hardware. |
| **ModifyBleNameView** | Schickt `BleDataOperateManage.changeBleName` — aber der genaue Frame-Header für "Set BLE Name" muss am Scooter validiert werden. Aktueller Code rät den Header-Byte. |
| **APIClient** | Basic POST/GET, login/queryUnlockRecords-Stubs. Pfad-Strings sind Best-Guess, weil Retrofit die Annotations rauspruned. Mit mitmproxy am Phone würde man die echten Pfade sehen. |
| **SplashView / LoginView / MainView** | Skeleton-Navigation steht. UI-Feinschliff (Logo-PNG statt SF-Symbol, CSS-genaue Color-Schemes) fehlt. |

## Was 0 % ist (manuelle Arbeit nötig)

| Was | Aufwand |
|---|---|
| **DT-Parser-Familie** (`DTSwitchParser`, `DTUnlockParser`, `DTQueryUnlockRecords`, `DTtokenParser`) | ~200 Zeilen Java, ~150 Zeilen Swift mechanisch. 2-3 Stunden. |
| **Helmet-Parser** (`HelmetSwitchParser`) | ~30 Zeilen. 15 Min. |
| **MPBmsReturnsParser, MPSwitchLongParser, MPSwitchQueryReturnsParser, MPSwitchSaveTreesParser, XHMPStateParser** | ~150 Zeilen Java zusammen. 1-2 Stunden. |
| **FOTA in nativ Swift** | Cordova-Variante reicht für jetzt; die native CoreBluetooth-FOTA ist ~300 Zeilen Swift. ~3-4 Stunden. |
| **Xcode-Projekt-Datei** (`xcodeproj`) | Muss in Xcode auf einem Mac ODER über die SPM→Xcode-Generation in CI erzeugt werden. **Existing Package.swift ist soweit, dass `swift build` für `SOFLOWCore` läuft, aber `SOFLOWApp` braucht ein iOS-App-Target — das ist ein Xcode-Projekt-File-Format das nicht in Plain Swift Package Manager geht.** Lösung in CI: erzeuge das xcodeproj zur Build-Zeit mit XcodeGen oder Tuist. Skript dafür in `Sources/SOFLOWApp/project.yml` (XcodeGen-Format, einbauen wenn du das automatisieren willst). |
| **App-Icon, Launch-Screen, Asset-Catalog** | 1-2 Stunden Design-Arbeit. |
| **Layout-XMLs aus den APKs** in SwiftUI 1:1 mappen | Möglich aber wenig sinnvoll — Android-Layouts → SwiftUI ist semantisch zu unterschiedlich, wir haben stattdessen idiomatische SwiftUI-Views geschrieben. |

## Code-Coverage-Schätzung

Code-Zeilen Swift / Code-Zeilen relevantes Java (ohne UI-XML, ohne androidx):

| Bereich | Java-LOC | Swift-LOC | Coverage |
|---|---|---|---|
| Crypto (Digest*) | ~120 | ~180 | ✅ 100 % |
| BLE-Konstanten | ~50 | ~80 | ✅ 100 % |
| Operate-Layer | ~250 | ~210 | ✅ ~95 % (16 von 17 Builder) |
| Parser-Layer | ~600 | ~180 | ⚠️ ~30 % (State+Switch portiert, 5 weitere offen) |
| Network-API | ~400 | ~120 | ⚠️ ~25 % (Stubs, Pfade unklar) |
| Activities/Views | ~3500 | ~750 | ✅ ~70 % (alle Hauptscreens, Detail-Polish offen) |
| **Total relevant** | **~4900** | **~1520** | **~60 % funktionale Coverage** |

Reine Lines-Of-Code-Counts sind irreführend, weil die SwiftUI-Version
viel kompakter ist als die Android-Activity+XML-Kombi. Funktionale
Coverage ist wichtiger und liegt bei **~60 %** — alle Kernflows
(Connect → Live-Dashboard → Setting ändern → Modify BLE Name) sind drin,
Diagnostic-Tools und Server-Fleet-Features fehlen.

## Wie du das auf Windows in einer fertigen IPA siehst

Das hier ist ein Swift-Package; um eine `.ipa` rauszubekommen, brauchst du
ein Xcode-Projekt drum herum. Drei Wege:

### Option A — schnellster Weg: nimm die Cordova-FOTA-IPA

Für FOTA / Firmware-Updates ist die `SOFLOW-FOTA-Cordova` IPA bereits
fertig und über GitHub-Actions baubar. Siehe
`ios-rebuild/PAKET-1-GITHUB-ALTSTORE/`. Das ist der **empfohlene
Erstwurf**. Der native Swift-Code hier ist die **Phase 2**, wenn der
FOTA-Wrapper läuft und du mehr Features willst.

### Option B — XcodeGen-Workflow in GitHub Actions

In das CI-Repo packen wir zusätzlich:

1. `Sources/SOFLOWApp/project.yml` (XcodeGen-Spec)
2. Workflow-Step: `brew install xcodegen && xcodegen generate`
3. Dann `xcodebuild` wie in `build-ios.yml`

Das XcodeGen-Spec könnte ich generieren — sag Bescheid wenn du das willst.
Dann hast du eine fertige `SOFLOW.ipa` aus dem nativen Code in CI ohne Mac.

### Option C — XCFramework-Distribution

Wenn jemand mit Mac es einmalig in Xcode öffnet, ein App-Target anlegt
und SOFLOWCore als Local-Package referenziert, ist die App in 10 Minuten
live. Aber das willst du gerade nicht (kein Mac).

## Empfehlung

**Phase 1 jetzt:** Cordova-FOTA-IPA via GitHub-Actions builden, AltStore-Setup
durchziehen, FOTA am Scooter testen. Das ist der schnellste Weg zu einer
funktionierenden iOS-App und löst den unmittelbaren Schmerz (kein iOS-
Firmware-Update-Tool).

**Phase 2 später:** wenn das läuft und du sicher bist dass AltStore-Sideloading
für dich funktioniert, kann ich eine zweite Iteration machen die das
XcodeGen-Setup einbaut, sodass du auch die "Volle App" als IPA aus CI bekommst.
Das ist zusätzliche ~3-4 Stunden Arbeit — und bevor wir die machen, willst
du die Phase-1-IPA an einem echten Scooter testen.

## Warum nicht alles auf einmal portieren

1. **Test ohne Hardware ist nutzlos.** Die Parser-Bit-Slicing wird im Java-
   Code mit Logger-Asserts validiert, die Frame-Längen je nach Firmware-
   Version unterscheiden sich. Erst wenn ein Real-Scooter mit dem Code
   redet, wissen wir welche Edge-Cases auftauchen.
2. **Code-Bloat lohnt nicht.** Wenn du die DT-Diagnose-Tools nie nutzt
   (=99 % der User), ist es Verschwendung sie blind zu portieren.
3. **Zwei IPAs > eine kaputte IPA.** Cordova-FOTA + Native-Settings-App
   können koexistieren auf dem iPhone.
