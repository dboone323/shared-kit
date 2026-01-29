//
//  AdvancedAgentFramework.swift
//  Quantum-workspace
//
//  Created: Phase 9 - Universal Agent Era
//  Purpose: Core autonomous agent frameworks with self-learning capabilities
//

import Combine
import Foundation

// MARK: - Core Agent Protocols

/// Protocol for autonomous agents with self-learning capabilities
public protocol AutonomousAgent: Sendable {
    var id: UUID { get }
    var name: String { get }
    var capabilities: [AgentCapability] { get }
    var intelligenceLevel: IntelligenceLevel { get set }
    var learningRate: Double { get set }
    var state: AgentState { get set }

    func process(_ input: AgentInput) async throws -> AgentOutput
    func learn(from experience: AgentExperience) async
    func adapt(to environment: AgentEnvironment) async
    func communicate(with agent: any AutonomousAgent, message: AgentMessage) async throws -> AgentMessage
    func evolve() async -> Self
}

/// Protocol for agent capabilities
public protocol AgentCapability: Sendable {
    var name: String { get }
    var description: String { get }
    var domain: AgentDomain { get }
    var complexity: CapabilityComplexity { get }

    func execute(with input: [String: Any]) async throws -> [String: Any]
    func train(on data: [AgentTrainingData]) async
    func evaluate(on testData: [AgentTrainingData]) async -> CapabilityMetrics
}

/// Protocol for agent intelligence amplification
public protocol IntelligenceAmplifier: Sendable {
    var amplificationFactor: Double { get }
    var domains: [AgentDomain] { get }

    func amplify(agent: any AutonomousAgent, for task: AgentTask) async -> IntelligenceAmplifiedAgent
    func optimizeAmplification(for agent: any AutonomousAgent) async
}

/// Protocol for agent learning systems
public protocol AgentLearningSystem: Sendable {
    var learningParadigm: LearningParadigm { get }
    var supportedDomains: [AgentDomain] { get }

    func learn(from experiences: [AgentExperience]) async -> LearningResult
    func generalize(from specificExperiences: [AgentExperience]) async -> [AgentPattern]
    func transferKnowledge(to agent: any AutonomousAgent, from domain: AgentDomain, to domain: AgentDomain) async
}

// MARK: - Core Agent Types

/// Agent input structure
public struct AgentInput: Sendable {
    public let id: UUID
    public let type: AgentInputType
    public let data: [String: AnyCodable]
    public let context: AgentContext
    public let timestamp: Date
    public let priority: AgentPriority

    public init(
        id: UUID = UUID(),
        type: AgentInputType,
        data: [String: AnyCodable],
        context: AgentContext,
        timestamp: Date = Date(),
        priority: AgentPriority = .normal
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.context = context
        self.timestamp = timestamp
        self.priority = priority
    }
}

/// Agent output structure
public struct AgentOutput: Sendable {
    public let id: UUID
    public let inputId: UUID
    public let type: AgentOutputType
    public let data: [String: AnyCodable]
    public let confidence: Double
    public let reasoning: [AgentReasoningStep]
    public let timestamp: Date
    public let metadata: [String: AnyCodable]

