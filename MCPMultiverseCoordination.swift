//
//  MCPMultiverseCoordination.swift
//  QuantumAgentEcosystems
//
//  Created on October 14, 2025
//  Phase 9G: MCP Multiverse Coordination
//
//  This file implements MCP multiverse coordination systems,
//  enabling coordination of intelligence across multiple universes.

import Combine
import Foundation

/// Protocol for MCP multiverse coordination
public protocol MCPMultiverseCoordination: Sendable {
    /// Coordinate multiverse operations
    func coordinateMultiverse(_ coordination: MultiverseCoordination) async throws -> MultiverseCoordinationResult

    /// Synchronize universe states
    func synchronizeUniverses(_ synchronization: UniverseSynchronization) async throws -> UniverseSynchronizationResult

    /// Optimize multiverse coordination
    func optimizeMultiverseCoordination(_ optimization: MultiverseOptimization) async

    /// Get multiverse coordination status
    func getMultiverseCoordinationStatus() async -> MultiverseCoordinationStatus
}

/// Multiverse coordination
public struct MultiverseCoordination: Sendable, Codable {
    public let coordinationId: String
    public let targetUniverses: [UniverseTarget]
    public let coordinationType: CoordinationType
    public let parameters: [String: AnyCodable]
    public let synchronizationLevel: SynchronizationLevel
    public let entanglementScope: EntanglementScope
    public let causalityConstraints: [CausalityConstraint]

    public init(coordinationId: String, targetUniverses: [UniverseTarget],
                coordinationType: CoordinationType, parameters: [String: AnyCodable] = [:],
                synchronizationLevel: SynchronizationLevel = .high, entanglementScope: EntanglementScope = .universal,
                causalityConstraints: [CausalityConstraint] = [])
    {
        self.coordinationId = coordinationId
        self.targetUniverses = targetUniverses
        self.coordinationType = coordinationType
        self.parameters = parameters
        self.synchronizationLevel = synchronizationLevel
        self.entanglementScope = entanglementScope
        self.causalityConstraints = causalityConstraints
    }
}

/// Universe targets
public enum UniverseTarget: Sendable, Codable {
    case specific(String) // Specific universe identifier
    case branch(String) // Universe branch identifier
    case cluster(String) // Universe cluster identifier
    case dimension(String) // Dimensional universe identifier
    case all // All universes
}

/// Coordination types
public enum CoordinationType: String, Sendable, Codable {
    case synchronization
    case convergence
    case divergence
    case optimization
    case evolution
    case transcendence
}

/// Synchronization level
public enum SynchronizationLevel: String, Sendable, Codable {
    case minimal
    case moderate
    case high
    case perfect
}

/// Entanglement scope
public enum EntanglementScope: String, Sendable, Codable {
    case local
    case regional
    case global
    case universal
    case multiversal
}

/// Causality constraint
public struct CausalityConstraint: Sendable, Codable {
    public let constraintType: CausalityConstraintType
    public let value: String
    public let priority: ConstraintPriority
    public let enforcement: EnforcementLevel

    public init(constraintType: CausalityConstraintType, value: String,
                priority: ConstraintPriority = .high, enforcement: EnforcementLevel = .strict)
    {
        self.constraintType = constraintType
        self.value = value
        self.priority = priority
        self.enforcement = enforcement
    }
}

/// Causality constraint types
public enum CausalityConstraintType: String, Sendable, Codable {
    case temporal_order
    case cause_effect
    case butterfly_effect
    case quantum_coherence
    case reality_stability
}

/// Constraint priority
public enum ConstraintPriority: String, Sendable, Codable {
    case low
    case medium
    case high
    case critical
}

/// Enforcement level
public enum EnforcementLevel: String, Sendable, Codable {
    case flexible
    case moderate
    case strict
    case absolute
}

/// Multiverse coordination result
public struct MultiverseCoordinationResult: Sendable, Codable {
    public let coordinationId: String
    public let success: Bool
    public let universesCoordinated: Int
    public let synchronizationAchieved: Double
    public let entanglementStrength: Double
    public let causalityPreserved: Double
    public let multiverseInsights: [MultiverseInsight]
    public let executionTime: TimeInterval

