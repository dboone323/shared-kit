//
//  WorkflowIntelligenceAmplificationSystem.swift
//  Quantum-workspace
//
//  Quantum-Inspired Intelligence Amplification System
//  Uses classical simulations of quantum intelligence concepts
//

import Combine
import Foundation

// MARK: - Intelligence Amplification Level

public enum IntelligenceAmplificationLevel: String, Codable, Sendable {
    case basic
    case advanced
    case expert
    case genius
    case transcendent

    var intelligenceMultiplier: Double {
        switch self {
        case .basic: return 1.0
        case .advanced: return 1.5
        case .expert: return 2.0
        case .genius: return 3.0
        case .transcendent: return 5.0
        }
    }
}

// MARK: - Intelligence Context

public struct WorkflowIntelligenceContext: Sendable {
    public let expectedExecutionTime: TimeInterval?
    public let resourceConstraints: [String: Double]
    public let qualityRequirements: [String: Double]
    public let businessPriority: IntelligencePriority
    public let historicalPerformance: [WorkflowPerformanceMetrics]

    public init(
        expectedExecutionTime: TimeInterval? = nil,
        resourceConstraints: [String: Double] = [:],
        qualityRequirements: [String: Double] = [:],
        businessPriority: IntelligencePriority = .normal,
        historicalPerformance: [WorkflowPerformanceMetrics] = []
    ) {
        self.expectedExecutionTime = expectedExecutionTime
        self.resourceConstraints = resourceConstraints
        self.qualityRequirements = qualityRequirements
        self.businessPriority = businessPriority
        self.historicalPerformance = historicalPerformance
    }
}

// MARK: - Quantum-Inspired Intelligence State

public struct QuantumIntelligenceState: Sendable, Codable {
    public var decisionSuperposition: [WeightedDecision]
    public var knowledgeEntanglement: [KnowledgeLink]
    public var learningCoherence: Double
    public var adaptationAmplitude: Double

    public init(
        decisionSuperposition: [WeightedDecision] = [],
        knowledgeEntanglement: [KnowledgeLink] = [],
        learningCoherence: Double = 0.8,
        adaptationAmplitude: Double = 0.5
    ) {
        self.decisionSuperposition = decisionSuperposition
        self.knowledgeEntanglement = knowledgeEntanglement
        self.learningCoherence = learningCoherence
        self.adaptationAmplitude = adaptationAmplitude
    }
}

public struct WeightedDecision: Sendable, Codable, Identifiable {
    public let id: UUID
    public let decision: String
    public let probability: Double
    public let expectedOutcome: Double
    public let confidence: Double

    public init(
        id: UUID = UUID(), decision: String, probability: Double, expectedOutcome: Double,
        confidence: Double
    ) {
        self.id = id
        self.decision = decision
        self.probability = probability
        self.expectedOutcome = expectedOutcome
        self.confidence = confidence
    }
}

public struct KnowledgeLink: Sendable, Codable, Identifiable {
    public let id: UUID
    public let sourceKnowledge: String
    public let targetKnowledge: String
    public let entanglementStrength: Double
    public let correlationFactor: Double

    public init(
        id: UUID = UUID(), sourceKnowledge: String, targetKnowledge: String,
        entanglementStrength: Double, correlationFactor: Double
    ) {
        self.id = id
        self.sourceKnowledge = sourceKnowledge
        self.targetKnowledge = targetKnowledge
        self.entanglementStrength = entanglementStrength
        self.correlationFactor = correlationFactor
    }
}

// MARK: - Intelligence Amplification Configuration

public struct IntelligenceAmplificationConfiguration: Sendable, Codable {
    public var maxDecisionBranches: Int
    public var knowledgeExplorationDepth: Int
    public var learningRate: Double
    public var adaptationThreshold: Double
    public var quantumSimulationSteps: Int

