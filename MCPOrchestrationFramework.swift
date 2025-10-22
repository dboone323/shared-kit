//
//  MCPOrchestrationFramework.swift
//  Quantum-workspace
//
//  Created: Phase 9C - Enhanced MCP Systems
//  Purpose: MCP Orchestration Framework for advanced workflow management
//

import Combine
import Foundation

// MARK: - MCP Orchestration Framework

/// Protocol for MCP workflow orchestrator
@preconcurrency public protocol MCPWorkflowOrchestrator: Sendable {
    func orchestrateWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult
    func validateWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowValidationResult
    func getWorkflowStatus(_ workflowId: String) async -> MCPWorkflowStatus?
    func cancelWorkflow(_ workflowId: String) async throws
    func pauseWorkflow(_ workflowId: String) async throws
    func resumeWorkflow(_ workflowId: String) async throws
}

/// Protocol for MCP workflow scheduler
public protocol MCPWorkflowScheduler {
    func scheduleWorkflow(_ workflow: MCPWorkflow, at date: Date) async throws -> String
    func scheduleRecurringWorkflow(_ workflow: MCPWorkflow, schedule: MCPWorkflowSchedule)
        async throws -> String
    func cancelScheduledWorkflow(_ workflowId: String) async throws
    func listScheduledWorkflows() async -> [MCPScheduledWorkflow]
}

/// Protocol for MCP workflow monitor
@preconcurrency public protocol MCPWorkflowMonitor {
    func monitorWorkflow(
        _ workflowId: UUID, progressHandler: @escaping @Sendable (MCPWorkflowProgress) -> Void
    ) -> MCPWorkflowSubscription
    func getWorkflowHistory(workflowId: UUID, limit: Int) async -> [MCPWorkflowExecution]
    func getWorkflowMetrics(timeRange: DateInterval) async -> MCPWorkflowMetrics
}

/// Protocol for MCP workflow optimizer
public protocol MCPWorkflowOptimizer {
    func optimizeWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowOptimizationResult
    func analyzeWorkflowPerformance(_ workflowId: String, executions: [MCPWorkflowExecution]) async
        -> MCPWorkflowAnalysis
    func suggestOptimizations(_ workflow: MCPWorkflow) async -> [MCPWorkflowSuggestion]
}

// MARK: - Core MCP Orchestration Types

/// MCP security context
public struct MCPSecurityContext: Sendable {
    public let userId: String?
    public let sessionId: String?
    public let permissions: Set<String>
    public let authenticationToken: String?
    public let securityLevel: MCPSecurityLevel

    public init(
        userId: String? = nil,
        sessionId: String? = nil,
        permissions: Set<String> = [],
        authenticationToken: String? = nil,
        securityLevel: MCPSecurityLevel = .standard
    ) {
        self.userId = userId
        self.sessionId = sessionId
        self.permissions = permissions
        self.authenticationToken = authenticationToken
        self.securityLevel = securityLevel
    }
}

/// MCP security level
public enum MCPSecurityLevel: String, Codable, Sendable {
    case standard
    case elevated
    case admin
    case system
}

/// MCP workflow execution context
public struct MCPWorkflowExecutionContext: Sendable {
    public let workflowId: UUID
    public let executionId: String
    public let startTime: Date
    public var variables: [String: AnyCodable]
    public var metadata: [String: String]
    public var securityContext: MCPSecurityContext?

    public init(
        workflowId: UUID,
        executionId: String = UUID().uuidString,
        startTime: Date = Date(),
        variables: [String: AnyCodable] = [:],
        metadata: [String: String] = [:],
        securityContext: MCPSecurityContext? = nil
    ) {
        self.workflowId = workflowId
        self.executionId = executionId
        self.startTime = startTime
        self.variables = variables
        self.metadata = metadata
        self.securityContext = securityContext
    }
}

/// MCP workflow execution context
public struct MCPWorkflowContext {
    public let workflowId: String
    public let executionId: String
    public let startTime: Date
    public var variables: [String: Any]
    public var metadata: [String: String]
    public var securityContext: MCPSecurityContext?

    public init(
        workflowId: String,
        executionId: String = UUID().uuidString,
        startTime: Date = Date(),
        variables: [String: Any] = [:],
        metadata: [String: String] = [:],
        securityContext: MCPSecurityContext? = nil
    ) {
        self.workflowId = workflowId
        self.executionId = executionId
        self.startTime = startTime
        self.variables = variables
        self.metadata = metadata
        self.securityContext = securityContext
    }

    public mutating func setVariable(_ key: String, value: Any) {
        variables[key] = value
    }

    public func getVariable<T>(_ key: String) -> T? {
        variables[key] as? T
    }

    public mutating func setMetadata(_ key: String, value: String) {
        metadata[key] = value
    }
}

/// MCP workflow step execution state
public enum MCPWorkflowStepState: String, Codable, Sendable {
    case pending
    case running
    case completed
    case failed
    case skipped
    case cancelled
}

/// MCP workflow step result
public struct MCPWorkflowStepResult: Sendable {
    public let stepId: UUID
    public let state: MCPWorkflowStepState
    public let output: AnyCodable?
    public let error: Error?
    public let startTime: Date
    public let endTime: Date
    public let executionTime: TimeInterval
    public let retryCount: Int

    public init(
        stepId: UUID,
        state: MCPWorkflowStepState,
        output: AnyCodable? = nil,
        error: Error? = nil,
        startTime: Date,
        endTime: Date,
        retryCount: Int = 0
    ) {
        self.stepId = stepId
        self.state = state
        self.output = output
        self.error = error
        self.startTime = startTime
        self.endTime = endTime
        self.executionTime = endTime.timeIntervalSince(startTime)
        self.retryCount = retryCount
    }
}