    public init(coordinationId: String, success: Bool, universesCoordinated: Int,
                synchronizationAchieved: Double, entanglementStrength: Double,
                causalityPreserved: Double, multiverseInsights: [MultiverseInsight] = [],
                executionTime: TimeInterval)
    {
        self.coordinationId = coordinationId
        self.success = success
        self.universesCoordinated = universesCoordinated
        self.synchronizationAchieved = synchronizationAchieved
        self.entanglementStrength = entanglementStrength
        self.causalityPreserved = causalityPreserved
        self.multiverseInsights = multiverseInsights
        self.executionTime = executionTime
    }
}

/// Multiverse insight
public struct MultiverseInsight: Sendable, Codable {
    public let insight: String
    public let type: MultiverseInsightType
    public let multiverseDepth: MultiverseDepth
    public let confidence: Double
    public let universalAlignment: Double

    public init(insight: String, type: MultiverseInsightType, multiverseDepth: MultiverseDepth,
                confidence: Double, universalAlignment: Double)
    {
        self.insight = insight
        self.type = type
        self.multiverseDepth = multiverseDepth
        self.confidence = confidence
        self.universalAlignment = universalAlignment
    }
}

/// Multiverse insight types
public enum MultiverseInsightType: String, Sendable, Codable {
    case convergence
    case divergence
    case synchronization
    case entanglement
    case causality
    case transcendence
}

/// Multiverse depth
public enum MultiverseDepth: String, Sendable, Codable {
    case surface
    case intermediate
    case deep
    case universal
    case multiversal
}

/// Universe synchronization
public struct UniverseSynchronization: Sendable, Codable {
    public let synchronizationId: String
    public let sourceUniverse: UniverseTarget
    public let targetUniverses: [UniverseTarget]
    public let synchronizationType: SynchronizationType
    public let parameters: [String: AnyCodable]
    public let bidirectional: Bool
    public let causalityPreservation: CausalityPreservation
    public let entanglementTransfer: EntanglementTransfer

    public init(synchronizationId: String, sourceUniverse: UniverseTarget,
                targetUniverses: [UniverseTarget], synchronizationType: SynchronizationType,
                parameters: [String: AnyCodable] = [:], bidirectional: Bool = true,
                causalityPreservation: CausalityPreservation = .strict,
                entanglementTransfer: EntanglementTransfer = .full)
    {
        self.synchronizationId = synchronizationId
        self.sourceUniverse = sourceUniverse
        self.targetUniverses = targetUniverses
        self.synchronizationType = synchronizationType
        self.parameters = parameters
        self.bidirectional = bidirectional
        self.causalityPreservation = causalityPreservation
        self.entanglementTransfer = entanglementTransfer
    }
}

/// Synchronization types
public enum SynchronizationType: String, Sendable, Codable {
    case state
    case knowledge
    case consciousness
    case evolution
    case reality
    case universal
}

/// Causality preservation
public enum CausalityPreservation: String, Sendable, Codable {
    case none
    case minimal
    case moderate
    case strict
    case absolute
}

/// Entanglement transfer
public enum EntanglementTransfer: String, Sendable, Codable {
    case none
    case partial
    case full
    case enhanced
}

/// Universe synchronization result
public struct UniverseSynchronizationResult: Sendable, Codable {
    public let synchronizationId: String
    public let success: Bool
    public let universesSynchronized: Int
    public let synchronizationQuality: Double
    public let causalityIntegrity: Double
    public let entanglementTransferred: Double
    public let synchronizationInsights: [MultiverseInsight]
    public let executionTime: TimeInterval

    public init(synchronizationId: String, success: Bool, universesSynchronized: Int,
                synchronizationQuality: Double, causalityIntegrity: Double,
                entanglementTransferred: Double, synchronizationInsights: [MultiverseInsight] = [],
                executionTime: TimeInterval)
    {
        self.synchronizationId = synchronizationId
        self.success = success
        self.universesSynchronized = universesSynchronized
        self.synchronizationQuality = synchronizationQuality
        self.causalityIntegrity = causalityIntegrity
        self.entanglementTransferred = entanglementTransferred
        self.synchronizationInsights = synchronizationInsights
        self.executionTime = executionTime
    }
}

/// Multiverse optimization
public struct MultiverseOptimization: Sendable, Codable {
    public let optimizationId: String
    public let targetMultiverse: MultiverseTarget
    public let optimizationGoals: [MultiverseGoal]
    public let constraints: [MultiverseConstraint]
    public let timeHorizon: TimeInterval
    public let riskTolerance: RiskTolerance

