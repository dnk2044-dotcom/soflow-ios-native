import SwiftUI

public struct MainView: View {
    @EnvironmentObject private var ble: BLEManager

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("BLE") {
                    NavigationLink(destination: ScannerView()) {
                        Label("Scan & Connect", systemImage: "magnifyingglass")
                    }
                    if ble.connected != nil {
                        NavigationLink(destination: DashboardView()) {
                            Label("Live Dashboard", systemImage: "speedometer")
                        }
                        NavigationLink(destination: SettingsView()) {
                            Label("Scooter Settings", systemImage: "gearshape")
                        }
                        NavigationLink(destination: ModifyBleNameView()) {
                            Label("Modify BLE Name", systemImage: "pencil.and.scribble")
                        }
                        NavigationLink(destination: FOTAView()) {
                            Label("Firmware Update (FOTA)", systemImage: "arrow.up.circle")
                        }
                    }
                }

                Section("Diagnostics") {
                    NavigationLink(destination: FactoryView()) {
                        Label("Factory Tools", systemImage: "wrench.and.screwdriver")
                    }
                    NavigationLink(destination: QueryView()) {
                        Label("Query / Records", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(destination: FaultView()) {
                        Label("Fault Codes", systemImage: "exclamationmark.triangle")
                    }
                }

                Section("Misc") {
                    NavigationLink(destination: PermissionView()) {
                        Label("Permissions", systemImage: "lock.shield")
                    }
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("SOFLOW")
        }
    }
}
