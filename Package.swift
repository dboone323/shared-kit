// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedKit",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(name: "SharedKit", targets: ["SharedKit"]),
        .library(name: "SharedTestSupport", targets: ["SharedTestSupport"]) // Reusable test utilities for Xcode projects
    ],
    targets: [
        // Minimal package for now; sources live under Sources/SharedKit
        .target(name: "SharedKit"),
        // Utilities intended for use from XCTest targets in app projects
        .target(name: "SharedTestSupport"),
        .testTarget(name: "SharedKitTests", dependencies: ["SharedKit"])
    ]
)
