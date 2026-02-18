//
//  EnhancedComputationSupport.swift
//  SharedKitCore
//

import Foundation
import SwiftData

public enum AccessPointType: String, CaseIterable, Codable {
    case publicTerminal
    case personalDevice
    case educationalLab
    case apiEndpoint
    case cloudResource
}

@Model
public final class EnhancedComputationSession {
    public var id: UUID
    public var userId: String
    public var duration: TimeInterval
    public var operationsPerformed: Double
    public var accessPointType: AccessPointType
    public var timestamp: Date
    public var userSatisfaction: Double?

    public var computationSystem: EnhancedUniversalComputationSystem?

    public init(
        computationSystem: EnhancedUniversalComputationSystem,
        userId: String,
        duration: TimeInterval,
        operationsPerformed: Double,
        accessPointType: AccessPointType
    ) {
        self.id = UUID()
        self.computationSystem = computationSystem
        self.userId = userId
        self.duration = duration
        self.operationsPerformed = operationsPerformed
        self.accessPointType = accessPointType
        self.timestamp = Date()
    }
}

@Model
public final class EnhancedAccessPoint {
    public var id: UUID
    public var location: String
    public var type: AccessPointType
    public var capacity: Int
    public var currentLoad: Int
    public var status: String

    public var computationSystem: EnhancedUniversalComputationSystem?

    public init(
        computationSystem: EnhancedUniversalComputationSystem,
        location: String,
        type: AccessPointType,
        capacity: Int = 100
    ) {
        self.id = UUID()
        self.computationSystem = computationSystem
        self.location = location
        self.type = type
        self.capacity = capacity
        self.currentLoad = 0
        self.status = "online"
    }
}

@Model
public final class EnhancedInfrastructureMetric {
    public var id: UUID
    public var componentId: UUID
    public var componentType: String
    public var metricName: String
    public var value: Double
    public var unit: String
    public var targetValue: Double?
    public var timestamp: Date

    public var computationSystem: EnhancedUniversalComputationSystem?

    public init(
        componentId: UUID,
        componentType: String,
        metricName: String,
        value: Double,
        unit: String,
        targetValue: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.componentId = componentId
        self.componentType = componentType
        self.metricName = metricName
        self.value = value
        self.unit = unit
        self.targetValue = targetValue
        self.timestamp = timestamp
    }
}
