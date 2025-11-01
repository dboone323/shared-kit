//
//  EnhancedQuantumEconomicSystem.swift
//  Quantum-workspace
//
//  Advanced infrastructure data models for quantum society components
//

import Foundation
import SwiftData

// MARK: - Enhanced Quantum Governance System

@Model
public final class EnhancedQuantumEconomicSystem: Validatable, Trackable, CrossProjectRelatable {
    public var id: UUID
    public var name: String
    public var description: String
    public var creationDate: Date
    public var lastModified: Date
    public var version: String
    public var isActive: Bool

    // Core Economic Metrics
    public var globalGDP: Double
    public var totalParticipants: Int
    public var activeEnterprises: Int
    public var totalTransactions: Int
    public var economicStability: Double
    public var incomeEquality: Double
    public var innovationIndex: Double
    public var sustainabilityIndex: Double

    // Economic Infrastructure
    public var quantumBanks: Int
    public var tradingPlatforms: Int
    public var investmentFunds: Int
    public var economicZones: Int
    public var innovationHubs: Int

    // Financial Performance
    public var averageIncome: Double
    public var unemploymentRate: Double
    public var inflationRate: Double
    public var investmentReturns: Double
    public var debtToGDPRatio: Double

    // Technology Integration
    public var quantumTradingAlgorithms: Double
    public var aiEconomicModeling: Double
    public var blockchainTransparency: Double
    public var predictiveAnalytics: Double
    public var automatedRegulation: Double

    // Social Impact
    public var povertyReduction: Double
    public var wealthDistribution: Double
    public var opportunityAccess: Double
    public var entrepreneurialSuccess: Double
    public var economicMobility: Double

