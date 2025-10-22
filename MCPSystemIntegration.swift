//
//  MCPSystemIntegration.swift
//  Quantum-workspace
//
//  Created: Phase 9C - Enhanced MCP Systems
//  Purpose: Complete MCP System Integration for Universal Agent Era
//

import Combine
import Foundation

// MARK: - MCP System Integration

/// Protocol for MCP system integration
public protocol MCPSystemIntegration {
    func initializeSystem() async throws
    func shutdownSystem() async throws
    func getSystemStatus() async -> MCPSystemStatus
    func registerComponent(_ component: MCPSystemComponent) async throws
    func unregisterComponent(_ componentId: String) async throws
    func getComponent(_ componentId: String) async -> MCPSystemComponent?
    func listComponents() async -> [MCPSystemComponent]
}

/// Protocol for MCP system component
@preconcurrency public protocol MCPSystemComponent: AnyObject, Sendable {
    var id: String { get }
    var name: String { get }
    var type: MCPComponentType { get }
    var version: String { get }
    var dependencies: [String] { get }
    var status: MCPComponentStatus { get set }

    func initialize() async throws
    func shutdown() async throws
    func healthCheck() async -> MCPComponentHealth
}

/// MCP component type
public enum MCPComponentType: String, Codable, Sendable {
    case orchestrator
    case tool
    case workflow
    case security
    case monitoring
    case api
    case scheduler
    case optimizer
    case integration
}

/// MCP component status
public enum MCPComponentStatus: String, Codable, Sendable {
    case uninitialized
    case initializing
    case ready
    case running
    case stopping
    case stopped
    case error
}

/// MCP component health
public struct MCPComponentHealth: Sendable {
    public let status: MCPComponentHealthStatus
    public let message: String?
    public let lastChecked: Date
    public let metrics: [String: Double]

    public init(
        status: MCPComponentHealthStatus,
        message: String? = nil,
        lastChecked: Date = Date(),
        metrics: [String: Double] = [:]
    ) {
        self.status = status
        self.message = message
        self.lastChecked = lastChecked
        self.metrics = metrics
    }
}

/// MCP component health status
public enum MCPComponentHealthStatus: String, Codable, Sendable {
    case healthy
    case degraded
    case unhealthy
    case unknown
}

/// MCP system status
public struct MCPSystemStatus: Sendable {
    public let overallHealth: MCPComponentHealthStatus
    public let components: [String: MCPComponentHealth]
    public let systemStartTime: Date
    public let lastHealthCheck: Date
    public let activeComponents: Int
    public let totalComponents: Int

    public init(
        overallHealth: MCPComponentHealthStatus,
        components: [String: MCPComponentHealth],
        systemStartTime: Date,
        lastHealthCheck: Date,
        activeComponents: Int,
        totalComponents: Int
    ) {
        self.overallHealth = overallHealth
        self.components = components
        self.systemStartTime = systemStartTime
        self.lastHealthCheck = lastHealthCheck
        self.activeComponents = activeComponents
        self.totalComponents = totalComponents
    }
}

/// MCP system configuration
public struct MCPSystemConfiguration: Sendable {
    public let maxConcurrentWorkflows: Int
    public let maxToolExecutionTime: TimeInterval
    public let enableMetrics: Bool
    public let enableSecurity: Bool
    public let enableCaching: Bool
    public let cacheExpirationTime: TimeInterval
    public let logLevel: MCPLogLevel
    public let monitoringInterval: TimeInterval

    public init(
        maxConcurrentWorkflows: Int = 10,
        maxToolExecutionTime: TimeInterval = 300,
        enableMetrics: Bool = true,
        enableSecurity: Bool = true,
        enableCaching: Bool = true,
        cacheExpirationTime: TimeInterval = 3600,
        logLevel: MCPLogLevel = .info,
        monitoringInterval: TimeInterval = 60
    ) {
        self.maxConcurrentWorkflows = maxConcurrentWorkflows
        self.maxToolExecutionTime = maxToolExecutionTime
        self.enableMetrics = enableMetrics
        self.enableSecurity = enableSecurity
        self.enableCaching = enableCaching
        self.cacheExpirationTime = cacheExpirationTime
        self.logLevel = logLevel
        self.monitoringInterval = monitoringInterval
    }
}

/// MCP log level
public enum MCPLogLevel: String, Codable, Sendable {
    case debug
    case info
    case warning
    case error
    case critical
}

/// MCP system event
public struct MCPSystemEvent: Sendable {
    public let id: String
    public let type: MCPSystemEventType
    public let componentId: String
    public let message: String
    public let data: [String: AnyCodable]?
    public let timestamp: Date
    public let severity: MCPEventSeverity