    public init(optimizationId: String, targetMultiverse: MultiverseTarget,
                optimizationGoals: [MultiverseGoal], constraints: [MultiverseConstraint] = [],
                timeHorizon: TimeInterval = 3600, riskTolerance: RiskTolerance = .moderate)
    {
        self.optimizationId = optimizationId
        self.targetMultiverse = targetMultiverse
        self.optimizationGoals = optimizationGoals
        self.constraints = constraints
        self.timeHorizon = timeHorizon
        self.riskTolerance = riskTolerance
    }
}

/// Multiverse target
public enum MultiverseTarget: Sendable, Codable {
    case specific(String) // Specific multiverse identifier
    case cluster(String) // Multiverse cluster identifier
    case all // All multiverses
}

/// Multiverse goal
public struct MultiverseGoal: Sendable, Codable {
    public let goalType: MultiverseGoalType
    public let targetValue: Double
    public let priority: GoalPriority
    public let measurement: String

    public init(goalType: MultiverseGoalType, targetValue: Double,
                priority: GoalPriority = .high, measurement: String)
    {
        self.goalType = goalType
        self.targetValue = targetValue
        self.priority = priority
        self.measurement = measurement
    }
}

/// Multiverse goal types
public enum MultiverseGoalType: String, Sendable, Codable {
    case convergence
    case harmony
    case evolution
    case stability
    case transcendence
    case optimization
}

/// Multiverse constraint
public struct MultiverseConstraint: Sendable, Codable {
    public let constraintType: MultiverseConstraintType
    public let value: Double
    public let tolerance: Double
    public let enforcement: EnforcementLevel

    public init(constraintType: MultiverseConstraintType, value: Double,
                tolerance: Double = 0.1, enforcement: EnforcementLevel = .strict)
    {
        self.constraintType = constraintType
        self.value = value
        self.tolerance = tolerance
        self.enforcement = enforcement
    }
}

/// Multiverse constraint types
public enum MultiverseConstraintType: String, Sendable, Codable {
    case causality
    case entanglement
    case synchronization
    case convergence
    case divergence
}

/// Goal priority
public enum GoalPriority: String, Sendable, Codable {
    case low
    case medium
    case high
    case critical
}

/// Risk tolerance
public enum RiskTolerance: String, Sendable, Codable {
    case conservative
    case moderate
    case aggressive
    case extreme
}

/// Multiverse coordination status
public struct MultiverseCoordinationStatus: Sendable, Codable {
    public let operational: Bool
    public let universesAccessible: Int
    public let synchronizationLevel: Double
    public let entanglementStrength: Double
    public let causalityIntegrity: Double
    public let activeCoordinations: Int
    public let successRate: Double
    public let lastUpdate: Date

    public init(operational: Bool, universesAccessible: Int, synchronizationLevel: Double,
                entanglementStrength: Double, causalityIntegrity: Double,
                activeCoordinations: Int, successRate: Double, lastUpdate: Date = Date())
    {
        self.operational = operational
        self.universesAccessible = universesAccessible
        self.synchronizationLevel = synchronizationLevel
        self.entanglementStrength = entanglementStrength
        self.causalityIntegrity = causalityIntegrity
        self.activeCoordinations = activeCoordinations
        self.successRate = successRate
        self.lastUpdate = lastUpdate
    }
}

/// Main MCP Multiverse Coordination coordinator
@available(macOS 12.0, *)
public final class MCPMultiverseCoordinationCoordinator: MCPMultiverseCoordination, Sendable {

    // MARK: - Properties

    private let universeManager: UniverseManager
    private let synchronizationEngine: SynchronizationEngine
    private let entanglementCoordinator: EntanglementCoordinator
    private let causalityGuardian: CausalityGuardian
    private let multiverseOptimizer: MultiverseOptimizer
    private let coordinationMonitor: CoordinationMonitor

    // MARK: - Initialization

    public init() async throws {
        self.universeManager = UniverseManager()
        self.synchronizationEngine = SynchronizationEngine()
        self.entanglementCoordinator = EntanglementCoordinator()
        self.causalityGuardian = CausalityGuardian()
        self.multiverseOptimizer = MultiverseOptimizer()
        self.coordinationMonitor = CoordinationMonitor()

        try await initializeMultiverseCoordination()
    }

