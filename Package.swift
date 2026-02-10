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
        .library(
            name: "EnterpriseScalingFramework",
            targets: ["EnterpriseScalingFramework"]
        ),
        .executable(
            name: "RAGVerifier",
            targets: ["RAGVerifier"]
        ),
        .executable(
            name: "AgentCLI",
            targets: ["AgentCLI"]
        ),
        .executable(
            name: "AgentDesktop",
            targets: ["AgentDesktop"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "AgentDesktop",
            dependencies: ["SharedKit"],
            path: "Sources/AgentDesktop"
        ),
        .executableTarget(
            name: "AgentCLI",
            dependencies: ["SharedKit"],
            path: "Sources/AgentCLI"
        ),
        .executableTarget(
            name: "RAGVerifier",
            dependencies: ["SharedKit"],
            path: "Sources/RAGVerifier"
        ),
        .target(
            name: "EnterpriseScalingFramework",
            dependencies: [],
            path: "Sources/EnterpriseScalingFramework"
        ),
        .target(
            name: "SharedKit",
            dependencies: [
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "Logging", package: "swift-log"),
            ],
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
