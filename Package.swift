// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SharedKit",
    platforms: [
        .iOS(.v17), .macOS(.v14),
    ],
    products: [
        .library(name: "SharedKit", targets: ["SharedKit"]),
        .library(name: "SharedTestSupport", targets: ["SharedTestSupport"]),  // Reusable test utilities for Xcode projects
    ],
    targets: [
        // Minimal package for now; sources live under Sources/SharedKit
        .target(name: "SharedKit", path: "Sources/SharedKit"),
        // Utilities intended for use from XCTest targets in app projects
        .target(
            name: "SharedTestSupport", dependencies: ["SharedKit"],
            path: "Sources/SharedTestSupport"),
        .testTarget(name: "SharedKitTests", dependencies: ["SharedKit", "SharedTestSupport"]),
    ]
)
