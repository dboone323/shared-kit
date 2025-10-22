//
//  MCPIntegrationAPIs.swift
//  Quantum-workspace
//
//  Created: Phase 9C - Enhanced MCP Systems
//  Purpose: MCP Integration APIs for seamless system integration
//

import Combine
import Foundation

// MARK: - MCP Integration APIs

/// Protocol for MCP API endpoints
public protocol MCPAPIEndpoint: Sendable {
    var path: String { get }
    var method: String { get }
    var parameters: [String: AnyCodable]? { get }
    var headers: [String: String]? { get }
}

/// Protocol for MCP API client
public protocol MCPAPIClient: Sendable {
    func execute<T: Decodable>(_ endpoint: MCPAPIEndpoint) async throws -> T
    func execute(_ endpoint: MCPAPIEndpoint) async throws -> [String: AnyCodable]
    func stream(_ endpoint: MCPAPIEndpoint) -> AsyncThrowingStream<[String: AnyCodable], Error>
}

/// Protocol for MCP service discovery
public protocol MCPServiceDiscovery: Sendable {
    func discoverServices() async throws -> [MCPServiceInfo]
    func registerService(_ service: MCPServiceInfo) async throws
    func unregisterService(_ serviceId: String) async throws
    func findService(byId id: String) async -> MCPServiceInfo?
    func findServices(byCapability capability: MCPToolCapability) async -> [MCPServiceInfo]
}

/// Protocol for MCP event system
public protocol MCPEventSystem: Sendable {
    func publish(_ event: MCPEvent) async
    func subscribe(to eventType: MCPEventType, handler: @escaping @Sendable (MCPEvent) -> Void)
        -> MCPSubscription
    func unsubscribe(_ subscription: MCPSubscription) async
}

/// Protocol for MCP metrics and monitoring
public protocol MCPMetricsSystem: Sendable {
    func recordMetric(_ metric: MCPMetric) async
    func getMetrics(for serviceId: String, timeRange: DateInterval) async -> [MCPMetric]
    func getHealthStatus() async -> MCPHealthStatus
    func getPerformanceReport(timeRange: DateInterval) async -> MCPPerformanceReport
}

// MARK: - Core MCP API Types

/// MCP service information
public struct MCPServiceInfo: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let version: String
    public let endpoint: String
    public let capabilities: [MCPToolCapability]
    public let healthCheckEndpoint: String?
    public let metadata: [String: String]

    public init(
        id: String,
        name: String,
        description: String,
        version: String = "1.0.0",
        endpoint: String,
        capabilities: [MCPToolCapability] = [],
        healthCheckEndpoint: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.endpoint = endpoint
        self.capabilities = capabilities
        self.healthCheckEndpoint = healthCheckEndpoint
        self.metadata = metadata
    }
}

/// MCP API request
public struct MCPAPIRequest: MCPAPIEndpoint {
    public let path: String
    public let method: String
    public let parameters: [String: AnyCodable]?
    public let headers: [String: String]?
    public let body: Data?
    public let timeout: TimeInterval

    public init(
        path: String,
        method: String = "GET",
        parameters: [String: AnyCodable]? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        timeout: TimeInterval = 30.0
    ) {
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

/// MCP API response
public struct MCPAPIResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let data: T?
    public let error: MCPAPIError?
    public let metadata: MCPResponseMetadata?

    public init(
        success: Bool,
        data: T? = nil,
        error: MCPAPIError? = nil,
        metadata: MCPResponseMetadata? = nil
    ) {
        self.success = success
        self.data = data
        self.error = error
        self.metadata = metadata
    }
}

/// MCP API error
public struct MCPAPIError: Codable, Error {
    public let code: String
    public let message: String
    public let details: [String: AnyCodable]?

