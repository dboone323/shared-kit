//
//  PredictiveMaintenanceSystem.swift
//  Quantum-workspace
//
//  Created by Phase 6 Implementation
//  Task 46: Predictive Maintenance System
//
//  This file implements an AI-driven predictive maintenance system that analyzes
//  system metrics, predicts potential failures, and performs preventive maintenance.
//

import Combine
import Foundation
import os.log

/// Represents different types of maintenance actions
public enum MaintenanceAction: String, Codable {
    case preventive
    case corrective
    case predictive
    case optimization
    case upgrade
}

/// Represents the confidence level of a prediction
public enum PredictionConfidence: String, Codable {
    case low
    case medium
    case high
    case critical
}

/// Represents a maintenance prediction
public struct MaintenancePrediction: Codable {
    public let id: UUID
    public let timestamp: Date
    public let component: String
    public let failureType: String
    public let probability: Double
    public let confidence: PredictionConfidence
    public let timeToFailure: TimeInterval
    public let recommendedAction: MaintenanceAction
    public let metadata: [String: String]

    public init(
        component: String, failureType: String, probability: Double,
        confidence: PredictionConfidence, timeToFailure: TimeInterval,
        recommendedAction: MaintenanceAction, metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.component = component
        self.failureType = failureType
        self.probability = probability
        self.confidence = confidence
        self.timeToFailure = timeToFailure
        self.recommendedAction = recommendedAction
        self.metadata = metadata
    }
}

/// Represents a maintenance schedule
public struct MaintenanceSchedule: Codable {
    public let id: UUID
    public let component: String
    public let scheduledDate: Date
    public let action: MaintenanceAction
    public let priority: PredictionConfidence
    public let estimatedDuration: TimeInterval
    public let prerequisites: [String]
    public let status: MaintenanceStatus

    public init(
        component: String, scheduledDate: Date, action: MaintenanceAction,
        priority: PredictionConfidence, estimatedDuration: TimeInterval,
        prerequisites: [String] = [], status: MaintenanceStatus = .scheduled
    ) {
        self.id = UUID()
        self.component = component
        self.scheduledDate = scheduledDate
        self.action = action
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.prerequisites = prerequisites
        self.status = status
    }
}

/// Status of a maintenance task
public enum MaintenanceStatus: String, Codable {
    case scheduled
    case inProgress = "in_progress"
    case completed
    case failed
    case cancelled
}

/// System metrics for predictive analysis
public struct SystemMetrics: Codable {
    public let timestamp: Date
    public let component: String
    public let metrics: [String: Double]
    public let anomalies: [String]
    public let trends: [String: TrendDirection]

    public init(
        component: String, metrics: [String: Double],
        anomalies: [String] = [], trends: [String: TrendDirection] = [:]
    ) {
        self.timestamp = Date()
        self.component = component
        self.metrics = metrics
        self.anomalies = anomalies
        self.trends = trends
    }
}

/// Trend direction for metrics
public enum TrendDirection: String, Codable {
    case increasing
    case decreasing
    case stable
    case volatile
}

/// AI-driven predictive maintenance system
@MainActor
public final class PredictiveMaintenanceSystem: ObservableObject {

    // MARK: - Properties

    public static let shared = PredictiveMaintenanceSystem()

    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var activePredictions: [MaintenancePrediction] = []
    @Published public private(set) var maintenanceSchedule: [MaintenanceSchedule] = []
    @Published public private(set) var systemHealthScore: Double = 100.0

    private let logger = Logger(
        subsystem: "com.quantum.workspace", category: "PredictiveMaintenance"
    )
    private var monitoringTask: Task<Void, Never>?
    private var predictionTask: Task<Void, Never>?
    private var maintenanceTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let monitoringInterval: TimeInterval = 60.0 // seconds
    private let predictionInterval: TimeInterval = 300.0 // 5 minutes
    private let maintenanceCheckInterval: TimeInterval = 3600.0 // 1 hour

    // AI Model parameters
    private let failureThreshold: Double = 0.7 // 70% failure probability triggers action
    private let criticalThreshold: Double = 0.9 // 90% failure probability is critical
    private let predictionHorizon: TimeInterval = 604_800.0 // 7 days

    // State
    private var metricsHistory = [String: [SystemMetrics]]()
    private var predictionHistory = [MaintenancePrediction]()
    private var maintenanceHistory = [MaintenanceSchedule]()

    // MARK: - Initialization

