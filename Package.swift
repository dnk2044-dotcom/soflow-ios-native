// swift-tools-version: 5.9
// Native iOS port of SO ONE-PLUS / Modify BLE Name.
// Library target SOFLOWCore is consumed by the SOFLOWApp xcodeproj
// (Sources/SOFLOWApp), which provides the @main entry point for iOS.

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
        .testTarget(
            name: "SOFLOWCoreTests",
            dependencies: ["SOFLOWCore"],
            path: "Tests/SOFLOWCoreTests"
        ),
    ]
)
