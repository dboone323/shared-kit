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
    dependencies: [],
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
            name: "SharedKit",
            dependencies: [],
            path: "Sources/SharedKitCore",
            sources: [
                "AnyCodable.swift",
                "Logger.swift",
                "ToolExecutionResult.swift",
                "KeychainManager.swift",
                "SecurityFramework.swift",
                "SharedArchitecture.swift",
                "Services/ServiceProtocols.swift",
                "Services/DependencyContainer.swift",
                "Services/PlatformFeatureRegistry.swift",
                "Services/BackupRestoreService.swift",
                "Security/CertificatePinningPolicy.swift",
                "Security/EncryptedFileStore.swift",
                "Utilities/AppLogger.swift",
                "Utilities/FinancialUtilities.swift",
                "Utilities/SwiftDataCompat.swift",
            ]
        ),
        .target(
            name: "SharedTestSupport",
            dependencies: ["SharedKit"],
            path: "Sources/SharedTestSupport"
        ),
    ]
)
