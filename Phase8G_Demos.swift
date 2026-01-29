//
//  Phase8G_Demos.swift
//  Central demo harness for Tasks 200–205 (no top-level code)
//

import Foundation

public enum Phase8GDemos {
    public static func runAllDemos() async {
        await demonstrateQuantumEntanglementNetworks()
        await demonstrateQuantumSpaceEngineering()
        // The following demos depend on broader SharedKit pieces; exclude in isolated build
        #if !PHASE8G_DEMO
            await demonstrateRealityConsciousnessInterfaces()
            await demonstrateQuantumRealityCommunication()
            await demonstrateRealityEvolutionAcceleration()
            await demonstrateQuantumRealityPreservation()
            await demonstrateUniversalRealityOptimization()
        #endif
    }

    public static func runComposedQSEQENDemo() async {
        // Compose QSE with QEN and perform a coherence reinforcement informed by QEN metrics
        let (qse, qen) = QSEQENCoordinator.makeComposedEngines()
        do {
            let network = try await qen.initializeEntanglementNetwork()
            // Generate a report to seed metrics
            _ = await qen.generateEntanglementReport()

            let field = try await qse.initializeSpatialField()
            let reinforcement = try await qse.reinforceCoherence(for: field)
            print(
                "QSE+QEN demo -> coherence: \(String(format: "%.3f", reinforcement.newCoherence)) on network: \(network.networkId)"
            )
        } catch {
            print("QSE+QEN demo error: \(error)")
        }
    }
}
