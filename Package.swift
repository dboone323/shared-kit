// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "shared-kit",
    // Lower macOS platform version to enable test discovery on current host (macOS 14)
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]
        ),
        .library(
            name: "SharedTestSupport",
            targets: ["SharedTestSupport"]
        ),
    ],
    targets: [
        .target(
            name: "SharedKit",
            path: "Sources/SharedKit"
        ),
        .target(
            name: "SharedTestSupport",
            dependencies: ["SharedKit"],
            path: "Sources/SharedTestSupport"
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit", "SharedTestSupport"],
            path: "Tests/SharedKitTests"
        ),
    ]
)