    public init(
        maxDecisionBranches: Int = 5,
        knowledgeExplorationDepth: Int = 3,
        learningRate: Double = 0.1,
        adaptationThreshold: Double = 0.7,
        quantumSimulationSteps: Int = 100
    ) {
        self.maxDecisionBranches = maxDecisionBranches
        self.knowledgeExplorationDepth = knowledgeExplorationDepth
        self.learningRate = learningRate
        self.adaptationThreshold = adaptationThreshold
        self.quantumSimulationSteps = quantumSimulationSteps
    }
}

// MARK: - Intelligence Amplification Results

public struct WorkflowIntelligenceAmplificationResult: Sendable {
    public let sessionId: String
    public let workflowId: String
    public let amplificationLevel: IntelligenceAmplificationLevel
    public let intelligenceGain: Double
    public let optimizationScore: Double
    public let predictionAccuracy: Double
    public let quantumEnhancement: Double
    public let decisionQuality: Double
    public let learningProgress: Double
    public let amplifiedWorkflow: MCPWorkflow
    public let intelligenceInsights: [String]
    public let performanceMetrics: WorkflowPerformanceMetrics
    public let executionTime: TimeInterval
    public let startTime: Date
    public let endTime: Date
}

public struct WorkflowIntelligenceMetrics: Sendable, Codable {
    public var totalAmplifications: Int
    public var averageIntelligenceGain: Double
    public var averageOptimizationScore: Double
    public var averageQuantumEnhancement: Double
    public var totalIntelligenceSessions: Int
    public var systemEfficiency: Double
    public var lastUpdate: Date

    public init(
        totalAmplifications: Int = 0,
        averageIntelligenceGain: Double = 0.0,
        averageOptimizationScore: Double = 0.0,
        averageQuantumEnhancement: Double = 0.0,
        totalIntelligenceSessions: Int = 0,
        systemEfficiency: Double = 1.0,
        lastUpdate: Date = Date()
    ) {
        self.totalAmplifications = totalAmplifications
        self.averageIntelligenceGain = averageIntelligenceGain
        self.averageOptimizationScore = averageOptimizationScore
        self.averageQuantumEnhancement = averageQuantumEnhancement
        self.totalIntelligenceSessions = totalIntelligenceSessions
        self.systemEfficiency = systemEfficiency
        self.lastUpdate = lastUpdate
    }
}

// MARK: - Intelligence Amplification Engine Actor

