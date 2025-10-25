//
//  IntelligentResourceManager.swift
//  Quantum-workspace
//
//  Created by GitHub Copilot on 2024
//
//  Implements intelligent resource management with autonomous scaling and optimization
//  for quantum-enhanced development environments.
//

import Combine
import Foundation
import OSLog

/// Resource types that can be managed
public enum ResourceType: String, Codable, Sendable {
    case cpu
    case memory
    case disk
    case network
    case gpu
    case quantumProcessor = "quantum_processor"
    case cloudInstances = "cloud_instances"
    case databaseConnections = "database_connections"
    case apiRateLimits = "api_rate_limits"
}

/// Scaling strategy for resource management
public enum ScalingStrategy: String, Codable {
    case horizontal
    case vertical
    case predictive
    case quantumInspired = "quantum_inspired"
    case costOptimized = "cost_optimized"
    case performanceOptimized = "performance_optimized"
}

/// Resource allocation request
public struct ResourceAllocation: Sendable {
    public let id: UUID
    public let resourceType: ResourceType
    public let requestedAmount: Double
    public let priority: ResourcePriority
    public let requester: String
    public let estimatedDuration: TimeInterval?
    public let metadata: [String: String]

    public init(
        resourceType: ResourceType,
        requestedAmount: Double,
        priority: ResourcePriority,
        requester: String,
        estimatedDuration: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.resourceType = resourceType
        self.requestedAmount = requestedAmount
        self.priority = priority
        self.requester = requester
        self.estimatedDuration = estimatedDuration
        self.metadata = metadata
    }
}

/// Resource priority levels
public enum ResourcePriority: Int, Codable, Sendable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

/// Resource metrics and monitoring data
public struct ResourceMetrics: Codable {
    public let timestamp: Date
    public let resourceType: ResourceType
    public let currentUsage: Double
    public let allocatedCapacity: Double
    public let availableCapacity: Double
    public let utilizationPercentage: Double
    public let costPerUnit: Double?
    public let performanceScore: Double
    public let predictedDemand: Double?

    public init(
        resourceType: ResourceType,
        currentUsage: Double,
        allocatedCapacity: Double,
        availableCapacity: Double,
        costPerUnit: Double? = nil,
        performanceScore: Double = 1.0,
        predictedDemand: Double? = nil
    ) {
        self.timestamp = Date()
        self.resourceType = resourceType
        self.currentUsage = currentUsage
        self.allocatedCapacity = allocatedCapacity
        self.availableCapacity = availableCapacity
        self.utilizationPercentage =
            allocatedCapacity > 0 ? (currentUsage / allocatedCapacity) * 100 : 0
        self.costPerUnit = costPerUnit
        self.performanceScore = performanceScore
        self.predictedDemand = predictedDemand
    }
}

/// Scaling decision and action
public struct ScalingDecision: Codable {
    public let id: UUID
    public let timestamp: Date
    public let resourceType: ResourceType
    public let action: ScalingAction
    public let amount: Double
    public let reason: String
    public let confidence: Double
    public let estimatedCost: Double?
    public let estimatedTime: TimeInterval

    public init(
        resourceType: ResourceType,
        action: ScalingAction,
        amount: Double,
        reason: String,
        confidence: Double,
        estimatedCost: Double? = nil,
        estimatedTime: TimeInterval = 300
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.resourceType = resourceType
        self.action = action
        self.amount = amount
        self.reason = reason
        self.confidence = confidence
        self.estimatedCost = estimatedCost
        self.estimatedTime = estimatedTime
    }
}

/// Scaling actions
public enum ScalingAction: String, Codable {
    case scaleUp = "scale_up"
    case scaleDown = "scale_down"
    case scaleOut = "scale_out"
    case scaleIn = "scale_in"
    case optimize
    case rebalance
}

/// Resource optimization policy
public struct ResourcePolicy: Codable {
    public let resourceType: ResourceType
    public let minCapacity: Double
    public let maxCapacity: Double
    public let targetUtilization: Double
    public let scalingThreshold: Double
    public let cooldownPeriod: TimeInterval
    public let costBudget: Double?
    public let priority: ResourcePriority

