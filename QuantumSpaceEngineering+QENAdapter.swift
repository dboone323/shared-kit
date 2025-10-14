//
//  QuantumSpaceEngineering+QENAdapter.swift
//  Adapter to compose QSE with QEN without introducing hard compile-time coupling
//

import Foundation

// This adapter is compiled alongside both files in Shared. It only relies on the
// EntanglementMetricsProvider protocol and QEN's public API surface.

final class QENMetricsAdapter: EntanglementMetricsProvider {
    private let engine: QuantumEntanglementNetworkEngine

    init(engine: QuantumEntanglementNetworkEngine) {
        self.engine = engine
    }

    func fetchSnapshot() async -> QSEEntanglementSnapshot {
        // Use QEN reporting to build a minimal snapshot for QSE feedback
        let report = await engine.generateEntanglementReport()
        return QSEEntanglementSnapshot(
            averageStrength: report.averageStrength,
            networkCoherence: report.networkCoherence
        )
    }
}

/// Convenience coordinator to wire QSE with QEN in app targets
enum QSEQENCoordinator {
    static func makeComposedEngines() -> (
        QuantumSpaceEngineeringEngine, QuantumEntanglementNetworkEngine
    ) {
        let qen = QuantumEntanglementNetworkFactory.createEntanglementNetwork()
        let adapter = QENMetricsAdapter(engine: qen)
        let qse = QuantumSpaceEngineeringEngine(metricsProvider: adapter)
        return (qse, qen)
    }
}
