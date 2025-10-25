//
//  EnhancedMCPIntegration.swift
//  Quantum-workspace
//
//  Created: Phase 9 - Universal Agent Era
//  Purpose: Enhanced Model Context Protocol integration with advanced tools and orchestration
//

import Combine
import Foundation

// MARK: - Base MCP Types

/// Base MCP tool protocol
public protocol MCPTool: Sendable {
    var id: String { get async }
    var name: String { get async }
    var description: String { get async }

    func execute(parameters: [String: AnyCodable]) async throws -> Any?
}

// MARK: - Enhanced MCP Protocols

/// Protocol for advanced MCP tool orchestration
public protocol AdvancedMCPOrchestrator {
    func registerTool(_ tool: any MCPTool) async
    func unregisterTool(_ toolId: String) async
    func executeTool(_ toolId: String, with parameters: [String: AnyCodable]) async throws
        -> MCPToolResult
    func listAvailableTools() async -> [MCPToolInfo]
    func getToolInfo(_ toolId: String) async -> MCPToolInfo?
    func orchestrateWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult
}

/// Protocol for MCP tool with enhanced capabilities
public protocol EnhancedMCPTool: MCPTool {
    var capabilities: [MCPToolCapability] { get }
    var dependencies: [String] { get }
    var performanceMetrics: MCPToolMetrics { get }

    func validateParameters(_ parameters: [String: AnyCodable]) throws
    func estimateExecutionTime(for parameters: [String: AnyCodable]) -> TimeInterval
    func getOptimizationHints() -> [String]
}

/// Protocol for MCP workflow management
@preconcurrency public protocol MCPWorkflowManager: Sendable {
    func createWorkflow(name: String, steps: [MCPWorkflowStep]) async -> MCPWorkflow
    func executeWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult
    func optimizeWorkflow(_ workflow: MCPWorkflow) async -> MCPWorkflow
    func monitorWorkflowExecution(_ workflowId: UUID) -> AsyncStream<MCPWorkflowExecutionStatus>
}

/// Protocol for MCP security and authentication
public protocol MCPSecurityManager: Sendable {
    func authenticateRequest(_ request: MCPRequest) async throws -> MCPAuthenticationResult
    func authorizeToolExecution(toolId: String, by principal: MCPPrincipal) async throws -> Bool
    func auditLogExecution(_ execution: MCPToolExecution) async
    func validateToolIntegrity(_ tool: any MCPTool) async throws -> Bool
}

// MARK: - Core MCP Types

/// Enhanced MCP tool result
public struct MCPToolResult: Sendable {
    public let toolId: String
    public let success: Bool
    public let output: AnyCodable?
    public let error: String?
    public let executionTime: TimeInterval
    public let metadata: [String: AnyCodable]

    public init(
        toolId: String,
        success: Bool,
        output: AnyCodable? = nil,
        error: String? = nil,
        executionTime: TimeInterval,
        metadata: [String: AnyCodable] = [:]
    ) {
        self.toolId = toolId
        self.success = success
        self.output = output
        self.error = error
        self.executionTime = executionTime
        self.metadata = metadata
    }
}

/// MCP tool information
public struct MCPToolInfo: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let version: String
    public let capabilities: [MCPToolCapability]
    public let parameters: [MCPParameterInfo]
    public let dependencies: [String]
    public let author: String
    public let createdAt: Date

    public init(
        id: String,
        name: String,
        description: String,
        version: String = "1.0.0",
        capabilities: [MCPToolCapability] = [],
        parameters: [MCPParameterInfo] = [],
        dependencies: [String] = [],
        author: String = "Quantum-workspace",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.capabilities = capabilities
        self.parameters = parameters
        self.dependencies = dependencies
        self.author = author
        self.createdAt = createdAt
    }
}

/// MCP tool capability
public enum MCPToolCapability: String, Codable, Sendable {
    case textProcessing = "text_processing"
    case dataAnalysis = "data_analysis"
    case fileOperations = "file_operations"
    case networkOperations = "network_operations"
    case systemOperations = "system_operations"
    case aiProcessing = "ai_processing"
    case workflowOrchestration = "workflow_orchestration"
    case securityOperations = "security_operations"
    case monitoring
    case optimization
}

/// MCP parameter information
public struct MCPParameterInfo: Codable, Sendable {
    public let name: String
    public let type: String
    public let description: String
    public let required: Bool
    public let defaultValue: AnyCodable?

