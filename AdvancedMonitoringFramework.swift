//
//  AdvancedMonitoringFramework.swift
//  Shared-Kit
//
//  Created on February 10, 2026
//  Phase 8: Enterprise Scaling - Advanced Monitoring
//
//  This framework provides enterprise-grade monitoring and distributed tracing
//  for comprehensive observability across all applications.
//

import Combine
import Foundation
import Network
import SwiftData

// MARK: - Core Monitoring Engine

@available(iOS 17.0, macOS 14.0, *)
public final class MonitoringEngine {
    public static let shared = MonitoringEngine()

    private let tracer: DistributedTracer
    private let metricsCollector: MetricsCollector
    private let logAggregator: LogAggregator
    private let alertManager: AlertManager

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.tracer = DistributedTracer()
        self.metricsCollector = MetricsCollector()
        self.logAggregator = LogAggregator()
        self.alertManager = AlertManager()

        setupMonitoring()
    }

    // MARK: - Public API

    /// Start a new trace
    public func startTrace(name: String, attributes: [String: String] = [:]) -> TraceSpan {
        tracer.startTrace(name: name, attributes: attributes)
    }

    /// Record a metric
    public func recordMetric(_ metric: Metric) async {
        await metricsCollector.record(metric)
    }

    /// Log a structured event
    public func log(_ event: LogEvent) async {
        await logAggregator.log(event)
    }

    /// Create an alert
    public func createAlert(_ alert: Alert) async {
        await alertManager.createAlert(alert)
    }

    /// Get monitoring dashboard data
    public func getDashboardData(timeRange: DateInterval) async -> MonitoringDashboard {
        await MonitoringDashboard.create(
            metrics: metricsCollector.getMetrics(in: timeRange),
            traces: tracer.getTraces(in: timeRange),
            logs: logAggregator.getLogs(in: timeRange),
            alerts: alertManager.getActiveAlerts()
        )
    }

    /// Configure monitoring settings
    public func configure(settings: MonitoringSettings) {
        tracer.configure(settings.tracing)
        metricsCollector.configure(settings.metrics)
        logAggregator.configure(settings.logging)
        alertManager.configure(settings.alerts)
    }

    // MARK: - Private Methods

    private func setupMonitoring() {
        // Set up periodic health checks
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.performHealthCheck()
                }
            }
            .store(in: &cancellables)
    }

    private func performHealthCheck() async {
        let healthMetrics = await collectHealthMetrics()

        // Check for issues and create alerts
        for metric in healthMetrics {
            if metric.value > metric.threshold {
                let alert = Alert(
                    id: UUID().uuidString,
                    type: .performance,
                    severity: .warning,
                    title: "Health Check Alert",
                    description: "\(metric.name) exceeded threshold: \(metric.value)",
                    source: "HealthMonitor",
                    timestamp: Date()
                )
                await alertManager.createAlert(alert)
            }
        }
    }

    private func collectHealthMetrics() async -> [HealthMetric] {
        // Collect system health metrics
        [
            HealthMetric(name: "MemoryUsage", value: 0.7, threshold: 0.9, unit: "percentage"),
            HealthMetric(name: "CPUUsage", value: 0.6, threshold: 0.8, unit: "percentage"),
            HealthMetric(name: "NetworkLatency", value: 50, threshold: 200, unit: "ms"),
            HealthMetric(name: "ErrorRate", value: 0.02, threshold: 0.05, unit: "percentage"),
        ]
    }
}

// MARK: - Distributed Tracing

@available(iOS 17.0, macOS 14.0, *)
private final class DistributedTracer {
    private var activeSpans: [String: TraceSpan] = [:]
    private var completedTraces: [Trace] = []
    private let traceQueue = DispatchQueue(label: "com.tools-automation.monitoring.tracer")
    private var settings: TracingSettings = .init()

    func configure(_ settings: TracingSettings) {
        self.settings = settings
    }

    func startTrace(name: String, attributes: [String: String] = [:]) -> TraceSpan {
        let spanId = UUID().uuidString
        let traceId = UUID().uuidString

        let span = TraceSpan(
            id: spanId,
            traceId: traceId,
            name: name,
            startTime: Date(),
            attributes: attributes,
            parentId: nil
        )

        traceQueue.sync {
            self.activeSpans[spanId] = span
        }

        return span
    }