    // Global Trade
    public var tradeVolume: Double
    public var tradePartners: Int
    public var tradeEfficiency: Double
    public var resourceOptimization: Double
    public var supplyChainResilience: Double

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \EnhancedEconomicEntity.economicSystem)
    public var economicEntities: [EnhancedEconomicEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \EnhancedEconomicTransaction.economicSystem)
    public var transactions: [EnhancedEconomicTransaction] = []

    @Relationship(deleteRule: .cascade, inverse: \EnhancedEconomicMetric.economicSystem)
    public var performanceMetrics: [EnhancedEconomicMetric] = []

    // Tracking
    public var eventLog: [TrackedEvent] = []
    public var crossProjectReferences: [CrossProjectReference] = []

    public init(
        name: String = "Enhanced Quantum Economic System",
        description: String = "Universal quantum-enhanced economic infrastructure"
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.creationDate = Date()
        self.lastModified = Date()
        self.version = "1.0.0"
        self.isActive = true

        // Initialize metrics
        self.globalGDP = 0.0
        self.totalParticipants = 0
        self.activeEnterprises = 0
        self.totalTransactions = 0
        self.economicStability = 0.0
        self.incomeEquality = 0.0
        self.innovationIndex = 0.0
        self.sustainabilityIndex = 0.0

        // Initialize infrastructure
        self.quantumBanks = 0
        self.tradingPlatforms = 0
        self.investmentFunds = 0
        self.economicZones = 0
        self.innovationHubs = 0

        // Initialize performance
        self.averageIncome = 0.0
        self.unemploymentRate = 0.0
        self.inflationRate = 0.0
        self.investmentReturns = 0.0
        self.debtToGDPRatio = 0.0

        // Initialize technology
        self.quantumTradingAlgorithms = 0.0
        self.aiEconomicModeling = 0.0
        self.blockchainTransparency = 0.0
        self.predictiveAnalytics = 0.0
        self.automatedRegulation = 0.0

        // Initialize social impact
        self.povertyReduction = 0.0
        self.wealthDistribution = 0.0
        self.opportunityAccess = 0.0
        self.entrepreneurialSuccess = 0.0
        self.economicMobility = 0.0

        // Initialize trade
        self.tradeVolume = 0.0
        self.tradePartners = 0
        self.tradeEfficiency = 0.0
        self.resourceOptimization = 0.0
        self.supplyChainResilience = 0.0

        self.trackEvent("system_initialized", parameters: ["version": self.version])
    }

    // MARK: - Validatable Protocol

    public func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.invalidData("Economic system name cannot be empty")
        }
        guard globalGDP >= 0 else {
            throw ValidationError.invalidData("Global GDP cannot be negative")
        }
        guard totalParticipants >= 0 else {
            throw ValidationError.invalidData("Total participants cannot be negative")
        }
        guard economicStability >= 0.0 && economicStability <= 1.0 else {
            throw ValidationError.invalidData("Economic stability must be between 0.0 and 1.0")
        }
    }

    // MARK: - Trackable Protocol

    public func trackEvent(_ event: String, parameters: [String: Any] = [:]) {
        let trackedEvent = TrackedEvent(
            componentId: self.id,
            eventType: event,
            parameters: parameters,
            timestamp: Date()
        )
        self.eventLog.append(trackedEvent)
        self.lastModified = Date()
    }

    // MARK: - CrossProjectRelatable Protocol

    public func addCrossProjectReference(projectId: UUID, referenceType: String, referenceId: UUID) {
        let reference = CrossProjectReference(
            sourceProjectId: self.id,
            targetProjectId: projectId,
            referenceType: referenceType,
            referenceId: referenceId,
            timestamp: Date()
        )
        self.crossProjectReferences.append(reference)
    }

    public func getRelatedProjects() -> [UUID] {
        self.crossProjectReferences.map(\.targetProjectId)
    }

    // MARK: - Economic System Methods

    @MainActor
    public func registerEconomicEntity(
        entityId: String,
        type: EconomicEntityType,
        location: String,
        initialCapital: Double,
        sector: String
    ) {
        let entity = EnhancedEconomicEntity(
            economicSystem: self,
            entityId: entityId,
            type: type,
            location: location,
            initialCapital: initialCapital,
            sector: sector
        )

        self.economicEntities.append(entity)

        switch type {
        case .individual:
            self.totalParticipants += 1
        case .enterprise:
            self.activeEnterprises += 1
        case .government:
            break // Governments are not counted in participants
        case .nonprofit:
            self.activeEnterprises += 1
        }

        // Update global GDP based on entity contributions
        self.globalGDP += initialCapital

        self.trackEvent(
            "entity_registered",
            parameters: [
                "entityId": entityId,
                "type": type.rawValue,
                "initialCapital": initialCapital,
            ]
        )
    }

    @MainActor
    public func recordTransaction(
        fromEntityId: String,
        toEntityId: String,
        amount: Double,
        transactionType: TransactionType,
        description: String = ""
    ) {
        let transaction = EnhancedEconomicTransaction(
            economicSystem: self,
            fromEntityId: fromEntityId,
            toEntityId: toEntityId,
            amount: amount,
            transactionType: transactionType,
            description: description
        )

        self.transactions.append(transaction)
        self.totalTransactions += 1
        self.tradeVolume += amount

        // Update entity balances
        if let fromEntity = self.economicEntities.first(where: { $0.entityId == fromEntityId }) {
            fromEntity.balance -= amount
        }
        if let toEntity = self.economicEntities.first(where: { $0.entityId == toEntityId }) {
            toEntity.balance += amount
        }

        self.trackEvent(
            "transaction_recorded",
            parameters: [
                "fromEntityId": fromEntityId,
                "toEntityId": toEntityId,
                "amount": amount,
                "type": transactionType.rawValue,
            ]
        )
    }

    @MainActor
    public func establishEconomicInfrastructure(
        banks: Int,
        platforms: Int,
        funds: Int,
        zones: Int,
        hubs: Int
    ) {
        self.quantumBanks += banks
        self.tradingPlatforms += platforms
        self.investmentFunds += funds
        self.economicZones += zones
        self.innovationHubs += hubs

        self.trackEvent(
            "infrastructure_established",
            parameters: [
                "banks": banks,
                "platforms": platforms,
                "funds": funds,
                "zones": zones,
                "hubs": hubs,
            ]
        )
    }

    @MainActor
    public func updateEconomicIndicators() {
        // Calculate average income from entity balances
        let totalBalance = self.economicEntities.reduce(0.0) { $0 + $1.balance }
        self.averageIncome = totalBalance / Double(max(1, self.economicEntities.count))

        // Calculate unemployment rate (simplified - based on inactive entities)
        let inactiveEntities = self.economicEntities.filter { $0.balance <= 0 }.count
        self.unemploymentRate =
            Double(inactiveEntities) / Double(max(1, self.economicEntities.count))

        // Calculate inflation rate (simplified - based on transaction volume growth)
        // This would need historical data in a real implementation
        self.inflationRate = 0.02 // Placeholder: 2% inflation

        // Calculate investment returns (simplified)
        let investmentTransactions = self.transactions.filter { $0.transactionType == .investment }
        if !investmentTransactions.isEmpty {
            let totalInvested = investmentTransactions.reduce(0.0) { $0 + $1.amount }
            let returns = totalInvested * 1.15 // Assume 15% return
            self.investmentReturns = (returns - totalInvested) / totalInvested
        }

        // Calculate debt to GDP ratio (simplified)
        let totalDebt = self.economicEntities.reduce(0.0) { $0 + max(0, -$1.balance) }
        self.debtToGDPRatio = totalDebt / max(1.0, self.globalGDP)

        self.trackEvent(
            "economic_indicators_updated",
            parameters: [
                "averageIncome": self.averageIncome,
                "unemploymentRate": self.unemploymentRate,
                "inflationRate": self.inflationRate,
                "investmentReturns": self.investmentReturns,
            ]
        )
    }

    @MainActor
    public func advanceEconomicTechnology() {
        // Improve quantum trading algorithms
        self.quantumTradingAlgorithms = min(1.0, self.quantumTradingAlgorithms + 0.1)

        // Enhance AI economic modeling
        self.aiEconomicModeling = min(1.0, self.aiEconomicModeling + 0.08)

        // Increase blockchain transparency
        self.blockchainTransparency = min(1.0, self.blockchainTransparency + 0.12)

        // Improve predictive analytics
        self.predictiveAnalytics = min(1.0, self.predictiveAnalytics + 0.09)

        // Enhance automated regulation
        self.automatedRegulation = min(1.0, self.automatedRegulation + 0.07)

        self.trackEvent(
            "economic_technology_advanced",
            parameters: [
                "quantumTrading": self.quantumTradingAlgorithms,
                "aiModeling": self.aiEconomicModeling,
                "blockchainTransparency": self.blockchainTransparency,
            ]
        )
    }

    @MainActor
    public func optimizeEconomicStability() {
        // Calculate economic stability based on various factors
        let stabilityFactors = [
            1.0 - self.unemploymentRate, // Lower unemployment = higher stability
            1.0 - abs(self.inflationRate - 0.02), // Closer to 2% target inflation = higher stability
            self.innovationIndex,
            self.sustainabilityIndex,
            self.tradeEfficiency,
        ]

        self.economicStability = stabilityFactors.reduce(0.0, +) / Double(stabilityFactors.count)

        // Calculate income equality (Gini coefficient approximation)
        let balances = self.economicEntities.map(\.balance).sorted()
        if !balances.isEmpty {
            let n = Double(balances.count)
            let mean = balances.reduce(0.0, +) / n
            let sumSquaredDifferences = balances.reduce(0.0) { $0 + pow($1 - mean, 2) }
            let variance = sumSquaredDifferences / n
            let standardDeviation = sqrt(variance)
            // Simplified Gini approximation
            self.incomeEquality = 1.0 - (1.0 / (1.0 + standardDeviation / max(mean, 1.0)))
        }

        self.trackEvent(
            "economic_stability_optimized",
            parameters: [
                "stability": self.economicStability,
                "incomeEquality": self.incomeEquality,
            ]
        )
    }

    @MainActor
    public func updateSocialEconomicMetrics() {
        // Poverty reduction based on entities above poverty line
        let povertyLine = 1000.0 // Arbitrary poverty line
        let abovePovertyLine = self.economicEntities.filter { $0.balance >= povertyLine }.count
        self.povertyReduction =
            Double(abovePovertyLine) / Double(max(1, self.economicEntities.count))

        // Wealth distribution (complement of income equality)
        self.wealthDistribution = 1.0 - self.incomeEquality

        // Opportunity access based on innovation hubs and economic zones
        self.opportunityAccess = Double(self.innovationHubs + self.economicZones) / 100.0

        // Entrepreneurial success based on enterprise performance
        let enterprises = self.economicEntities.filter { $0.type == .enterprise }
        if !enterprises.isEmpty {
            let successfulEnterprises = enterprises.filter { $0.balance > $0.initialCapital }.count
            self.entrepreneurialSuccess = Double(successfulEnterprises) / Double(enterprises.count)
        }

        // Economic mobility (simplified - based on transaction activity)
        let activeEntities = self.economicEntities.filter { $0.transactionCount > 0 }.count
        self.economicMobility = Double(activeEntities) / Double(max(1, self.economicEntities.count))

        self.trackEvent(
            "social_economic_metrics_updated",
            parameters: [
                "povertyReduction": self.povertyReduction,
                "wealthDistribution": self.wealthDistribution,
                "opportunityAccess": self.opportunityAccess,
            ]
        )
    }

    @MainActor
    public func enhanceGlobalTrade(targetPartners: Int, targetVolume: Double) {
        self.tradePartners = max(self.tradePartners, targetPartners)
        self.tradeVolume = max(self.tradeVolume, targetVolume)

        // Improve trade route efficiency with quantum optimization
        self.tradeRouteEfficiency = min(1.0, self.tradeRouteEfficiency + 0.1)

        // Optimize resource allocation
        self.resourceOptimization = min(1.0, self.resourceOptimization + 0.08)

        // Enhance supply chain resilience
        self.supplyChainResilience = min(1.0, self.supplyChainResilience + 0.06)

        self.trackEvent(
            "global_trade_enhanced",
            parameters: [
                "tradePartners": self.tradePartners,
                "tradeVolume": self.tradeVolume,
                "tradeEfficiency": self.tradeEfficiency,
            ]
        )
    }

    private func updatePerformanceMetrics() {
        let metrics = [
            EnhancedEconomicMetric(
                economicSystem: self,
                metricName: "Global GDP",
                value: self.globalGDP,
                unit: "currency",
                targetValue: nil,
                category: "Economic Output"
            ),
            EnhancedEconomicMetric(
                economicSystem: self,
                metricName: "Economic Stability",
                value: self.economicStability,
                unit: "index",
                targetValue: 0.9,
                category: "Stability"
            ),
            EnhancedEconomicMetric(
                economicSystem: self,
                metricName: "Unemployment Rate",
                value: self.unemploymentRate,
                unit: "%",
                targetValue: 5.0,
                category: "Employment"
            ),
            EnhancedEconomicMetric(
                economicSystem: self,
                metricName: "Poverty Reduction",
                value: self.povertyReduction,
                unit: "%",
                targetValue: 100.0,
                category: "Social Impact"
            ),
        ]

        // Remove old metrics
        self.performanceMetrics.removeAll()
        self.performanceMetrics.append(contentsOf: metrics)
    }
}

// MARK: - Enhanced Quantum Environmental System