/// MCP workflow progress
public struct MCPWorkflowProgress: Sendable {
    public let workflowId: UUID
    public let executionId: String
    public let totalSteps: Int
    public let completedSteps: Int
    public let failedSteps: Int
    public let currentStep: UUID?
    public let estimatedTimeRemaining: TimeInterval?
    public let progress: Double  // 0.0 to 1.0

    public init(
        workflowId: UUID,
        executionId: String,
        totalSteps: Int,
        completedSteps: Int,
        failedSteps: Int,
        currentStep: UUID? = nil,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.workflowId = workflowId
        self.executionId = executionId
        self.totalSteps = totalSteps
        self.completedSteps = completedSteps
        self.failedSteps = failedSteps
        self.currentStep = currentStep
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.progress = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0.0
    }
}

/// MCP workflow status
public struct MCPWorkflowStatus: Sendable {
    public let workflowId: UUID
    public let executionId: String
    public let state: MCPWorkflowExecutionState
    public let progress: MCPWorkflowProgress
    public let stepResults: [MCPWorkflowStepResult]
    public let startTime: Date
    public let lastUpdateTime: Date
    public let estimatedCompletionTime: Date?

    public init(
        workflowId: UUID,
        executionId: String,
        state: MCPWorkflowExecutionState,
        progress: MCPWorkflowProgress,
        stepResults: [MCPWorkflowStepResult],
        startTime: Date,
        lastUpdateTime: Date = Date(),
        estimatedCompletionTime: Date? = nil
    ) {
        self.workflowId = workflowId
        self.executionId = executionId
        self.state = state
        self.progress = progress
        self.stepResults = stepResults
        self.startTime = startTime
        self.lastUpdateTime = lastUpdateTime
        self.estimatedCompletionTime = estimatedCompletionTime
    }
}

/// MCP workflow execution state
public enum MCPWorkflowExecutionState: String, Codable, Sendable {
    case pending
    case running
    case paused
    case completed
    case failed
    case cancelled
}

/// MCP workflow validation result
public struct MCPWorkflowValidationResult {
    public let isValid: Bool
    public let errors: [MCPWorkflowValidationError]
    public let warnings: [MCPWorkflowValidationWarning]
    public let suggestions: [String]

    public init(
        isValid: Bool,
        errors: [MCPWorkflowValidationError] = [],
        warnings: [MCPWorkflowValidationWarning] = [],
        suggestions: [String] = []
    ) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.suggestions = suggestions
    }
}

/// MCP workflow validation error
public struct MCPWorkflowValidationError: Sendable {
    public let stepId: UUID?
    public let message: String
    public let severity: MCPWorkflowValidationSeverity

    public init(
        stepId: UUID? = nil, message: String, severity: MCPWorkflowValidationSeverity = .error
    ) {
        self.stepId = stepId
        self.message = message
        self.severity = severity
    }
}

/// MCP workflow validation warning
public struct MCPWorkflowValidationWarning: Sendable {
    public let stepId: UUID?
    public let message: String

    public init(stepId: UUID? = nil, message: String) {
        self.stepId = stepId
        self.message = message
    }
}

/// MCP workflow validation severity
public enum MCPWorkflowValidationSeverity: String, Codable, Sendable {
    case error
    case warning
}

/// MCP workflow schedule
public struct MCPWorkflowSchedule: Sendable {
    public let frequency: MCPWorkflowFrequency
    public let interval: Int
    public let startDate: Date?
    public let endDate: Date?
    public let timeZone: TimeZone

    public init(
        frequency: MCPWorkflowFrequency,
        interval: Int = 1,
        startDate: Date? = nil,
        endDate: Date? = nil,
        timeZone: TimeZone = .current
    ) {
        self.frequency = frequency
        self.interval = interval
        self.startDate = startDate
        self.endDate = endDate
        self.timeZone = timeZone
    }
}

/// MCP workflow frequency
public enum MCPWorkflowFrequency: String, Codable, Sendable {
    case hourly
    case daily
    case weekly
    case monthly
    case yearly
}

/// MCP scheduled workflow
public struct MCPScheduledWorkflow: Sendable {
    public let id: String
    public let workflow: MCPWorkflow
    public let schedule: MCPWorkflowSchedule
    public let nextExecutionDate: Date
    public let isActive: Bool
    public let createdAt: Date