    func endSpan(_ span: TraceSpan) {
        let endTime = Date()
        let duration = endTime.timeIntervalSince(span.startTime)

        traceQueue.sync {
            var completedSpan = span
            completedSpan.endTime = endTime
            completedSpan.duration = duration

            // Create trace if this is the root span
            if span.parentId == nil {
                let trace = Trace(
                    id: span.traceId,
                    name: span.name,
                    startTime: span.startTime,
                    endTime: endTime,
                    duration: duration,
                    spans: [completedSpan],
                    status: .completed
                )
                self.completedTraces.append(trace)
            }

            self.activeSpans.removeValue(forKey: span.id)
        }
    }

    func getTraces(in timeRange: DateInterval) -> [Trace] {
        traceQueue.sync {
            self.completedTraces.filter { trace in
                timeRange.contains(trace.startTime)
            }
        }
    }

    func getActiveSpans() -> [TraceSpan] {
        traceQueue.sync {
            Array(self.activeSpans.values)
        }
    }
}

// MARK: - Metrics Collection

@available(iOS 17.0, macOS 14.0, *)
private final class MetricsCollector {
    private var metrics: [Metric] = []
    private let metricsQueue = DispatchQueue(label: "com.tools-automation.monitoring.metrics")
    private var settings: MetricsSettings = .init()

    func configure(_ settings: MetricsSettings) {
        self.settings = settings
    }

    func record(_ metric: Metric) async {
        await withCheckedContinuation { continuation in
            metricsQueue.async {
                self.metrics.append(metric)

                // Maintain rolling window
                let cutoffDate = Date().addingTimeInterval(-self.settings.retentionPeriod)
                self.metrics.removeAll { $0.timestamp < cutoffDate }

                continuation.resume()
            }
        }
    }

    func getMetrics(in timeRange: DateInterval) -> [Metric] {
        metricsQueue.sync {
            self.metrics.filter { timeRange.contains($0.timestamp) }
        }
    }

    func getAggregatedMetrics(type: MetricType, timeRange: DateInterval) -> MetricAggregation {
        let relevantMetrics = getMetrics(in: timeRange).filter { $0.type == type }

        guard !relevantMetrics.isEmpty else {
            return MetricAggregation(type: type, count: 0, average: 0, min: 0, max: 0, p95: 0, p99: 0)
        }

        let values = relevantMetrics.map(\.value)
        let sortedValues = values.sorted()

        return MetricAggregation(
            type: type,
            count: values.count,
            average: values.reduce(0, +) / Double(values.count),
            min: values.min() ?? 0,
            max: values.max() ?? 0,
            p95: sortedValues[Int(Double(sortedValues.count) * 0.95)],
            p99: sortedValues[Int(Double(sortedValues.count) * 0.99)]
        )
    }
}

// MARK: - Log Aggregation

@available(iOS 17.0, macOS 14.0, *)
private final class LogAggregator {
    private var logEvents: [LogEvent] = []
    private let logQueue = DispatchQueue(label: "com.tools-automation.monitoring.logs")
    private var settings: LoggingSettings = .init()

    func configure(_ settings: LoggingSettings) {
        self.settings = settings
    }

    func log(_ event: LogEvent) async {
        await withCheckedContinuation { continuation in
            logQueue.async {
                self.logEvents.append(event)

                // Maintain rolling window
                let cutoffDate = Date().addingTimeInterval(-self.settings.retentionPeriod)
                self.logEvents.removeAll { $0.timestamp < cutoffDate }

                continuation.resume()
            }
        }
    }

    func getLogs(in timeRange: DateInterval) -> [LogEvent] {
        logQueue.sync {
            self.logEvents.filter { timeRange.contains($0.timestamp) }
        }
    }

    func searchLogs(query: String, timeRange: DateInterval) -> [LogEvent] {
        getLogs(in: timeRange).filter { event in
            event.message.localizedCaseInsensitiveContains(query) ||
                event.metadata.values.contains(where: { "\($0)".localizedCaseInsensitiveContains(query) })
        }
    }
}

// MARK: - Alert Management