    public init(code: String, message: String, details: [String: AnyCodable]? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

/// MCP response metadata
public struct MCPResponseMetadata: Codable {
    public let requestId: String
    public let timestamp: Date
    public let processingTime: TimeInterval
    public let serverVersion: String?

    public init(
        requestId: String = UUID().uuidString,
        timestamp: Date = Date(),
        processingTime: TimeInterval = 0,
        serverVersion: String? = nil
    ) {
        self.requestId = requestId
        self.timestamp = timestamp
        self.processingTime = processingTime
        self.serverVersion = serverVersion
    }
}

/// MCP event types
public enum MCPEventType: String, Codable, Sendable {
    case serviceRegistered
    case serviceUnregistered
    case toolExecuted
    case workflowStarted
    case workflowCompleted
    case errorOccurred
    case healthCheckFailed
    case performanceAlert
}

/// MCP event
public struct MCPEvent: Codable, Sendable {
    public let id: String
    public let type: MCPEventType
    public let source: String
    public let data: [String: AnyCodable]
    public let timestamp: Date
    public let severity: MCPEventSeverity

    public init(
        id: String = UUID().uuidString,
        type: MCPEventType,
        source: String,
        data: [String: AnyCodable] = [:],
        timestamp: Date = Date(),
        severity: MCPEventSeverity = .info
    ) {
        self.id = id
        self.type = type
        self.source = source
        self.data = data
        self.timestamp = timestamp
        self.severity = severity
    }
}

/// MCP event severity
public enum MCPEventSeverity: String, Codable, Sendable {
    case debug
    case info
    case warning
    case error
    case critical
}

/// MCP subscription
public struct MCPSubscription: Sendable {
    public let id: String
    public let eventType: MCPEventType
    public let handler: @Sendable (MCPEvent) -> Void

    public init(
        id: String = UUID().uuidString, eventType: MCPEventType,
        handler: @escaping @Sendable (MCPEvent) -> Void
    ) {
        self.id = id
        self.eventType = eventType
        self.handler = handler
    }
}

/// MCP metric
public struct MCPMetric: Codable, Sendable {
    public let id: String
    public let serviceId: String
    public let name: String
    public let value: Double
    public let unit: String
    public let timestamp: Date
    public let tags: [String: String]

    public init(
        id: String = UUID().uuidString,
        serviceId: String,
        name: String,
        value: Double,
        unit: String = "",
        timestamp: Date = Date(),
        tags: [String: String] = [:]
    ) {
        self.id = id
        self.serviceId = serviceId
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.tags = tags
    }
}

/// MCP health status
public struct MCPHealthStatus: Codable, Sendable {
    public let overall: MCPHealthState
    public let services: [String: MCPHealthState]
    public let timestamp: Date
    public let uptime: TimeInterval

    public init(
        overall: MCPHealthState,
        services: [String: MCPHealthState],
        timestamp: Date = Date(),
        uptime: TimeInterval = 0
    ) {
        self.overall = overall
        self.services = services
        self.timestamp = timestamp
        self.uptime = uptime
    }
}

/// MCP health state
public enum MCPHealthState: String, Codable, Sendable {
    case healthy
    case degraded
    case unhealthy
}

/// MCP health issue
public struct MCPHealthIssue: Codable {
    public let serviceId: String
    public let issue: String
    public let severity: MCPEventSeverity
    public let timestamp: Date

    public init(
        serviceId: String, issue: String, severity: MCPEventSeverity, timestamp: Date = Date()
    ) {
        self.serviceId = serviceId
        self.issue = issue
        self.severity = severity
        self.timestamp = timestamp
    }
}

/// MCP performance summary
public struct MCPPerformanceSummary: Codable, Sendable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageResponseTime: TimeInterval
    public let peakResponseTime: TimeInterval
    public let throughput: Double
    public let errorRate: Double

    public init(
        totalRequests: Int,
        successfulRequests: Int,
        failedRequests: Int,
        averageResponseTime: TimeInterval,
        peakResponseTime: TimeInterval,
        throughput: Double,
        errorRate: Double
    ) {
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageResponseTime = averageResponseTime
        self.peakResponseTime = peakResponseTime
        self.throughput = throughput
        self.errorRate = errorRate
    }
}

/// MCP performance report
public struct MCPPerformanceReport: Codable, Sendable {
    public let timeRange: DateInterval
    public let metrics: [MCPMetricSummary]
    public let summary: MCPPerformanceSummary
    public let recommendations: [String]

