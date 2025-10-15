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
public protocol MCPAPIEndpoint {
    var path: String { get }
    var method: String { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
}

/// Protocol for MCP API client
public protocol MCPAPIClient {
    func execute<T: Decodable>(_ endpoint: MCPAPIEndpoint) async throws -> T
    func execute(_ endpoint: MCPAPIEndpoint) async throws -> [String: Any]
    func stream(_ endpoint: MCPAPIEndpoint) -> AsyncThrowingStream<[String: Any], Error>
}

/// Protocol for MCP service discovery
public protocol MCPServiceDiscovery {
    func discoverServices() async throws -> [MCPServiceInfo]
    func registerService(_ service: MCPServiceInfo) async throws
    func unregisterService(_ serviceId: String) async throws
    func findService(byId id: String) async -> MCPServiceInfo?
    func findServices(byCapability capability: MCPToolCapability) async -> [MCPServiceInfo]
}

/// Protocol for MCP event system
public protocol MCPEventSystem {
    func publish(_ event: MCPEvent) async
    func subscribe(to eventType: MCPEventType, handler: @escaping (MCPEvent) -> Void)
        -> MCPSubscription
    func unsubscribe(_ subscription: MCPSubscription) async
}

/// Protocol for MCP metrics and monitoring
public protocol MCPMetricsSystem {
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
public enum MCPEventType: String, Codable {
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
public struct MCPEvent: Codable {
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
public enum MCPEventSeverity: String, Codable {
    case debug
    case info
    case warning
    case error
    case critical
}

/// MCP subscription
public struct MCPSubscription {
    public let id: String
    public let eventType: MCPEventType
    public let handler: (MCPEvent) -> Void

    public init(
        id: String = UUID().uuidString, eventType: MCPEventType,
        handler: @escaping (MCPEvent) -> Void
    ) {
        self.id = id
        self.eventType = eventType
        self.handler = handler
    }
}

/// MCP metric
public struct MCPMetric: Codable {
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
public struct MCPHealthStatus: Codable {
    public let overall: MCPHealthState
    public let services: [String: MCPHealthState]
    public let lastChecked: Date
    public let issues: [MCPHealthIssue]

    public init(
        overall: MCPHealthState,
        services: [String: MCPHealthState] = [:],
        lastChecked: Date = Date(),
        issues: [MCPHealthIssue] = []
    ) {
        self.overall = overall
        self.services = services
        self.lastChecked = lastChecked
        self.issues = issues
    }
}

/// MCP health state
public enum MCPHealthState: String, Codable {
    case healthy
    case degraded
    case unhealthy
    case unknown
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

/// MCP performance report
public struct MCPPerformanceReport: Codable {
    public let timeRange: DateInterval
    public let metrics: [MCPMetricSummary]
    public let bottlenecks: [MCPBottleneck]
    public let recommendations: [String]

    public init(
        timeRange: DateInterval,
        metrics: [MCPMetricSummary] = [],
        bottlenecks: [MCPBottleneck] = [],
        recommendations: [String] = []
    ) {
        self.timeRange = timeRange
        self.metrics = metrics
        self.bottlenecks = bottlenecks
        self.recommendations = recommendations
    }
}

/// MCP metric summary
public struct MCPMetricSummary: Codable {
    public let name: String
    public let average: Double
    public let minimum: Double
    public let maximum: Double
    public let percentile95: Double
    public let trend: MCPTrend