    private init() {
        setupMetricsCollection()
        setupPredictionEngine()
    }

    // MARK: - Public Interface

    /// Start the predictive maintenance system
    public func start() async {
        guard !isActive else { return }

        logger.info("🚀 Starting Predictive Maintenance System")
        isActive = true

        // Start monitoring task
        monitoringTask = Task {
            await startMonitoringLoop()
        }

        // Start prediction task
        predictionTask = Task {
            await startPredictionLoop()
        }

        // Start maintenance task
        maintenanceTask = Task {
            await startMaintenanceLoop()
        }

        logger.info("✅ Predictive Maintenance System started successfully")
    }

    /// Stop the predictive maintenance system
    public func stop() async {
        guard isActive else { return }

        logger.info("🛑 Stopping Predictive Maintenance System")
        isActive = false

        // Cancel all tasks
        monitoringTask?.cancel()
        predictionTask?.cancel()
        maintenanceTask?.cancel()

        monitoringTask = nil
        predictionTask = nil
        maintenanceTask = nil

        logger.info("✅ Predictive Maintenance System stopped")
    }

    /// Get current predictions
    public func getPredictions() -> [MaintenancePrediction] {
        activePredictions
    }

    /// Get maintenance schedule
    public func getMaintenanceSchedule() -> [MaintenanceSchedule] {
        maintenanceSchedule
    }

    /// Manually trigger prediction analysis for a component
    public func analyzeComponent(_ component: String) async {
        logger.info("🔍 Manual analysis requested for component: \(component)")

        let metrics = await collectMetrics(for: component)
        let predictions = await generatePredictions(for: component, metrics: metrics)

        await MainActor.run {
            // Update active predictions
            activePredictions.removeAll { $0.component == component }
            activePredictions.append(contentsOf: predictions)

            // Schedule maintenance for high-probability predictions
            for prediction in predictions where prediction.probability >= failureThreshold {
                scheduleMaintenance(for: prediction)
            }
        }
    }

    /// Execute scheduled maintenance
    public func executeMaintenance(scheduleId: UUID) async -> Bool {
        guard let schedule = maintenanceSchedule.first(where: { $0.id == scheduleId }) else {
            logger.error("❌ Maintenance schedule not found: \(scheduleId)")
            return false
        }

        logger.info(
            "🔧 Executing maintenance: \(schedule.action.rawValue) for \(schedule.component)")

        await MainActor.run {
            updateMaintenanceStatus(scheduleId, status: .inProgress)
        }

        let success = await performMaintenanceAction(schedule.action, for: schedule.component)

        await MainActor.run {
            updateMaintenanceStatus(scheduleId, status: success ? .completed : .failed)
        }

        if success {
            logger.info("✅ Maintenance completed successfully")
        } else {
            logger.error("❌ Maintenance failed")
        }

        return success
    }

    // MARK: - Private Methods

