// swift-tools-version: 6.2
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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "4.2.0"),
    ],
    targets: [
        .target(
            name: "EnterpriseScalingFramework",
            dependencies: [],
            path: "Sources/EnterpriseScalingFramework"
        ),
        .executableTarget(
            name: "AgentDesktop",
            dependencies: ["SharedKit"],
            path: "Sources/AgentDesktop",
            exclude: ["AgentMonitoringView.swift"],
            sources: ["AgentDesktopApp.swift"]
        ),
        .executableTarget(
            name: "AgentCLI",
            dependencies: ["SharedKit"],
            path: "Sources/AgentCLI",
            sources: ["main.swift"]
        ),
        .executableTarget(
            name: "RAGVerifier",
            dependencies: ["SharedKit"],
            path: "Sources/RAGVerifier",
            sources: ["main.swift"]
        ),
        .target(
            name: "SharedKitCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux]))
            ],
            path: "Sources/SharedKitCore"
        ),
        .target(
            name: "SharedKit",
            dependencies: [
                "SharedKitCore",
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
            ],
            path: "Sources/SharedKit",
            exclude: [
                "UI/UI_UX_IMPLEMENTATION_GUIDE.md",
                "Services/SERVICE_LAYER_INTEGRATION_GUIDE.md",
                "StateManagement/STATE_MANAGEMENT_INTEGRATION_GUIDE.md",
            ]
        ),
        .target(
            name: "SharedTestSupport",
            dependencies: ["SharedKit"],
            path: "Sources/SharedTestSupport",
            exclude: [
                "Testing/TESTING_FRAMEWORK_GUIDE.md"
            ]
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit", "SharedTestSupport", "SharedKitCore"],
            path: "Tests/SharedKitTests"
        ),
    ]
)
