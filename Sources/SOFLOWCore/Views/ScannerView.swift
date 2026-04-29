import SwiftUI
import CoreBluetooth

public struct ScannerView: View {
    @EnvironmentObject private var ble: BLEManager
    @State private var connecting: UUID?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            statusBar
            deviceList
        }
        .navigationTitle("SOFLOW")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { ble.startScan() }) {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .disabled(ble.state != .poweredOn)
            }
        }
        .onAppear { ble.startScan() }
    }

    private var statusBar: some View {
        HStack {
            Circle()
                .fill(ble.state == .poweredOn ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(stateLabel).font(.footnote).foregroundStyle(.secondary)
            Spacer()
            if let conn = ble.connected {
                Text("Connected: \(conn.name ?? conn.identifier.uuidString)")
                    .font(.footnote.monospaced())
                Button("Disconnect") { ble.disconnect() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var deviceList: some View {
        List(ble.discovered, id: \.identifier) { p in
            Button {
                connecting = p.identifier
                ble.connect(p)
            } label: {
                VStack(alignment: .leading) {
                    Text(p.name ?? "(unnamed)").font(.body)
                    Text(p.identifier.uuidString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var stateLabel: String {
        switch ble.state {
        case .poweredOn:    return "Bluetooth on"
        case .poweredOff:   return "Bluetooth off"
        case .unauthorized: return "Bluetooth permission denied"
        case .unsupported:  return "Unsupported"
        case .resetting:    return "Resetting"
        case .unknown:      return "Initializing…"
        @unknown default:   return "?"
        }
    }
}
