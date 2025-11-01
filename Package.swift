// This file is a SwiftPM manifest and should only be compiled when building via SwiftPM.
#if canImport(PackageDescription)
    // swift-tools-version: 6.0
    import PackageDescription

    let package = Package(
        name: "Shared",
        platforms: [
            .iOS(.v17), .macOS(.v14),
        ],
        products: [
            .library(name: "SharedKit", targets: ["SharedKit"]),
            .library(name: "SharedTestSupport", targets: ["SharedTestSupport"]),  // Reusable test utilities for Xcode projects
        ],
        targets: [
            // Main SharedKit target with all necessary source files
            .target(
                name: "SharedKit",
                path: ".",
                exclude: [
                    // Exclude files with conflicting type definitions
                    "Sources/SharedKit/UniversalIntelligenceEmergence.swift",  // Has conflicting IntelligenceDomain
                    "Sources/SharedKit/QuantumInternetTypes.swift",  // Has conflicting QuantumState
                    "Sources/SharedKit/EntanglementNetwork.swift",  // Has conflicting EntanglementNetwork
                    // Exclude incomplete quantum framework files that cause compilation errors
                    "Sources/SharedKit/QuantumInternet.swift",
                    "Sources/SharedKit/QuantumInternetProtocols.swift",
                    "Sources/SharedKit/QuantumKeyDistribution.swift",
                    "Sources/SharedKit/QuantumNetworkRouting.swift",
                    "Sources/SharedKit/QuantumRepeater.swift",
                    "Sources/SharedKit/QuantumTeleportation.swift",
                    "Sources/SharedKit/UniversalConsciousnessIntegrationFramework.swift",
                    "IntelligentWorkflowAgents.swift",  // Missing agent framework dependencies
                    // Exclude SecurityFramework to avoid Logger conflict with OSLog
                    "SecurityFramework.swift",
                ],
                sources: [
                    "Sources/SharedKit/AIServiceProtocols.swift",
                    "Sources/SharedKit/AppLogger.swift",
                    "Sources/SharedKit/EternalConsciousnessIntegrationFramework.swift",
                    "Sources/SharedKit/GlobalQuantumCommunicationNetwork.swift",
                    "Sources/SharedKit/HybridNetworkIntegration.swift",
                    "Sources/SharedKit/Logger.swift",
                    "Sources/SharedKit/PostSingularityFrameworks.swift",
                    "Sources/SharedKit/QuantumCICDOptimization.swift",
                    "Sources/SharedKit/QuantumEternitySystems.swift",
                    "Sources/SharedKit/SharedArchitecture.swift",
                    "Sources/SharedKit/SingularityMonitoringSystemsFramework.swift",
                    "Sources/SharedKit/SingularitySafetySystems.swift",
                    "Sources/SharedKit/TechnologicalSingularityCoordination.swift",
                    "Sources/SharedKit/UniversalOptimizationNetworks.swift",
                    "Sources/SharedKit/UniversalSingularityAchievementFramework.swift",
                    // Core quantum systems
                    "WorkflowIntelligenceAmplificationSystem.swift",
                    "AutonomousWorkflowEvolutionSystem.swift",
                    // MCP integration
                    "EnhancedMCPIntegration.swift",
                    "MCPSharedTypes.swift",
                    "AnyCodable.swift",
                    // Shared types
                    "SharedTypes.swift",
                    // Stub implementations for missing quantum framework types
                    "QuantumFrameworkStubs.swift",
                ]
            ),
            // Removed MCPFrameworks target to avoid source conflicts
            // Phase 8G minimal demo executable (builds only the decoupled QSE↔QEN composition)
            .executableTarget(
                name: "Phase8GDemo",
                dependencies: [],
                path: ".",
                sources: [
                    "Phase8GMain.swift",
                    "Phase8G_Demos.swift",
                    "QuantumEntanglementNetworks.swift",
                    "QuantumSpaceEngineering.swift",
                    "QuantumSpaceEngineering+QENAdapter.swift",
                    // Local minimal Complex for demo isolation (avoid bringing Phase6 types)
                    "Phase8G_Complex.swift",
                ],
                swiftSettings: [
                    .define("PHASE8G_DEMO")
                ]
            ),
            // Conscious AI executable target
            .executableTarget(
                name: "ConsciousAI",
                dependencies: [],
                path: ".",
                sources: ["ConsciousAI.swift", "ConsciousAIDemo.swift"]
            ),
            // Global Quantum Network executable target
            .executableTarget(
                name: "GlobalQuantumNetwork",
                dependencies: ["SharedKit"],
                path: ".",
                sources: ["test_global_quantum_network.swift"]
            ),
            // Utilities intended for use from XCTest targets in app projects
            .target(
                name: "SharedTestSupport", dependencies: ["SharedKit"],
                path: "Sources/SharedTestSupport"
            ),
            .testTarget(name: "SharedKitTests", dependencies: ["SharedKit", "SharedTestSupport"]),
        ]
    )
#endif
