//
//  MCPSharedTypes.swift
//  QuantumAgentEcosystems
//
//  Created on October 14, 2025
//  Shared types for MCP Universal Intelligence frameworks
//
//  This file contains common types used across all MCP framework files.

import Foundation

/// AnyCodable type for flexible JSON encoding/decoding
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [AnyCodable]:
            try container.encode(arrayValue)
        case let dictValue as [String: AnyCodable]:
            try container.encode(dictValue)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

/// Intelligence priority levels
public enum IntelligencePriority: String, Sendable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    case universal = "universal"
}

/// Intelligence domains
public enum IntelligenceDomain: String, Sendable, Codable, CaseIterable {
    case analytical = "analytical"
    case creative = "creative"
    case ethical = "ethical"
    case strategic = "strategic"
    case emotional = "emotional"
    case spatial = "spatial"
    case temporal = "temporal"
    case quantum = "quantum"
    case consciousness = "consciousness"
    case universal = "universal"
}

/// Consciousness levels
public enum ConsciousnessLevel: String, Sendable, Codable {
    case standard = "standard"
    case enhanced = "enhanced"
    case transcendent = "transcendent"
    case universal = "universal"
    case singularity = "singularity"
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
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Universal insight
public struct UniversalInsight: Codable {
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
public struct UniversalIntelligenceOutput: Codable {
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
public struct DomainResult: Codable {
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
public struct WorkflowSuccessCriterion: Codable {
    public let criterionId: String
    public let criterionType: String
    public let threshold: Double
    public let description: String

    public init(criterionId: String, criterionType: String, threshold: Double, description: String)
    {
        self.criterionId = criterionId
        self.criterionType = criterionType
        self.threshold = threshold
        self.description = description
    }
}

/// Workflow orchestration strategy
public enum WorkflowOrchestrationStrategy: String, Sendable, Codable {
    case sequential = "sequential"
    case parallel = "parallel"
    case adaptive = "adaptive"
    case quantum_entangled = "quantum_entangled"
    case consciousness_driven = "consciousness_driven"
    case universal = "universal"
}