    public init(
        id: UUID = UUID(),
        inputId: UUID,
        type: AgentOutputType,
        data: [String: AnyCodable],
        confidence: Double,
        reasoning: [AgentReasoningStep] = [],
        timestamp: Date = Date(),
        metadata: [String: AnyCodable] = [:]
    ) {
        self.id = id
        self.inputId = inputId
        self.type = type
        self.data = data
        self.confidence = confidence
        self.reasoning = reasoning
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// Agent experience for learning
public struct AgentExperience: Sendable {
    public let input: AgentInput
    public let output: AgentOutput
    public let outcome: AgentOutcome
    public let reward: Double
    public let context: AgentContext
    public let timestamp: Date

    public init(
        input: AgentInput,
        output: AgentOutput,
        outcome: AgentOutcome,
        reward: Double,
        context: AgentContext,
        timestamp: Date = Date()
    ) {
        self.input = input
        self.output = output
        self.outcome = outcome
        self.reward = reward
        self.context = context
        self.timestamp = timestamp
    }
}

/// Agent state enumeration
public enum AgentState: String, Sendable {
    case initializing
    case learning
    case active
    case adapting
    case evolving
    case paused
    case error
    case terminated
}

/// Agent input types
public enum AgentInputType: String, Sendable {
    case task
    case query
    case observation
    case feedback
    case command
    case data
    case event
}

/// Agent output types
public enum AgentOutputType: String, Sendable {
    case result
    case decision
    case action
    case response
    case insight
    case error
}

/// Agent priority levels
public enum AgentPriority: String, Sendable {
    case low
    case normal
    case high
    case critical
}

/// Agent outcome types
public enum AgentOutcome: String, Sendable {
    case success
    case partialSuccess
    case failure
    case neutral
    case catastrophic
}

/// Intelligence levels
public enum IntelligenceLevel: String, Sendable {
    case basic
    case intermediate
    case advanced
    case expert
    case master
    case genius
    case superintelligent
    case universal
}

/// Agent domains
public enum AgentDomain: String, Sendable {
    case general
    case scientific
    case engineering
    case medical
    case financial
    case creative
    case social
    case strategic
    case analytical
    case operational
    case ethical
    case philosophical
}

/// Capability complexity levels
public enum CapabilityComplexity: String, Sendable {
    case simple
    case moderate
    case complex
    case advanced
    case expert
    case master
}

/// Learning paradigms
public enum LearningParadigm: String, Sendable {
    case supervised
    case unsupervised
    case reinforcement
    case transfer
    case meta
    case evolutionary
    case quantum
}

/// Agent context
public struct AgentContext: Sendable {
    public let environment: AgentEnvironment
    public let history: [AgentExperience]
    public let goals: [AgentGoal]
    public let constraints: [AgentConstraint]
    public let relationships: [AgentRelationship]

    public init(
        environment: AgentEnvironment,
        history: [AgentExperience] = [],
        goals: [AgentGoal] = [],
        constraints: [AgentConstraint] = [],
        relationships: [AgentRelationship] = []
    ) {
        self.environment = environment
        self.history = history
        self.goals = goals
        self.constraints = constraints
        self.relationships = relationships
    }
}

/// Agent environment
public struct AgentEnvironment: Sendable {
    public let id: UUID
    public let type: EnvironmentType
    public let parameters: [String: AnyCodable]
    public let resources: [AgentResource]
    public let constraints: [EnvironmentConstraint]

    public init(
        id: UUID = UUID(),
        type: EnvironmentType,
        parameters: [String: AnyCodable] = [:],
        resources: [AgentResource] = [],
        constraints: [EnvironmentConstraint] = []
    ) {
        self.id = id
        self.type = type
        self.parameters = parameters
        self.resources = resources
        self.constraints = constraints
    }
}

/// Environment types
public enum EnvironmentType: String, Sendable {
    case local
    case distributed
    case cloud
    case quantum
    case multiverse
    case simulated
}

/// Agent goal
public struct AgentGoal: Sendable {
    public let id: UUID
    public let description: String
    public let priority: AgentPriority
    public let deadline: Date?
    public let successCriteria: [String]

    public init(
        id: UUID = UUID(),
        description: String,
        priority: AgentPriority = .normal,
        deadline: Date? = nil,
        successCriteria: [String] = []
    ) {
        self.id = id
        self.description = description
        self.priority = priority
        self.deadline = deadline
        self.successCriteria = successCriteria
    }
}

/// Agent constraint
public struct AgentConstraint: Sendable {
    public let id: UUID
    public let type: ConstraintType
    public let description: String
    public let severity: ConstraintSeverity

    public init(
        id: UUID = UUID(),
        type: ConstraintType,
        description: String,
        severity: ConstraintSeverity = .medium
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.severity = severity
    }
}

/// Constraint types
public enum ConstraintType: String, Sendable {
    case resource
    case time
    case ethical
    case legal
    case technical
    case environmental
}

/// Constraint severity
public enum ConstraintSeverity: String, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Agent relationship
public struct AgentRelationship: Sendable {
    public let targetAgentId: UUID
    public let type: RelationshipType
    public let strength: Double
    public let trustLevel: Double

    public init(
        targetAgentId: UUID,
        type: RelationshipType,
        strength: Double = 0.5,
        trustLevel: Double = 0.5
    ) {
        self.targetAgentId = targetAgentId
        self.type = type
        self.strength = strength
        self.trustLevel = trustLevel
    }
}

/// Relationship types
public enum RelationshipType: String, Sendable {
    case collaborator
    case competitor
    case mentor
    case student
    case supervisor
    case subordinate
    case peer
}

/// Agent resource
public struct AgentResource: Sendable {
    public let id: UUID
    public let type: ResourceType
    public let name: String
    public let capacity: Double
    public let availability: Double

    public init(
        id: UUID = UUID(),
        type: ResourceType,
        name: String,
        capacity: Double,
        availability: Double = 1.0
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.capacity = capacity
        self.availability = availability
    }
}

/// Resource types
public enum ResourceType: String, Sendable {
    case computational
    case memory
    case storage
    case network
    case energy
    case knowledge
    case time
}

/// Environment constraint
public struct EnvironmentConstraint: Sendable {
    public let id: UUID
    public let type: ConstraintType
    public let description: String
    public let limit: Double

    public init(
        id: UUID = UUID(),
        type: ConstraintType,
        description: String,
        limit: Double
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.limit = limit
    }
}

/// Agent task
public struct AgentTask: Sendable {
    public let id: UUID
    public let description: String
    public let domain: AgentDomain
    public let complexity: TaskComplexity
    public let requirements: [AgentCapability]
    public let deadline: Date?
    public let priority: AgentPriority

    public init(
        id: UUID = UUID(),
        description: String,
        domain: AgentDomain,
        complexity: TaskComplexity,
        requirements: [AgentCapability],
        deadline: Date? = nil,
        priority: AgentPriority = .normal
    ) {
        self.id = id
        self.description = description
        self.domain = domain
        self.complexity = complexity
        self.requirements = requirements
        self.deadline = deadline
        self.priority = priority
    }
}

/// Task complexity
public enum TaskComplexity: String, Sendable {
    case trivial
    case simple
    case moderate
    case complex
    case challenging
    case expert
    case genius
    case impossible
}

/// Agent message for communication
public struct AgentMessage: Sendable {
    public let id: UUID
    public let senderId: UUID
    public let receiverId: UUID
    public let type: MessageType
    public let content: [String: AnyCodable]
    public let timestamp: Date
    public let priority: AgentPriority

    public init(
        id: UUID = UUID(),
        senderId: UUID,
        receiverId: UUID,
        type: MessageType,
        content: [String: AnyCodable],
        timestamp: Date = Date(),
        priority: AgentPriority = .normal
    ) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.priority = priority
    }
}

/// Message types
public enum MessageType: String, Sendable {
    case request
    case response
    case notification
    case command
    case query
    case update
    case error
}

/// Agent reasoning step
public struct AgentReasoningStep: Sendable {
    public let step: Int
    public let description: String
    public let confidence: Double
    public let evidence: [String]
    public let timestamp: Date