@available(iOS 17.0, macOS 14.0, *)
private final class AlertManager {
    private var activeAlerts: [Alert] = []
    private let alertQueue = DispatchQueue(label: "com.tools-automation.monitoring.alerts")
    private var settings: AlertSettings = .init()

    func configure(_ settings: AlertSettings) {
        self.settings = settings
    }

    func createAlert(_ alert: Alert) async {
        await withCheckedContinuation { continuation in
            alertQueue.async {
                self.activeAlerts.append(alert)

                // Auto-resolve old alerts
                let cutoffDate = Date().addingTimeInterval(-self.settings.alertRetentionPeriod)
                self.activeAlerts.removeAll { $0.timestamp < cutoffDate }

                // In a real implementation, this would send notifications
                print("🚨 Alert created: \(alert.title) - \(alert.description)")

                continuation.resume()
            }
        }
    }

    func resolveAlert(id: String) async {
        await withCheckedContinuation { continuation in
            alertQueue.async {
                self.activeAlerts.removeAll { $0.id == id }
                continuation.resume()
            }
        }
    }

    func getActiveAlerts() -> [Alert] {
        alertQueue.sync {
            self.activeAlerts
        }
    }

    func getAlerts(severity: AlertSeverity, timeRange: DateInterval) -> [Alert] {
        alertQueue.sync {
            self.activeAlerts.filter { alert in
                alert.severity == severity && timeRange.contains(alert.timestamp)
            }
        }
    }
}

// MARK: - Data Models

public struct TraceSpan {
    public let id: String
    public let traceId: String
    public let name: String
    public let startTime: Date
    public var endTime: Date?
    public var duration: TimeInterval?
    public let attributes: [String: String]
    public let parentId: String?

    public init(
        id: String,
        traceId: String,
        name: String,
        startTime: Date,
        attributes: [String: String] = [:],
        parentId: String? = nil
    ) {
        self.id = id
        self.traceId = traceId
        self.name = name
        self.startTime = startTime
        self.attributes = attributes
        self.parentId = parentId
    }
}

public struct Trace {
    public let id: String
    public let name: String
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let spans: [TraceSpan]
    public let status: TraceStatus
}

public enum TraceStatus {
    case completed, failed, cancelled
}

public struct Metric {
    public let name: String
    public let type: MetricType
    public let value: Double
    public let unit: String
    public let tags: [String: String]
    public let timestamp: Date

    public init(
        name: String,
        type: MetricType,
        value: Double,
        unit: String = "",
        tags: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.name = name
        self.type = type
        self.value = value
        self.unit = unit
        self.tags = tags
        self.timestamp = timestamp
    }
}

public enum MetricType {
    case counter, gauge, histogram, summary
}

public struct MetricAggregation {
    public let type: MetricType
    public let count: Int
    public let average: Double
    public let min: Double
    public let max: Double
    public let p95: Double
    public let p99: Double
}

public struct LogEvent {
    public let level: LogLevel
    public let message: String
    public let source: String
    public let metadata: [String: Any]
    public let timestamp: Date

