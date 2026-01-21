//
//  EnhancedUniversalComputationSystem.swift
//  Quantum-workspace
//
//  Advanced infrastructure data models for quantum society components
//

import Foundation
import SwiftData

// MARK: - Enhanced Quantum Governance System

@Model
public final class EnhancedUniversalComputationSystem: Validatable, Trackable, CrossProjectRelatable {
    // Core Properties
    public var id: UUID
    public var name: String
    public var computationDescription: String
    public var creationDate: Date
    public var lastUpdated: Date
    public var version: String
    public var isActive: Bool

    // Operational Properties
    public var operationalStatus: String
    public var quantumCoherence: Double
    public var globalCoverage: Double
    public var energyEfficiency: Double
    public var totalAccessPoints: Int
    public var activeUsers: Int
    public var averageComputationPower: Double
    public var freeAccessUsers: Int

    // System Metrics
    public var totalComputationSessions: Int
    public var averageSessionDuration: Double
    public var peakConcurrentUsers: Int
    public var totalOperationsPerformed: Double
    public var lastSyncDate: Date?
    public var syncInterval: TimeInterval

    // Configuration
    public var maxSessionDuration: TimeInterval
    public var computationLimitPerUser: Double
    public var priorityQueueEnabled: Bool
    public var educationalAccessPriority: Bool
    public var emergencyAccessOverride: Bool

    // Analytics Properties
    public var educationalLabsCount: Int
    public var apiEndpointsCount: Int
    public var cloudResourcesCount: Int
    public var publicTerminalsCount: Int
    public var personalDevicesCount: Int
    public var averageUserSatisfaction: Double