    public init(
        id: String,
        workflow: MCPWorkflow,
        schedule: MCPWorkflowSchedule,
        nextExecutionDate: Date,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.workflow = workflow
        self.schedule = schedule
        self.nextExecutionDate = nextExecutionDate
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

/// MCP workflow subscription
public struct MCPWorkflowSubscription: Sendable {
    public let workflowId: UUID
    public let handler: @Sendable (MCPWorkflowProgress) -> Void

    public init(workflowId: UUID, handler: @escaping @Sendable (MCPWorkflowProgress) -> Void) {
        self.workflowId = workflowId
        self.handler = handler
    }
}

/// MCP workflow execution record
public struct MCPWorkflowExecution: Sendable {
    public let executionId: String
    public let workflowId: UUID
    public let startTime: Date
    public let endTime: Date?
    public let state: MCPWorkflowExecutionState
    public let result: MCPWorkflowResult?
    public let error: String?
    public let totalExecutionTime: TimeInterval?

    public init(
        executionId: String,
        workflowId: UUID,
        startTime: Date,
        endTime: Date? = nil,
        state: MCPWorkflowExecutionState,
        result: MCPWorkflowResult? = nil,
        error: String? = nil
    ) {
        self.executionId = executionId
        self.workflowId = workflowId
        self.startTime = startTime
        self.endTime = endTime
        self.state = state
        self.result = result
        self.error = error
        self.totalExecutionTime = endTime?.timeIntervalSince(startTime)
    }
}

/// MCP workflow metrics
public struct MCPWorkflowMetrics: Sendable {
    public let totalExecutions: Int
    public let successfulExecutions: Int
    public let failedExecutions: Int
    public let averageExecutionTime: TimeInterval
    public let successRate: Double
    public let mostExecutedWorkflows: [(workflowId: UUID, count: Int)]
    public let slowestWorkflows: [(workflowId: UUID, averageTime: TimeInterval)]

    public init(
        totalExecutions: Int,
        successfulExecutions: Int,
        failedExecutions: Int,
        averageExecutionTime: TimeInterval,
        mostExecutedWorkflows: [(workflowId: UUID, count: Int)] = [],
        slowestWorkflows: [(workflowId: UUID, averageTime: TimeInterval)] = []
    ) {
        self.totalExecutions = totalExecutions
        self.successfulExecutions = successfulExecutions
        self.failedExecutions = failedExecutions
        self.averageExecutionTime = averageExecutionTime
        self.successRate =
            totalExecutions > 0 ? Double(successfulExecutions) / Double(totalExecutions) : 0.0
        self.mostExecutedWorkflows = mostExecutedWorkflows
        self.slowestWorkflows = slowestWorkflows
    }
}

/// MCP workflow optimization result
public struct MCPWorkflowOptimizationResult {
    public let optimizedWorkflow: MCPWorkflow
    public let improvements: [MCPWorkflowImprovement]
    public let estimatedPerformanceGain: Double
    public let riskLevel: MCPWorkflowOptimizationRisk

    public init(
        optimizedWorkflow: MCPWorkflow,
        improvements: [MCPWorkflowImprovement],
        estimatedPerformanceGain: Double,
        riskLevel: MCPWorkflowOptimizationRisk
    ) {
        self.optimizedWorkflow = optimizedWorkflow
        self.improvements = improvements
        self.estimatedPerformanceGain = estimatedPerformanceGain
        self.riskLevel = riskLevel
    }
}

/// MCP workflow improvement
public struct MCPWorkflowImprovement {
    public let type: MCPWorkflowImprovementType
    public let description: String
    public let impact: Double  // Performance impact (0.0 to 1.0)

    public init(type: MCPWorkflowImprovementType, description: String, impact: Double) {
        self.type = type
        self.description = description
        self.impact = impact
    }
}

/// MCP workflow improvement type
public enum MCPWorkflowImprovementType: String, Codable {
    case parallelization
    case caching
    case stepConsolidation
    case resourceOptimization
    case errorHandling
}

/// MCP workflow optimization risk
public enum MCPWorkflowOptimizationRisk: String, Codable {
    case low
    case medium
    case high
}

/// MCP workflow analysis
public struct MCPWorkflowAnalysis {
    public let workflowId: UUID
    public let bottlenecks: [MCPWorkflowBottleneck]
    public let performanceTrends: [MCPWorkflowPerformanceTrend]
    public let recommendations: [String]

    public init(
        workflowId: UUID,
        bottlenecks: [MCPWorkflowBottleneck] = [],
        performanceTrends: [MCPWorkflowPerformanceTrend] = [],
        recommendations: [String] = []
    ) {
        self.workflowId = workflowId
        self.bottlenecks = bottlenecks
        self.performanceTrends = performanceTrends
        self.recommendations = recommendations
    }
}

/// MCP workflow bottleneck
public struct MCPWorkflowBottleneck {
    public let stepId: UUID
    public let averageExecutionTime: TimeInterval
    public let frequency: Int
    public let impact: Double

    public init(stepId: UUID, averageExecutionTime: TimeInterval, frequency: Int, impact: Double) {
        self.stepId = stepId
        self.averageExecutionTime = averageExecutionTime
        self.frequency = frequency
        self.impact = impact
    }
}

/// MCP workflow performance trend
public struct MCPWorkflowPerformanceTrend {
    public let metric: String
    public let trend: MCPWorkflowTrend
    public let changePercent: Double
    public let timeRange: DateInterval

    public init(
        metric: String, trend: MCPWorkflowTrend, changePercent: Double, timeRange: DateInterval
    ) {
        self.metric = metric
        self.trend = trend
        self.changePercent = changePercent
        self.timeRange = timeRange
    }
}

/// MCP workflow trend
public enum MCPWorkflowTrend: String, Codable {
    case improving
    case stable
    case degrading
}

/// MCP workflow suggestion
public struct MCPWorkflowSuggestion {
    public let type: MCPWorkflowSuggestionType
    public let description: String
    public let priority: MCPWorkflowSuggestionPriority
    public let estimatedBenefit: Double

    public init(
        type: MCPWorkflowSuggestionType,
        description: String,
        priority: MCPWorkflowSuggestionPriority,
        estimatedBenefit: Double
    ) {
        self.type = type
        self.description = description
        self.priority = priority
        self.estimatedBenefit = estimatedBenefit
    }
}

/// MCP workflow suggestion type
public enum MCPWorkflowSuggestionType: String, Codable {
    case addParallelization
    case implementCaching
    case consolidateSteps
    case addRetryLogic
    case optimizeResourceUsage
    case addMonitoring
}

/// MCP workflow suggestion priority
public enum MCPWorkflowSuggestionPriority: String, Codable {
    case low
    case medium
    case high
    case critical
}

// MARK: - MCP Workflow Orchestrator Implementation

/// Advanced MCP workflow orchestrator
public final class AdvancedMCPWorkflowOrchestrator: MCPWorkflowOrchestrator {
    private let orchestrator: EnhancedMCPOrchestrator
    private let securityManager: MCPSecurityManager
    private var activeExecutions: [String: MCPWorkflowExecutionContext] = [:]
    private var executionStatuses: [String: MCPWorkflowStatus] = [:]
    private let queue = DispatchQueue(label: "mcp.workflow.orchestrator", attributes: .concurrent)

    public init(orchestrator: EnhancedMCPOrchestrator, securityManager: MCPSecurityManager) {
        self.orchestrator = orchestrator
        self.securityManager = securityManager
    }

    public func orchestrateWorkflow(_ workflow: MCPWorkflow) async throws -> MCPWorkflowResult {
        let executionId = UUID().uuidString
        let context = MCPWorkflowExecutionContext(workflowId: workflow.id, executionId: executionId)

        // Store execution context
        queue.async(flags: .barrier) {
            self.activeExecutions[executionId] = context
        }

        do {
            // Validate workflow
            let validationResult = try await validateWorkflow(workflow)
            guard validationResult.isValid else {
                throw MCPWorkflowError.validationFailed(validationResult.errors)
            }

            // Initialize status
            let initialStatus = MCPWorkflowStatus(
                workflowId: workflow.id,
                executionId: executionId,
                state: .running,
                progress: MCPWorkflowProgress(
                    workflowId: workflow.id,
                    executionId: executionId,
                    totalSteps: workflow.steps.count,
                    completedSteps: 0,
                    failedSteps: 0
                ),
                stepResults: [],
                startTime: Date()
            )

            queue.async(flags: .barrier) {
                self.executionStatuses[executionId] = initialStatus
            }

            // Execute workflow using the enhanced orchestrator
            let result = try await orchestrator.orchestrateWorkflow(workflow)

            // Update final status
            let finalStatus = MCPWorkflowStatus(
                workflowId: workflow.id,
                executionId: executionId,
                state: result.success ? .completed : .failed,
                progress: MCPWorkflowProgress(
                    workflowId: workflow.id,
                    executionId: executionId,
                    totalSteps: workflow.steps.count,
                    completedSteps: result.success
                        ? workflow.steps.count
                        : result.stepResults.filter { $0.value.success }.count,
                    failedSteps: result.stepResults.filter { !$0.value.success }.count
                ),
                stepResults: result.stepResults.map { (stepId, toolResult) in
                    MCPWorkflowStepResult(
                        stepId: stepId,
                        state: toolResult.success ? .completed : .failed,
                        output: toolResult.output != nil ? AnyCodable(toolResult.output!) : nil,
                        error: toolResult.error != nil
                            ? NSError(
                                domain: "MCPWorkflow", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: toolResult.error!]) : nil,
                        startTime: context.startTime,
                        endTime: Date(),
                        retryCount: 0
                    )
                },
                startTime: context.startTime,
                estimatedCompletionTime: Date()
            )

            queue.async(flags: .barrier) {
                self.executionStatuses[executionId] = finalStatus
                self.activeExecutions.removeValue(forKey: executionId)
            }

            return result

        } catch {
            // Update status on failure
            let failedStatus = MCPWorkflowStatus(
                workflowId: workflow.id,
                executionId: executionId,
                state: .failed,
                progress: MCPWorkflowProgress(
                    workflowId: workflow.id,
                    executionId: executionId,
                    totalSteps: workflow.steps.count,
                    completedSteps: 0,
                    failedSteps: workflow.steps.count
                ),
                stepResults: [],
                startTime: context.startTime
            )

            queue.async(flags: .barrier) {
                self.executionStatuses[executionId] = failedStatus
                self.activeExecutions.removeValue(forKey: executionId)
            }

            throw error
        }
    }

    public func validateWorkflow(_ workflow: MCPWorkflow) async throws
        -> MCPWorkflowValidationResult
    {
        var errors: [MCPWorkflowValidationError] = []
        var warnings: [MCPWorkflowValidationWarning] = []
        var suggestions: [String] = []

        // Check for empty workflow
        if workflow.steps.isEmpty {
            errors.append(
                MCPWorkflowValidationError(
                    message: "Workflow must contain at least one step",
                    severity: .error
                ))
        }

        // Check for duplicate step IDs
        let stepIds = workflow.steps.map { $0.id }
        let uniqueStepIds = Set(stepIds)
        if stepIds.count != uniqueStepIds.count {
            errors.append(
                MCPWorkflowValidationError(
                    message: "Workflow contains duplicate step IDs",
                    severity: .error
                ))
        }

        // Check for missing dependencies
        for step in workflow.steps {
            for dependency in step.dependencies {
                if !stepIds.contains(dependency) {
                    errors.append(
                        MCPWorkflowValidationError(
                            stepId: step.id,
                            message: "Step depends on non-existent step: \(dependency)",
                            severity: .error
                        ))
                }
            }
        }

        // Check for circular dependencies
        if hasCircularDependencies(workflow) {
            errors.append(
                MCPWorkflowValidationError(
                    message: "Workflow contains circular dependencies",
                    severity: .error
                ))
        }

        // Check for unreachable steps
        let reachableSteps = findReachableSteps(workflow)
        for step in workflow.steps {
            if !reachableSteps.contains(step.id) {
                warnings.append(
                    MCPWorkflowValidationWarning(
                        stepId: step.id,
                        message: "Step is unreachable and will never execute"
                    ))
            }
        }

        // Performance suggestions
        if workflow.steps.count > 10 {
            suggestions.append(
                "Consider breaking large workflows into smaller, reusable components")
        }

        let parallelSteps = workflow.steps.filter { $0.executionMode == .parallel }
        if parallelSteps.count > 5 {
            suggestions.append("High parallelization may impact system resources")
        }

        return MCPWorkflowValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            suggestions: suggestions
        )
    }