    public init(
        resourceType: ResourceType,
        minCapacity: Double = 0.1,
        maxCapacity: Double = 10.0,
        targetUtilization: Double = 0.7,
        scalingThreshold: Double = 0.8,
        cooldownPeriod: TimeInterval = 300,
        costBudget: Double? = nil,
        priority: ResourcePriority = .medium
    ) {
        self.resourceType = resourceType
        self.minCapacity = minCapacity
        self.maxCapacity = maxCapacity
        self.targetUtilization = targetUtilization
        self.scalingThreshold = scalingThreshold
        self.cooldownPeriod = cooldownPeriod
        self.costBudget = costBudget
        self.priority = priority
    }
}

/// Intelligent resource manager with autonomous scaling
@MainActor
public final class IntelligentResourceManager: ObservableObject {

    // MARK: - Properties

    public static let shared = IntelligentResourceManager()

    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var currentAllocations: [UUID: ResourceAllocation] = [:]
    @Published public private(set) var resourceMetrics: [ResourceType: ResourceMetrics] = [:]
    @Published public private(set) var scalingDecisions: [ScalingDecision] = []
    @Published public private(set) var optimizationScore: Double = 0.0

    private let logger = Logger(
        subsystem: "com.quantum.workspace", category: "IntelligentResourceManager"
    )
    private var monitoringTask: Task<Void, Never>?
    private var optimizationTask: Task<Void, Never>?
    private var scalingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let monitoringInterval: TimeInterval = 30.0 // seconds
    private let optimizationInterval: TimeInterval = 300.0 // 5 minutes
    private let scalingCooldown: TimeInterval = 180.0 // 3 minutes

    // Resource policies
    private var resourcePolicies: [ResourceType: ResourcePolicy] = [:]

    // State tracking
    private var lastScalingActions: [ResourceType: Date] = [:]
    private var resourceHistory: [ResourceType: [ResourceMetrics]] = [:]
    private var allocationQueue: [ResourceAllocation] = []

    // AI-driven optimization parameters
    private let learningRate: Double = 0.1
    private let predictionHorizon: TimeInterval = 3600.0 // 1 hour
    private let costOptimizationWeight: Double = 0.3
    private let performanceOptimizationWeight: Double = 0.7

    // MARK: - Initialization

    private init() {
        setupResourcePolicies()
        setupMonitoring()
        setupOptimization()
    }

    // MARK: - Public Interface

    /// Start the intelligent resource manager
    public func start() async {
        guard !isActive else { return }

        logger.info("🚀 Starting Intelligent Resource Manager")
        isActive = true

        // Start monitoring task
        monitoringTask = Task {
            await startMonitoringLoop()
        }

        // Start optimization task
        optimizationTask = Task {
            await startOptimizationLoop()
        }

        // Start scaling task
        scalingTask = Task {
            await startScalingLoop()
        }

        logger.info("✅ Intelligent Resource Manager started successfully")
    }

    /// Stop the intelligent resource manager
    public func stop() async {
        guard isActive else { return }

        logger.info("🛑 Stopping Intelligent Resource Manager")
        isActive = false

        // Cancel all tasks
        monitoringTask?.cancel()
        optimizationTask?.cancel()
        scalingTask?.cancel()

        monitoringTask = nil
        optimizationTask = nil
        scalingTask = nil

        logger.info("✅ Intelligent Resource Manager stopped")
    }

    /// Request resource allocation
    public func requestAllocation(_ allocation: ResourceAllocation) async throws -> UUID {
        logger.info(
            "📋 Resource allocation requested: \(allocation.resourceType.rawValue) x\(allocation.requestedAmount)"
        )

        // Check if allocation can be fulfilled
        guard let metrics = resourceMetrics[allocation.resourceType] else {
            throw ResourceError.resourceTypeNotMonitored(allocation.resourceType)
        }

        guard metrics.availableCapacity >= allocation.requestedAmount else {
            throw ResourceError.insufficientCapacity(
                requested: allocation.requestedAmount,
                available: metrics.availableCapacity
            )
        }

        // Add to current allocations
        await MainActor.run {
            currentAllocations[allocation.id] = allocation
        }

        // Trigger immediate optimization
        await optimizeResourceAllocation(for: allocation.resourceType)

        logger.info("✅ Resource allocation granted: \(allocation.id)")
        return allocation.id
    }