    // Cross-project Properties
    public var globalId: String
    public var projectContext: String
    public var externalReferences: [ExternalReference]

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \EnhancedComputationSession.computationSystem)
    public var computationSessions: [EnhancedComputationSession] = []

    @Relationship(deleteRule: .cascade, inverse: \EnhancedAccessPoint.computationSystem)
    public var accessPoints: [EnhancedAccessPoint] = []

    @Relationship(deleteRule: .cascade)
    public var performanceMetrics: [EnhancedInfrastructureMetric] = []

    // Computed Properties
    public var utilizationRate: Double {
        Double(activeUsers) / Double(max(1, totalAccessPoints))
    }

    public var globalLiteracyRate: Double {
        Double(freeAccessUsers) / Double(max(1, activeUsers))
    }

    public var operationsPerSecond: Double {
        let totalDuration = computationSessions.reduce(0.0) { $0 + $1.duration }
        return totalDuration > 0 ? totalOperationsPerformed / totalDuration : 0
    }

    public var averageComputationPerUser: Double {
        activeUsers > 0 ? averageComputationPower : 0
    }

    // Initialization
    public init(
        name: String,
        computationDescription: String,
        version: String = "1.0.0"
    ) {
        self.id = UUID()
        self.name = name
        self.computationDescription = computationDescription
        self.creationDate = Date()
        self.lastUpdated = Date()
        self.version = version
        self.isActive = true

        self.operationalStatus = "initializing"
        self.quantumCoherence = 0.0
        self.globalCoverage = 0.0
        self.energyEfficiency = 0.0
        self.totalAccessPoints = 0
        self.activeUsers = 0
        self.averageComputationPower = 0.0
        self.freeAccessUsers = 0

        self.totalComputationSessions = 0
        self.averageSessionDuration = 0.0
        self.peakConcurrentUsers = 0
        self.totalOperationsPerformed = 0.0
        self.syncInterval = 60 * 60 // 1 hour

        self.maxSessionDuration = 8 * 60 * 60 // 8 hours
        self.computationLimitPerUser = 1e18 // 10^18 operations
        self.priorityQueueEnabled = true
        self.educationalAccessPriority = true
        self.emergencyAccessOverride = true

        self.educationalLabsCount = 0
        self.apiEndpointsCount = 0
        self.cloudResourcesCount = 0
        self.publicTerminalsCount = 0
        self.personalDevicesCount = 0
        self.averageUserSatisfaction = 0.0

        self.globalId = "computation_\(self.id.uuidString)"
        self.projectContext = ProjectContext.codingReviewer.rawValue
        self.externalReferences = []
    }

    // MARK: - Validatable Implementation

    @MainActor
    public func validate() throws {
        let errors = self.validationErrors
        if !errors.isEmpty {
            throw errors.first!
        }
    }

    public var isValid: Bool {
        self.validationErrors.isEmpty
    }

    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []

        if self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "name"))
        }

        if self.name.count > 100 {
            errors.append(.invalid(field: "name", reason: "must be 100 characters or less"))
        }

        if self.computationDescription.count > 1000 {
            errors.append(
                .invalid(field: "computationDescription", reason: "must be 1000 characters or less")
            )
        }

        if self.quantumCoherence < 0.0 || self.quantumCoherence > 1.0 {
            errors.append(.outOfRange(field: "quantumCoherence", min: 0.0, max: 1.0))
        }

        if self.globalCoverage < 0.0 || self.globalCoverage > 1.0 {
            errors.append(.outOfRange(field: "globalCoverage", min: 0.0, max: 1.0))
        }

        if self.totalAccessPoints < 0 {
            errors.append(.invalid(field: "totalAccessPoints", reason: "must be non-negative"))
        }

        if self.activeUsers < 0 {
            errors.append(.invalid(field: "activeUsers", reason: "must be non-negative"))
        }

        if self.maxSessionDuration <= 0 {
            errors.append(.invalid(field: "maxSessionDuration", reason: "must be positive"))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "computation_\(self.id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "name": self.name,
            "operationalStatus": self.operationalStatus,
            "totalAccessPoints": self.totalAccessPoints,
            "activeUsers": self.activeUsers,
            "utilizationRate": self.utilizationRate,
            "globalCoverage": self.globalCoverage,
            "operationsPerSecond": self.operationsPerSecond,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = self.analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking computation event: \(event) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func addAccessPoint(
        location: String,
        type: AccessPointType,
        capacity: Int = 100
    ) {
        let accessPoint = EnhancedAccessPoint(
            computationSystem: self,
            location: location,
            type: type,
            capacity: capacity
        )

        self.accessPoints.append(accessPoint)
        self.totalAccessPoints += 1

        // Update type counts
        switch type {
        case .educationalLab:
            self.educationalLabsCount += 1
        case .apiEndpoint:
            self.apiEndpointsCount += 1
        case .cloudResource:
            self.cloudResourcesCount += 1
        case .publicTerminal:
            self.publicTerminalsCount += 1
        case .personalDevice:
            self.personalDevicesCount += 1
        }

        self.trackEvent(
            "access_point_added",
            parameters: [
                "location": location,
                "type": type.rawValue,
                "capacity": capacity,
            ]
        )
    }

    @MainActor
    public func recordComputationSession(
        userId: String,
        duration: TimeInterval,
        operationsPerformed: Double,
        accessPointType: AccessPointType,
        userSatisfaction: Double? = nil
    ) {
        let session = EnhancedComputationSession(
            computationSystem: self,
            userId: userId,
            duration: duration,
            operationsPerformed: operationsPerformed,
            accessPointType: accessPointType
        )

        self.computationSessions.append(session)
        self.totalComputationSessions += 1
        self.activeUsers += 1
        self.totalOperationsPerformed += operationsPerformed

        // Update average computation power
        let totalSessions = Double(self.computationSessions.count)
        self.averageComputationPower =
            self.computationSessions.reduce(0.0) { $0 + $1.operationsPerformed } / totalSessions

        // Update average session duration
        self.averageSessionDuration =
            self.computationSessions.reduce(0.0) { $0 + $1.duration } / totalSessions

        // Update peak concurrent users
        self.peakConcurrentUsers = max(self.peakConcurrentUsers, self.activeUsers)

        // Update user satisfaction
        if let satisfaction = userSatisfaction {
            let totalSessionsWithRating = Double(
                self.computationSessions.filter { $0.userSatisfaction != nil }.count)
            if totalSessionsWithRating > 0 {
                self.averageUserSatisfaction =
                    (self.averageUserSatisfaction * (totalSessionsWithRating - 1) + satisfaction)
                        / totalSessionsWithRating
            } else {
                self.averageUserSatisfaction = satisfaction
            }
        }

        self.trackEvent(
            "computation_session_completed",
            parameters: [
                "userId": userId,
                "duration": duration,
                "operations": operationsPerformed,
                "accessPointType": accessPointType.rawValue,
            ]
        )
    }

    @MainActor
    public func scaleInfrastructure(targetAccessPoints: Int) {
        let pointsToAdd = targetAccessPoints - self.totalAccessPoints
        guard pointsToAdd > 0 else { return }

        for i in 0 ..< pointsToAdd {
            let location = "Global Access Point \(self.totalAccessPoints + i + 1)"
            let type = AccessPointType.allCases.randomElement() ?? .publicTerminal
            self.addAccessPoint(location: location, type: type)
        }

        self.globalCoverage = min(1.0, Double(self.totalAccessPoints) / 50000.0) // Target: 50,000 access points

        self.trackEvent(
            "infrastructure_scaled",
            parameters: [
                "pointsAdded": pointsToAdd,
                "totalPoints": self.totalAccessPoints,
                "globalCoverage": self.globalCoverage,
            ]
        )
    }

    @MainActor
    public func optimizePerformance() {
        self.quantumCoherence = min(1.0, self.quantumCoherence + 0.1)
        self.energyEfficiency = min(1.0, self.energyEfficiency + 0.05)
        self.averageComputationPower *= 1.2

        self.trackEvent(
            "performance_optimized",
            parameters: [
                "quantumCoherence": self.quantumCoherence,
                "energyEfficiency": self.energyEfficiency,
                "computationPower": self.averageComputationPower,
            ]
        )
    }

    @MainActor
    public func updateGlobalMetrics() {
        // Update utilization and coverage
        self.globalCoverage = min(1.0, Double(self.activeUsers) / 8_000_000_000.0) // Target: 8 billion users

        // Update performance metrics
        updatePerformanceMetrics()
    }

    private func updatePerformanceMetrics() {
        let metrics = [
            EnhancedInfrastructureMetric(
                componentId: self.id,
                componentType: "computation",
                metricName: "Utilization Rate",
                value: self.utilizationRate,
                unit: "%",
                targetValue: 80.0,
                timestamp: Date()
            ),
            EnhancedInfrastructureMetric(
                componentId: self.id,
                componentType: "computation",
                metricName: "Global Coverage",
                value: self.globalCoverage,
                unit: "%",
                targetValue: 100.0,
                timestamp: Date()
            ),
            EnhancedInfrastructureMetric(
                componentId: self.id,
                componentType: "computation",
                metricName: "Quantum Coherence",
                value: self.quantumCoherence,
                unit: "%",
                targetValue: 99.9,
                timestamp: Date()
            ),
            EnhancedInfrastructureMetric(
                componentId: self.id,
                componentType: "computation",
                metricName: "Operations/Second",
                value: self.operationsPerSecond,
                unit: "ops/s",
                targetValue: nil,
                timestamp: Date()
            ),
        ]

        // Remove old metrics for this component
        self.performanceMetrics.removeAll { $0.componentId == self.id }
        self.performanceMetrics.append(contentsOf: metrics)
    }
}

// MARK: - Enhanced Quantum Education System