    public func getWorkflowStatus(_ workflowId: String) async -> MCPWorkflowStatus? {
        queue.sync { executionStatuses[workflowId] }
    }

    public func cancelWorkflow(_ workflowId: String) async throws {
        guard let status = await getWorkflowStatus(workflowId) else {
            throw MCPWorkflowError.workflowNotFound(workflowId)
        }

        guard status.state == .running || status.state == .paused else {
            throw MCPWorkflowError.invalidState("Cannot cancel workflow in state: \(status.state)")
        }

        let cancelledStatus = MCPWorkflowStatus(
            workflowId: status.workflowId,
            executionId: status.executionId,
            state: .cancelled,
            progress: status.progress,
            stepResults: status.stepResults,
            startTime: status.startTime,
            lastUpdateTime: Date()
        )

        queue.async(flags: .barrier) {
            self.executionStatuses[workflowId] = cancelledStatus
            self.activeExecutions.removeValue(forKey: workflowId)
        }
    }

    public func pauseWorkflow(_ workflowId: String) async throws {
        guard let status = await getWorkflowStatus(workflowId) else {
            throw MCPWorkflowError.workflowNotFound(workflowId)
        }

        guard status.state == .running else {
            throw MCPWorkflowError.invalidState("Cannot pause workflow in state: \(status.state)")
        }

        let pausedStatus = MCPWorkflowStatus(
            workflowId: status.workflowId,
            executionId: status.executionId,
            state: .paused,
            progress: status.progress,
            stepResults: status.stepResults,
            startTime: status.startTime,
            lastUpdateTime: Date()
        )

        queue.async(flags: .barrier) {
            self.executionStatuses[workflowId] = pausedStatus
        }
    }