actor IntelligenceAmplificationEngine {
    private var configuration: IntelligenceAmplificationConfiguration
    private var learningHistory: [IntelligenceLearningRecord]
    private var knowledgeBase: [String: KnowledgeEntry]

    init(configuration: IntelligenceAmplificationConfiguration = .init()) {
        self.configuration = configuration
        self.learningHistory = []
        self.knowledgeBase = [:]
    }

    // MARK: - Quantum-Inspired Decision Superposition

    /// Generates multiple decision branches simultaneously (quantum superposition simulation)
    func generateDecisionSuperposition(
        workflow: MCPWorkflow,
        context: WorkflowIntelligenceContext
    ) async -> [WeightedDecision] {
        var decisions: [WeightedDecision] = []
        let branchCount = min(configuration.maxDecisionBranches, workflow.steps.count)

        // Generate decision branches with different optimization strategies
        for i in 0 ..< branchCount {
            let strategy = DecisionStrategy.allCases[i % DecisionStrategy.allCases.count]
            let decision = await generateDecisionForStrategy(
                workflow: workflow,
                strategy: strategy,
                context: context
            )
            decisions.append(decision)
        }

        // Normalize probabilities
        let totalProbability = decisions.reduce(0.0) { $0 + $1.probability }
        return decisions.map { decision in
            WeightedDecision(
                id: decision.id,
                decision: decision.decision,
                probability: decision.probability / max(totalProbability, 1.0),
                expectedOutcome: decision.expectedOutcome,
                confidence: decision.confidence
            )
        }
    }

    private func generateDecisionForStrategy(
        workflow: MCPWorkflow,
        strategy: DecisionStrategy,
        context: WorkflowIntelligenceContext
    ) async -> WeightedDecision {
        let stepCount = Double(workflow.steps.count)
        let parallelSteps = Double(workflow.steps.filter { $0.executionMode == .parallel }.count)

        var probability = 1.0 / Double(configuration.maxDecisionBranches)
        var expectedOutcome = 0.5
        var confidence = 0.7

        switch strategy {
        case .maximizeSpeed:
            // Favor parallelization
            let parallelRatio = parallelSteps / max(stepCount, 1.0)
            expectedOutcome = 0.3 + parallelRatio * 0.5
            confidence = 0.75 + parallelRatio * 0.2
            probability += parallelRatio * 0.2

        case .minimizeResources:
            // Favor resource efficiency
            let resourceScore = calculateResourceEfficiency(workflow: workflow, context: context)
            expectedOutcome = resourceScore
            confidence = 0.7 + resourceScore * 0.2
            probability += resourceScore * 0.15

        case .maximizeReliability:
            // Favor error handling and validation
            let validationSteps = Double(
                workflow.steps.filter {
                    $0.toolId.contains("validation") || $0.toolId.contains("error")
                }.count)
            let reliabilityScore = validationSteps / max(stepCount, 1.0)
            expectedOutcome = 0.6 + reliabilityScore * 0.3
            confidence = 0.8 + reliabilityScore * 0.15
            probability += reliabilityScore * 0.1

        case .balancedApproach:
            // Balanced optimization
            let parallelRatio = parallelSteps / max(stepCount, 1.0)
            let resourceScore = calculateResourceEfficiency(workflow: workflow, context: context)
            expectedOutcome = (0.5 + parallelRatio * 0.3 + resourceScore * 0.2)
            confidence = 0.8
            probability += 0.1

        case .adaptiveOptimization:
            // Learn from historical performance
            let historicalScore = calculateHistoricalPerformanceScore(context: context)
            expectedOutcome = 0.5 + historicalScore * 0.4
            confidence = 0.75 + historicalScore * 0.2
            probability += historicalScore * 0.15
        }

        return WeightedDecision(
            decision: strategy.description,
            probability: min(max(probability, 0.1), 0.9),
            expectedOutcome: min(max(expectedOutcome, 0.0), 1.0),
            confidence: min(max(confidence, 0.5), 0.95)
        )
    }

    // MARK: - Knowledge Entanglement Analysis

    /// Analyzes knowledge correlations and creates entanglement links (quantum entanglement simulation)
    func analyzeKnowledgeEntanglement(
        workflow: MCPWorkflow,
        decisions: [WeightedDecision]
    ) async -> [KnowledgeLink] {
        var links: [KnowledgeLink] = []

        // Build knowledge graph from workflow steps
        let knowledgeNodes = extractKnowledgeNodes(from: workflow)

        // Create entanglement links between related knowledge
        for i in 0 ..< knowledgeNodes.count {
            for j
                in (i + 1) ..< min(i + configuration.knowledgeExplorationDepth, knowledgeNodes.count)
            {
                let source = knowledgeNodes[i]
                let target = knowledgeNodes[j]

                let entanglementStrength = calculateEntanglementStrength(
                    source: source,
                    target: target,
                    workflow: workflow
                )

                let correlationFactor = calculateCorrelationFactor(
                    source: source,
                    target: target,
                    decisions: decisions
                )

                if entanglementStrength > 0.3 {
                    links.append(
                        KnowledgeLink(
                            sourceKnowledge: source,
                            targetKnowledge: target,
                            entanglementStrength: entanglementStrength,
                            correlationFactor: correlationFactor
                        ))
                }
            }
        }

        return links
    }

    private func extractKnowledgeNodes(from workflow: MCPWorkflow) -> [String] {
        var nodes: [String] = []

        for step in workflow.steps {
            nodes.append("step_\(step.toolId)")

            if step.executionMode == .parallel {
                nodes.append("parallel_execution")
            }

            if !step.dependencies.isEmpty {
                nodes.append("has_dependencies")
            }
        }

        return Array(Set(nodes)).sorted()
    }

    private func calculateEntanglementStrength(
        source: String,
        target: String,
        workflow: MCPWorkflow
    ) -> Double {
        // Calculate how strongly two knowledge nodes are entangled based on workflow structure
        var strength = 0.5 // Base strength

        // Check if both relate to parallel execution
        if source.contains("parallel") && target.contains("parallel") {
            strength += 0.3
        }

        // Check if both relate to dependencies
        if source.contains("dependencies") && target.contains("dependencies") {
            strength += 0.2
        }

        // Check step type similarity
        if source.contains("step_") && target.contains("step_") {
            let sourceType = source.replacingOccurrences(of: "step_", with: "")
            let targetType = target.replacingOccurrences(of: "step_", with: "")
            if sourceType == targetType {
                strength += 0.25
            }
        }

        return min(strength, 1.0)
    }

    private func calculateCorrelationFactor(
        source: String,
        target: String,
        decisions: [WeightedDecision]
    ) -> Double {
        // Calculate correlation based on decision outcomes
        var correlations: [Double] = []

        for decision in decisions {
            let sourceRelevance =
                decision.decision.lowercased().contains(source.lowercased()) ? 1.0 : 0.0
            let targetRelevance =
                decision.decision.lowercased().contains(target.lowercased()) ? 1.0 : 0.0

            if sourceRelevance > 0 || targetRelevance > 0 {
                correlations.append((sourceRelevance + targetRelevance) / 2.0 * decision.confidence)
            }
        }

        return correlations.isEmpty ? 0.5 : correlations.reduce(0, +) / Double(correlations.count)
    }

    // MARK: - Adaptive Learning System

    /// Implements adaptive learning with feedback loops (quantum measurement simulation)
    func performAdaptiveLearning(
        workflow: MCPWorkflow,
        context: WorkflowIntelligenceContext,
        decisions: [WeightedDecision],
        entanglements: [KnowledgeLink]
    ) async -> AdaptiveLearningResult {
        let learningCycles = configuration.quantumSimulationSteps
        var currentCoherence = 0.8
        var learningProgress = 0.0
        var insights: [String] = []

        for cycle in 0 ..< learningCycles {
            let cycleProgress = Double(cycle) / Double(learningCycles)

            // Simulate quantum measurement collapse - learning converges
            let coherenceDecay = exp(-Double(cycle) / 50.0)
            currentCoherence *= coherenceDecay

            // Update learning based on decision quality
            let bestDecision = decisions.max(by: { $0.expectedOutcome < $1.expectedOutcome })
            if let best = bestDecision {
                learningProgress +=
                    best.expectedOutcome * configuration.learningRate * (1.0 - cycleProgress)
            }

            // Knowledge entanglement contributes to learning
            let entanglementBonus =
                entanglements.reduce(0.0) { $0 + $1.entanglementStrength }
                    / max(Double(entanglements.count), 1.0)
            learningProgress += entanglementBonus * 0.01

            // Generate insights at key milestones
            if cycle % 25 == 0 {
                insights.append(
                    "Learning cycle \(cycle): Coherence \(String(format: "%.2f", currentCoherence)), Progress \(String(format: "%.2f", learningProgress))"
                )
            }
        }

        let record = IntelligenceLearningRecord(
            workflowId: workflow.id.uuidString,
            learningProgress: min(learningProgress, 1.0),
            finalCoherence: currentCoherence,
            decisionCount: decisions.count,
            entanglementCount: entanglements.count,
            timestamp: Date()
        )
        learningHistory.append(record)

        // Update knowledge base
        for decision in decisions where decision.confidence > configuration.adaptationThreshold {
            updateKnowledgeBase(decision: decision)
        }

        return AdaptiveLearningResult(
            learningProgress: min(learningProgress, 1.0),
            finalCoherence: currentCoherence,
            insights: insights,
            learnedPatterns: learningHistory.count
        )
    }

    private func updateKnowledgeBase(decision: WeightedDecision) {
        let entry = KnowledgeEntry(
            decision: decision.decision,
            confidence: decision.confidence,
            expectedOutcome: decision.expectedOutcome,
            lastUpdated: Date()
        )
        knowledgeBase[decision.decision] = entry
    }

    // MARK: - Helper Methods

    private func calculateResourceEfficiency(
        workflow: MCPWorkflow,
        context: WorkflowIntelligenceContext
    ) -> Double {
        let constraints = context.resourceConstraints
        if constraints.isEmpty {
            return 0.7 // Default efficiency
        }

        let totalConstraints = constraints.values.reduce(0, +)
        let stepCount = Double(workflow.steps.count)

        // Lower resource requirements per step = higher efficiency
        let efficiencyScore = 1.0 - min(totalConstraints / (stepCount * 10.0), 0.5)
        return max(efficiencyScore, 0.3)
    }

    private func calculateHistoricalPerformanceScore(context: WorkflowIntelligenceContext) -> Double {
        let history = context.historicalPerformance
        if history.isEmpty {
            return 0.5 // Default score with no history
        }

        let avgSuccessRate =
            history.reduce(into: 0.0) {
                $0 += Double($1.successfulExecutions) / Double(max($1.totalExecutions, 1))
            } / Double(history.count)
        return avgSuccessRate
    }

    func getConfiguration() -> IntelligenceAmplificationConfiguration {
        configuration
    }

    func updateConfiguration(_ newConfig: IntelligenceAmplificationConfiguration) {
        configuration = newConfig
    }

    func getLearningHistory() -> [IntelligenceLearningRecord] {
        learningHistory
    }

    func getKnowledgeBase() -> [String: KnowledgeEntry] {
        knowledgeBase
    }
}