    public init(
        name: String,
        average: Double,
        minimum: Double,
        maximum: Double,
        percentile95: Double,
        trend: MCPTrend
    ) {
        self.name = name
        self.average = average
        self.minimum = minimum
        self.maximum = maximum
        self.percentile95 = percentile95
        self.trend = trend
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
public final class MCPHTTPClient: MCPAPIClient {
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
        let response: MCPAPIResponse<T> = try await execute(endpoint)
        guard response.success, let data = response.data else {
            throw MCPAPIError(
                code: response.error?.code ?? "unknown",
                message: response.error?.message ?? "Unknown error")
        }
        return data
    }

    public func execute(_ endpoint: MCPAPIEndpoint) async throws -> [String: Any] {
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

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return jsonObject ?? [:]
    }

    public func stream(_ endpoint: MCPAPIEndpoint) -> AsyncThrowingStream<[String: Any], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = baseURL.appendingPathComponent(endpoint.path)

                    var request = URLRequest(url: url)
                    request.httpMethod = endpoint.method

                    // Add headers for streaming
                    if let headers = endpoint.headers {
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

                    continuation.yield(["status": "connected", "timestamp": Date()])

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                                let jsonObject = try? JSONSerialization.jsonObject(with: data)
                                    as? [String: Any]
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
public final class MCPInMemoryServiceDiscovery: MCPServiceDiscovery {
    private var services: [String: MCPServiceInfo] = [:]
    private let queue = DispatchQueue(label: "mcp.service.discovery", attributes: .concurrent)

    public init() {}

    public func discoverServices() async throws -> [MCPServiceInfo] {
        queue.sync { Array(services.values) }
    }

    public func registerService(_ service: MCPServiceInfo) async throws {
        queue.async(flags: .barrier) {
            self.services[service.id] = service
        }
    }

    public func unregisterService(_ serviceId: String) async throws {
        queue.async(flags: .barrier) {
            self.services.removeValue(forKey: serviceId)
        }
    }

    public func findService(byId id: String) async -> MCPServiceInfo? {
        queue.sync { services[id] }
    }

    public func findServices(byCapability capability: MCPToolCapability) async -> [MCPServiceInfo] {
        queue.sync {
            services.values.filter { $0.capabilities.contains(capability) }
        }
    }
}

// MARK: - MCP Event System Implementation

/// In-memory MCP event system
public final class MCPInMemoryEventSystem: MCPEventSystem {
    private var subscriptions: [String: MCPSubscription] = [:]
    private let queue = DispatchQueue(label: "mcp.event.system", attributes: .concurrent)

    public init() {}

    public func publish(_ event: MCPEvent) async {
        let subs = queue.sync { Array(subscriptions.values) }
        for subscription in subs where subscription.eventType == event.type {
            subscription.handler(event)
        }
    }

    public func subscribe(to eventType: MCPEventType, handler: @escaping (MCPEvent) -> Void)
        -> MCPSubscription
    {
        let subscription = MCPSubscription(eventType: eventType, handler: handler)
        queue.async(flags: .barrier) {
            self.subscriptions[subscription.id] = subscription
        }
        return subscription
    }

    public func unsubscribe(_ subscription: MCPSubscription) async {
        queue.async(flags: .barrier) {
            self.subscriptions.removeValue(forKey: subscription.id)
        }
    }
}

// MARK: - MCP Metrics System Implementation

/// In-memory MCP metrics system
public final class MCPInMemoryMetricsSystem: MCPMetricsSystem {
    private var metrics: [MCPMetric] = []
    private let queue = DispatchQueue(label: "mcp.metrics.system", attributes: .concurrent)

    public init() {}

    public func recordMetric(_ metric: MCPMetric) async {
        queue.async(flags: .barrier) {
            self.metrics.append(metric)
            // Keep only recent metrics (last 1000)
            if self.metrics.count > 1000 {
                self.metrics.removeFirst(self.metrics.count - 1000)
            }
        }
    }

    public func getMetrics(for serviceId: String, timeRange: DateInterval) async -> [MCPMetric] {
        queue.sync {
            metrics.filter { metric in
                metric.serviceId == serviceId && timeRange.contains(metric.timestamp)
            }
        }
    }

    public func getHealthStatus() async -> MCPHealthStatus {
        let recentMetrics = queue.sync {
            metrics.filter { $0.timestamp > Date().addingTimeInterval(-300) }  // Last 5 minutes
        }

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
            serviceHealth.values.contains(.unhealthy)
            ? .unhealthy : serviceHealth.values.contains(.degraded) ? .degraded : .healthy

        return MCPHealthStatus(
            overall: overallHealth,
            services: serviceHealth,
            issues: issues
        )
    }

    public func getPerformanceReport(timeRange: DateInterval) async -> MCPPerformanceReport {
        let relevantMetrics = queue.sync {
            metrics.filter { timeRange.contains($0.timestamp) }
        }

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
                    minimum: minimum,
                    maximum: maximum,
                    percentile95: percentile95,
                    trend: trend
                ))
        }

        // Identify bottlenecks (simplified)
        var bottlenecks: [MCPBottleneck] = []
        for summary in summaries where summary.maximum > summary.average * 2 {
            bottlenecks.append(
                MCPBottleneck(
                    serviceId: "unknown",  // Would need service mapping
                    metric: summary.name,
                    severity: .warning,
                    description:
                        "High variance in \(summary.name): max \(String(format: "%.2f", summary.maximum)) vs avg \(String(format: "%.2f", summary.average))"
                ))
        }

        // Generate recommendations
        var recommendations: [String] = []
        if bottlenecks.count > 0 {
            recommendations.append("Address performance bottlenecks in high-variance metrics")
        }
        if summaries.contains(where: { $0.trend == .degrading }) {
            recommendations.append("Investigate degrading performance trends")
        }
        if summaries.isEmpty {
            recommendations.append("Increase metric collection for better performance insights")
        }

        return MCPPerformanceReport(
            timeRange: timeRange,
            metrics: summaries,
            bottlenecks: bottlenecks,
            recommendations: recommendations
        )
    }
}

// MARK: - MCP Integration Manager

/// Central MCP integration manager
public final class MCPIntegrationManager {
    public let apiClient: MCPAPIClient
    public let serviceDiscovery: MCPServiceDiscovery
    public let eventSystem: MCPEventSystem
    public let metricsSystem: MCPMetricsSystem
    public let orchestrator: EnhancedMCPOrchestrator
    public let securityManager: MCPSecurityManager

    private var registeredTools: [any MCPTool] = []

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
        registeredTools.append(tool)

        // Register as a service
        let toolInfo = await orchestrator.getToolInfo(await tool.id())!
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
                data: ["service_id": .init(serviceInfo.id)]
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
                        "tool_id": .init(toolId),
                        "success": .init(result.success),
                        "execution_time": .init(executionTime),
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
                        "tool_id": .init(toolId),
                        "error": .init(error.localizedDescription),
                        "execution_time": .init(executionTime),
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
    public func subscribeToEvents(_ eventType: MCPEventType, handler: @escaping (MCPEvent) -> Void)
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