    public func resumeWorkflow(_ workflowId: String) async throws {
        guard let status = await getWorkflowStatus(workflowId) else {
            throw MCPWorkflowError.workflowNotFound(workflowId)
        }

        guard status.state == .paused else {
            throw MCPWorkflowError.invalidState("Cannot resume workflow in state: \(status.state)")
        }

        let resumedStatus = MCPWorkflowStatus(
            workflowId: status.workflowId,
            executionId: status.executionId,
            state: .running,
            progress: status.progress,
            stepResults: status.stepResults,
            startTime: status.startTime,
            lastUpdateTime: Date()
        )

        queue.async(flags: .barrier) {
            self.executionStatuses[workflowId] = resumedStatus
        }
    }

    // MARK: - Private Helper Methods

    private func hasCircularDependencies(_ workflow: MCPWorkflow) -> Bool {
        var visited = Set<UUID>()
        var recursionStack = Set<UUID>()

        func hasCycle(_ stepId: UUID) -> Bool {
            visited.insert(stepId)
            recursionStack.insert(stepId)

            guard let step = workflow.steps.first(where: { $0.id == stepId }) else {
                return false
            }

            for dependencyId in step.dependencies {
                if !visited.contains(dependencyId) && hasCycle(dependencyId) {
                    return true
                } else if recursionStack.contains(dependencyId) {
                    return true
                }
            }

            recursionStack.remove(stepId)
            return false
        }

        for step in workflow.steps {
            if !visited.contains(step.id) && hasCycle(step.id) {
                return true
            }
        }

        return false
    }

    private func findReachableSteps(_ workflow: MCPWorkflow) -> Set<UUID> {
        var reachable = Set<UUID>()
        var queue = [UUID]()

        // Start with steps that have no dependencies
        for step in workflow.steps where step.dependencies.isEmpty {
            reachable.insert(step.id)
            queue.append(step.id)
        }

        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            guard let currentStep = workflow.steps.first(where: { $0.id == currentId }) else {
                continue
            }

            // Find steps that depend on current step
            for step in workflow.steps where step.dependencies.contains(currentId) {
                if !reachable.contains(step.id) {
                    reachable.insert(step.id)
                    queue.append(step.id)
                }
            }
        }

        return reachable
    }
}

// MARK: - MCP Workflow Scheduler Implementation

/// Basic MCP workflow scheduler
public final class BasicMCPWorkflowScheduler: MCPWorkflowScheduler, @unchecked Sendable {
    private var scheduledWorkflows: [String: MCPScheduledWorkflow] = [:]
    private let orchestrator: MCPWorkflowOrchestrator
    private let queue = DispatchQueue(label: "mcp.workflow.scheduler", attributes: .concurrent)

    public init(orchestrator: MCPWorkflowOrchestrator) {
        self.orchestrator = orchestrator
    }

    public func scheduleWorkflow(_ workflow: MCPWorkflow, at date: Date) async throws -> String {
        let scheduleId = UUID().uuidString
        let scheduledWorkflow = MCPScheduledWorkflow(
            id: scheduleId,
            workflow: workflow,
            schedule: MCPWorkflowSchedule(frequency: .hourly),  // One-time
            nextExecutionDate: date
        )

        queue.async(flags: .barrier) {
            self.scheduledWorkflows[scheduleId] = scheduledWorkflow
        }

        // Schedule execution
        let localOrchestrator = orchestrator  // Capture locally to avoid data race
        let localQueue = queue  // Capture locally to avoid data race
        let localScheduleId = scheduleId  // Capture locally to avoid data race
        let localWorkflow = workflow  // Capture locally to avoid data race

        Task { @Sendable in
            try await Task.sleep(nanoseconds: UInt64(date.timeIntervalSinceNow * 1_000_000_000))
            let scheduledWorkflow = localQueue.sync(execute: { [weak self] in
                self?.scheduledWorkflows[localScheduleId]
            })
            if scheduledWorkflow != nil {
                do {
                    _ = try await localOrchestrator.orchestrateWorkflow(localWorkflow)
                    // Remove one-time schedule after execution
                    localQueue.async(flags: .barrier) { [weak self] in
                        self?.scheduledWorkflows.removeValue(forKey: localScheduleId)
                    }
                } catch {
                    print("Scheduled workflow execution failed: \(error)")
                }
            }
        }

        return scheduleId
    }