// MARK: - Supporting Types

enum DecisionStrategy: CaseIterable, CustomStringConvertible {
    case maximizeSpeed
    case minimizeResources
    case maximizeReliability
    case balancedApproach
    case adaptiveOptimization

    var description: String {
        switch self {
        case .maximizeSpeed: return "Maximize execution speed through parallelization"
        case .minimizeResources: return "Minimize resource consumption"
        case .maximizeReliability: return "Maximize reliability and error handling"
        case .balancedApproach: return "Balanced optimization across metrics"
        case .adaptiveOptimization: return "Adaptive optimization based on learning"
        }
    }
}

struct IntelligenceLearningRecord: Sendable, Codable {
    let workflowId: String
    let learningProgress: Double
    let finalCoherence: Double
    let decisionCount: Int
    let entanglementCount: Int
    let timestamp: Date
}

struct KnowledgeEntry: Sendable, Codable {
    let decision: String
    let confidence: Double
    let expectedOutcome: Double
    let lastUpdated: Date
}

struct AdaptiveLearningResult: Sendable {
    let learningProgress: Double
    let finalCoherence: Double
    let insights: [String]
    let learnedPatterns: Int
}

// MARK: - Main System Class

@MainActor
public final class WorkflowIntelligenceAmplificationSystem: ObservableObject {
    @Published public private(set) var isProcessing = false
    @Published public private(set) var systemMetrics: WorkflowIntelligenceMetrics

