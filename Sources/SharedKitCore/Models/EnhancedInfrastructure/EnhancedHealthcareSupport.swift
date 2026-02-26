#if canImport(SwiftData) || canImport(CloudKit) || canImport(OSLog) || canImport(SwiftUI)
//
//  EnhancedHealthcareSupport.swift
//  Quantum-workspace
//
//  Advanced infrastructure data models for quantum society components
//

import Foundation
import SwiftData

// MARK: - Enhanced Quantum Governance System

@Model
public final class EnhancedMedicalFacility {
    public var id: UUID
    public var name: String
    public var type: FacilityType
    public var location: String
    public var capacity: Int
    public var specializations: [String]
    public var establishmentDate: Date
    public var patientsServed: Int
    public var averageWaitTime: TimeInterval
    public var equipmentUtilization: Double
    public var maintenanceSchedule: Date?

    public var healthcareSystem: EnhancedQuantumHealthcareSystem?

    public init(
        healthcareSystem: EnhancedQuantumHealthcareSystem,
        name: String,
        type: FacilityType,
        location: String,
        capacity: Int,
        specializations: [String]
    ) {
        self.id = UUID()
        self.healthcareSystem = healthcareSystem
        self.name = name
        self.type = type
        self.location = location
        self.capacity = capacity
        self.specializations = specializations
        self.establishmentDate = Date()
        self.patientsServed = 0
        self.averageWaitTime = 0.0
        self.equipmentUtilization = 0.0
    }
}

@Model
public final class EnhancedTreatment {
    public var id: UUID
    public var providerId: String
    public var treatmentType: String
    public var success: Bool
    public var duration: TimeInterval
    public var cost: Double
    public var timestamp: Date
    public var sideEffects: [String]
    public var followUpRequired: Bool
    public var notes: String?

    public var patientRecord: EnhancedPatientRecord?

    public init(
        patientRecord: EnhancedPatientRecord,
        providerId: String,
        treatmentType: String,
        success: Bool,
        duration: TimeInterval,
        cost: Double
    ) {
        self.id = UUID()
        self.patientRecord = patientRecord
        self.providerId = providerId
        self.treatmentType = treatmentType
        self.success = success
        self.duration = duration
        self.cost = cost
        self.timestamp = Date()
        self.sideEffects = []
        self.followUpRequired = false
    }
}

@Model
public final class EnhancedHealthcareMetric {
    public var id: UUID
    public var metricName: String
    public var value: Double
    public var unit: String
    public var targetValue: Double?
    public var category: String
    public var timestamp: Date
    public var isWithinRange: Bool

    public var healthcareSystem: EnhancedQuantumHealthcareSystem?

    public init(
        healthcareSystem: EnhancedQuantumHealthcareSystem,
        metricName: String,
        value: Double,
        unit: String,
        targetValue: Double?,
        category: String
    ) {
        self.id = UUID()
        self.healthcareSystem = healthcareSystem
        self.metricName = metricName
        self.value = value
        self.unit = unit
        self.targetValue = targetValue
        self.category = category
        self.timestamp = Date()
        self.isWithinRange = targetValue.map { abs(value - $0) / $0 <= 0.1 } ?? true
    }
}

public enum FacilityType: String, CaseIterable, Codable {
    case hospital
    case clinic
    case telemedicine
    case research
    case emergency
}

public enum Gender: String, CaseIterable, Codable {
    case male
    case female
    case nonBinary
    case other
}

@Model
public final class EnhancedPatientRecord {
    public var id: UUID
    public var patientId: String
    public var age: Int
    public var gender: Gender
    public var location: String
    public var medicalHistory: [String]
    public var healthIndex: Double
    public var lastVisit: Date
    public var registrationDate: Date

    @Relationship(deleteRule: .cascade, inverse: \EnhancedTreatment.patientRecord)
    public var treatments: [EnhancedTreatment] = []

    public var healthcareSystem: EnhancedQuantumHealthcareSystem?

    public init(
        healthcareSystem: EnhancedQuantumHealthcareSystem,
        patientId: String,
        age: Int,
        gender: Gender,
        location: String,
        medicalHistory: [String] = []
    ) {
        self.id = UUID()
        self.healthcareSystem = healthcareSystem
        self.patientId = patientId
        self.age = age
        self.gender = gender
        self.location = location
        self.medicalHistory = medicalHistory
        self.healthIndex = 1.0
        self.lastVisit = Date()
        self.registrationDate = Date()
    }

    @MainActor
    public func recordTreatment(
        providerId: String,
        treatmentType: String,
        success: Bool,
        duration: TimeInterval,
        cost: Double
    ) {
        let treatment = EnhancedTreatment(
            patientRecord: self,
            providerId: providerId,
            treatmentType: treatmentType,
            success: success,
            duration: duration,
            cost: cost
        )
        self.treatments.append(treatment)
        self.lastVisit = Date()

        // Update health index based on success
        if success {
            self.healthIndex = min(1.0, self.healthIndex + 0.05)
        } else {
            self.healthIndex = max(0.0, self.healthIndex - 0.1)
        }
    }
}

@Model
public final class EnhancedHealthcareProvider {
    public var id: UUID
    public var providerId: String
    public var specializations: [String]
    public var experience: Double
    public var aiProficiency: Double
    public var facilityId: UUID
    public var rating: Double
    public var totalTreatments: Int

    public var healthcareSystem: EnhancedQuantumHealthcareSystem?

