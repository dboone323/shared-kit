//
//  QuantumSpaceEngineering.swift
//  Quantum Singularity Era - Task 200 (Naming alignment wrapper)
//
//  Purpose: Provide a Task 200 wrapper named "Quantum Space Engineering" that composes the
//  Quantum Entanglement Networks engine to manage spatial coherence and connectivity. This aligns
//  with the Phase planning document while reusing the validated entanglement implementation.
//

import Foundation

protocol QSEProtocol {
    func initializeSpatialField() async throws -> QSEField
    func reinforceCoherence(for field: QSEField) async throws -> QSEReinforcement
}

struct QSEField: Sendable {
    let id: UUID
    let dimensions: Int
    var coherence: Double
    var curvature: Double
    let createdAt: Date
}

struct QSEReinforcement: Sendable {
    let fieldId: UUID
    let success: Bool
    let newCoherence: Double
    let energyCost: Double
}

// MARK: - Decoupled Composition Contracts

/// Minimal metrics snapshot used by QSE to adjust coherence without depending on QEN types
struct QSEEntanglementSnapshot: Sendable {
    let averageStrength: Double
    let networkCoherence: Double
}

/// Abstraction that any entanglement engine can implement (via adapter) to provide metrics
protocol EntanglementMetricsProvider {
    func fetchSnapshot() async -> QSEEntanglementSnapshot
}

// MARK: - Engine

final class QuantumSpaceEngineeringEngine: QSEProtocol {
    private let metricsProvider: EntanglementMetricsProvider?

    init(metricsProvider: EntanglementMetricsProvider? = nil) {
        self.metricsProvider = metricsProvider
    }

    func initializeSpatialField() async throws -> QSEField {
        QSEField(
            id: UUID(), dimensions: 3, coherence: 0.93, curvature: 0.01, createdAt: Date()
        )
    }

    func reinforceCoherence(for field: QSEField) async throws -> QSEReinforcement {
        // If a metrics provider is available, use entanglement metrics to adapt reinforcement.
        var coherenceBoostCap = 0.05
        var energyScale = 42.0

        if let provider = metricsProvider {
            let snapshot = await provider.fetchSnapshot()
            // When entanglement is weak, allow larger boost but pay higher energy; otherwise be gentle.
            if snapshot.averageStrength < 0.7 || snapshot.networkCoherence < 0.75 {
                coherenceBoostCap = 0.08
                energyScale = 60.0
            } else if snapshot.averageStrength > 0.9 && snapshot.networkCoherence > 0.9 {
                coherenceBoostCap = 0.03
                energyScale = 30.0
            }
        }

        let delta = min(1.0 - field.coherence, coherenceBoostCap)
        return QSEReinforcement(
            fieldId: field.id, success: delta > 0, newCoherence: field.coherence + delta,
            energyCost: delta * energyScale
        )
    }
}

func demonstrateQuantumSpaceEngineering() async {
    let engine = QuantumSpaceEngineeringEngine()
    do {
        let field = try await engine.initializeSpatialField()
        let result = try await engine.reinforceCoherence(for: field)
        print(
            "QSE demo -> success: \(result.success), coherence: \(String(format: "%.3f", result.newCoherence))"
        )
    } catch { print("QSE demo error: \(error)") }
}