    public func scheduleRecurringWorkflow(_ workflow: MCPWorkflow, schedule: MCPWorkflowSchedule)
        async throws -> String
    {
        let scheduleId = UUID().uuidString
        let nextExecution = calculateNextExecution(schedule)
        let scheduledWorkflow = MCPScheduledWorkflow(
            id: scheduleId,
            workflow: workflow,
            schedule: schedule,
            nextExecutionDate: nextExecution
        )

        queue.async(flags: .barrier) {
            self.scheduledWorkflows[scheduleId] = scheduledWorkflow
        }

        // Start recurring execution loop
        let localOrchestrator = orchestrator  // Capture locally to avoid data race
        let localQueue = queue  // Capture locally to avoid data race
        let localScheduleId = scheduleId  // Capture locally to avoid data race
        let localWorkflow = workflow  // Capture locally to avoid data race
        let localSchedule = schedule  // Capture locally to avoid data race

        Task { @Sendable in
            while let currentSchedule = localQueue.sync(execute: { [weak self] in
                self?.scheduledWorkflows[localScheduleId]
            }),
                currentSchedule.isActive
            {

                let now = Date()
                if now >= currentSchedule.nextExecutionDate {
                    do {
                        _ = try await localOrchestrator.orchestrateWorkflow(localWorkflow)

                        // Calculate next execution (local copy to avoid self capture)
                        let calendar = Calendar.current
                        var components = DateComponents()
                        switch localSchedule.frequency {
                        case .hourly:
                            components.hour = localSchedule.interval
                        case .daily:
                            components.day = localSchedule.interval
                        case .weekly:
                            components.day = 7 * localSchedule.interval
                        case .monthly:
                            components.month = localSchedule.interval
                        case .yearly:
                            components.year = localSchedule.interval
                        }
                        let nextExecution =
                            calendar.date(
                                byAdding: components, to: currentSchedule.nextExecutionDate)
                            ?? currentSchedule.nextExecutionDate.addingTimeInterval(3600)

                        let updatedSchedule = MCPScheduledWorkflow(
                            id: localScheduleId,
                            workflow: localWorkflow,
                            schedule: localSchedule,
                            nextExecutionDate: nextExecution,
                            isActive: true,
                            createdAt: currentSchedule.createdAt
                        )

                        localQueue.async(flags: .barrier) { [weak self] in
                            self?.scheduledWorkflows[localScheduleId] = updatedSchedule
                        }

                    } catch {
                        print("Recurring workflow execution failed: \(error)")
                        // Continue with next schedule
                    }
                }

                try await Task.sleep(nanoseconds: 60_000_000_000)  // Check every minute
            }
        }

        return scheduleId
    }

    public func cancelScheduledWorkflow(_ workflowId: String) async throws {
        guard queue.sync(execute: { self.scheduledWorkflows[workflowId] }) != nil else {
            throw MCPWorkflowError.workflowNotFound(workflowId)
        }

        queue.async(flags: .barrier) {
            self.scheduledWorkflows.removeValue(forKey: workflowId)
        }
    }

    public func listScheduledWorkflows() async -> [MCPScheduledWorkflow] {
        queue.sync { Array(scheduledWorkflows.values) }
    }

    private func calculateNextExecution(_ schedule: MCPWorkflowSchedule, from date: Date = Date())
        -> Date
    {
        let calendar = Calendar.current
        var components = DateComponents()

        switch schedule.frequency {
        case .hourly:
            components.hour = schedule.interval
        case .daily:
            components.day = schedule.interval
        case .weekly:
            components.day = 7 * schedule.interval
        case .monthly:
            components.month = schedule.interval
        case .yearly:
            components.year = schedule.interval
        }

        return calendar.date(byAdding: components, to: date) ?? date.addingTimeInterval(3600)
    }
}

// MARK: - MCP Workflow Monitor Implementation

/// Basic MCP workflow monitor
public final class BasicMCPWorkflowMonitor: MCPWorkflowMonitor, @unchecked Sendable {
    private var subscriptions: [UUID: MCPWorkflowSubscription] = [:]
    private var executionHistory: [UUID: [MCPWorkflowExecution]] = [:]
    private let monitorQueue = DispatchQueue(
        label: "com.mcp.workflow.monitor", attributes: .concurrent)

    public init() {}

    public func monitorWorkflow(
        _ workflowId: UUID, progressHandler: @escaping @Sendable (MCPWorkflowProgress) -> Void
    ) -> MCPWorkflowSubscription {
        var subscription: MCPWorkflowSubscription!
        monitorQueue.sync(flags: .barrier) {
            subscription = MCPWorkflowSubscription(workflowId: workflowId, handler: progressHandler)
            self.subscriptions[workflowId] = subscription
        }
        return subscription
    }

    public func getWorkflowHistory(workflowId: UUID, limit: Int = 10) async
        -> [MCPWorkflowExecution]
    {
        await withCheckedContinuation { continuation in
            monitorQueue.async {
                let history = self.executionHistory[workflowId]?.suffix(limit).reversed() ?? []
                continuation.resume(returning: history)
            }
        }
    }