    /// Release resource allocation
    public func releaseAllocation(_ allocationId: UUID) async {
        guard let allocation = currentAllocations[allocationId] else {
            logger.warning("⚠️ Attempted to release unknown allocation: \(allocationId)")
            return
        }

        logger.info(
            "🔓 Releasing resource allocation: \(allocation.resourceType.rawValue) x\(allocation.requestedAmount)"
        )

        await MainActor.run {
            currentAllocations.removeValue(forKey: allocationId)
        }

        // Trigger optimization for released resource type
        await optimizeResourceAllocation(for: allocation.resourceType)
    }

    /// Get current resource metrics
    public func getResourceMetrics() -> [ResourceType: ResourceMetrics] {
        resourceMetrics
    }

    /// Get resource utilization summary
    public func getUtilizationSummary() -> [ResourceType: Double] {
        resourceMetrics.mapValues { $0.utilizationPercentage }
    }

    /// Force scaling decision for a resource type
    public func forceScaling(for resourceType: ResourceType, action: ScalingAction, amount: Double)
        async
    {
        logger.info("🔧 Forced scaling: \(resourceType.rawValue) \(action.rawValue) x\(amount)")

        let decision = ScalingDecision(
            resourceType: resourceType,
            action: action,
            amount: amount,
            reason: "Manual scaling request",
            confidence: 1.0,
            estimatedTime: 60
        )

        await executeScalingDecision(decision)
    }

    /// Update resource policy
    public func updatePolicy(_ policy: ResourcePolicy) {
        resourcePolicies[policy.resourceType] = policy
        logger.info("📝 Updated policy for \(policy.resourceType.rawValue)")
    }

    // MARK: - Private Methods

    private func setupResourcePolicies() {
        // Default policies for common resource types
        let defaultPolicies: [ResourceType: ResourcePolicy] = [
            .cpu: ResourcePolicy(
                resourceType: .cpu, minCapacity: 0.1, maxCapacity: 8.0, targetUtilization: 0.7
            ),
            .memory: ResourcePolicy(
                resourceType: .memory, minCapacity: 512, maxCapacity: 32768, targetUtilization: 0.8
            ),
            .disk: ResourcePolicy(
                resourceType: .disk, minCapacity: 1024, maxCapacity: 1_048_576,
                targetUtilization: 0.6
            ),
            .network: ResourcePolicy(
                resourceType: .network, minCapacity: 10, maxCapacity: 1000, targetUtilization: 0.5
            ),
            .gpu: ResourcePolicy(
                resourceType: .gpu, minCapacity: 0, maxCapacity: 4, targetUtilization: 0.8
            ),
            .quantumProcessor: ResourcePolicy(
                resourceType: .quantumProcessor, minCapacity: 0, maxCapacity: 100,
                targetUtilization: 0.9
            ),
            .cloudInstances: ResourcePolicy(
                resourceType: .cloudInstances, minCapacity: 1, maxCapacity: 50,
                targetUtilization: 0.7
            ),
            .databaseConnections: ResourcePolicy(
                resourceType: .databaseConnections, minCapacity: 5, maxCapacity: 1000,
                targetUtilization: 0.6
            ),
            .apiRateLimits: ResourcePolicy(
                resourceType: .apiRateLimits, minCapacity: 100, maxCapacity: 10000,
                targetUtilization: 0.8
            ),
        ]

        resourcePolicies = defaultPolicies
        logger.info("📋 Initialized resource policies for \(defaultPolicies.count) resource types")
    }