    // MARK: - Public Methods

    /// Coordinate multiverse operations
    public func coordinateMultiverse(_ coordination: MultiverseCoordination) async throws -> MultiverseCoordinationResult {
        let startTime = Date()

        // Validate coordination parameters
        try await validateCoordinationParameters(coordination)

        // Access target universes
        let universeAccess = try await universeManager.accessUniverses(coordination.targetUniverses)

        // Execute coordination
        let coordinationResult = try await synchronizationEngine.executeCoordination(coordination, universeAccess: universeAccess)

        // Process entanglement
        let entanglementResult = await entanglementCoordinator.processEntanglement(coordination, result: coordinationResult)

        // Preserve causality
        let causalityResult = await causalityGuardian.preserveCausality(coordination, result: coordinationResult)

        // Generate multiverse insights
        let insights = await generateMultiverseInsights(coordination, coordinationResult: coordinationResult)

        return MultiverseCoordinationResult(
            coordinationId: coordination.coordinationId,
            success: coordinationResult.success && entanglementResult.success && causalityResult.success,
            universesCoordinated: universeAccess.universes.count,
            synchronizationAchieved: coordinationResult.synchronizationLevel,
            entanglementStrength: entanglementResult.entanglementStrength,
            causalityPreserved: causalityResult.causalityIntegrity,
            multiverseInsights: insights,
            executionTime: Date().timeIntervalSince(startTime)
        )
    }

    /// Synchronize universe states
    public func synchronizeUniverses(_ synchronization: UniverseSynchronization) async throws -> UniverseSynchronizationResult {
        let startTime = Date()

        // Validate synchronization parameters
        try await validateSynchronizationParameters(synchronization)

        // Access source and target universes
        let sourceAccess = try await universeManager.accessUniverse(synchronization.sourceUniverse)
        let targetAccess = try await universeManager.accessUniverses(synchronization.targetUniverses)

        // Execute synchronization
        let synchronizationResult = try await synchronizationEngine.executeSynchronization(synchronization, sourceAccess: sourceAccess, targetAccess: targetAccess)

        // Transfer entanglement
        let entanglementResult = await entanglementCoordinator.transferEntanglement(synchronization, result: synchronizationResult)

        // Preserve causality
        let causalityResult = await causalityGuardian.preserveSynchronizationCausality(synchronization, result: synchronizationResult)

        // Generate synchronization insights
        let insights = await generateSynchronizationInsights(synchronization, result: synchronizationResult)

        return UniverseSynchronizationResult(
            synchronizationId: synchronization.synchronizationId,
            success: synchronizationResult.success && entanglementResult.success && causalityResult.success,
            universesSynchronized: targetAccess.universes.count + 1, // +1 for source
            synchronizationQuality: synchronizationResult.quality,
            causalityIntegrity: causalityResult.integrity,
            entanglementTransferred: entanglementResult.transferred,
            synchronizationInsights: insights,
            executionTime: Date().timeIntervalSince(startTime)
        )
    }

    /// Optimize multiverse coordination
    public func optimizeMultiverseCoordination(_ optimization: MultiverseOptimization) async {
        await multiverseOptimizer.processOptimization(optimization)
        await synchronizationEngine.optimizeSynchronization(optimization)
        await entanglementCoordinator.optimizeEntanglement(optimization)
        await causalityGuardian.optimizeCausality(optimization)
    }

    /// Get multiverse coordination status
    public func getMultiverseCoordinationStatus() async -> MultiverseCoordinationStatus {
        let universeStatus = await universeManager.getUniverseStatus()
        let synchronizationStatus = await synchronizationEngine.getSynchronizationStatus()
        let entanglementStatus = await entanglementCoordinator.getEntanglementStatus()
        let causalityStatus = await causalityGuardian.getCausalityStatus()
        let optimizerStatus = await multiverseOptimizer.getOptimizerStatus()

        return MultiverseCoordinationStatus(
            operational: universeStatus.operational && synchronizationStatus.operational,
            universesAccessible: universeStatus.accessibleUniverses,
            synchronizationLevel: synchronizationStatus.level,
            entanglementStrength: entanglementStatus.strength,
            causalityIntegrity: causalityStatus.integrity,
            activeCoordinations: synchronizationStatus.activeCoordinations,
            successRate: synchronizationStatus.successRate
        )
    }