    private let engine: IntelligenceAmplificationEngine
    private let statusSubject = PassthroughSubject<String, Never>()

    public var statusPublisher: AnyPublisher<String, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    public init(configuration: IntelligenceAmplificationConfiguration = .init()) {
        self.engine = IntelligenceAmplificationEngine(configuration: configuration)
        self.systemMetrics = WorkflowIntelligenceMetrics()
    }

    // MARK: - Public API

    public func amplifyWorkflowIntelligence(
        _ workflow: MCPWorkflow,
        amplificationLevel: IntelligenceAmplificationLevel = .advanced,
        context: WorkflowIntelligenceContext = WorkflowIntelligenceContext()
    ) async throws -> WorkflowIntelligenceAmplificationResult {
        isProcessing = true
        defer { isProcessing = false }

        let sessionId = UUID().uuidString
        let startTime = Date()

        statusSubject.send(
            "Starting intelligence amplification (Level: \(amplificationLevel.rawValue))")

        // Phase 1: Generate decision superposition
        statusSubject.send("Phase 1: Generating decision superposition...")
        let decisions = await engine.generateDecisionSuperposition(
            workflow: workflow, context: context
        )

        // Phase 2: Analyze knowledge entanglement
        statusSubject.send("Phase 2: Analyzing knowledge entanglement...")
        let entanglements = await engine.analyzeKnowledgeEntanglement(
            workflow: workflow, decisions: decisions
        )

        // Phase 3: Perform adaptive learning
        statusSubject.send("Phase 3: Performing adaptive learning...")
        let learningResult = await engine.performAdaptiveLearning(
            workflow: workflow,
            context: context,
            decisions: decisions,
            entanglements: entanglements
        )

        // Phase 4: Synthesize results
        statusSubject.send("Phase 4: Synthesizing intelligence amplification...")
        let result = synthesizeResults(
            sessionId: sessionId,
            workflow: workflow,
            amplificationLevel: amplificationLevel,
            decisions: decisions,
            entanglements: entanglements,
            learningResult: learningResult,
            startTime: startTime
        )

        // Update metrics
        updateMetrics(with: result)

        statusSubject.send("Intelligence amplification completed successfully")

        return result
    }

