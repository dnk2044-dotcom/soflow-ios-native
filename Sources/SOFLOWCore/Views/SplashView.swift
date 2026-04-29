import SwiftUI

public struct SplashView: View {
    @State private var didNavigate = false
    @StateObject private var ble = BLEManager()
    @AppStorage("hasLoggedIn") private var hasLoggedIn = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "scooter")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                Text("SOFLOW")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("BLE Tools")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            ble.setFactory(.walkiz)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                didNavigate = true
            }
        }
        .fullScreenCover(isPresented: $didNavigate) {
            if hasLoggedIn {
                MainView().environmentObject(ble)
            } else {
                LoginView(onLoginSuccess: {
                    hasLoggedIn = true
                }).environmentObject(ble)
            }
        }
    }
}
