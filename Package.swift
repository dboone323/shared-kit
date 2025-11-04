// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "shared-kit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]
        )
    ],
    targets: [
        .target(
            name: "SharedKit",
            path: "."
        )
    ]
)