    public init(
        id: String = UUID().uuidString,
        type: MCPSystemEventType,
        componentId: String,
        message: String,
        data: [String: AnyCodable]? = nil,
        timestamp: Date = Date(),
        severity: MCPEventSeverity = .info
    ) {
        self.id = id
        self.type = type
        self.componentId = componentId
        self.message = message
        self.data = data
        self.timestamp = timestamp
        self.severity = severity
    }
}

/// MCP system event type
public enum MCPSystemEventType: String, Codable, Sendable {
    case systemStarted
    case systemStopped
    case componentRegistered
    case componentUnregistered
    case componentHealthChanged
    case workflowExecuted
    case toolExecuted
    case errorOccurred
    case securityAlert
    case performanceAlert
}

/// MCP system metrics
public struct MCPSystemMetrics: Sendable {
    public let activeWorkflows: Int
    public let totalWorkflowsExecuted: Int
    public let averageWorkflowExecutionTime: TimeInterval
    public let activeTools: Int
    public let totalToolExecutions: Int
    public let averageToolExecutionTime: TimeInterval
    public let systemUptime: TimeInterval
    public let memoryUsage: Double
    public let cpuUsage: Double
    public let errorRate: Double

    public init(
        activeWorkflows: Int = 0,
        totalWorkflowsExecuted: Int = 0,
        averageWorkflowExecutionTime: TimeInterval = 0,
        activeTools: Int = 0,
        totalToolExecutions: Int = 0,
        averageToolExecutionTime: TimeInterval = 0,
        systemUptime: TimeInterval = 0,
        memoryUsage: Double = 0,
        cpuUsage: Double = 0,
        errorRate: Double = 0
    ) {
        self.activeWorkflows = activeWorkflows
        self.totalWorkflowsExecuted = totalWorkflowsExecuted
        self.averageWorkflowExecutionTime = averageWorkflowExecutionTime
        self.activeTools = activeTools
        self.totalToolExecutions = totalToolExecutions
        self.averageToolExecutionTime = averageToolExecutionTime
        self.systemUptime = systemUptime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.errorRate = errorRate
    }
}

// MARK: - MCP System Integration Implementation