    private func setupMonitoring() {
        // Set up periodic resource monitoring
        Timer.publish(every: monitoringInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.performResourceMonitoring()
                }
            }
            .store(in: &cancellables)
    }

    private func setupOptimization() {
        // Set up periodic optimization
        Timer.publish(every: optimizationInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.performGlobalOptimization()
                }
            }
            .store(in: &cancellables)
    }

    private func startMonitoringLoop() async {
        while isActive && !Task.isCancelled {
            await performResourceMonitoring()
            try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
        }
    }

    private func startOptimizationLoop() async {
        while isActive && !Task.isCancelled {
            await performGlobalOptimization()
            try? await Task.sleep(nanoseconds: UInt64(optimizationInterval * 1_000_000_000))
        }
    }

    private func startScalingLoop() async {
        while isActive && !Task.isCancelled {
            await evaluateScalingDecisions()
            try? await Task.sleep(nanoseconds: UInt64(60 * 1_000_000_000)) // 1 minute
        }
    }

    private func performResourceMonitoring() async {
        for resourceType in ResourceType.allCases {
            let metrics = await monitorResource(resourceType)
            await MainActor.run {
                resourceMetrics[resourceType] = metrics

                // Store in history for trend analysis
                if resourceHistory[resourceType] == nil {
                    resourceHistory[resourceType] = []
                }
                resourceHistory[resourceType]?.append(metrics)

                // Keep only last 100 entries
                if resourceHistory[resourceType]!.count > 100 {
                    resourceHistory[resourceType]?.removeFirst()
                }
            }
        }

        // Update optimization score
        await updateOptimizationScore()
    }

    private func monitorResource(_ resourceType: ResourceType) async -> ResourceMetrics {
        switch resourceType {
        case .cpu:
            return await monitorCPU()
        case .memory:
            return await monitorMemory()
        case .disk:
            return await monitorDisk()
        case .network:
            return await monitorNetwork()
        case .gpu:
            return await monitorGPU()
        case .quantumProcessor:
            return await monitorQuantumProcessor()
        case .cloudInstances:
            return await monitorCloudInstances()
        case .databaseConnections:
            return await monitorDatabaseConnections()
        case .apiRateLimits:
            return await monitorAPIRateLimits()
        }
    }

    private func monitorCPU() async -> ResourceMetrics {
        // Get CPU usage
        let processInfo = ProcessInfo.processInfo
        let systemUsage = 1.0 - processInfo.systemUptime.remainder(dividingBy: 1.0) // Placeholder
        let availableCores = Double(processInfo.activeProcessorCount)
        let allocatedCores = availableCores // Assume all cores allocated

        return ResourceMetrics(
            resourceType: .cpu,
            currentUsage: systemUsage * allocatedCores,
            allocatedCapacity: allocatedCores,
            availableCapacity: allocatedCores - (systemUsage * allocatedCores),
            costPerUnit: 0.05, // Cost per CPU core per hour
            performanceScore: 1.0 - systemUsage
        )
    }

    private func monitorMemory() async -> ResourceMetrics {
        // Get memory usage
        let processInfo = ProcessInfo.processInfo
        let totalMemory = Double(processInfo.physicalMemory) / 1024.0 / 1024.0 / 1024.0 // GB
        let usedMemory = totalMemory * 0.6 // Placeholder - would use actual measurement

        return ResourceMetrics(
            resourceType: .memory,
            currentUsage: usedMemory,
            allocatedCapacity: totalMemory,
            availableCapacity: totalMemory - usedMemory,
            costPerUnit: 0.01, // Cost per GB per hour
            performanceScore: 1.0 - (usedMemory / totalMemory)
        )
    }

    private func monitorDisk() async -> ResourceMetrics {
        // Get disk usage
        do {
            let fileManager = FileManager.default
            let homeURL = fileManager.homeDirectoryForCurrentUser
            let attributes = try fileManager.attributesOfFileSystem(forPath: homeURL.path)

            if let totalSpace = attributes[.systemSize] as? NSNumber,
               let freeSpace = attributes[.systemFreeSize] as? NSNumber
            {
                let totalGB = totalSpace.doubleValue / 1024.0 / 1024.0 / 1024.0
                let freeGB = freeSpace.doubleValue / 1024.0 / 1024.0 / 1024.0
                let usedGB = totalGB - freeGB

                return ResourceMetrics(
                    resourceType: .disk,
                    currentUsage: usedGB,
                    allocatedCapacity: totalGB,
                    availableCapacity: freeGB,
                    costPerUnit: 0.0001, // Cost per GB per hour
                    performanceScore: freeGB / totalGB
                )
            }
        } catch {
            logger.error("Failed to monitor disk: \(error.localizedDescription)")
        }

        return ResourceMetrics(
            resourceType: .disk,
            currentUsage: 0,
            allocatedCapacity: 1000,
            availableCapacity: 500,
            performanceScore: 0.5
        )
    }

    private func monitorNetwork() async -> ResourceMetrics {
        // Network monitoring placeholder
        ResourceMetrics(
            resourceType: .network,
            currentUsage: 50, // Mbps
            allocatedCapacity: 1000, // Mbps
            availableCapacity: 950,
            costPerUnit: 0.001, // Cost per Mbps per hour
            performanceScore: 0.95
        )
    }

    private func monitorGPU() async -> ResourceMetrics {
        // GPU monitoring placeholder
        ResourceMetrics(
            resourceType: .gpu,
            currentUsage: 0.5, // GPUs in use
            allocatedCapacity: 2, // Available GPUs
            availableCapacity: 1.5,
            costPerUnit: 1.0, // Cost per GPU per hour
            performanceScore: 0.75
        )
    }

    private func monitorQuantumProcessor() async -> ResourceMetrics {
        // Quantum processor monitoring placeholder
        ResourceMetrics(
            resourceType: .quantumProcessor,
            currentUsage: 10, // Qubits in use
            allocatedCapacity: 100, // Total qubits
            availableCapacity: 90,
            costPerUnit: 10.0, // Cost per qubit per hour
            performanceScore: 0.9
        )
    }

    private func monitorCloudInstances() async -> ResourceMetrics {
        // Cloud instances monitoring placeholder
        ResourceMetrics(
            resourceType: .cloudInstances,
            currentUsage: 5, // Instances running
            allocatedCapacity: 20, // Max instances
            availableCapacity: 15,
            costPerUnit: 0.1, // Cost per instance per hour
            performanceScore: 0.75
        )
    }

    private func monitorDatabaseConnections() async -> ResourceMetrics {
        // Database connections monitoring placeholder
        ResourceMetrics(
            resourceType: .databaseConnections,
            currentUsage: 50, // Active connections
            allocatedCapacity: 200, // Max connections
            availableCapacity: 150,
            costPerUnit: 0.001, // Cost per connection per hour
            performanceScore: 0.75
        )
    }

    private func monitorAPIRateLimits() async -> ResourceMetrics {
        // API rate limits monitoring placeholder
        ResourceMetrics(
            resourceType: .apiRateLimits,
            currentUsage: 500, // Requests per minute
            allocatedCapacity: 2000, // Max requests per minute
            availableCapacity: 1500,
            costPerUnit: 0.0001, // Cost per request
            performanceScore: 0.75
        )
    }

    private func performGlobalOptimization() async {
        logger.info("🔧 Performing global resource optimization")

        for resourceType in ResourceType.allCases {
            await optimizeResourceAllocation(for: resourceType)
        }

        // Perform cross-resource optimization
        await performCrossResourceOptimization()
    }

    private func optimizeResourceAllocation(for resourceType: ResourceType) async {
        guard let metrics = resourceMetrics[resourceType],
              let policy = resourcePolicies[resourceType]
        else {
            return
        }

        let utilization = metrics.utilizationPercentage / 100.0

        // Check if scaling is needed
        if utilization > policy.scalingThreshold {
            // Scale up
            let scaleAmount = calculateScaleAmount(
                for: resourceType, currentUtilization: utilization, policy: policy
            )
            await proposeScalingDecision(
                resourceType: resourceType,
                action: .scaleUp,
                amount: scaleAmount,
                reason: "High utilization: \(String(format: "%.1f", utilization * 100))%"
            )
        } else if utilization < policy.targetUtilization * 0.5 {
            // Scale down
            let scaleAmount = calculateScaleAmount(
                for: resourceType, currentUtilization: utilization, policy: policy
            )
            await proposeScalingDecision(
                resourceType: resourceType,
                action: .scaleDown,
                amount: scaleAmount,
                reason: "Low utilization: \(String(format: "%.1f", utilization * 100))%"
            )
        }
    }

    private func calculateScaleAmount(
        for resourceType: ResourceType, currentUtilization: Double, policy: ResourcePolicy
    ) -> Double {
        let targetUtilization = policy.targetUtilization
        let currentCapacity = resourceMetrics[resourceType]?.allocatedCapacity ?? 1.0

        if currentUtilization > targetUtilization {
            // Scale up to bring utilization to target
            let requiredCapacity = currentCapacity * (currentUtilization / targetUtilization)
            return min(requiredCapacity - currentCapacity, policy.maxCapacity - currentCapacity)
        } else {
            // Scale down to bring utilization to target
            let requiredCapacity = currentCapacity * (currentUtilization / targetUtilization)
            let scaleDownAmount = currentCapacity - requiredCapacity
            return min(scaleDownAmount, currentCapacity - policy.minCapacity)
        }
    }

    private func proposeScalingDecision(
        resourceType: ResourceType, action: ScalingAction, amount: Double, reason: String
    ) async {
        guard amount > 0 else { return }

        // Check cooldown period
        if let lastAction = lastScalingActions[resourceType] {
            let timeSinceLastAction = Date().timeIntervalSince(lastAction)
            guard timeSinceLastAction >= scalingCooldown else {
                return // Still in cooldown
            }
        }

        // Predict future demand
        let predictedDemand = await predictResourceDemand(for: resourceType)

        // Calculate confidence based on prediction accuracy
        let confidence = calculateScalingConfidence(
            resourceType: resourceType, predictedDemand: predictedDemand
        )

        // Estimate cost
        let estimatedCost = calculateScalingCost(
            resourceType: resourceType, action: action, amount: amount
        )

        let decision = ScalingDecision(
            resourceType: resourceType,
            action: action,
            amount: amount,
            reason: reason,
            confidence: confidence,
            estimatedCost: estimatedCost
        )

        await MainActor.run {
            scalingDecisions.append(decision)
        }

        logger.info(
            "📊 Proposed scaling decision: \(resourceType.rawValue) \(action.rawValue) x\(amount) (confidence: \(String(format: "%.2f", confidence)))"
        )
    }

    private func evaluateScalingDecisions() async {
        let pendingDecisions = scalingDecisions.filter { decision in
            // Only execute high-confidence decisions automatically
            decision.confidence > 0.8
        }

        for decision in pendingDecisions {
            await executeScalingDecision(decision)

            // Remove from pending decisions
            await MainActor.run {
                scalingDecisions.removeAll { $0.id == decision.id }
            }
        }
    }

    private func executeScalingDecision(_ decision: ScalingDecision) async {
        logger.info(
            "⚡ Executing scaling decision: \(decision.resourceType.rawValue) \(decision.action.rawValue) x\(decision.amount)"
        )

        // Update last scaling action
        lastScalingActions[decision.resourceType] = Date()

        // Simulate scaling execution
        try? await Task.sleep(nanoseconds: UInt64(decision.estimatedTime * 1_000_000_000))

        // Update resource metrics after scaling
        await performResourceMonitoring()

        logger.info("✅ Scaling decision executed successfully")
    }

    private func predictResourceDemand(for resourceType: ResourceType) async -> Double? {
        guard let history = resourceHistory[resourceType], history.count >= 3 else {
            return nil
        }

        // Simple linear regression for prediction
        let recentUsage = history.suffix(10).map(\.currentUsage)
        guard recentUsage.count >= 2 else { return nil }

        // Calculate trend
        let n = Double(recentUsage.count)
        let sumX = (0 ..< recentUsage.count).reduce(0.0) { $0 + Double($1) }
        let sumY = recentUsage.reduce(0, +)
        let sumXY = zip(0 ..< recentUsage.count, recentUsage).reduce(0.0) { $0 + Double($1.0) * $1.1 }
        let sumXX = (0 ..< recentUsage.count).reduce(0.0) { $0 + Double($1 * $1) }

        let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n

        // Predict next value
        let nextX = Double(recentUsage.count)
        let predictedValue = slope * nextX + intercept

        return max(0, predictedValue)
    }

    private func calculateScalingConfidence(resourceType: ResourceType, predictedDemand: Double?)
        -> Double
    {
        guard let predicted = predictedDemand,
              let currentMetrics = resourceMetrics[resourceType]
        else {
            return 0.5 // Default confidence
        }

        let currentUsage = currentMetrics.currentUsage
        let predictionAccuracy = 1.0 - abs(predicted - currentUsage) / max(currentUsage, 1.0)

        return min(max(predictionAccuracy, 0.1), 1.0)
    }

    private func calculateScalingCost(
        resourceType: ResourceType, action: ScalingAction, amount: Double
    ) -> Double? {
        guard let costPerUnit = resourceMetrics[resourceType]?.costPerUnit else {
            return nil
        }

        let timeMultiplier = 1.0 // 1 hour
        return amount * costPerUnit * timeMultiplier
    }

    private func performCrossResourceOptimization() async {
        // Optimize across multiple resources for cost-performance balance
        let totalCost = resourceMetrics.values.compactMap(\.costPerUnit).reduce(0, +)
        let averagePerformance =
            resourceMetrics.values.map(\.performanceScore).reduce(0, +)
                / Double(resourceMetrics.count)

        let optimizationScore =
            (performanceOptimizationWeight * averagePerformance)
                - (costOptimizationWeight * min(totalCost / 100.0, 1.0))

        await MainActor.run {
            self.optimizationScore = optimizationScore
        }

        logger.info(
            "🎯 Cross-resource optimization score: \(String(format: "%.3f", optimizationScore))")
    }

    private func updateOptimizationScore() async {
        let utilizationScores = resourceMetrics.values.map { metrics in
            let utilization = metrics.utilizationPercentage / 100.0
            let targetUtilization = resourcePolicies[metrics.resourceType]?.targetUtilization ?? 0.7
            return 1.0 - abs(utilization - targetUtilization)
        }

        let averageUtilizationScore =
            utilizationScores.reduce(0, +) / Double(utilizationScores.count)

        await MainActor.run {
            optimizationScore = averageUtilizationScore
        }
    }
}

