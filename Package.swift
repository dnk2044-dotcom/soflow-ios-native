// swift-tools-version: 5.9
// Native iOS port of SO ONE-PLUS / Modify BLE Name.
// Library target SOFLOWCore is consumed by the SOFLOWApp xcodeproj
// (Sources/SOFLOWApp), which provides the @main entry point for iOS.
//
// To build the .ipa via GitHub Actions, see
// ios-rebuild/PAKET-1-GITHUB-ALTSTORE/GITHUB-SETUP-GUIDE.md.

import PackageDescription

let package = Package(
    name: "SOFLOW",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "SOFLOWCore", targets: ["SOFLOWCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SOFLOWCore",
            path: "Sources/SOFLOWCore"
        ),
        .t