/// Complete MCP system integration
public actor MCPCompleteSystemIntegration: MCPSystemIntegration {
    public let configuration: MCPSystemConfiguration
    public let integrationManager: MCPIntegrationManager
    public let workflowOrchestrator: AdvancedMCPWorkflowOrchestrator
    public let workflowScheduler: BasicMCPWorkflowScheduler
    public let workflowMonitor: BasicMCPWorkflowMonitor
    public let workflowOptimizer: BasicMCPWorkflowOptimizer

    private var _components: [String: MCPSystemComponent] = [:]
    private var _systemStartTime: Date?
    private var _isRunning = false
    private var _monitoringTask: Task<Void, Never>?

    public init(configuration: MCPSystemConfiguration = MCPSystemConfiguration()) {
        self.configuration = configuration

        // Initialize core components
        let securityManager = BasicMCPSecurityManager()
        let orchestrator = EnhancedMCPOrchestrator(
            securityManager: securityManager,
            workflowManager: BasicMCPWorkflowManager()
        )

        self.integrationManager = MCPIntegrationManager(securityManager: securityManager)
        self.workflowOrchestrator = AdvancedMCPWorkflowOrchestrator(
            orchestrator: orchestrator,
            securityManager: securityManager
        )
        self.workflowScheduler = BasicMCPWorkflowScheduler(orchestrator: workflowOrchestrator)
        self.workflowMonitor = BasicMCPWorkflowMonitor()
        self.workflowOptimizer = BasicMCPWorkflowOptimizer()
    }

    public func initializeSystem() async throws {
        guard !_isRunning else { return }

        _systemStartTime = Date()
        _isRunning = true

        // Initialize core components
        try await initializeCoreComponents()

        // Start monitoring
        startMonitoring()

        // Publish system start event
        await publishSystemEvent(
            MCPSystemEvent(
                type: .systemStarted,
                componentId: "system",
                message: "MCP System initialized successfully",
                data: ["version": .init("9.0.0")]
            ))
    }

    public func shutdownSystem() async throws {
        guard _isRunning else { return }

        _isRunning = false
        let taskToCancel = _monitoringTask
        _monitoringTask = nil
        let currentComponents = _components
        _components = [:]

        // Stop monitoring
        taskToCancel?.cancel()

        // Shutdown all components
        for component in currentComponents.values {
            do {
                try await component.shutdown()
            } catch {
                print("Error shutting down component \(component.id): \(error)")
            }
        }

        // Publish system stop event
        await publishSystemEvent(
            MCPSystemEvent(
                type: .systemStopped,
                componentId: "system",
                message: "MCP System shut down successfully"
            ))
    }

    public func getSystemStatus() async -> MCPSystemStatus {
        let componentHealth = await getAllComponentHealth()
        let overallHealth = calculateOverallHealth(componentHealth)
        let activeComponents = componentHealth.values.filter { $0.status == .healthy }.count
        let totalComponents = componentHealth.count

        return MCPSystemStatus(
            overallHealth: overallHealth,
            components: componentHealth,
            systemStartTime: _systemStartTime ?? Date(),
            lastHealthCheck: Date(),
            activeComponents: activeComponents,
            totalComponents: totalComponents
        )
    }

    public func registerComponent(_ component: MCPSystemComponent) async throws {
        try await component.initialize()

        _components[component.id] = component

        await publishSystemEvent(
            MCPSystemEvent(
                type: .componentRegistered,
                componentId: component.id,
                message: "Component \(component.name) registered successfully",
                data: ["type": .init(component.type.rawValue)]
            ))
    }

    public func unregisterComponent(_ componentId: String) async throws {
        guard let component = _components[componentId] else {
            throw MCPSystemError.componentNotFound(componentId)
        }
        _components.removeValue(forKey: componentId)

        try await component.shutdown()

        await publishSystemEvent(
            MCPSystemEvent(
                type: .componentUnregistered,
                componentId: componentId,
                message: "Component \(component.name) unregistered successfully"
            ))
    }

    public func getComponent(_ componentId: String) async -> MCPSystemComponent? {
        return _components[componentId]
    }

    public func listComponents() async -> [MCPSystemComponent] {
        return Array(_components.values)
    }

    // MARK: - Private Methods

    private func initializeCoreComponents() async throws {
        // Register core system components
        let coreComponents: [MCPSystemComponent] = [
            MCPOrchestratorComponent(orchestrator: workflowOrchestrator),
            MCPSchedulerComponent(scheduler: workflowScheduler),
            MCPMonitorComponent(monitor: workflowMonitor),
            MCPOptimizerComponent(optimizer: workflowOptimizer),
            MCPIntegrationComponent(integration: integrationManager),
        ]

        for component in coreComponents {
            try await registerComponent(component)
        }
    }

    private func startMonitoring() {
        let task = Task {
            while !Task.isCancelled {
                guard _isRunning else { break }

                do {
                    // Perform health checks
                    await performHealthChecks()

                    // Collect metrics
                    await collectSystemMetrics()

                    // Wait for next monitoring interval
                    try await Task.sleep(
                        nanoseconds: UInt64(configuration.monitoringInterval * 1_000_000_000))
                } catch {
                    if !Task.isCancelled {
                        await publishSystemEvent(
                            MCPSystemEvent(
                                type: .errorOccurred,
                                componentId: "system",
                                message: "Monitoring error: \(error.localizedDescription)",
                                severity: .error
                            ))
                    }
                }
            }
        }

        _monitoringTask = task
    }

    private func performHealthChecks() async {
        for component in await listComponents() {
            do {
                let health = await component.healthCheck()

                // Check if health changed
                let previousStatus = component.status
                if health.status != .healthy && previousStatus != .error {
                    await publishSystemEvent(
                        MCPSystemEvent(
                            type: .componentHealthChanged,
                            componentId: component.id,
                            message: "Component health changed to \(health.status)",
                            data: ["previous_status": .init(previousStatus.rawValue)],
                            severity: health.status == .unhealthy ? .error : .warning
                        ))
                }

                // Update component status
                component.status = health.status == .healthy ? .running : .error

            } catch {
                await publishSystemEvent(
                    MCPSystemEvent(
                        type: .errorOccurred,
                        componentId: component.id,
                        message: "Health check failed: \(error.localizedDescription)",
                        severity: .error
                    ))
            }
        }
    }

    private func collectSystemMetrics() async {
        // This would collect actual system metrics
        // For now, we'll use placeholder values
        let uptime = abs(_systemStartTime?.timeIntervalSinceNow ?? 0)

        let metrics = MCPSystemMetrics(
            systemUptime: uptime
        )

        // Store metrics for monitoring
        _ = metrics
    }

    private func getAllComponentHealth() async -> [String: MCPComponentHealth] {
        let components = await listComponents()
        var healthMap: [String: MCPComponentHealth] = [:]

        for component in components {
            do {
                let health = await component.healthCheck()
                healthMap[component.id] = health
            } catch {
                healthMap[component.id] = MCPComponentHealth(
                    status: .unhealthy,
                    message: error.localizedDescription
                )
            }
        }

        return healthMap
    }

    private func calculateOverallHealth(_ componentHealth: [String: MCPComponentHealth])
        -> MCPComponentHealthStatus
    {
        let statuses = componentHealth.values.map { $0.status }

        if statuses.contains(.unhealthy) {
            return .unhealthy
        } else if statuses.contains(.degraded) {
            return .degraded
        } else if statuses.allSatisfy({ $0 == .healthy }) {
            return .healthy
        } else {
            return .unknown
        }
    }

    private func publishSystemEvent(_ event: MCPSystemEvent) async {
        // Publish to integration manager's event system
        await integrationManager.eventSystem.publish(
            MCPEvent(
                id: event.id,
                type: .serviceRegistered,  // Map to existing event type
                source: event.componentId,
                data: event.data ?? [:],
                severity: event.severity
            ))
    }
}

