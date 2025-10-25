//
//  MCPSharedTypes.swift
//  QuantumAgentEcosystems
//
//  Created on October 14, 2025
//  Shared types for MCP Universal Intelligence frameworks
//
//  This file contains common types used across all MCP framework files.

import Foundation

/// Intelligence priority levels
public enum IntelligencePriority: String, Sendable, Codable {
    case low
    case normal
    case high
    case critical
    case universal
}

/// Intelligence domains
public enum IntelligenceDomain: String, Sendable, Codable, CaseIterable {
    case analytical
    case creative
    case ethical
    case strategic
    case emotional
    case spatial
    case temporal
    case quantum
    case consciousness
    case universal
}

/// Consciousness levels
public enum ConsciousnessLevel: String, Sendable, Codable {
    case standard
    case enhanced
    case transcendent
    case universal
    case singularity
}

/// Quantum state for processing
public struct QuantumState: Sendable, Codable {
    public let superposition: [String: Double]
    public let entanglement: [String: [String]]
    public let coherence: Double
    public let dimension: Int

    public init(
        superposition: [String: Double], entanglement: [String: [String]],
        coherence: Double, dimension: Int
    ) {
        self.superposition = superposition
        self.entanglement = entanglement
        self.coherence = coherence
        self.dimension = dimension
    }
}

/// Constraint priority levels
public enum ConstraintPriority: String, Sendable, Codable {
    case low
    case medium
    case high
    case critical
}

/// Universal insight
public struct UniversalInsight: Codable, Sendable {
    public let insightId: String
    public let insightType: String
    public let content: AnyCodable
    public let confidence: Double
    public let impact: Double

    public init(
        insightId: String, insightType: String, content: AnyCodable,
        confidence: Double, impact: Double
    ) {
        self.insightId = insightId
        self.insightType = insightType
        self.content = content
        self.confidence = confidence
        self.impact = impact
    }
}

/// Universal intelligence input
public struct UniversalIntelligenceInput: Codable {
    public let query: String
    public let context: [String: AnyCodable]
    public let domains: [IntelligenceDomain]
    public let priority: IntelligencePriority
    public let constraints: [UniversalConstraint]
    public let quantumState: QuantumState?

    public init(
        query: String, context: [String: AnyCodable] = [:],
        domains: [IntelligenceDomain] = IntelligenceDomain.allCases,
        priority: IntelligencePriority = .normal,
        constraints: [UniversalConstraint] = [],
        quantumState: QuantumState? = nil
    ) {
        self.query = query
        self.context = context
        self.domains = domains
        self.priority = priority
        self.constraints = constraints
        self.quantumState = quantumState
    }
}

/// Universal intelligence output
public struct UniversalIntelligenceOutput: Codable, Sendable {
    public let result: AnyCodable
    public let universalInsights: [UniversalInsight]
    public let processingMetrics: [String: Double]
    public let confidence: Double

    public init(
        result: AnyCodable, universalInsights: [UniversalInsight] = [],
        processingMetrics: [String: Double] = [:], confidence: Double = 0.0
    ) {
        self.result = result
        self.universalInsights = universalInsights
        self.processingMetrics = processingMetrics
        self.confidence = confidence
    }
}

/// Universal constraint
public struct UniversalConstraint: Codable {
    public let type: UniversalConstraintType
    public let value: String
    public let priority: ConstraintPriority

    public init(
        type: UniversalConstraintType, value: String, priority: ConstraintPriority = .medium
    ) {
        self.type = type
        self.value = value
        self.priority = priority
    }
}

/// Universal constraint type
public enum UniversalConstraintType: String, Sendable, Codable {
    case ethical
    case temporal
    case resource
    case complexity
    case consciousness
    case quantum
    case reality
    case harmony
    case evolution
    case domainComplexity
    case integrationDepth
    case coordinationTime
    case resourceUsage
    case harmonyRequirements
}

/// Domain result
public struct DomainResult: Codable, Sendable {
    public let domain: IntelligenceDomain
    public let success: Bool
    public let result: AnyCodable
    public let confidence: Double
    public let processingTime: TimeInterval
    public let quantumContribution: Double

    public init(
        domain: IntelligenceDomain, success: Bool, result: AnyCodable,
        confidence: Double, processingTime: TimeInterval, quantumContribution: Double
    ) {
        self.domain = domain
        self.success = success
        self.result = result
        self.confidence = confidence
        self.processingTime = processingTime
        self.quantumContribution = quantumContribution
    }
}

/// Workflow success criterion
public struct WorkflowSuccessCriterion: Codable, Sendable {
    public let criterionId: String
    public let criterionType: String
    public let threshold: Double
    public let description: String

    public init(criterionId: String, criterionType: String, threshold: Double, description: String) {
        self.criterionId = criterionId
        self.criterionType = criterionType
        self.threshold = threshold
        self.description = description
    }
}

/// Workflow orchestration strategy
public enum WorkflowOrchestrationStrategy: String, Sendable, Codable {
    case sequential
    case parallel
    case adaptive
    case quantum_entangled
    case consciousness_driven
    case universal
}