    public init(
        step: Int,
        description: String,
        confidence: Double,
        evidence: [String] = [],
        timestamp: Date = Date()
    ) {
        self.step = step
        self.description = description
        self.confidence = confidence
        self.evidence = evidence
        self.timestamp = timestamp
    }
}

/// Agent training data
public struct AgentTrainingData: Sendable {
    public let input: [String: AnyCodable]
    public let expectedOutput: [String: AnyCodable]
    public let context: AgentContext
    public let difficulty: TrainingDifficulty

    public init(
        input: [String: AnyCodable],
        expectedOutput: [String: AnyCodable],
        context: AgentContext = AgentContext(environment: AgentEnvironment(type: .local)),
        difficulty: TrainingDifficulty = .medium
    ) {
        self.input = input
        self.expectedOutput = expectedOutput
        self.context = context
        self.difficulty = difficulty
    }
}

/// Training difficulty
public enum TrainingDifficulty: String, Sendable {
    case easy
    case medium
    case hard
    case expert
}

/// Capability metrics
public struct CapabilityMetrics: Sendable {
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    public let trainingTime: TimeInterval
    public let inferenceTime: TimeInterval

    public init(
        accuracy: Double,
        precision: Double,
        recall: Double,
        f1Score: Double,
        trainingTime: TimeInterval,
        inferenceTime: TimeInterval
    ) {
        self.accuracy = accuracy
        self.precision = precision
        self.recall = recall
        self.f1Score = f1Score
        self.trainingTime = trainingTime
        self.inferenceTime = inferenceTime
    }
}

/// Learning result
public struct LearningResult: Sendable {
    public let patternsLearned: Int
    public let accuracyImprovement: Double
    public let generalizationScore: Double
    public let trainingTime: TimeInterval
    public let insights: [String]