    public init(
        healthcareSystem: EnhancedQuantumHealthcareSystem,
        providerId: String,
        specializations: [String],
        experience: Double,
        aiProficiency: Double,
        facilityId: UUID
    ) {
        self.id = UUID()
        self.healthcareSystem = healthcareSystem
        self.providerId = providerId
        self.specializations = specializations
        self.experience = experience
        self.aiProficiency = aiProficiency
        self.facilityId = facilityId
        self.rating = 5.0
        self.totalTreatments = 0
    }
}

// MARK: - Supporting Economic Models

public enum EconomicEntityType: String, CaseIterable, Codable {
    case individual
    case enterprise
    case government
    case nonprofit
}

@Model
public final class EnhancedEconomicEntity {
    public var id: UUID
    public var entityId: String
    public var type: EconomicEntityType
    public var location: String
    public var initialCapital: Double
    public var balance: Double
    public var sector: String
    public var registrationDate: Date
    public var transactionCount: Int
    public var creditScore: Double
    public var riskProfile: String

    public var economicSystem: EnhancedQuantumEconomicSystem?

    public init(
        economicSystem: EnhancedQuantumEconomicSystem,
        entityId: String,
        type: EconomicEntityType,
        location: String,
        initialCapital: Double,
        sector: String
    ) {
        self.id = UUID()
        self.economicSystem = economicSystem
        self.entityId = entityId
        self.type = type
        self.location = location
        self.initialCapital = initialCapital
        self.balance = initialCapital
        self.sector = sector
        self.registrationDate = Date()
        self.transactionCount = 0
        self.creditScore = 700.0  // Default good credit
        self.riskProfile = "Low"
    }
}

@Model
public final class EnhancedEconomicTransaction {
    public var id: UUID
    public var fromEntityId: String
    public var toEntityId: String
    public var amount: Double
    public var transactionType: TransactionType
    public var transactionDescription: String
    public var timestamp: Date
    public var fee: Double
    public var status: String
    public var blockchainHash: String?

    public var economicSystem: EnhancedQuantumEconomicSystem?

    public init(
        economicSystem: EnhancedQuantumEconomicSystem,
        fromEntityId: String,
        toEntityId: String,
        amount: Double,
        transactionType: TransactionType,
        description: String = ""
    ) {
        self.id = UUID()
        self.economicSystem = economicSystem
        self.fromEntityId = fromEntityId
        self.toEntityId = toEntityId
        self.amount = amount
        self.transactionType = transactionType
        self.transactionDescription = description
        self.timestamp = Date()
        self.fee = amount * 0.001  // 0.1% transaction fee
        self.status = "completed"
    }
}

@Model
public final class EnhancedEconomicMetric {
    public var id: UUID
    public var metricName: String
    public var value: Double
    public var unit: String
    public var targetValue: Double?
    public var category: String
    public var timestamp: Date
    public var isWithinRange: Bool

    public var economicSystem: EnhancedQuantumEconomicSystem?

    public init(
        economicSystem: EnhancedQuantumEconomicSystem,
        metricName: String,
        value: Double,
        unit: String,
        targetValue: Double?,
        category: String
    ) {
        self.id = UUID()
        self.economicSystem = economicSystem
        self.metricName = metricName
        self.value = value
        self.unit = unit
        self.targetValue = targetValue
        self.category = category
        self.timestamp = Date()
        self.isWithinRange = targetValue.map { abs(value - $0) / $0 <= 0.1 } ?? true
    }
}

// MARK: - Supporting Environmental Models

public enum EnvironmentalZoneType: String, CaseIterable, Codable {
    case monitoring
    case restoration
    case conservation
    case research
}

public enum EnvironmentalPriority: String, CaseIterable, Codable {
    case low
    case medium
    case high
    case critical
}

@Model
public final class EnhancedEnvironmentalZone {
    public var id: UUID
    public var name: String
    public var type: EnvironmentalZoneType
    public var location: String
    public var area: Double
    public var priority: EnvironmentalPriority
    public var establishmentDate: Date
    public var airQuality: Double
    public var waterQuality: Double
    public var soilHealth: Double
    public var biodiversity: Double
    public var restorationProgress: Double
    public var monitoringFrequency: TimeInterval

    public var environmentalSystem: EnhancedQuantumEnvironmentalSystem?

    public init(
        environmentalSystem: EnhancedQuantumEnvironmentalSystem,
        name: String,
        type: EnvironmentalZoneType,
        location: String,
        area: Double,
        priority: EnvironmentalPriority
    ) {
        self.id = UUID()
        self.environmentalSystem = environmentalSystem
        self.name = name
        self.type = type
        self.location = location
        self.area = area
        self.priority = priority
        self.establishmentDate = Date()
        self.airQuality = 0.5  // Default moderate quality
        self.waterQuality = 0.5
        self.soilHealth = 0.5
        self.biodiversity = 0.5
        self.restorationProgress = 0.0
        self.monitoringFrequency = 3600.0  // 1 hour
    }
}

@Model
public final class EnhancedEnvironmentalMetric {
    public var id: UUID
    public var metricName: String
    public var value: Double
    public var unit: String
    public var targetValue: Double?
    public var category: String
    public var timestamp: Date
    public var isWithinRange: Bool

    public var environmentalSystem: EnhancedQuantumEnvironmentalSystem?

    public init(
        environmentalSystem: EnhancedQuantumEnvironmentalSystem,
        metricName: String,
        value: Double,
        unit: String,
        targetValue: Double?,
        category: String
    ) {
        self.id = UUID()
        self.environmentalSystem = environmentalSystem
        self.metricName = metricName
        self.value = value
        self.unit = unit
        self.targetValue = targetValue
        self.category = category
        self.timestamp = Date()
        self.isWithinRange = targetValue.map { abs(value - $0) / $0 <= 0.1 } ?? true
    }
}
#endif