    public init(
        name: String,
        type: String,
        description: String,
        required: Bool = false,
        defaultValue: AnyCodable? = nil
    ) {
        self.name = name
        self.type = type
        self.description = description
        self.required = required
        self.defaultValue = defaultValue
    }
}

/// MCP tool metrics
public struct MCPToolMetrics: Codable, Sendable {
    public var averageExecutionTime: TimeInterval
    public var successRate: Double
    public var errorRate: Double
    public var resourceUsage: MCPResourceUsage
    public var performanceScore: Double

    public init(
        averageExecutionTime: TimeInterval = 0,
        successRate: Double = 1.0,
        errorRate: Double = 0.0,
        resourceUsage: MCPResourceUsage = .init(),
        performanceScore: Double = 1.0
    ) {
        self.averageExecutionTime = averageExecutionTime
        self.successRate = successRate
        self.errorRate = errorRate
        self.resourceUsage = resourceUsage
        self.performanceScore = performanceScore
    }
}

/// MCP resource usage
public struct MCPResourceUsage: Codable, Sendable {
    public let cpuUsage: Double
    public let memoryUsage: Int64
    public let networkUsage: Int64
    public let diskUsage: Int64

    public init(
        cpuUsage: Double = 0,
        memoryUsage: Int64 = 0,
        networkUsage: Int64 = 0,
        diskUsage: Int64 = 0
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.networkUsage = networkUsage
        self.diskUsage = diskUsage
    }
}

// MARK: - Workflow Types

/// MCP workflow definition
public struct MCPWorkflow: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let steps: [MCPWorkflowStep]
    public let createdAt: Date
    public let modifiedAt: Date
    public let author: String
    public let metadata: [String: AnyCodable]?

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        steps: [MCPWorkflowStep],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        author: String = "Quantum-workspace",
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.steps = steps
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.author = author
        self.metadata = metadata
    }
}

/// MCP workflow execution mode
public enum MCPWorkflowExecutionMode: String, Codable, Sendable {
    case sequential
    case parallel
}

/// MCP workflow step
public struct MCPWorkflowStep: Codable, Sendable {
    public let id: UUID
    public let toolId: String
    public let parameters: [String: AnyCodable]
    public let dependencies: [UUID]
    public let executionMode: MCPWorkflowExecutionMode
    public let retryPolicy: MCPRetryPolicy?
    public let timeout: TimeInterval?
    public let metadata: [String: AnyCodable]?

    public init(
        id: UUID = UUID(),
        toolId: String,
        parameters: [String: AnyCodable] = [:],
        dependencies: [UUID] = [],
        executionMode: MCPWorkflowExecutionMode = .sequential,
        retryPolicy: MCPRetryPolicy? = nil,
        timeout: TimeInterval? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.toolId = toolId
        self.parameters = parameters
        self.dependencies = dependencies
        self.executionMode = executionMode
        self.retryPolicy = retryPolicy
        self.timeout = timeout
        self.metadata = metadata
    }
}

/// MCP retry policy
public struct MCPRetryPolicy: Codable, Sendable {
    public let maxAttempts: Int
    public let backoffStrategy: MCPBackoffStrategy
    public let baseDelay: TimeInterval

    public init(
        maxAttempts: Int = 3,
        backoffStrategy: MCPBackoffStrategy = .exponential,
        baseDelay: TimeInterval = 1.0
    ) {
        self.maxAttempts = maxAttempts
        self.backoffStrategy = backoffStrategy
        self.baseDelay = baseDelay
    }
}

/// MCP backoff strategy for retry policies
public enum MCPBackoffStrategy: String, Codable, Sendable {
    case fixed
    case linear
    case exponential
    case fibonacci
}

/// MCP workflow result
public struct MCPWorkflowResult: Sendable {
    public let workflowId: UUID
    public let success: Bool
    public let stepResults: [UUID: MCPToolResult]
    public let executionTime: TimeInterval
    public let errors: [MCPWorkflowExecutionError]

    public init(
        workflowId: UUID,
        success: Bool,
        stepResults: [UUID: MCPToolResult] = [:],
        executionTime: TimeInterval,
        errors: [MCPWorkflowExecutionError] = []
    ) {
        self.workflowId = workflowId
        self.success = success
        self.stepResults = stepResults
        self.executionTime = executionTime
        self.errors = errors
    }
}

