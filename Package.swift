// This file is a SwiftPM manifest and should only be compiled when building via SwiftPM.
#if canImport(PackageDescription)
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
            // Add all MCP framework files
            .target(
                name: "MCPFrameworks", dependencies: [], path: ".",
                sources: [
                    "MCPSharedTypes.swift",
                    "EnhancedMCPIntegration.swift",
                    "UniversalMCPFrameworks.swift",
                    "MCPIntelligenceSynthesis.swift",
                    "MCPCoordinationSystems.swift",
                    "QuantumOrchestrationFrameworks.swift",
                    "ComprehensiveSupportingArchitectures.swift",
                    "MCPSystemIntegration.swift",
                    "MCPUniversalIntelligence.swift",
                    "MCPIntegrationAPIs.swift",
                    "UniversalAgentEraCompletion.swift",
                ]),
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
                path: "Sources/SharedTestSupport"),
            .testTarget(name: "SharedKitTests", dependencies: ["SharedKit", "SharedTestSupport"]),
        ]
    )
#endif