    public init(
        timeRange: DateInterval,
        metrics: [MCPMetricSummary],
        summary: MCPPerformanceSummary,
        recommendations: [String] = []
    ) {
        self.timeRange = timeRange
        self.metrics = metrics
        self.summary = summary
        self.recommendations = recommendations
    }
}

/// MCP metric summary
public struct MCPMetricSummary: Codable, Sendable {
    public let name: String
    public let average: Double
    public let min: Double?
    public let max: Double?
    public let count: Int

    public init(
        name: String,
        average: Double,
        min: Double? = nil,
        max: Double? = nil,
        count: Int
    ) {
        self.name = name
        self.average = average
        self.min = min
        self.max = max
        self.count = count
    }
}

/// MCP trend
public enum MCPTrend: String, Codable {
    case improving
    case stable
    case degrading
    case unknown
}

/// MCP bottleneck
public struct MCPBottleneck: Codable {
    public let serviceId: String
    public let metric: String
    public let severity: MCPEventSeverity
    public let description: String

    public init(serviceId: String, metric: String, severity: MCPEventSeverity, description: String)
    {
        self.serviceId = serviceId
        self.metric = metric
        self.severity = severity
        self.description = description
    }
}

// MARK: - MCP API Client Implementation

/// HTTP-based MCP API client
public final class MCPHTTPClient: MCPAPIClient, Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseURL: URL, timeout: TimeInterval = 30.0) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    public func execute<T: Decodable>(_ endpoint: MCPAPIEndpoint) async throws -> T {
        let response: [String: AnyCodable] = try await execute(endpoint)
        guard let success = response["success"]?.value as? Bool, success,
            let dataValue = response["data"]
        else {
            let errorCode =
                (response["error"] as? [String: AnyCodable])?["code"]?.value as? String ?? "unknown"
            let errorMessage =
                (response["error"] as? [String: AnyCodable])?["message"]?.value as? String
                ?? "Unknown error"
            throw MCPAPIError(code: errorCode, message: errorMessage)
        }

        // Decode the data using the generic type
        let data = try JSONEncoder().encode(dataValue.value)
        return try decoder.decode(T.self, from: data)
    }

