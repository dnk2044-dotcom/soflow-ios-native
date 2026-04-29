// LoginView.swift
// Replacement for com.ble.soflow.LoginActivity. The Android app posts
// username/password to {baseURL}/loginV. This view is opt-in: the Modify-
// BLE-Name flow and the BLE control commands work fully offline (the
// AES master key is hardcoded). Server login is only required for fleet
// management features (UnlockRecords, TPMS history) which we don't port.

import SwiftUI

public struct LoginView: View {
    public let onLoginSuccess: () -> Void

    @EnvironmentObject private var ble: BLEManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoggingIn = false
    @State private var errorMessage: String?

    public init(onLoginSuccess: @escaping () -> Void) {
        self.onLoginSuccess = onLoginSuccess
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Welcome to SOFLOW")
                    .font(.title2.bold())
                    .padding(.top, 40)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Username").font(.caption).foregroundColor(.secondary)
                    TextField("Enter username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Text("Password").font(.caption).foregroundColor(.secondary)
                    SecureField("Enter password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 24)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal, 24)
                }

                Button {
                    login()
                } label: {
                    HStack {
                        if isLoggingIn { ProgressView().tint(.white) }
                        Text(isLoggingIn ? "Logging in…" : "Log In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoggingIn || username.isEmpty || password.isEmpty)
                .padding(.horizontal, 24)

                Divider().padding(.vertical, 12)

                Button("Skip — go straight to BLE tools") {
                    onLoginSuccess()
                }
                .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func login() {
        isLoggingIn = true
        errorMessage = nil
        Task {
            do {
                try await APIClient.shared.login(username: username, password: password)
                isLoggingIn = false
                onLoginSuccess()
            } catch {
                isLoggingIn = false
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }
}
