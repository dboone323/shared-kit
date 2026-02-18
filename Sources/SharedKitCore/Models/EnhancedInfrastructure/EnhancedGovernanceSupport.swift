//
//  EnhancedGovernanceSupport.swift
//  SharedKitCore
//

import Foundation
import SwiftData

public enum DecisionPriority: String, CaseIterable, Codable {
    case low
    case medium
    case high
    case critical
    case emergency
}

@Model
public final class EnhancedGovernanceDecision {
    public var id: UUID
    public var title: String
    public var summary: String
    public var priority: DecisionPriority
    public var status: String
    public var consensusLevel: Double
    public var timestamp: Date
    public var decisionTime: TimeInterval
    public var confidence: Double

    public var governanceSystem: EnhancedQuantumGovernanceSystem?

    public init(
        governanceSystem: EnhancedQuantumGovernanceSystem,
        title: String,
        summary: String,
        priority: DecisionPriority,
        confidence: Double = 0.0
    ) {
        self.id = UUID()
        self.governanceSystem = governanceSystem
        self.title = title
        self.summary = summary
        self.priority = priority
        self.status = "proposed"
        self.consensusLevel = 0.0
        self.timestamp = Date()
        self.decisionTime = 0.0
        self.confidence = confidence
    }
}

@Model
public final class EnhancedGovernancePolicy {
    public var id: UUID
    public var name: String
    public var policyDescription: String
    public var effectiveness: Double
    public var optimizationScore: Double
    public var optimizationCount: Int
    public var registrationDate: Date
    public var lastModified: Date
    public var lastOptimized: Date

    public var governanceSystem: EnhancedQuantumGovernanceSystem?

    public init(
        governanceSystem: EnhancedQuantumGovernanceSystem,
        name: String,
        description: String
    ) {
        self.id = UUID()
        self.governanceSystem = governanceSystem
        self.name = name
        self.policyDescription = description
        self.effectiveness = 1.0
        self.optimizationScore = 0.0
        self.optimizationCount = 0
        self.registrationDate = Date()
        self.lastModified = Date()
        self.lastOptimized = Date()
    }
}

@Model
public final class EnhancedConsensusNetwork {
    public var id: UUID
    public var name: String
    public var participantCount: Int
    public var nodeCount: Int
    public var throughput: Double
    public var latency: TimeInterval
    public var securityLevel: Double
    public var regions: [String]

    public var governanceSystem: EnhancedQuantumGovernanceSystem?

    public init(
        governanceSystem: EnhancedQuantumGovernanceSystem,
        name: String,
        participantCount: Int,
        regions: [String] = []
    ) {
        self.id = UUID()
        self.governanceSystem = governanceSystem
        self.name = name
        self.participantCount = participantCount
        self.nodeCount = participantCount / 10
        self.throughput = 0.0
        self.latency = 0.0
        self.securityLevel = 0.95
        self.regions = regions
    }
}
