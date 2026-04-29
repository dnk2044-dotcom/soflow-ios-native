import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var ble: BLEManager

    @State private var topSpeed: Double = 25
    @State private var lampOn: Bool = false
    @State private var darkMode: Bool = false
    @State private var ecoLevel: Int = 1
    @State private var brightness: Double = 5
    @State private var metric: Bool = true
    @State private var lockMode: Bool = false
    @State private var cruise: Bool = false
    @State private var boost: Bool = false
    @State private var connectionLight: Bool = true

    public init() {}

    public var body: some View {
        Form {
            Section("Speed & power") {
                HStack {
                    Text("Top speed")
                    Spacer()
                    Text("\(Int(topSpeed)) km/h").foregroundColor(.secondary)
                }
                Slider(value: $topSpeed, in: 5...30, step: 1) { editing in
                    if !editing { ble.send { BleDataOperateManage.setSpeedMax(Int(topSpeed)) } }
                }
                Picker("Eco level", selection: $ecoLevel) {
                    Text("Low").tag(0)
                    Text("Medium").tag(1)
                    Text("High").tag(2)
                }.onChange(of: ecoLevel) { _, new in
                    ble.send { BleDataOperateManage.eco(level: new) }
                }
                Toggle("Cruise control", isOn: $cruise)
                    .onChange(of: cruise) { _, new in
                        ble.send { BleDataOperateManage.cruiseSetting(on: new) }
                    }
                Toggle("Boost", isOn: $boost)
                    .onChange(of: boost) { _, new in
                        ble.send { BleDataOperateManage.boostSetting(on: new) }
                    }
            }

            Section("Lights & display") {
                Toggle("Headlight", isOn: $lampOn)
                    .onChange(of: lampOn) { _, new in
                        ble.send { BleDataOperateManage.lampSetting(on: new) }
                    }
                Toggle("Connection-status light", isOn: $connectionLight)
                    .onChange(of: connectionLight) { _, new in
                        ble.send { BleDataOperateManage.connectionLight(on: new) }
                    }
                Toggle("Dark mode display", isOn: $darkMode)
                    .onChange(of: darkMode) { _, new in
                        ble.send { BleDataOperateManage.darkMode(on: new) }
                    }
                HStack {
                    Text("Brightness")
                    Spacer()
                    Text("\(Int(brightness))/10").foregroundColor(.secondary)
                }
                Slider(value: $brightness, in: 0...10, step: 1) { editing in
                    if !editing { ble.send { BleDataOperateManage.brightness(level: Int(brightness)) } }
                }
            }

            Section("Misc") {
                Toggle("Metric (km / km/h)", isOn: $metric)
                    .onChange(of: metric) { _, new in
                        ble.send { BleDataOperateManage.unit(metric: new) }
                        ble.send { BleDataOperateManage.flowMiles(metric: new) }
                    }
                Toggle("Lock mode", isOn: $lockMode)
                    .onChange(of: lockMode) { _, new in
                        ble.send { BleDataOperateManage.lockMode(on: new) }
                    }
                Button(role: .destructive) {
                    ble.send { BleDataOperateManage.reset() }
                } label: {
                    Label("Reset trip data", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Scooter Settings")
        .onAppear {
            ble.send { BleDataOperateManage.query() }
        }
    }
}

public struct FactoryView: View {
    public init() {}
    public var body: some View {
        Text("Factory tools — needs DT* parsers ported.")
            .padding()
            .navigationTitle("Factory")
    }
}

public struct QueryView: View {
    public init() {}
    public var body: some View {
        Text("Query / Records — needs DTQueryUnlockRecordsParser port.")
            .padding()
            .navigationTitle("Query")
    }
}

public struct FaultView: View {
    @EnvironmentObject private var ble: BLEManager
    public init() {}
    public var body: some View {
        List {
            if let s = ble.lastState {
                if s.faultBrake         { Text("Brake fault") }
                if s.faultController    { Text("Controller fault") }
                if s.faultMotor         { Text("Motor fault") }
                if s.faultCommunication { Text("Communication fault") }
                if s.stealingAlert      { Text("Stealing alert / anti-theft") }
                if s.transferFault      { Text("Transfer fault") }
                if !s.faultBrake && !s.faultController && !s.faultMotor &&
                   !s.faultCommunication && !s.stealingAlert && !s.transferFault {
                    Text("No active faults").foregroundColor(.green)
                }
            } else {
                Text("Connect to a scooter and wait for state notifications.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Fault Codes")
    }
}

public struct PermissionView: View {
    public init() {}
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Bluetooth — required", systemImage: "antenna.radiowaves.left.and.right")
            Label("Local Network — for AltStore refresh", systemImage: "wifi")
            Text("On iOS 13+, location is NOT required for BLE.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Permissions")
    }
}

public struct AboutView: View {
    public init() {}
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOFLOW iOS — community port")
                .font(.headline)
            Text("Reverse-engineered from the Android APKs. " +
                 "All control commands work offline; server login is optional.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("About")
    }
}

public struct FOTAView: View {
    public init() {}
    public var body: some View {
        Text("FOTA flow — please use the separate Cordova-FOTA app for now.\n\n" +
             "Native CoreBluetooth FOTA implementation pending.")
            .padding()
            .multilineTextAlignment(.center)
            .navigationTitle("Firmware Update")
    }
}