// MARK: - Extensions

public extension IntelligentResourceManager {
    /// Get resource allocation summary
    func getAllocationSummary() -> [ResourceType: Int] {
        var summary = [ResourceType: Int]()
        for allocation in currentAllocations.values {
            summary[allocation.resourceType, default: 0] += 1
        }
        return summary
    }

    /// Get pending scaling decisions
    func getPendingScalingDecisions() -> [ScalingDecision] {
        scalingDecisions
    }

    /// Export resource metrics for analysis
    func exportResourceMetrics() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(resourceMetrics)
    }

    /// Import resource policies
    func importResourcePolicies(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let policies = try? decoder.decode([ResourceType: ResourcePolicy].self, from: data) {
            resourcePolicies = policies
        }
    }
}

// MARK: - Supporting Types

extension ResourceType: CaseIterable {
    public static let allCases: [ResourceType] = [
        .cpu, .memory, .disk, .network, .gpu, .quantumProcessor,
        .cloudInstances, .databaseConnections, .apiRateLimits,
    ]
}

/// Resource management errors
public enum ResourceError: Error {
    case resourceTypeNotMonitored(ResourceType)
    case insufficientCapacity(requested: Double, available: Double)
    case scalingFailed(String)
    case allocationTimeout
}

// MARK: - Convenience Functions

/// Global function to request resource allocation
public func requestResourceAllocation(
    type: ResourceType,
    amount: Double,
    priority: ResourcePriority = .medium,
    requester: String
) async throws -> UUID {
    let allocation = ResourceAllocation(
        resourceType: type,
        requestedAmount: amount,
        priority: priority,
        requester: requester
    )

    return try await IntelligentResourceManager.shared.requestAllocation(allocation)
}

/// Global function to get current resource utilization
public func getResourceUtilization() async -> [ResourceType: Double] {
    await IntelligentResourceManager.shared.getUtilizationSummary()
}

/// Global function to check if resource manager is active
public func isResourceManagerActive() async -> Bool {
    await IntelligentResourceManager.shared.isActive
}

/// Global function to get optimization score
public func getResourceOptimizationScore() async -> Double {
    await IntelligentResourceManager.shared.optimizationScore
}