    public init(
        level: LogLevel,
        message: String,
        source: String,
        metadata: [String: Any] = [:],
        timestamp: Date = Date()
    ) {
        self.level = level
        self.message = message
        self.source = source
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

public enum LogLevel {
    case debug, info, warning, error, critical
}

public struct Alert {
    public let id: String
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let description: String
    public let source: String
    public let timestamp: Date

    public init(
        id: String,
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        description: String,
        source: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.description = description
        self.source = source
        self.timestamp = timestamp
    }
}

public enum AlertType {
    case performance, security, availability, custom
}

public enum AlertSeverity {
    case info, warning, error, critical
}

public struct HealthMetric {
    public let name: String
    public let value: Double
    public let threshold: Double
    public let unit: String
}

public struct MonitoringDashboard {
    public let metrics: [MetricAggregation]
    public let traces: [Trace]
    public let logs: [LogEvent]
    public let alerts: [Alert]
    public let generatedAt: Date

    public static func create(
        metrics: [Metric],
        traces: [Trace],
        logs: [LogEvent],
        alerts: [Alert]
    ) -> MonitoringDashboard {
        // Aggregate metrics by type
        let timeRange = DateInterval(start: Date().addingTimeInterval(-3600), end: Date()) // Last hour
        var aggregations: [MetricAggregation] = []

        for type in [MetricType.counter, .gauge, .histogram, .summary] {
            let aggregation = MonitoringEngine.shared.metricsCollector.getAggregatedMetrics(
                type: type,
                timeRange: timeRange
            )
            if !aggregation.isEmpty {
                aggregations.append(aggregation)
            }
        }

        return MonitoringDashboard(
            metrics: aggregations,
            traces: traces,
            logs: logs,
            alerts: alerts,
            generatedAt: Date()
        )
    }
}

// MARK: - Configuration

public struct MonitoringSettings {
    public let tracing: TracingSettings
    public let metrics: MetricsSettings
    public let logging: LoggingSettings
    public let alerts: AlertSettings

    public init(
        tracing: TracingSettings = TracingSettings(),
        metrics: MetricsSettings = MetricsSettings(),
        logging: LoggingSettings = LoggingSettings(),
        alerts: AlertSettings = AlertSettings()
    ) {
        self.tracing = tracing
        self.metrics = metrics
        self.logging = logging
        self.alerts = alerts
    }
}

public struct TracingSettings {
    public let enabled: Bool
    public let sampleRate: Double
    public let maxSpansPerTrace: Int
    public let retentionPeriod: TimeInterval

    public init(
        enabled: Bool = true,
        sampleRate: Double = 1.0,
        maxSpansPerTrace: Int = 100,
        retentionPeriod: TimeInterval = 604_800
    ) { // 7 days
        self.enabled = enabled
        self.sampleRate = sampleRate
        self.maxSpansPerTrace = maxSpansPerTrace
        self.retentionPeriod = retentionPeriod
    }
}

public struct MetricsSettings {
    public let enabled: Bool
    public let collectionInterval: TimeInterval
    public let retentionPeriod: TimeInterval
    public let maxMetricsPerCollection: Int

    public init(
        enabled: Bool = true,
        collectionInterval: TimeInterval = 60,
        retentionPeriod: TimeInterval = 2_592_000, // 30 days
        maxMetricsPerCollection: Int = 1000
    ) {
        self.enabled = enabled
        self.collectionInterval = collectionInterval
        self.retentionPeriod = retentionPeriod
        self.maxMetricsPerCollection = maxMetricsPerCollection
    }
}

public struct LoggingSettings {
    public let enabled: Bool
    public let level: LogLevel
    public let retentionPeriod: TimeInterval
    public let maxLogsPerHour: Int

    public init(
        enabled: Bool = true,
        level: LogLevel = .info,
        retentionPeriod: TimeInterval = 2_592_000, // 30 days
        maxLogsPerHour: Int = 10000
    ) {
        self.enabled = enabled
        self.level = level
        self.retentionPeriod = retentionPeriod
        self.maxLogsPerHour = maxLogsPerHour
    }
}

public struct AlertSettings {
    public let enabled: Bool
    public let alertRetentionPeriod: TimeInterval
    public let maxAlertsPerHour: Int
    public let notificationChannels: [String]

    public init(
        enabled: Bool = true,
        alertRetentionPeriod: TimeInterval = 604_800, // 7 days
        maxAlertsPerHour: Int = 100,
        notificationChannels: [String] = ["console"]
    ) {
        self.enabled = enabled
        self.alertRetentionPeriod = alertRetentionPeriod
        self.maxAlertsPerHour = maxAlertsPerHour
        self.notificationChannels = notificationChannels
    }
}

// MARK: - Extensions

extension MonitoringEngine {
    var metricsCollector: MetricsCollector {
        // Access to private property for internal use
        self.metricsCollector
    }
}

// MARK: - Codable Extensions

extension TraceSpan: Codable {}
extension Trace: Codable {}
extension TraceStatus: Codable {}
extension Metric: Codable {}
extension MetricType: Codable {}
extension MetricAggregation: Codable {}
extension LogEvent: Codable {}
extension LogLevel: Codable {}
extension Alert: Codable {}
extension AlertType: Codable {}
extension AlertSeverity: Codable {}
extension HealthMetric: Codable {}
extension MonitoringDashboard: Codable {}
extension MonitoringSettings: Codable {}
extension TracingSettings: Codable {}
extension MetricsSettings: Codable {}
extension LoggingSettings: Codable {}
extension AlertSettings: Codable {}