// MARK: - MCP System Components

/// MCP orchestrator component
public final class MCPOrchestratorComponent: MCPSystemComponent {
    public let id = "orchestrator"
    public let name = "Workflow Orchestrator"
    public let type = MCPComponentType.orchestrator
    public let version = "9.0.0"
    public let dependencies: [String] = ["security", "workflow_manager"]

    private var _status: MCPComponentStatus = .uninitialized
    private let statusLock = NSLock()

    public var status: MCPComponentStatus {
        get {
            statusLock.lock()
            defer { statusLock.unlock() }
            return _status
        }
        set {
            statusLock.lock()
            defer { statusLock.unlock() }
            _status = newValue
        }
    }

    private let orchestrator: AdvancedMCPWorkflowOrchestrator

    public init(orchestrator: AdvancedMCPWorkflowOrchestrator) {
        self.orchestrator = orchestrator
    }

    public func initialize() async throws {
        status = .ready
    }

    public func shutdown() async throws {
        status = .stopped
    }

    public func healthCheck() async -> MCPComponentHealth {
        // Simple health check - in real implementation, would check actual orchestrator state
        return MCPComponentHealth(status: .healthy, message: "Orchestrator operational")
    }
}

/// MCP scheduler component
public final class MCPSchedulerComponent: MCPSystemComponent {
    public let id = "scheduler"
    public let name = "Workflow Scheduler"
    public let type = MCPComponentType.scheduler
    public let version = "9.0.0"
    public let dependencies: [String] = ["orchestrator"]

    private var _status: MCPComponentStatus = .uninitialized
    private let statusLock = NSLock()

    public var status: MCPComponentStatus {
        get {
            statusLock.lock()
            defer { statusLock.unlock() }
            return _status
        }
        set {
            statusLock.lock()
            defer { statusLock.unlock() }
            _status = newValue
        }
    }

    private let scheduler: BasicMCPWorkflowScheduler

    public init(scheduler: BasicMCPWorkflowScheduler) {
        self.scheduler = scheduler
    }

    public func initialize() async throws {
        status = .ready
    }

    public func shutdown() async throws {
        status = .stopped
    }

    public func healthCheck() async -> MCPComponentHealth {
        return MCPComponentHealth(status: .healthy, message: "Scheduler operational")
    }
}

/// MCP monitor component
public final class MCPMonitorComponent: MCPSystemComponent {
    public let id = "monitor"
    public let name = "Workflow Monitor"
    public let type = MCPComponentType.monitoring
    public let version = "9.0.0"
    public let dependencies: [String] = []

    private var _status: MCPComponentStatus = .uninitialized
    private let statusLock = NSLock()

    public var status: MCPComponentStatus {
        get {
            statusLock.lock()
            defer { statusLock.unlock() }
            return _status
        }
        set {
            statusLock.lock()
            defer { statusLock.unlock() }
            _status = newValue
        }
    }

    private let monitor: BasicMCPWorkflowMonitor

    public init(monitor: BasicMCPWorkflowMonitor) {
        self.monitor = monitor
    }

    public func initialize() async throws {
        status = .ready
    }

    public func shutdown() async throws {
        status = .stopped
    }

    public func healthCheck() async -> MCPComponentHealth {
        return MCPComponentHealth(status: .healthy, message: "Monitor operational")
    }
}

/// MCP optimizer component
public final class MCPOptimizerComponent: MCPSystemComponent {
    public let id = "optimizer"
    public let name = "Workflow Optimizer"
    public let type = MCPComponentType.optimizer
    public let version = "9.0.0"
    public let dependencies: [String] = []