    private func setupMetricsCollection() {
        // Set up periodic metrics collection
        Timer.publish(every: monitoringInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.collectAllMetrics()
                }
            }
            .store(in: &cancellables)
    }

    private func setupPredictionEngine() {
        // Initialize prediction models
        // In a real implementation, this would load trained ML models
        logger.info("🤖 Prediction engine initialized")
    }

    private func startMonitoringLoop() async {
        while isActive && !Task.isCancelled {
            await collectAllMetrics()
            try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
        }
    }

    private func startPredictionLoop() async {
        while isActive && !Task.isCancelled {
            await performPredictionAnalysis()
            try? await Task.sleep(nanoseconds: UInt64(predictionInterval * 1_000_000_000))
        }
    }

    private func startMaintenanceLoop() async {
        while isActive && !Task.isCancelled {
            await checkAndExecuteMaintenance()
            try? await Task.sleep(nanoseconds: UInt64(maintenanceCheckInterval * 1_000_000_000))
        }
    }

    private func collectAllMetrics() async {
        let components = ["memory", "cpu", "disk", "network", "database", "api", "filesystem"]

        for component in components {
            let metrics = await collectMetrics(for: component)
            storeMetrics(metrics)

            // Update health score
            await updateHealthScore()
        }
    }

    private func collectMetrics(for component: String) async -> SystemMetrics {
        switch component {
        case "memory":
            return await collectMemoryMetrics()
        case "cpu":
            return await collectCPUMetrics()
        case "disk":
            return await collectDiskMetrics()
        case "network":
            return await collectNetworkMetrics()
        case "database":
            return await collectDatabaseMetrics()
        case "api":
            return await collectAPIMetrics()
        case "filesystem":
            return await collectFilesystemMetrics()
        default:
            return SystemMetrics(component: component, metrics: [:])
        }
    }

    private func collectMemoryMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        // Get memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            let totalMB = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0

            metrics["used_mb"] = usedMB
            metrics["total_mb"] = totalMB
            metrics["usage_percent"] = (usedMB / totalMB) * 100.0
        }

        let anomalies = detectAnomalies(in: metrics, for: "memory")
        let trends = analyzeTrends(for: "memory")

        return SystemMetrics(
            component: "memory", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func collectCPUMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        // CPU usage (simplified - would use more sophisticated monitoring in production)
        metrics["usage_percent"] = Double.random(in: 10 ... 80)
        metrics["core_count"] = Double(ProcessInfo.processInfo.activeProcessorCount)
        metrics["temperature"] = Double.random(in: 40 ... 80) // Simulated temperature

        let anomalies = detectAnomalies(in: metrics, for: "cpu")
        let trends = analyzeTrends(for: "cpu")

        return SystemMetrics(
            component: "cpu", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func collectDiskMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        do {
            let fileManager = FileManager.default
            let homeURL = fileManager.homeDirectoryForCurrentUser
            let attributes = try fileManager.attributesOfFileSystem(forPath: homeURL.path)

            if let freeSpace = attributes[.systemFreeSize] as? NSNumber,
               let totalSpace = attributes[.systemSize] as? NSNumber
            {
                let freeGB = freeSpace.doubleValue / 1024.0 / 1024.0 / 1024.0
                let totalGB = totalSpace.doubleValue / 1024.0 / 1024.0 / 1024.0

                metrics["free_gb"] = freeGB
                metrics["total_gb"] = totalGB
                metrics["usage_percent"] = ((totalGB - freeGB) / totalGB) * 100.0
            }
        } catch {
            metrics["error"] = 1.0
        }

        let anomalies = detectAnomalies(in: metrics, for: "disk")
        let trends = analyzeTrends(for: "disk")

        return SystemMetrics(
            component: "disk", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func collectNetworkMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        // Network metrics (simplified)
        metrics["latency_ms"] = Double.random(in: 10 ... 200)
        metrics["bandwidth_mbps"] = Double.random(in: 50 ... 1000)
        metrics["packet_loss_percent"] = Double.random(in: 0 ... 5)

        let anomalies = detectAnomalies(in: metrics, for: "network")
        let trends = analyzeTrends(for: "network")

        return SystemMetrics(
            component: "network", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func collectDatabaseMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        // Database metrics (placeholder - would connect to actual database)
        metrics["connection_count"] = Double.random(in: 1 ... 100)
        metrics["query_time_ms"] = Double.random(in: 1 ... 500)
        metrics["cache_hit_ratio"] = Double.random(in: 0.8 ... 1.0)

        let anomalies = detectAnomalies(in: metrics, for: "database")
        let trends = analyzeTrends(for: "database")

        return SystemMetrics(
            component: "database", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func collectAPIMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        // API metrics (placeholder - would monitor actual API endpoints)
        metrics["response_time_ms"] = Double.random(in: 50 ... 1000)
        metrics["error_rate_percent"] = Double.random(in: 0 ... 10)
        metrics["throughput_rps"] = Double.random(in: 10 ... 1000)

        let anomalies = detectAnomalies(in: metrics, for: "api")
        let trends = analyzeTrends(for: "api")

        return SystemMetrics(
            component: "api", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func collectFilesystemMetrics() async -> SystemMetrics {
        var metrics = [String: Double]()

        // Filesystem metrics
        do {
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let contents = try fileManager.contentsOfDirectory(
                at: documentsURL, includingPropertiesForKeys: [.fileSizeKey]
            )

            var totalSize: Int64 = 0
            for url in contents {
                let attributes = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(attributes.fileSize ?? 0)
            }

            metrics["total_files"] = Double(contents.count)
            metrics["total_size_mb"] = Double(totalSize) / 1024.0 / 1024.0
        } catch {
            metrics["error"] = 1.0
        }

        let anomalies = detectAnomalies(in: metrics, for: "filesystem")
        let trends = analyzeTrends(for: "filesystem")

        return SystemMetrics(
            component: "filesystem", metrics: metrics, anomalies: anomalies, trends: trends
        )
    }

    private func storeMetrics(_ metrics: SystemMetrics) {
        if metricsHistory[metrics.component] == nil {
            metricsHistory[metrics.component] = []
        }

        metricsHistory[metrics.component]?.append(metrics)

        // Keep only last 1000 metrics per component
        if let count = metricsHistory[metrics.component]?.count, count > 1000 {
            metricsHistory[metrics.component]?.removeFirst(count - 1000)
        }
    }

    private func detectAnomalies(in metrics: [String: Double], for component: String) -> [String] {
        var anomalies = [String]()

        // Simple anomaly detection based on thresholds
        for (key, value) in metrics {
            switch (component, key) {
            case ("memory", "usage_percent") where value > 90:
                anomalies.append("High memory usage: \(String(format: "%.1f", value))%")
            case ("cpu", "usage_percent") where value > 85:
                anomalies.append("High CPU usage: \(String(format: "%.1f", value))%")
            case ("disk", "usage_percent") where value > 95:
                anomalies.append("Low disk space: \(String(format: "%.1f", value))% used")
            case ("network", "packet_loss_percent") where value > 2:
                anomalies.append("High packet loss: \(String(format: "%.1f", value))%")
            case ("api", "error_rate_percent") where value > 5:
                anomalies.append("High API error rate: \(String(format: "%.1f", value))%")
            default:
                break
            }
        }

        return anomalies
    }

    private func analyzeTrends(for component: String) -> [String: TrendDirection] {
        guard let history = metricsHistory[component], history.count >= 3 else {
            return [:]
        }

        var trends = [String: TrendDirection]()

        // Analyze trends for key metrics
        let recentMetrics = history.suffix(10) // Last 10 measurements

        for metricKey in ["usage_percent", "response_time_ms", "error_rate_percent"] {
            let values = recentMetrics.compactMap { $0.metrics[metricKey] }
            if values.count >= 3 {
                let trend = calculateTrend(for: values)
                trends[metricKey] = trend
            }
        }

        return trends
    }

    private func calculateTrend(for values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }

        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)

        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

        let change = secondAvg - firstAvg
        let changePercent = abs(change / firstAvg)

        if changePercent < 0.05 {
            return .stable
        } else if changePercent > 0.2 {
            return .volatile
        } else if change > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }

    private func performPredictionAnalysis() async {
        let components = ["memory", "cpu", "disk", "network", "database", "api", "filesystem"]

        for component in components {
            guard let metrics = metricsHistory[component], !metrics.isEmpty else { continue }

            let predictions = await generatePredictions(for: component, metrics: metrics.last!)
            await MainActor.run {
                // Update active predictions
                activePredictions.removeAll { $0.component == component }
                activePredictions.append(contentsOf: predictions)

                // Schedule maintenance for high-probability predictions
                for prediction in predictions where prediction.probability >= failureThreshold {
                    scheduleMaintenance(for: prediction)
                }
            }
        }
    }

    private func generatePredictions(for component: String, metrics: SystemMetrics) async
        -> [MaintenancePrediction]
    {
        var predictions = [MaintenancePrediction]()

        // Analyze each metric for potential failures
        for (metricKey, value) in metrics.metrics {
            let prediction = await predictFailure(
                for: component, metric: metricKey, value: value, trends: metrics.trends
            )
            if let prediction {
                predictions.append(prediction)
            }
        }

        // Component-specific predictions
        switch component {
        case "memory":
            if let memoryPrediction = await predictMemoryFailure(metrics) {
                predictions.append(memoryPrediction)
            }
        case "disk":
            if let diskPrediction = await predictDiskFailure(metrics) {
                predictions.append(diskPrediction)
            }
        case "network":
            if let networkPrediction = await predictNetworkFailure(metrics) {
                predictions.append(networkPrediction)
            }
        default:
            break
        }

        return predictions
    }

    private func predictFailure(
        for component: String, metric: String, value: Double, trends: [String: TrendDirection]
    ) async -> MaintenancePrediction? {
        // Simple prediction logic based on thresholds and trends
        var probability = 0.0
        var timeToFailure: TimeInterval = predictionHorizon
        var failureType = "unknown"
        var confidence: PredictionConfidence = .low

        switch (component, metric) {
        case ("memory", "usage_percent"):
            if value > 85 {
                probability = min(value / 100.0, 0.95)
                timeToFailure = predictionHorizon * (1.0 - probability)
                failureType = "memory_exhaustion"
                confidence = value > 90 ? .high : .medium
            }
        case ("cpu", "usage_percent"):
            if value > 80 {
                probability = min(value / 100.0 * 1.2, 0.95)
                timeToFailure = predictionHorizon * (1.0 - probability)
                failureType = "cpu_overload"
                confidence = value > 90 ? .high : .medium
            }
        case ("disk", "usage_percent"):
            if value > 90 {
                probability = min(value / 100.0, 0.95)
                timeToFailure = predictionHorizon * (1.0 - probability)
                failureType = "disk_full"
                confidence = .high
            }
        case ("network", "packet_loss_percent"):
            if value > 1.0 {
                probability = min(value / 5.0, 0.95)
                timeToFailure = predictionHorizon * (1.0 - probability)
                failureType = "network_failure"
                confidence = value > 3.0 ? .high : .medium
            }
        case ("api", "error_rate_percent"):
            if value > 2.0 {
                probability = min(value / 10.0, 0.95)
                timeToFailure = predictionHorizon * (1.0 - probability)
                failureType = "api_degradation"
                confidence = value > 5.0 ? .high : .medium
            }
        default:
            return nil
        }

        // Adjust based on trends
        if let trend = trends[metric] {
            switch trend {
            case .increasing:
                probability *= 1.2
                timeToFailure *= 0.8
            case .volatile:
                probability *= 1.1
                confidence = .medium
            case .decreasing:
                probability *= 0.8
                timeToFailure *= 1.2
            case .stable:
                break
            }
        }

        if probability >= failureThreshold {
            let action: MaintenanceAction = component == "disk" ? .preventive : .predictive
            return MaintenancePrediction(
                component: component,
                failureType: failureType,
                probability: probability,
                confidence: confidence,
                timeToFailure: timeToFailure,
                recommendedAction: action,
                metadata: ["metric": metric, "value": "\(value)"]
            )
        }

        return nil
    }

    private func predictMemoryFailure(_ metrics: SystemMetrics) async -> MaintenancePrediction? {
        guard let usagePercent = metrics.metrics["usage_percent"], usagePercent > 80 else {
            return nil
        }

        let probability = min(usagePercent / 100.0 * 1.1, 0.95)
        let timeToFailure = predictionHorizon * (1.0 - probability)

        return MaintenancePrediction(
            component: "memory",
            failureType: "memory_leak_or_exhaustion",
            probability: probability,
            confidence: usagePercent > 90 ? .critical : .high,
            timeToFailure: timeToFailure,
            recommendedAction: .optimization,
            metadata: ["pattern": "memory_pressure"]
        )
    }

    private func predictDiskFailure(_ metrics: SystemMetrics) async -> MaintenancePrediction? {
        guard let usagePercent = metrics.metrics["usage_percent"], usagePercent > 85 else {
            return nil
        }

        let probability = min(usagePercent / 100.0, 0.95)
        let timeToFailure = predictionHorizon * (1.0 - probability)

        return MaintenancePrediction(
            component: "disk",
            failureType: "disk_space_exhaustion",
            probability: probability,
            confidence: .critical,
            timeToFailure: timeToFailure,
            recommendedAction: .preventive,
            metadata: ["pattern": "disk_pressure"]
        )
    }

    private func predictNetworkFailure(_ metrics: SystemMetrics) async -> MaintenancePrediction? {
        guard let packetLoss = metrics.metrics["packet_loss_percent"], packetLoss > 1.5 else {
            return nil
        }

        let probability = min(packetLoss / 5.0, 0.95)
        let timeToFailure = predictionHorizon * (1.0 - probability)

        return MaintenancePrediction(
            component: "network",
            failureType: "network_connectivity_issues",
            probability: probability,
            confidence: packetLoss > 3.0 ? .high : .medium,
            timeToFailure: timeToFailure,
            recommendedAction: .corrective,
            metadata: ["pattern": "network_degradation"]
        )
    }

    private func scheduleMaintenance(for prediction: MaintenancePrediction) {
        // Check if maintenance is already scheduled
        let existingSchedule = maintenanceSchedule.first {
            $0.component == prediction.component && $0.action == prediction.recommendedAction
        }

        if existingSchedule == nil {
            let scheduledDate = Date().addingTimeInterval(prediction.timeToFailure * 0.5) // Schedule halfway to predicted failure
            let schedule = MaintenanceSchedule(
                component: prediction.component,
                scheduledDate: scheduledDate,
                action: prediction.recommendedAction,
                priority: prediction.confidence,
                estimatedDuration: 1800.0, // 30 minutes
                prerequisites: []
            )

            maintenanceSchedule.append(schedule)
            logger.info(
                "📅 Scheduled maintenance: \(prediction.recommendedAction.rawValue) for \(prediction.component)"
            )
        }
    }

    private func checkAndExecuteMaintenance() async {
        let now = Date()
        let dueSchedules = maintenanceSchedule.filter {
            $0.scheduledDate <= now && $0.status == .scheduled
        }

        for schedule in dueSchedules {
            if schedule.priority == .critical || schedule.priority == .high {
                _ = await executeMaintenance(scheduleId: schedule.id)
            }
        }
    }

    private func performMaintenanceAction(_ action: MaintenanceAction, for component: String) async
        -> Bool
    {
        logger.info("🔧 Performing \(action.rawValue) maintenance on \(component)")

        // Simulate maintenance duration
        let duration = Double.random(in: 300 ... 1800) // 5-30 minutes
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

        // Simulate success/failure (80% success rate)
        let success = Double.random(in: 0 ... 1) < 0.8

        if success {
            // Clear related predictions
            await MainActor.run {
                activePredictions.removeAll { $0.component == component }
            }
        }

        return success
    }

    private func updateMaintenanceStatus(_ scheduleId: UUID, status: MaintenanceStatus) {
        if let index = maintenanceSchedule.firstIndex(where: { $0.id == scheduleId }) {
            maintenanceSchedule[index] = MaintenanceSchedule(
                component: maintenanceSchedule[index].component,
                scheduledDate: maintenanceSchedule[index].scheduledDate,
                action: maintenanceSchedule[index].action,
                priority: maintenanceSchedule[index].priority,
                estimatedDuration: maintenanceSchedule[index].estimatedDuration,
                prerequisites: maintenanceSchedule[index].prerequisites,
                status: status
            )
        }
    }

    private func updateHealthScore() async {
        var totalScore = 100.0
        var componentCount = 0

        for (component, metrics) in metricsHistory {
            guard let latestMetrics = metrics.last else { continue }

            var componentScore = 100.0

            // Penalize based on anomalies
            componentScore -= Double(latestMetrics.anomalies.count) * 5.0

            // Penalize based on critical metrics
            for (key, value) in latestMetrics.metrics {
                switch (component, key) {
                case ("memory", "usage_percent") where value > 90:
                    componentScore -= (value - 90) * 2.0
                case ("cpu", "usage_percent") where value > 85:
                    componentScore -= (value - 85) * 1.5
                case ("disk", "usage_percent") where value > 95:
                    componentScore -= (value - 95) * 3.0
                default:
                    break
                }
            }

            totalScore += max(componentScore, 0)
            componentCount += 1
        }

        if componentCount > 0 {
            systemHealthScore = totalScore / Double(componentCount)
        }
    }
}

// MARK: - Extensions

public extension PredictiveMaintenanceSystem {
    /// Get health score for a specific component
    func getComponentHealthScore(_ component: String) -> Double {
        guard let metrics = metricsHistory[component]?.last else { return 100.0 }

        var score = 100.0

        // Penalize based on anomalies
        score -= Double(metrics.anomalies.count) * 5.0

        // Penalize based on critical metrics
        for (key, value) in metrics.metrics {
            switch (component, key) {
            case ("memory", "usage_percent") where value > 90:
                score -= (value - 90) * 2.0
            case ("cpu", "usage_percent") where value > 85:
                score -= (value - 85) * 1.5
            case ("disk", "usage_percent") where value > 95:
                score -= (value - 95) * 3.0
            default:
                break
            }
        }

        return max(score, 0)
    }

    /// Export maintenance history for analysis
    func exportMaintenanceHistory() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(maintenanceHistory)
    }

    /// Get maintenance recommendations
    func getMaintenanceRecommendations() -> [MaintenancePrediction] {
        activePredictions.filter { $0.probability >= failureThreshold }
    }
}

// MARK: - Convenience Functions

/// Global function to get current system health score
public func getSystemHealthScore() async -> Double {
    await PredictiveMaintenanceSystem.shared.systemHealthScore
}

/// Global function to get maintenance recommendations
public func getMaintenanceRecommendations() async -> [MaintenancePrediction] {
    await PredictiveMaintenanceSystem.shared.getMaintenanceRecommendations()
}

/// Global function to trigger component analysis
public func analyzeComponentHealth(_ component: String) {
    Task {
        await PredictiveMaintenanceSystem.shared.analyzeComponent(component)
    }
}