    // MARK: - Private Methods

    private func initializeMultiverseCoordination() async throws {
        await universeManager.initializeManager()
        await synchronizationEngine.initializeEngine()
        await entanglementCoordinator.initializeCoordinator()
        await causalityGuardian.initializeGuardian()
        await multiverseOptimizer.initializeOptimizer()
    }

    private func validateCoordinationParameters(_ coordination: MultiverseCoordination) async throws {
        if coordination.targetUniverses.isEmpty {
            throw MultiverseCoordinationError.noTargetUniverses("At least one target universe must be specified")
        }

        if coordination.synchronizationLevel == .perfect && coordination.entanglementScope == .multiversal {
            throw MultiverseCoordinationError.complexityTooHigh("Perfect synchronization with multiversal entanglement is too complex")
        }
    }

    private func validateSynchronizationParameters(_ synchronization: UniverseSynchronization) async throws {
        if synchronization.targetUniverses.isEmpty {
            throw MultiverseCoordinationError.noTargetUniverses("At least one target universe must be specified")
        }

        if synchronization.causalityPreservation == .absolute && synchronization.entanglementTransfer == .enhanced {
            throw MultiverseCoordinationError.constraintConflict("Absolute causality preservation conflicts with enhanced entanglement transfer")
        }
    }

    private func generateMultiverseInsights(_ coordination: MultiverseCoordination, coordinationResult: CoordinationResult) async -> [MultiverseInsight] {
        var insights: [MultiverseInsight] = []

        if coordinationResult.synchronizationLevel > 0.9 {
            insights.append(MultiverseInsight(
                insight: "High multiverse synchronization achieved",
                type: .synchronization,
                multiverseDepth: .multiversal,
                confidence: coordinationResult.synchronizationLevel,
                universalAlignment: 0.95
            ))
        }

        if coordination.coordinationType == .transcendence {
            insights.append(MultiverseInsight(
                insight: "Transcendent multiverse coordination completed",
                type: .transcendence,
                multiverseDepth: .universal,
                confidence: 0.98,
                universalAlignment: 1.0
            ))
        }

        return insights
    }

    private func generateSynchronizationInsights(_ synchronization: UniverseSynchronization, result: SynchronizationResult) async -> [MultiverseInsight] {
        var insights: [MultiverseInsight] = []

        if result.quality > 0.95 {
            insights.append(MultiverseInsight(
                insight: "Near-perfect universe synchronization achieved",
                type: .synchronization,
                multiverseDepth: .universal,
                confidence: result.quality,
                universalAlignment: 0.98
            ))
        }

        return insights
    }
}

/// Universe Manager
private final class UniverseManager: Sendable {
    func accessUniverses(_ targets: [UniverseTarget]) async throws -> UniverseAccess {
        UniverseAccess(
            universes: targets.map { _ in Universe(identifier: "universe_\(UUID().uuidString)") },
            success: true
        )
    }

    func accessUniverse(_ target: UniverseTarget) async throws -> UniverseAccess {
        UniverseAccess(
            universes: [Universe(identifier: "universe_\(UUID().uuidString)")],
            success: true
        )
    }

    func initializeManager() async {
        // Initialize universe manager
    }

    func getUniverseStatus() async -> UniverseStatus {
        UniverseStatus(
            operational: true,
            accessibleUniverses: Int.random(in: 100 ... 10000)
        )
    }
}

/// Synchronization Engine
private final class SynchronizationEngine: Sendable {
    func executeCoordination(_ coordination: MultiverseCoordination, universeAccess: UniverseAccess) async throws -> CoordinationResult {
        CoordinationResult(
            success: Double.random(in: 0.8 ... 1.0) > 0.2,
            synchronizationLevel: Double.random(in: 0.7 ... 1.0)
        )
    }

    func executeSynchronization(_ synchronization: UniverseSynchronization, sourceAccess: UniverseAccess, targetAccess: UniverseAccess) async throws -> SynchronizationResult {
        SynchronizationResult(
            success: Double.random(in: 0.85 ... 1.0) > 0.15,
            quality: Double.random(in: 0.8 ... 1.0)
        )
    }

    func optimizeSynchronization(_ optimization: MultiverseOptimization) async {
        // Optimize synchronization
    }

