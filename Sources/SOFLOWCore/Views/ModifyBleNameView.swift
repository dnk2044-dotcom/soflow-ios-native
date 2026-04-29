import SwiftUI

public struct ModifyBleNameView: View {
    @EnvironmentObject private var ble: BLEManager
    @State private var newName: String = ""
    @State private var status: String = ""

    public init() {}

    public var body: some View {
        Form {
            Section("New BLE name") {
                TextField("e.g. SO-PLUS-DEAN", text: $newName)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                Text("\(newName.utf8.count) bytes (max 26)")
                    .font(.caption)
                    .foregroundColor(newName.utf8.count > 26 ? .red : .secondary)
            }

            Section {
                Button {
                    writeName()
                } label: {
                    Label("Write name to scooter", systemImage: "pencil.and.scribble")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newName.isEmpty || newName.utf8.count > 26 || ble.connected == nil)
            } footer: {
                Text("Most SOFLOW firmwares accept a 1-26 char ASCII name. The scooter will reboot the BLE stack and re-advertise under the new name.")
                    .font(.footnote)
            }

            if !status.isEmpty {
                Section("Last write") {
                    Text(status).font(.caption.monospaced())
                }
            }
        }
        .navigationTitle("Modify BLE Name")
    }

    private func writeName() {
        let data = BleDataOperateManage.changeBleName(newName)
        ble.writeRaw(data)
        status = "Wrote \(data.count) bytes (\(HexParser.bytesToHexString(data)))"
    }
}