    private var _status: MCPComponentStatus = .uninitialized
    private let statusLock = NSLock()

    public var status: MCPComponentStatus {
        get {
            statusLock.lock()
            defer { statusLock.unlock() }
            return _status
        }
        set {
            statusLock.lock()
            defer { statusLock.unlock() }
            _status = newValue
        }
    }

    private let optimizer: BasicMCPWorkflowOptimizer

    public init(optimizer: BasicMCPWorkflowOptimizer) {
        self.optimizer = optimizer
    }

    public func initialize() async throws {
        status = .ready
    }

    public func shutdown() async throws {
        status = .stopped
    }

    public func healthCheck() async -> MCPComponentHealth {
        return MCPComponentHealth(status: .healthy, message: "Optimizer operational")
    }
}

/// MCP integration component
public final class MCPIntegrationComponent: MCPSystemComponent {
    public let id = "integration"
    public let name = "System Integration"
    public let type = MCPComponentType.integration
    public let version = "9.0.0"
    public let dependencies: [String] = []

    private var _status: MCPComponentStatus = .uninitialized
    private let statusLock = NSLock()

    public var status: MCPComponentStatus {
        get {
            statusLock.lock()
            defer { statusLock.unlock() }
            return _status
        }
        set {
            statusLock.lock()
            defer { statusLock.unlock() }
            _status = newValue
        }
    }

    private let integration: MCPIntegrationManager

    public init(integration: MCPIntegrationManager) {
        self.integration = integration
    }

    public func initialize() async throws {
        status = .ready
    }

    public func shutdown() async throws {
        status = .stopped
    }

    public func healthCheck() async -> MCPComponentHealth {
        return MCPComponentHealth(status: .healthy, message: "Integration operational")
    }
}

// MARK: - MCP System Error

/// MCP system error
public enum MCPSystemError: Error {
    case componentNotFound(String)
    case componentAlreadyExists(String)
    case systemNotInitialized
    case systemAlreadyRunning
    case invalidConfiguration(String)
}

// MARK: - Convenience Extensions

extension MCPCompleteSystemIntegration {
    /// Execute a workflow with full system integration
    public func executeWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult {
        let result = try await workflowOrchestrator.orchestrateWorkflow(workflow)

        // Record execution in monitor
        let execution = MCPWorkflowExecution(
            executionId: UUID().uuidString,
            workflowId: workflow.id,
            startTime: Date().addingTimeInterval(-result.executionTime),
            endTime: Date(),
            state: result.success ? .completed : .failed,
            result: result
        )
        workflowMonitor.recordExecution(execution)

        return result
    }

    /// Get comprehensive system metrics
    public func getSystemMetrics() async -> MCPSystemMetrics {
        let status = await getSystemStatus()
        let workflowMetrics = await workflowMonitor.getWorkflowMetrics(
            timeRange: DateInterval(start: Date().addingTimeInterval(-3600), end: Date())
        )
        let uptime = abs(_systemStartTime?.timeIntervalSinceNow ?? 0)

        return MCPSystemMetrics(
            totalWorkflowsExecuted: workflowMetrics.totalExecutions,
            averageWorkflowExecutionTime: workflowMetrics.averageExecutionTime,
            systemUptime: uptime
        )
    }

    /// Optimize and execute workflow
    public nonisolated func optimizeAndExecuteWorkflow(_ workflow: MCPWorkflow) async throws
        -> MCPWorkflowResult
    {
        let optimization = try await workflowOptimizer.optimizeWorkflow(workflow)
        return try await executeWorkflow(optimization.optimizedWorkflow)
    }

    /// Schedule optimized workflow
    public nonisolated func scheduleOptimizedWorkflow(
        _ workflow: MCPWorkflow, schedule: MCPWorkflowSchedule
    )
        async throws -> String
    {
        let optimization = try await workflowOptimizer.optimizeWorkflow(workflow)
        return try await workflowScheduler.scheduleRecurringWorkflow(
            optimization.optimizedWorkflow, schedule: schedule)
    }
}

// MARK: - Global System Instance

/// Global MCP system instance
@MainActor
public let mcpSystem = MCPCompleteSystemIntegration()

/// Convenience function to initialize the MCP system
public func initializeMCPSystem(configuration: MCPSystemConfiguration = MCPSystemConfiguration())
    async throws
{
    try await mcpSystem.initializeSystem()
}

/// Convenience function to get system status
public func getMCPSystemStatus() async -> MCPSystemStatus {
    await mcpSystem.getSystemStatus()
}

/// Convenience function to execute workflow
public func executeMCPWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult {
    try await mcpSystem.executeWorkflow(workflow)
}