    public func getWorkflowMetrics(timeRange: DateInterval) async -> MCPWorkflowMetrics {
        await withCheckedContinuation { continuation in
            monitorQueue.async {
                let allExecutions = self.executionHistory.values.flatMap { $0 }
                let relevantExecutions = allExecutions.filter { timeRange.contains($0.startTime) }

                let totalExecutions = relevantExecutions.count
                let successfulExecutions = relevantExecutions.filter { $0.state == .completed }
                    .count
                let failedExecutions = relevantExecutions.filter { $0.state == .failed }.count

                let completedExecutions = relevantExecutions.filter { $0.totalExecutionTime != nil }
                let averageExecutionTime =
                    completedExecutions.isEmpty
                    ? 0
                    : completedExecutions.reduce(0) { $0 + ($1.totalExecutionTime ?? 0) }
                        / Double(completedExecutions.count)

                // Calculate most executed workflows
                let workflowCounts = Dictionary(grouping: relevantExecutions) { $0.workflowId }
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }
                    .prefix(5)

                // Calculate slowest workflows
                let workflowAverageTimes = Dictionary(grouping: completedExecutions) {
                    $0.workflowId
                }
                .mapValues { executions in
                    executions.reduce(0) { $0 + ($1.totalExecutionTime ?? 0) }
                        / Double(executions.count)
                }
                .sorted { $0.value > $1.value }
                .prefix(5)

                let metrics = MCPWorkflowMetrics(
                    totalExecutions: totalExecutions,
                    successfulExecutions: successfulExecutions,
                    failedExecutions: failedExecutions,
                    averageExecutionTime: averageExecutionTime,
                    mostExecutedWorkflows: workflowCounts.map {
                        (workflowId: $0.key, count: $0.value)
                    },
                    slowestWorkflows: workflowAverageTimes.map {
                        (workflowId: $0.key, averageTime: $0.value)
                    }
                )
                continuation.resume(returning: metrics)
            }
        }
    }

    /// Internal method to record execution (called by orchestrator)
    func recordExecution(_ execution: MCPWorkflowExecution) {
        monitorQueue.async(flags: .barrier) {
            if self.executionHistory[execution.workflowId] == nil {
                self.executionHistory[execution.workflowId] = []
            }
            self.executionHistory[execution.workflowId]?.append(execution)

            // Keep only last 100 executions per workflow
            if let count = self.executionHistory[execution.workflowId]?.count, count > 100 {
                self.executionHistory[execution.workflowId]?.removeFirst(count - 100)
            }
        }
    }

    /// Internal method to update progress (called by orchestrator)
    func updateProgress(_ progress: MCPWorkflowProgress) {
        monitorQueue.async(flags: .barrier) {
            if let subscription = self.subscriptions[progress.workflowId] {
                subscription.handler(progress)
            }
        }
    }
}

// MARK: - MCP Workflow Optimizer Implementation

/// Basic MCP workflow optimizer
public final class BasicMCPWorkflowOptimizer: MCPWorkflowOptimizer, Sendable {
    public init() {}

    public func optimizeWorkflow(_ workflow: MCPWorkflow) async throws
        -> MCPWorkflowOptimizationResult
    {
        var optimizedSteps = workflow.steps
        var improvements: [MCPWorkflowImprovement] = []

        // Identify parallelizable steps
        let parallelizableSteps = identifyParallelizableSteps(workflow)
        if !parallelizableSteps.isEmpty {
            for stepId in parallelizableSteps {
                if let index = optimizedSteps.firstIndex(where: { $0.id == stepId }) {
                    optimizedSteps[index] = MCPWorkflowStep(
                        id: optimizedSteps[index].id,
                        toolId: optimizedSteps[index].toolId,
                        parameters: optimizedSteps[index].parameters,
                        dependencies: optimizedSteps[index].dependencies,
                        executionMode: .parallel,
                        retryPolicy: optimizedSteps[index].retryPolicy,
                        timeout: optimizedSteps[index].timeout,
                        metadata: optimizedSteps[index].metadata
                    )
                }
            }
            improvements.append(
                MCPWorkflowImprovement(
                    type: .parallelization,
                    description:
                        "Converted \(parallelizableSteps.count) steps to parallel execution",
                    impact: 0.3
                ))
        }

        // Suggest caching for repeated operations
        let repeatedTools = findRepeatedTools(workflow)
        if !repeatedTools.isEmpty {
            improvements.append(
                MCPWorkflowImprovement(
                    type: .caching,
                    description:
                        "Consider caching results for \(repeatedTools.count) repeated tool calls",
                    impact: 0.2
                ))
        }

        // Consolidate similar steps
        let consolidatedSteps = consolidateSimilarSteps(optimizedSteps)
        if consolidatedSteps.count < optimizedSteps.count {
            optimizedSteps = consolidatedSteps
            improvements.append(
                MCPWorkflowImprovement(
                    type: .stepConsolidation,
                    description:
                        "Consolidated \(workflow.steps.count - consolidatedSteps.count) similar steps",
                    impact: 0.15
                ))
        }

        let optimizedWorkflow = MCPWorkflow(
            id: workflow.id,
            name: workflow.name,
            description: workflow.description,
            steps: optimizedSteps,
            metadata: workflow.metadata
        )

        let estimatedGain = improvements.reduce(0) { $0 + $1.impact }
        let riskLevel: MCPWorkflowOptimizationRisk =
            estimatedGain > 0.5 ? .high : estimatedGain > 0.2 ? .medium : .low

        return MCPWorkflowOptimizationResult(
            optimizedWorkflow: optimizedWorkflow,
            improvements: improvements,
            estimatedPerformanceGain: estimatedGain,
            riskLevel: riskLevel
        )
    }