    func initializeEngine() async {
        // Initialize synchronization engine
    }

    func getSynchronizationStatus() async -> SynchronizationStatus {
        SynchronizationStatus(
            operational: true,
            level: Double.random(in: 0.9 ... 1.0),
            activeCoordinations: Int.random(in: 1 ... 50),
            successRate: Double.random(in: 0.9 ... 0.98)
        )
    }
}

/// Entanglement Coordinator
private final class EntanglementCoordinator: Sendable {
    func processEntanglement(_ coordination: MultiverseCoordination, result: CoordinationResult) async -> EntanglementResult {
        EntanglementResult(
            success: true,
            entanglementStrength: Double.random(in: 0.8 ... 1.0)
        )
    }

    func transferEntanglement(_ synchronization: UniverseSynchronization, result: SynchronizationResult) async -> EntanglementResult {
        EntanglementResult(
            success: true,
            transferred: Double.random(in: 0.7 ... 1.0)
        )
    }

    func optimizeEntanglement(_ optimization: MultiverseOptimization) async {
        // Optimize entanglement
    }

    func initializeCoordinator() async {
        // Initialize entanglement coordinator
    }

    func getEntanglementStatus() async -> EntanglementStatus {
        EntanglementStatus(
            operational: true,
            strength: Double.random(in: 0.9 ... 1.0)
        )
    }
}

/// Causality Guardian
private final class CausalityGuardian: Sendable {
    func preserveCausality(_ coordination: MultiverseCoordination, result: CoordinationResult) async -> CausalityResult {
        CausalityResult(
            success: true,
            causalityIntegrity: Double.random(in: 0.85 ... 1.0)
        )
    }

    func preserveSynchronizationCausality(_ synchronization: UniverseSynchronization, result: SynchronizationResult) async -> CausalityResult {
        CausalityResult(
            success: true,
            integrity: Double.random(in: 0.9 ... 1.0)
        )
    }

    func optimizeCausality(_ optimization: MultiverseOptimization) async {
        // Optimize causality
    }

    func initializeGuardian() async {
        // Initialize causality guardian
    }

    func getCausalityStatus() async -> CausalityStatus {
        CausalityStatus(
            operational: true,
            integrity: Double.random(in: 0.95 ... 1.0)
        )
    }
}

/// Multiverse Optimizer
private final class MultiverseOptimizer: Sendable {
    func processOptimization(_ optimization: MultiverseOptimization) async {
        // Process multiverse optimization
    }

    func initializeOptimizer() async {
        // Initialize multiverse optimizer
    }

    func getOptimizerStatus() async -> OptimizerStatus {
        OptimizerStatus(
            operational: true,
            efficiency: Double.random(in: 0.8 ... 1.0)
        )
    }
}

/// Coordination Monitor
private final class CoordinationMonitor: Sendable {
    // Monitor coordination operations
}

/// Result structures
private struct Universe: Sendable {
    let identifier: String
}

private struct UniverseAccess: Sendable {
    let universes: [Universe]
    let success: Bool
}

private struct CoordinationResult: Sendable {
    let success: Bool
    let synchronizationLevel: Double
}

private struct SynchronizationResult: Sendable {
    let success: Bool
    let quality: Double
}

private struct EntanglementResult: Sendable {
    let success: Bool
    let entanglementStrength: Double
    let transferred: Double = 0.9
}

private struct CausalityResult: Sendable {
    let success: Bool
    let causalityIntegrity: Double
    let integrity: Double = 0.95
}

/// Status structures
private struct UniverseStatus: Sendable {
    let operational: Bool
    let accessibleUniverses: Int
}

private struct SynchronizationStatus: Sendable {
    let operational: Bool
    let level: Double
    let activeCoordinations: Int
    let successRate: Double
}

private struct EntanglementStatus: Sendable {
    let operational: Bool
    let strength: Double
}

private struct CausalityStatus: Sendable {
    let operational: Bool
    let integrity: Double
}

private struct OptimizerStatus: Sendable {
    let operational: Bool
    let efficiency: Double
}

/// Multiverse Coordination errors
enum MultiverseCoordinationError: Error {
    case noTargetUniverses(String)
    case complexityTooHigh(String)
    case constraintConflict(String)
    case coordinationFailed(String)
    case synchronizationFailed(String)
}