    public func amplifyMultipleWorkflows(
        _ workflows: [MCPWorkflow],
        amplificationLevel: IntelligenceAmplificationLevel = .advanced
    ) async throws -> [WorkflowIntelligenceAmplificationResult] {
        var results: [WorkflowIntelligenceAmplificationResult] = []

        for workflow in workflows {
            let result = try await amplifyWorkflowIntelligence(
                workflow, amplificationLevel: amplificationLevel
            )
            results.append(result)
        }

        return results
    }

    public func getIntelligenceMetrics() -> WorkflowIntelligenceMetrics {
        systemMetrics
    }

    public func getConfiguration() async -> IntelligenceAmplificationConfiguration {
        await engine.getConfiguration()
    }

    public func updateConfiguration(_ configuration: IntelligenceAmplificationConfiguration) async {
        await engine.updateConfiguration(configuration)
    }

    // MARK: - Private Methods

    private func synthesizeResults(
        sessionId: String,
        workflow: MCPWorkflow,
        amplificationLevel: IntelligenceAmplificationLevel,
        decisions: [WeightedDecision],
        entanglements: [KnowledgeLink],
        learningResult: AdaptiveLearningResult,
        startTime: Date
    ) -> WorkflowIntelligenceAmplificationResult {
        // Select best decision
        let bestDecision =
            decisions.max(by: { $0.expectedOutcome < $1.expectedOutcome }) ?? decisions[0]

        // Calculate metrics
        let intelligenceGain = calculateIntelligenceGain(
            decisions: decisions,
            learningProgress: learningResult.learningProgress,
            level: amplificationLevel
        )

        let optimizationScore = calculateOptimizationScore(
            decisions: decisions,
            entanglements: entanglements
        )

        let predictionAccuracy = calculatePredictionAccuracy(
            decisions: decisions,
            learningResult: learningResult
        )

        let quantumEnhancement = calculateQuantumEnhancement(
            entanglements: entanglements,
            coherence: learningResult.finalCoherence
        )

        let decisionQuality = bestDecision.confidence * bestDecision.expectedOutcome

        // Create amplified workflow (in production, would apply optimizations)
        let amplifiedWorkflow = workflow

        // Generate insights
        var insights = learningResult.insights
        insights.append(
            "Best decision: \(bestDecision.decision) (outcome: \(String(format: "%.2f", bestDecision.expectedOutcome)))"
        )
        insights.append("Knowledge entanglements discovered: \(entanglements.count)")
        insights.append("Intelligence gain: \(String(format: "%.1f", intelligenceGain * 100))%")

        let performanceMetrics = WorkflowPerformanceMetrics(
            totalExecutions: 1,
            successfulExecutions: 1,
            averageExecutionTime: Date().timeIntervalSince(startTime),
            errorRate: 0.0, // No errors in this execution
            throughput: 1.0 / Date().timeIntervalSince(startTime) // executions per second
        )

        return WorkflowIntelligenceAmplificationResult(
            sessionId: sessionId,
            workflowId: workflow.id.uuidString,
            amplificationLevel: amplificationLevel,
            intelligenceGain: intelligenceGain,
            optimizationScore: optimizationScore,
            predictionAccuracy: predictionAccuracy,
            quantumEnhancement: quantumEnhancement,
            decisionQuality: decisionQuality,
            learningProgress: learningResult.learningProgress,
            amplifiedWorkflow: amplifiedWorkflow,
            intelligenceInsights: insights,
            performanceMetrics: performanceMetrics,
            executionTime: Date().timeIntervalSince(startTime),
            startTime: startTime,
            endTime: Date()
        )
    }