    public func analyzeWorkflowPerformance(_ workflowId: String, executions: [MCPWorkflowExecution])
        async -> MCPWorkflowAnalysis
    {
        var bottlenecks: [MCPWorkflowBottleneck] = []
        var trends: [MCPWorkflowPerformanceTrend] = []
        var recommendations: [String] = []

        // Analyze execution times
        let completedExecutions = executions.filter {
            $0.state == .completed && $0.totalExecutionTime != nil
        }
        if completedExecutions.count >= 2 {
            let sortedExecutions = completedExecutions.sorted { $0.startTime < $1.startTime }
            let firstHalf = sortedExecutions.prefix(sortedExecutions.count / 2)
            let secondHalf = sortedExecutions.suffix(sortedExecutions.count / 2)

            let firstHalfAvg =
                firstHalf.reduce(0) { $0 + ($1.totalExecutionTime ?? 0) } / Double(firstHalf.count)
            let secondHalfAvg =
                secondHalf.reduce(0) { $0 + ($1.totalExecutionTime ?? 0) }
                / Double(secondHalf.count)

            let changePercent = ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100
            let trend: MCPWorkflowTrend =
                changePercent > 10 ? .degrading : changePercent < -10 ? .improving : .stable

            trends.append(
                MCPWorkflowPerformanceTrend(
                    metric: "execution_time",
                    trend: trend,
                    changePercent: changePercent,
                    timeRange: DateInterval(
                        start: sortedExecutions.first!.startTime,
                        end: sortedExecutions.last!.startTime)
                ))
        }

        // Identify failure patterns
        let failedExecutions = executions.filter { $0.state == .failed }
        if Double(failedExecutions.count) / Double(executions.count) > 0.1 {
            recommendations.append(
                "High failure rate detected - review error handling and retry policies")
        }

        return MCPWorkflowAnalysis(
            workflowId: UUID(uuidString: workflowId) ?? UUID(),
            bottlenecks: bottlenecks,
            performanceTrends: trends,
            recommendations: recommendations
        )
    }

    public func suggestOptimizations(_ workflow: MCPWorkflow) async -> [MCPWorkflowSuggestion] {
        var suggestions: [MCPWorkflowSuggestion] = []

        // Check for sequential bottlenecks
        let sequentialSteps = workflow.steps.filter { $0.executionMode == .sequential }
        if sequentialSteps.count > workflow.steps.count / 2 {
            suggestions.append(
                MCPWorkflowSuggestion(
                    type: .addParallelization,
                    description: "Consider parallelizing \(sequentialSteps.count) sequential steps",
                    priority: .medium,
                    estimatedBenefit: 0.25
                ))
        }

        // Check for missing retry logic
        let stepsWithoutRetry = workflow.steps.filter { $0.retryPolicy == nil }
        if !stepsWithoutRetry.isEmpty {
            suggestions.append(
                MCPWorkflowSuggestion(
                    type: .addRetryLogic,
                    description:
                        "Add retry logic to \(stepsWithoutRetry.count) steps without error handling",
                    priority: .high,
                    estimatedBenefit: 0.15
                ))
        }

        // Check for long-running steps
        let longRunningSteps = workflow.steps.filter { ($0.timeout ?? 300) > 600 }
        if !longRunningSteps.isEmpty {
            suggestions.append(
                MCPWorkflowSuggestion(
                    type: .optimizeResourceUsage,
                    description: "Review timeouts for \(longRunningSteps.count) long-running steps",
                    priority: .medium,
                    estimatedBenefit: 0.1
                ))
        }

        return suggestions
    }

    // MARK: - Private Helper Methods

    private func identifyParallelizableSteps(_ workflow: MCPWorkflow) -> [UUID] {
        var parallelizable: [UUID] = []

        for step in workflow.steps {
            // A step can be parallelized if none of its dependents depend on other steps
            let dependents = workflow.steps.filter { $0.dependencies.contains(step.id) }
            let canParallelize = dependents.allSatisfy { dependent in
                dependent.dependencies.count == 1 && dependent.dependencies.contains(step.id)
            }

            if canParallelize && step.executionMode == .sequential {
                parallelizable.append(step.id)
            }
        }

        return parallelizable
    }

    private func findRepeatedTools(_ workflow: MCPWorkflow) -> [String] {
        let toolCounts = Dictionary(grouping: workflow.steps) { $0.toolId }
            .mapValues { $0.count }
        return toolCounts.filter { $0.value > 1 }.map { $0.key }
    }

    private func consolidateSimilarSteps(_ steps: [MCPWorkflowStep]) -> [MCPWorkflowStep] {
        var consolidated: [MCPWorkflowStep] = []
        var processedIds = Set<UUID>()

        for step in steps {
            if processedIds.contains(step.id) { continue }

            // Find similar steps (same tool, similar parameters)
            let similarSteps = steps.filter { candidate in
                !processedIds.contains(candidate.id) && candidate.toolId == step.toolId
                    && candidate.parameters.count == step.parameters.count
                    && candidate.executionMode == step.executionMode
            }

            if similarSteps.count > 1 {
                // Create consolidated step
                let consolidatedId = UUID()
                let consolidatedStep = MCPWorkflowStep(
                    id: consolidatedId,
                    toolId: step.toolId,
                    parameters: step.parameters,
                    dependencies: step.dependencies,
                    executionMode: step.executionMode,
                    retryPolicy: step.retryPolicy,
                    timeout: step.timeout,
                    metadata: [
                        "consolidated_steps": AnyCodable(similarSteps.map { $0.id.uuidString })
                    ]
                )
                consolidated.append(consolidatedStep)

                // Mark all similar steps as processed
                similarSteps.forEach { processedIds.insert($0.id) }
            } else {
                consolidated.append(step)
                processedIds.insert(step.id)
            }
        }

        return consolidated
    }
}

// MARK: - MCP Workflow Error

/// MCP workflow error
public enum MCPWorkflowError: Error {
    case workflowNotFound(String)
    case validationFailed([MCPWorkflowValidationError])
    case invalidState(String)
    case executionFailed(String)
    case timeout(String)
    case cancelled(String)
}

// MARK: - Convenience Extensions

extension MCPWorkflowOrchestrator {
    /// Execute workflow with progress monitoring
    func executeWorkflowWithProgress(
        _ workflow: MCPWorkflow,
        progressHandler: @escaping @Sendable (MCPWorkflowProgress) -> Void
    ) async throws -> MCPWorkflowResult {
        // This would be implemented by concrete orchestrators
        return try await orchestrateWorkflow(workflow)
    }
}