    public func execute(_ endpoint: MCPAPIEndpoint) async throws -> [String: AnyCodable] {
        let url = baseURL.appendingPathComponent(endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method

        // Add headers
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Add default headers
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Add body if present
        if let body = (endpoint as? MCPAPIRequest)?.body {
            request.httpBody = body
        } else if let parameters = endpoint.parameters {
            request.httpBody = try encoder.encode(parameters)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPAPIError(code: "network_error", message: "Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw MCPAPIError(
                code: "http_\(httpResponse.statusCode)", message: "HTTP \(httpResponse.statusCode)")
        }

        // Decode as AnyCodable dictionary
        let jsonObject = try decoder.decode([String: AnyCodable].self, from: data)
        return jsonObject
    }

    public func stream(_ endpoint: MCPAPIEndpoint) -> AsyncThrowingStream<
        [String: AnyCodable], Error
    > {
        AsyncThrowingStream { continuation in
            Task { @Sendable in
                let localEndpoint = endpoint  // Create local copy to avoid data race
                do {
                    let url = baseURL.appendingPathComponent(localEndpoint.path)

                    var request = URLRequest(url: url)
                    request.httpMethod = localEndpoint.method

                    // Add headers for streaming
                    if let headers = localEndpoint.headers {
                        for (key, value) in headers {
                            request.setValue(value, forHTTPHeaderField: key)
                        }
                    }
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

                    let (bytes, response) = try await session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode)
                    else {
                        throw MCPAPIError(
                            code: "stream_error", message: "Failed to establish stream")
                    }

                    continuation.yield([
                        "status": AnyCodable("connected"), "timestamp": AnyCodable(Date()),
                    ])

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                                let jsonObject = try? decoder.decode(
                                    [String: AnyCodable].self, from: data)
                            {
                                continuation.yield(jsonObject)
                            }
                        }
                    }

                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - MCP Service Discovery Implementation

/// In-memory MCP service discovery
public actor MCPInMemoryServiceDiscovery: MCPServiceDiscovery {
    private var _services: [String: MCPServiceInfo] = [:]

    public init() {}

    public func discoverServices() async throws -> [MCPServiceInfo] {
        return Array(_services.values)
    }

    public func registerService(_ service: MCPServiceInfo) async throws {
        _services[service.id] = service
    }

    public func unregisterService(_ serviceId: String) async throws {
        _services.removeValue(forKey: serviceId)
    }

    public func findService(byId id: String) async -> MCPServiceInfo? {
        return _services[id]
    }

    public func findServices(byCapability capability: MCPToolCapability) async -> [MCPServiceInfo] {
        return _services.values.filter { $0.capabilities.contains(capability) }
    }
}

// MARK: - MCP Event System Implementation

/// In-memory MCP event system
public actor MCPInMemoryEventSystem: @preconcurrency MCPEventSystem {
    private var _subscriptions: [String: MCPSubscription] = [:]

    public init() {}

    public func publish(_ event: MCPEvent) async {
        let subs = Array(_subscriptions.values)

        for subscription in subs where subscription.eventType == event.type {
            subscription.handler(event)
        }
    }

    public func subscribe(
        to eventType: MCPEventType, handler: @escaping @Sendable (MCPEvent) -> Void
    ) -> MCPSubscription {
        let subscription = MCPSubscription(eventType: eventType, handler: handler)
        Task {
            await self._subscriptions[subscription.id] = subscription
        }
        return subscription
    }

    public func unsubscribe(_ subscription: MCPSubscription) async {
        _subscriptions.removeValue(forKey: subscription.id)
    }
}

// MARK: - MCP Metrics System Implementation

/// In-memory MCP metrics system
public actor MCPInMemoryMetricsSystem: MCPMetricsSystem {
    private var _metrics: [MCPMetric] = []

    public init() {}

    public func recordMetric(_ metric: MCPMetric) async {
        _metrics.append(metric)
        // Keep only recent metrics (last 1000)
        if _metrics.count > 1000 {
            _metrics.removeFirst(_metrics.count - 1000)
        }
    }

    public func getMetrics(for serviceId: String, timeRange: DateInterval) async -> [MCPMetric] {
        return _metrics.filter { metric in
            metric.serviceId == serviceId && timeRange.contains(metric.timestamp)
        }
    }

    public func getHealthStatus() async -> MCPHealthStatus {
        let recentMetrics = _metrics.filter { $0.timestamp > Date().addingTimeInterval(-300) }  // Last 5 minutes

        var serviceHealth: [String: MCPHealthState] = [:]
        var issues: [MCPHealthIssue] = []

        // Group metrics by service
        let metricsByService = Dictionary(grouping: recentMetrics) { $0.serviceId }

        for (serviceId, serviceMetrics) in metricsByService {
            let errorMetrics = serviceMetrics.filter { $0.name.contains("error") }
            let errorRate = Double(errorMetrics.count) / Double(serviceMetrics.count)

            if errorRate > 0.5 {
                serviceHealth[serviceId] = .unhealthy
                issues.append(
                    MCPHealthIssue(
                        serviceId: serviceId,
                        issue: "High error rate: \(String(format: "%.1f%%", errorRate * 100))",
                        severity: .error
                    ))
            } else if errorRate > 0.1 {
                serviceHealth[serviceId] = .degraded
                issues.append(
                    MCPHealthIssue(
                        serviceId: serviceId,
                        issue: "Elevated error rate: \(String(format: "%.1f%%", errorRate * 100))",
                        severity: .warning
                    ))
            } else {
                serviceHealth[serviceId] = .healthy
            }
        }

        let overallHealth =
            serviceHealth.values.contains(MCPHealthState.unhealthy)
            ? MCPHealthState.unhealthy
            : serviceHealth.values.contains(MCPHealthState.degraded)
                ? MCPHealthState.degraded : MCPHealthState.healthy

        return MCPHealthStatus(
            overall: overallHealth,
            services: serviceHealth
        )
    }

    public func getPerformanceReport(timeRange: DateInterval) async -> MCPPerformanceReport {
        let relevantMetrics = _metrics.filter { timeRange.contains($0.timestamp) }

        // Calculate metric summaries
        let metricsByName = Dictionary(grouping: relevantMetrics) { $0.name }
        var summaries: [MCPMetricSummary] = []

        for (name, nameMetrics) in metricsByName {
            let values = nameMetrics.map { $0.value }.sorted()
            if values.isEmpty { continue }

            let average = values.reduce(0, +) / Double(values.count)
            let minimum = values.min() ?? 0
            let maximum = values.max() ?? 0
            let percentile95 =
                values.count > 20 ? values[Int(Double(values.count) * 0.95)] : maximum

            // Simple trend calculation
            let trend: MCPTrend
            if nameMetrics.count >= 2 {
                let firstHalf = nameMetrics.prefix(nameMetrics.count / 2).map { $0.value }
                let secondHalf = nameMetrics.suffix(nameMetrics.count / 2).map { $0.value }
                let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
                let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

                if secondAvg > firstAvg * 1.05 {
                    trend = .degrading
                } else if secondAvg < firstAvg * 0.95 {
                    trend = .improving
                } else {
                    trend = .stable
                }
            } else {
                trend = .unknown
            }

            summaries.append(
                MCPMetricSummary(
                    name: name,
                    average: average,
                    min: minimum,
                    max: maximum,
                    count: values.count
                ))
        }

        // Identify bottlenecks (simplified)
        var bottlenecks: [MCPBottleneck] = []
        for summary in summaries where (summary.max ?? 0) > summary.average * 2 {
            bottlenecks.append(
                MCPBottleneck(
                    serviceId: "unknown",  // Would need service mapping
                    metric: summary.name,
                    severity: .warning,
                    description:
                        "High variance in \(summary.name): max \(String(format: "%.2f", summary.max ?? 0)) vs avg \(String(format: "%.2f", summary.average))"
                ))
        }

        // Generate recommendations
        var recommendations: [String] = []
        if bottlenecks.count > 0 {
            recommendations.append("Address performance bottlenecks in high-variance metrics")
        }
        if summaries.isEmpty {
            recommendations.append("Increase metric collection for better performance insights")
        }

        // Create performance summary
        let totalRequests = relevantMetrics.count
        let successfulRequests = relevantMetrics.filter { $0.value >= 0 }.count  // Simplified success criteria
        let failedRequests = totalRequests - successfulRequests
        let responseTimes = relevantMetrics.map { $0.value }
        let averageResponseTime =
            responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        let peakResponseTime = responseTimes.max() ?? 0
        let throughput = Double(totalRequests) / timeRange.duration
        let errorRate = totalRequests > 0 ? Double(failedRequests) / Double(totalRequests) : 0

        let summary = MCPPerformanceSummary(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: failedRequests,
            averageResponseTime: averageResponseTime,
            peakResponseTime: peakResponseTime,
            throughput: throughput,
            errorRate: errorRate
        )

        return MCPPerformanceReport(
            timeRange: timeRange,
            metrics: summaries,
            summary: summary,
            recommendations: recommendations
        )
    }
}

// MARK: - MCP Integration Manager

/// Central MCP integration manager
public final class MCPIntegrationManager: Sendable {
    public let apiClient: MCPAPIClient
    public let serviceDiscovery: MCPServiceDiscovery
    public let eventSystem: MCPEventSystem
    public let metricsSystem: MCPMetricsSystem
    public let orchestrator: EnhancedMCPOrchestrator
    public let securityManager: MCPSecurityManager

    public init(
        baseURL: URL = URL(string: "http://localhost:11434")!,
        securityManager: MCPSecurityManager? = nil
    ) {
        self.apiClient = MCPHTTPClient(baseURL: baseURL)
        self.serviceDiscovery = MCPInMemoryServiceDiscovery()
        self.eventSystem = MCPInMemoryEventSystem()
        self.metricsSystem = MCPInMemoryMetricsSystem()
        self.securityManager = securityManager ?? BasicMCPSecurityManager()
        self.orchestrator = EnhancedMCPOrchestrator(
            securityManager: self.securityManager,
            workflowManager: BasicMCPWorkflowManager()
        )
    }

    /// Register an MCP tool
    public func registerTool(_ tool: any MCPTool) async throws {
        try await orchestrator.registerTool(tool)

        // Register as a service
        let toolId = await tool.id
        let toolInfo = await orchestrator.getToolInfo(toolId)!
        let serviceInfo = MCPServiceInfo(
            id: toolInfo.id,
            name: toolInfo.name,
            description: toolInfo.description,
            endpoint: "/tools/\(toolInfo.id)",
            capabilities: toolInfo.capabilities
        )

        try await serviceDiscovery.registerService(serviceInfo)

        // Publish registration event
        await eventSystem.publish(
            MCPEvent(
                type: .serviceRegistered,
                source: "MCPIntegrationManager",
                data: ["service_id": AnyCodable(serviceInfo.id)]
            ))
    }

    /// Execute a tool by ID
    public func executeTool(_ toolId: String, parameters: [String: AnyCodable]) async throws
        -> MCPToolResult
    {
        let startTime = Date()

        do {
            let result = try await orchestrator.executeTool(toolId, with: parameters)
            let executionTime = Date().timeIntervalSince(startTime)

            // Record metrics
            await metricsSystem.recordMetric(
                MCPMetric(
                    serviceId: toolId,
                    name: "execution_time",
                    value: executionTime,
                    unit: "seconds"
                ))

            await metricsSystem.recordMetric(
                MCPMetric(
                    serviceId: toolId,
                    name: "execution_success",
                    value: 1.0,
                    unit: "count"
                ))

            // Publish execution event
            await eventSystem.publish(
                MCPEvent(
                    type: .toolExecuted,
                    source: "MCPIntegrationManager",
                    data: [
                        "tool_id": AnyCodable(toolId),
                        "success": AnyCodable(result.success),
                        "execution_time": AnyCodable(executionTime),
                    ]
                ))

            return result

        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            // Record error metrics
            await metricsSystem.recordMetric(
                MCPMetric(
                    serviceId: toolId,
                    name: "execution_error",
                    value: 1.0,
                    unit: "count"
                ))

            // Publish error event
            await eventSystem.publish(
                MCPEvent(
                    type: .errorOccurred,
                    source: "MCPIntegrationManager",
                    data: [
                        "tool_id": AnyCodable(toolId),
                        "error": AnyCodable(error.localizedDescription),
                        "execution_time": AnyCodable(executionTime),
                    ],
                    severity: .error
                ))

            throw error
        }
    }

    /// Get system health status
    public func getHealthStatus() async -> MCPHealthStatus {
        await metricsSystem.getHealthStatus()
    }

    /// Get performance report
    public func getPerformanceReport(timeRange: DateInterval) async -> MCPPerformanceReport {
        await metricsSystem.getPerformanceReport(timeRange: timeRange)
    }

    /// Discover available services
    public func discoverServices() async throws -> [MCPServiceInfo] {
        try await serviceDiscovery.discoverServices()
    }

    /// Subscribe to events
    public func subscribeToEvents(
        _ eventType: MCPEventType, handler: @escaping @Sendable (MCPEvent) -> Void
    )
        -> MCPSubscription
    {
        eventSystem.subscribe(to: eventType, handler: handler)
    }

    /// Unsubscribe from events
    public func unsubscribeFromEvents(_ subscription: MCPSubscription) async {
        await eventSystem.unsubscribe(subscription)
    }
}

// MARK: - Convenience Extensions

extension MCPIntegrationManager {
    /// Register multiple tools at once
    public func registerTools(_ tools: [any MCPTool]) async throws {
        for tool in tools {
            try await registerTool(tool)
        }
    }

    /// Execute a workflow
    public func executeWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult {
        try await orchestrator.orchestrateWorkflow(workflow)
    }

    /// Get tool information
    public func getToolInfo(_ toolId: String) async -> MCPToolInfo? {
        await orchestrator.getToolInfo(toolId)
    }

    /// List all available tools
    public func listAvailableTools() async -> [MCPToolInfo] {
        await orchestrator.listAvailableTools()
    }
}