    private func calculateIntelligenceGain(
        decisions: [WeightedDecision],
        learningProgress: Double,
        level: IntelligenceAmplificationLevel
    ) -> Double {
        let decisionQuality =
            decisions.reduce(0.0) { $0 + $1.expectedOutcome * $1.probability }
                / Double(decisions.count)
        let baseGain = decisionQuality * 0.5 + learningProgress * 0.5
        return baseGain * level.intelligenceMultiplier / 5.0 // Normalize to 0-1 range
    }

    private func calculateOptimizationScore(
        decisions: [WeightedDecision],
        entanglements: [KnowledgeLink]
    ) -> Double {
        let decisionScore =
            decisions.reduce(0.0) { $0 + $1.confidence } / Double(max(decisions.count, 1))
        let entanglementScore =
            entanglements.reduce(0.0) { $0 + $1.entanglementStrength }
                / Double(max(entanglements.count, 1))
        return decisionScore * 0.7 + entanglementScore * 0.3
    }

    private func calculatePredictionAccuracy(
        decisions: [WeightedDecision],
        learningResult: AdaptiveLearningResult
    ) -> Double {
        let avgConfidence =
            decisions.reduce(0.0) { $0 + $1.confidence } / Double(max(decisions.count, 1))
        return avgConfidence * 0.6 + learningResult.learningProgress * 0.4
    }

    private func calculateQuantumEnhancement(
        entanglements: [KnowledgeLink],
        coherence: Double
    ) -> Double {
        let entanglementLevel =
            entanglements.reduce(0.0) { $0 + $1.entanglementStrength }
                / Double(max(entanglements.count, 1))
        return entanglementLevel * 0.5 + coherence * 0.5
    }

    private func updateMetrics(with result: WorkflowIntelligenceAmplificationResult) {
        systemMetrics.totalAmplifications += 1
        systemMetrics.totalIntelligenceSessions += 1

        // Running average
        let n = Double(systemMetrics.totalAmplifications)
        systemMetrics.averageIntelligenceGain =
            (systemMetrics.averageIntelligenceGain * (n - 1) + result.intelligenceGain) / n
        systemMetrics.averageOptimizationScore =
            (systemMetrics.averageOptimizationScore * (n - 1) + result.optimizationScore) / n
        systemMetrics.averageQuantumEnhancement =
            (systemMetrics.averageQuantumEnhancement * (n - 1) + result.quantumEnhancement) / n

        systemMetrics.systemEfficiency = (result.intelligenceGain + result.optimizationScore) / 2.0
        systemMetrics.lastUpdate = Date()
    }
}
