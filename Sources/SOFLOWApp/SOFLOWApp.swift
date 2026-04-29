// SOFLOWApp.swift
// @main entry point for the iOS app target. Build this in Xcode by
// adding it to a SwiftUI iOS app target (`File → New → Project → iOS App`)
// and importing SOFLOWCore as a Swift-Package dependency.

import SwiftUI
import SOFLOWCore

@main
struct SOFLOWApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}