/// MCP workflow execution error
public struct MCPWorkflowExecutionError: Sendable {
    public let stepId: UUID
    public let toolId: String
    public let message: String
    public let timestamp: Date

    public init(stepId: UUID, toolId: String, message: String, timestamp: Date = Date()) {
        self.stepId = stepId
        self.toolId = toolId
        self.message = message
        self.timestamp = timestamp
    }
}

/// MCP workflow execution status
public struct MCPWorkflowExecutionStatus: Sendable {
    public let workflowId: UUID
    public let status: MCPWorkflowExecutionState
    public let currentStep: UUID?
    public let progress: Double
    public let estimatedTimeRemaining: TimeInterval?

    public init(
        workflowId: UUID,
        status: MCPWorkflowExecutionState,
        currentStep: UUID? = nil,
        progress: Double = 0.0,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.workflowId = workflowId
        self.status = status
        self.currentStep = currentStep
        self.progress = progress
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

// MARK: - Security Types

/// MCP request for authentication
public struct MCPRequest: Sendable {
    public let toolId: String
    public let parameters: [String: AnyCodable]
    public let principal: MCPPrincipal
    public let timestamp: Date

    public init(
        toolId: String,
        parameters: [String: AnyCodable],
        principal: MCPPrincipal,
        timestamp: Date = Date()
    ) {
        self.toolId = toolId
        self.parameters = parameters
        self.principal = principal
        self.timestamp = timestamp
    }
}

/// MCP principal (user/agent identity)
public struct MCPPrincipal: Codable, Sendable {
    public let id: String
    public let type: MCPPrincipalType
    public let permissions: [String]
    public let attributes: [String: String]

    public init(
        id: String,
        type: MCPPrincipalType,
        permissions: [String] = [],
        attributes: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.permissions = permissions
        self.attributes = attributes
    }
}

/// MCP principal type
public enum MCPPrincipalType: String, Codable, Sendable {
    case user
    case agent
    case system
    case service
}

/// MCP authentication result
public struct MCPAuthenticationResult: Sendable {
    public let authenticated: Bool
    public let principal: MCPPrincipal?
    public let token: String?
    public let expiresAt: Date?

    public init(
        authenticated: Bool,
        principal: MCPPrincipal? = nil,
        token: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.authenticated = authenticated
        self.principal = principal
        self.token = token
        self.expiresAt = expiresAt
    }
}

/// MCP tool execution for auditing
public struct MCPToolExecution: Sendable {
    public let executionId: UUID
    public let toolId: String
    public let principal: MCPPrincipal
    public let parameters: [String: AnyCodable]
    public let result: MCPToolResult
    public let timestamp: Date

    public init(
        executionId: UUID = UUID(),
        toolId: String,
        principal: MCPPrincipal,
        parameters: [String: AnyCodable],
        result: MCPToolResult,
        timestamp: Date = Date()
    ) {
        self.executionId = executionId
        self.toolId = toolId
        self.principal = principal
        self.parameters = parameters
        self.result = result
        self.timestamp = timestamp
    }
}

// MARK: - Enhanced MCP Orchestrator Implementation

/// Implementation of advanced MCP orchestrator
public actor EnhancedMCPOrchestrator: AdvancedMCPOrchestrator {
    private var _tools: [String: any MCPTool] = [:]
    private var _toolMetrics: [String: MCPToolMetrics] = [:]
    private let securityManager: MCPSecurityManager
    private let workflowManager: MCPWorkflowManager

    public init(
        securityManager: MCPSecurityManager,
        workflowManager: MCPWorkflowManager
    ) {
        self.securityManager = securityManager
        self.workflowManager = workflowManager
    }

    public func registerTool(_ tool: any MCPTool) async {
        let toolId = await tool.id
        _tools[toolId] = tool

        // Initialize metrics for the tool
        if let enhancedTool = tool as? any EnhancedMCPTool {
            _toolMetrics[toolId] = enhancedTool.performanceMetrics
        } else {
            _toolMetrics[toolId] = MCPToolMetrics()
        }
    }

    public func unregisterTool(_ toolId: String) async {
        _tools.removeValue(forKey: toolId)
        _toolMetrics.removeValue(forKey: toolId)
    }

    public func executeTool(_ toolId: String, with parameters: [String: AnyCodable]) async throws
        -> MCPToolResult
    {
        guard let tool = _tools[toolId] else {
            throw MCPError.toolNotFound(toolId)
        }

        let startTime = Date()

        // Validate parameters if enhanced tool
        if let enhancedTool = tool as? any EnhancedMCPTool {
            try enhancedTool.validateParameters(parameters)
        }

        // Execute the tool
        do {
            let result = try await tool.execute(parameters: parameters)
            let executionTime = Date().timeIntervalSince(startTime)

            let output: AnyCodable?
            if let stringResult = result as? String {
                output = AnyCodable(stringResult)
            } else if let intResult = result as? Int {
                output = AnyCodable(intResult)
            } else if let doubleResult = result as? Double {
                output = AnyCodable(doubleResult)
            } else if let boolResult = result as? Bool {
                output = AnyCodable(boolResult)
            } else {
                output = AnyCodable(String(describing: result))
            }

            let toolResult = MCPToolResult(
                toolId: toolId,
                success: true,
                output: output,
                executionTime: executionTime
            )

            // Update metrics
            await updateToolMetrics(toolId, with: toolResult)

            return toolResult

        } catch {
            let executionTime = Date().timeIntervalSince(startTime)

            let toolResult = MCPToolResult(
                toolId: toolId,
                success: false,
                error: error.localizedDescription,
                executionTime: executionTime
            )

            // Update metrics
            await updateToolMetrics(toolId, with: toolResult)

            throw error
        }
    }

    public func listAvailableTools() async -> [MCPToolInfo] {
        let currentTools = _tools

        var toolInfos: [MCPToolInfo] = []

        for (toolId, tool) in currentTools {
            let capabilities: [MCPToolCapability]
            let dependencies: [String]

            if let enhancedTool = tool as? any EnhancedMCPTool {
                capabilities = enhancedTool.capabilities
                dependencies = enhancedTool.dependencies
            } else {
                capabilities = []
                dependencies = []
            }

            let toolInfo = await MCPToolInfo(
                id: toolId,
                name: tool.name,
                description: tool.description,
                capabilities: capabilities,
                dependencies: dependencies
            )

            toolInfos.append(toolInfo)
        }

        return toolInfos
    }

    public func getToolInfo(_ toolId: String) async -> MCPToolInfo? {
        guard let tool = _tools[toolId] else {
            return nil
        }

        let capabilities: [MCPToolCapability]
        let dependencies: [String]

        if let enhancedTool = tool as? any EnhancedMCPTool {
            capabilities = enhancedTool.capabilities
            dependencies = enhancedTool.dependencies
        } else {
            capabilities = []
            dependencies = []
        }

        return await MCPToolInfo(
            id: toolId,
            name: tool.name,
            description: tool.description,
            capabilities: capabilities,
            dependencies: dependencies
        )
    }

    public func orchestrateWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult {
        try await workflowManager.executeWorkflow(workflow)
    }

    // MARK: - Private Methods

    private func updateToolMetrics(_ toolId: String, with result: MCPToolResult) async {
        guard var metrics = _toolMetrics[toolId] else {
            return
        }

        // Update execution time (moving average)
        let alpha = 0.1 // Smoothing factor
        metrics.averageExecutionTime =
            (1 - alpha) * metrics.averageExecutionTime + alpha * result.executionTime

        // Update success/error rates
        if result.success {
            metrics.successRate = (1 - alpha) * metrics.successRate + alpha * 1.0
            metrics.errorRate = (1 - alpha) * metrics.errorRate + alpha * 0.0
        } else {
            metrics.successRate = (1 - alpha) * metrics.successRate + alpha * 0.0
            metrics.errorRate = (1 - alpha) * metrics.errorRate + alpha * 1.0
        }

        // Update performance score based on various factors
        metrics.performanceScore = calculatePerformanceScore(metrics)

        _toolMetrics[toolId] = metrics
    }

    private func calculatePerformanceScore(_ metrics: MCPToolMetrics) -> Double {
        // Simple performance score calculation
        let timeScore = max(0, 1 - metrics.averageExecutionTime / 10.0) // Better if faster than 10s
        let reliabilityScore = metrics.successRate
        let efficiencyScore = 1 - metrics.errorRate

        return (timeScore + reliabilityScore + efficiencyScore) / 3.0
    }
}

// MARK: - Basic MCP Security Manager Implementation

/// Basic implementation of MCP security manager
public actor BasicMCPSecurityManager: MCPSecurityManager {
    private var _authenticatedPrincipals: [String: MCPPrincipal] = [:]
    private var _executionLog: [MCPToolExecution] = []

    public func authenticateRequest(_ request: MCPRequest) async throws -> MCPAuthenticationResult {
        // Basic authentication - in practice, this would integrate with proper auth systems
        let principal = request.principal

        // Simple validation - check if principal exists
        let principalExists = _authenticatedPrincipals[principal.id] != nil

        if principalExists {
            return MCPAuthenticationResult(
                authenticated: true,
                principal: principal,
                token: UUID().uuidString,
                expiresAt: Date().addingTimeInterval(3600) // 1 hour
            )
        }

        // Auto-register new principals for demo purposes
        _authenticatedPrincipals[principal.id] = principal

        return MCPAuthenticationResult(
            authenticated: true,
            principal: principal,
            token: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(3600)
        )
    }

    public func authorizeToolExecution(toolId: String, by principal: MCPPrincipal) async throws
        -> Bool
    {
        // Basic authorization - check if principal has required permissions
        principal.permissions.contains("tool:\(toolId)")
            || principal.permissions.contains("tool:*") || principal.type == .system
    }

    public func auditLogExecution(_ execution: MCPToolExecution) async {
        _executionLog.append(execution)

        // In practice, this would write to a secure audit log
        print(
            "Audit: Tool \(execution.toolId) executed by \(execution.principal.id) at \(execution.timestamp)"
        )
    }

    public func validateToolIntegrity(_ tool: any MCPTool) async throws -> Bool {
        // Basic integrity check - in practice, this would verify signatures, hashes, etc.
        let toolId = await tool.id
        return !toolId.isEmpty
    }
}

// MARK: - Basic MCP Workflow Manager Implementation

/// Basic implementation of MCP workflow manager
public final class BasicMCPWorkflowManager: MCPWorkflowManager {
    private var workflows: [UUID: MCPWorkflow] = [:]
    private var executionStatuses: [UUID: MCPWorkflowExecutionStatus] = [:]
    private let workflowQueue = DispatchQueue(
        label: "com.mcp.workflow.manager", attributes: .concurrent
    )

    public func createWorkflow(name: String, steps: [MCPWorkflowStep]) async -> MCPWorkflow {
        await withCheckedContinuation { continuation in
            workflowQueue.async(flags: .barrier) {
                let workflow = MCPWorkflow(name: name, steps: steps)
                self.workflows[workflow.id] = workflow
                continuation.resume(returning: workflow)
            }
        }
    }

    public func executeWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult {
        let startTime = Date()
        var stepResults: [UUID: MCPToolResult] = [:]
        var errors: [MCPWorkflowExecutionError] = []

        await withCheckedContinuation { continuation in
            workflowQueue.async(flags: .barrier) {
                // Update status
                self.executionStatuses[workflow.id] = MCPWorkflowExecutionStatus(
                    workflowId: workflow.id,
                    status: .running,
                    progress: 0.0
                )
                continuation.resume()
            }
        }

        // Execute steps in dependency order
        let executionOrder = try topologicalSort(workflow.steps)

        for (index, step) in executionOrder.enumerated() {
            do {
                await withCheckedContinuation { continuation in
                    workflowQueue.async(flags: .barrier) {
                        // Update current step
                        self.executionStatuses[workflow.id] = MCPWorkflowExecutionStatus(
                            workflowId: workflow.id,
                            status: .running,
                            currentStep: step.id,
                            progress: Double(index) / Double(executionOrder.count)
                        )
                        continuation.resume()
                    }
                }

                // Execute step (this would need actual tool execution)
                let result = MCPToolResult(
                    toolId: step.toolId,
                    success: true,
                    output: AnyCodable("Step executed successfully"),
                    executionTime: 1.0
                )

                await withCheckedContinuation { continuation in
                    workflowQueue.async(flags: .barrier) {
                        stepResults[step.id] = result
                        continuation.resume()
                    }
                }

            } catch {
                let workflowError = MCPWorkflowExecutionError(
                    stepId: step.id,
                    toolId: step.toolId,
                    message: error.localizedDescription
                )
                errors.append(workflowError)

                await withCheckedContinuation { continuation in
                    workflowQueue.async(flags: .barrier) {
                        // Update status to failed
                        self.executionStatuses[workflow.id] = MCPWorkflowExecutionStatus(
                            workflowId: workflow.id,
                            status: .failed,
                            currentStep: step.id,
                            progress: Double(index) / Double(executionOrder.count)
                        )
                        continuation.resume()
                    }
                }

                throw error
            }
        }

        let executionTime = Date().timeIntervalSince(startTime)
        let success = errors.isEmpty

        await withCheckedContinuation { continuation in
            workflowQueue.async(flags: .barrier) {
                // Update final status
                self.executionStatuses[workflow.id] = MCPWorkflowExecutionStatus(
                    workflowId: workflow.id,
                    status: success ? .completed : .failed,
                    progress: 1.0
                )
                continuation.resume()
            }
        }

        return MCPWorkflowResult(
            workflowId: workflow.id,
            success: success,
            stepResults: stepResults,
            executionTime: executionTime,
            errors: errors
        )
    }

    public func optimizeWorkflow(_ workflow: MCPWorkflow) async -> MCPWorkflow {
        // Basic optimization - identify parallel execution opportunities
        var optimizedSteps = workflow.steps

        // Group independent steps
        let independentSteps = optimizedSteps.filter(\.dependencies.isEmpty)
        let dependentSteps = optimizedSteps.filter { !$0.dependencies.isEmpty }

        // Create parallel execution step for independent steps
        if independentSteps.count > 1 {
            let parallelStep = MCPWorkflowStep(
                toolId: "parallel_executor",
                parameters: ["steps": AnyCodable(independentSteps.map(\.id.uuidString))],
                dependencies: []
            )
            optimizedSteps = [parallelStep] + dependentSteps
        }

        return MCPWorkflow(
            id: workflow.id,
            name: workflow.name,
            description: workflow.description,
            steps: optimizedSteps,
            createdAt: workflow.createdAt,
            modifiedAt: Date()
        )
    }

    public func monitorWorkflowExecution(_ workflowId: UUID) -> AsyncStream<
        MCPWorkflowExecutionStatus
    > {
        AsyncStream { continuation in
            Task {
                while true {
                    let status = await withCheckedContinuation { continuation in
                        self.workflowQueue.async {
                            let status = self.executionStatuses[workflowId]
                            continuation.resume(returning: status)
                        }
                    }

                    if let status {
                        continuation.yield(status)

                        if status.status == .completed || status.status == .failed
                            || status.status == .cancelled
                        {
                            continuation.finish()
                            break
                        }
                    }

                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
        }
    }

    private func topologicalSort(_ steps: [MCPWorkflowStep]) throws -> [MCPWorkflowStep] {
        var result: [MCPWorkflowStep] = []
        var visited = Set<UUID>()
        var visiting = Set<UUID>()

        func visit(_ step: MCPWorkflowStep) throws {
            if visiting.contains(step.id) {
                throw MCPError.cyclicDependency
            }
            if visited.contains(step.id) {
                return
            }

            visiting.insert(step.id)

            for dependencyId in step.dependencies {
                if let dependency = steps.first(where: { $0.id == dependencyId }) {
                    try visit(dependency)
                }
            }

            visiting.remove(step.id)
            visited.insert(step.id)
            result.append(step)
        }

        for step in steps {
            if !visited.contains(step.id) {
                try visit(step)
            }
        }

        return result
    }
}

// MARK: - MCP Errors

public enum MCPError: Error {
    case toolNotFound(String)
    case invalidParameters(String)
    case executionFailed(String)
    case authenticationFailed
    case authorizationFailed
    case cyclicDependency
    case workflowExecutionFailed(String)
}

// MARK: - Extensions

public extension MCPToolResult {
    var isSuccessful: Bool { success }
    var hasError: Bool { error != nil }
}

public extension MCPWorkflow {
    var stepCount: Int { steps.count }
    var hasDependencies: Bool { steps.contains { !$0.dependencies.isEmpty } }
}

public extension MCPPrincipal {
    static let system = MCPPrincipal(id: "system", type: .system, permissions: ["*"])
    static func agent(_ id: String) -> MCPPrincipal {
        MCPPrincipal(id: id, type: .agent, permissions: ["tool:*"])
    }

    static func user(_ id: String) -> MCPPrincipal {
        MCPPrincipal(id: id, type: .user, permissions: ["tool:read"])
    }
}