    public init(
        patternsLearned: Int,
        accuracyImprovement: Double,
        generalizationScore: Double,
        trainingTime: TimeInterval,
        insights: [String] = []
    ) {
        self.patternsLearned = patternsLearned
        self.accuracyImprovement = accuracyImprovement
        self.generalizationScore = generalizationScore
        self.trainingTime = trainingTime
        self.insights = insights
    }
}

/// Agent pattern for generalization
public struct AgentPattern: Sendable {
    public let id: UUID
    public let type: PatternType
    public let description: String
    public let confidence: Double
    public let applicability: [AgentDomain]
    public let examples: [AgentExperience]

    public init(
        id: UUID = UUID(),
        type: PatternType,
        description: String,
        confidence: Double,
        applicability: [AgentDomain],
        examples: [AgentExperience] = []
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.confidence = confidence
        self.applicability = applicability
        self.examples = examples
    }
}

/// Pattern types
public enum PatternType: String, Sendable {
    case behavioral
    case decision
    case problemSolving
    case communication
    case learning
    case adaptation
}

/// Intelligence amplified agent
public struct IntelligenceAmplifiedAgent: Sendable {
    public let baseAgent: UUID
    public let amplifiedCapabilities: [AgentCapability]
    public let amplificationFactor: Double
    public let domain: AgentDomain
    public let duration: TimeInterval?

    public init(
        baseAgent: UUID,
        amplifiedCapabilities: [AgentCapability],
        amplificationFactor: Double,
        domain: AgentDomain,
        duration: TimeInterval? = nil
    ) {
        self.baseAgent = baseAgent
        self.amplifiedCapabilities = amplifiedCapabilities
        self.amplificationFactor = amplificationFactor
        self.domain = domain
        self.duration = duration
    }
}

// MARK: - Extensions

public extension AgentInput {
    var isExpired: Bool {
        let age = Date().timeIntervalSince(timestamp)
        return age > 300 // 5 minutes
    }

    var urgency: Double {
        let age = Date().timeIntervalSince(timestamp)
        let priorityMultiplier = switch priority {
        case .low: 0.5
        case .normal: 1.0
        case .high: 2.0
        case .critical: 4.0
        }
        return age * priorityMultiplier
    }
}

public extension AgentOutput {
    var isConfident: Bool { confidence > 0.8 }
    var hasReasoning: Bool { !reasoning.isEmpty }
}

public extension AgentExperience {
    var isPositive: Bool { reward > 0 }
    var magnitude: Double { abs(reward) }
}

public extension IntelligenceLevel {
    var numericValue: Double {
        switch self {
        case .basic: 1.0
        case .intermediate: 2.0
        case .advanced: 3.0
        case .expert: 4.0
        case .master: 5.0
        case .genius: 6.0
        case .superintelligent: 7.0
        case .universal: 8.0
        }
    }

    static func fromNumericValue(_ value: Double) -> IntelligenceLevel {
        switch value {
        case ..<1.5: .basic
        case 1.5 ..< 2.5: .intermediate
        case 2.5 ..< 3.5: .advanced
        case 3.5 ..< 4.5: .expert
        case 4.5 ..< 5.5: .master
        case 5.5 ..< 6.5: .genius
        case 6.5 ..< 7.5: .superintelligent
        default: .universal
        }
    }
}

public extension AgentDomain {
    var requiresSpecialization: Bool {
        switch self {
        case .general: false
        default: true
        }
    }

    var typicalComplexity: CapabilityComplexity {
        switch self {
        case .general: .simple
        case .scientific, .engineering: .complex
        case .medical, .financial: .advanced
        case .creative, .social: .moderate
        case .strategic, .analytical: .expert
        case .operational: .moderate
        case .ethical, .philosophical: .master
        }
    }
}

public extension TaskComplexity {
    var estimatedDuration: TimeInterval {
        switch self {
        case .trivial: 60 // 1 minute
        case .simple: 300 // 5 minutes
        case .moderate: 1800 // 30 minutes
        case .complex: 7200 // 2 hours
        case .challenging: 21600 // 6 hours
        case .expert: 86400 // 1 day
        case .genius: 604_800 // 1 week
        case .impossible: .infinity
        }
    }
}
