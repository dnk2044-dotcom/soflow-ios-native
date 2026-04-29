// ModifyBleNameView.swift
// Functional equivalent of the entire "Modify BLE Name" Android app
// (com.soflow.modify) — connect to a scooter, write a new BLE
// advertised name, disconnect. Uses BleDataOperateManage.changeBleName,
// which encrypts to two AES blocks (64 hex chars padded) per the Java code.

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
                Text("Most SOFLOW firmwares accept a 1–26 char ASCII name. The scooter will reboot the BLE stack and re-advertise under the new name.")
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

