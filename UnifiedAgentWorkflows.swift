//
//  UnifiedAgentWorkflows.swift
//  Quantum-workspace
//
//  Created: Phase 9D - Agent-Workflow-MCP Integration
//  Purpose: Unified workflows that seamlessly integrate autonomous agents with MCP systems
//

import Combine
import Foundation

// MARK: - Unified Agent Workflow Types

/// Unified agent workflow that integrates agents, workflows, and MCP tools
public struct UnifiedAgentWorkflow {
    public let id: String
    public let name: String
    public let description: String
    public let agent: AutonomousAgentSystem
    public let workflow: MCPWorkflow
    public let mcpTools: [any MCPTool]
    public let integrationRules: [AgentWorkflowIntegrationRule]
    public let metadata: [String: AnyCodable]
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        agent: AutonomousAgentSystem,
        workflow: MCPWorkflow,
        mcpTools: [any MCPTool] = [],
        integrationRules: [AgentWorkflowIntegrationRule] = [],
        metadata: [String: AnyCodable] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.agent = agent
        self.workflow = workflow
        self.mcpTools = mcpTools
        self.integrationRules = integrationRules
        self.metadata = metadata
        self.createdAt = createdAt
    }
}

/// Integration rule for agent-workflow-MCP coordination
public struct AgentWorkflowIntegrationRule {
    public let id: String
    public let trigger: AgentWorkflowTrigger
    public let conditions: [AgentWorkflowCondition]
    public let actions: [AgentWorkflowAction]
    public let priority: Int
    public let enabled: Bool

    public init(
        id: String = UUID().uuidString,
        trigger: AgentWorkflowTrigger,
        conditions: [AgentWorkflowCondition] = [],
        actions: [AgentWorkflowAction],
        priority: Int = 0,
        enabled: Bool = true
    ) {
        self.id = id
        self.trigger = trigger
        self.conditions = conditions
        self.actions = actions
        self.priority = priority
        self.enabled = enabled
    }
}

/// Trigger for agent-workflow integration
public enum AgentWorkflowTrigger {
    case agentDecision(agentId: String, decision: AgentDecision)
    case workflowStep(stepId: String, state: MCPWorkflowStepState)
    case mcpToolExecution(toolId: String, result: MCPToolResult)
    case systemEvent(event: MCPSystemEvent)
    case timeInterval(interval: TimeInterval)
    case custom(triggerId: String, data: [String: AnyCodable])
}

/// Condition for integration rule execution
public struct AgentWorkflowCondition {
    public let type: AgentWorkflowConditionType
    public let parameters: [String: AnyCodable]
    public let logic: AgentWorkflowLogic

    public init(
        type: AgentWorkflowConditionType,
        parameters: [String: AnyCodable] = [:],
        logic: AgentWorkflowLogic = .and
    ) {
        self.type = type
        self.parameters = parameters
        self.logic = logic
    }
}

/// Condition types for integration rules
public enum AgentWorkflowConditionType {
    case agentState(agentId: String, state: AgentState)
    case workflowProgress(workflowId: String, minProgress: Double)
    case mcpToolSuccess(toolId: String, minSuccessRate: Double)
    case systemHealth(minHealth: MCPComponentHealthStatus)
    case timeWindow(start: Date, end: Date)
    case custom(conditionId: String, parameters: [String: AnyCodable])
}

/// Logic operators for conditions
public enum AgentWorkflowLogic {
    case and
    case or
    case not
}

/// Action for integration rule execution
public struct AgentWorkflowAction {
    public let type: AgentWorkflowActionType
    public let parameters: [String: AnyCodable]
    public let delay: TimeInterval

    public init(
        type: AgentWorkflowActionType,
        parameters: [String: AnyCodable] = [:],
        delay: TimeInterval = 0
    ) {
        self.type = type
        self.parameters = parameters
        self.delay = delay
    }
}

/// Action types for integration rules
public enum AgentWorkflowActionType {
    case executeWorkflow(workflowId: String)
    case triggerAgentDecision(agentId: String, decision: AgentDecision)
    case invokeMCPTool(toolId: String, parameters: [String: Any])
    case updateWorkflowStep(stepId: String, action: MCPWorkflowStepAction)
    case sendSystemEvent(event: MCPSystemEvent)
    case pauseWorkflow(workflowId: String)
    case resumeWorkflow(workflowId: String)
    case custom(actionId: String, parameters: [String: AnyCodable])
}

/// Workflow step action
public enum MCPWorkflowStepAction {
    case retry(maxAttempts: Int)
    case skip
    case modifyParameters(parameters: [String: Any])
    case replaceWithTool(toolId: String)
}

/// Unified agent workflow execution context
public struct UnifiedAgentWorkflowContext {
    public let workflowId: String
    public let executionId: String
    public let agent: AutonomousAgentSystem
    public let workflow: MCPWorkflow
    public let mcpTools: [any MCPTool]
    public var agentState: AgentState
    public var workflowProgress: MCPWorkflowProgress
    public var activeRules: [AgentWorkflowIntegrationRule]
    public var executionHistory: [UnifiedWorkflowExecutionEvent]
    public var sharedData: [String: Any]
    public let startTime: Date

    public init(
        workflowId: String,
        executionId: String = UUID().uuidString,
        agent: AutonomousAgentSystem,
        workflow: MCPWorkflow,
        mcpTools: [any MCPTool] = [],
        startTime: Date = Date()
    ) {
        self.workflowId = workflowId
        self.executionId = executionId
        self.agent = agent
        self.workflow = workflow
        self.mcpTools = mcpTools
        self.agentState = .idle
        self.workflowProgress = MCPWorkflowProgress(
            workflowId: workflowId,
            executionId: executionId,
            totalSteps: workflow.steps.count,
            completedSteps: 0,
            failedSteps: 0
        )
        self.activeRules = []
        self.executionHistory = []
        self.sharedData = [:]
        self.startTime = startTime
    }

    public mutating func updateAgentState(_ state: AgentState) {
        self.agentState = state
        recordEvent(.agentStateChanged(oldState: self.agentState, newState: state))
    }

    public mutating func updateWorkflowProgress(_ progress: MCPWorkflowProgress) {
        self.workflowProgress = progress
        recordEvent(.workflowProgressUpdated(progress: progress))
    }

    public mutating func addActiveRule(_ rule: AgentWorkflowIntegrationRule) {
        self.activeRules.append(rule)
        recordEvent(.ruleActivated(ruleId: rule.id))
    }

    public mutating func removeActiveRule(_ ruleId: String) {
        self.activeRules.removeAll { $0.id == ruleId }
        recordEvent(.ruleDeactivated(ruleId: ruleId))
    }

    public mutating func setSharedData(_ key: String, value: Any) {
        self.sharedData[key] = value
        recordEvent(.sharedDataUpdated(key: key, value: String(describing: value)))
    }

    public func getSharedData<T>(_ key: String) -> T? {
        self.sharedData[key] as? T
    }

    private mutating func recordEvent(_ event: UnifiedWorkflowExecutionEvent) {
        self.executionHistory.append(event)
    }
}

/// Unified workflow execution event
public enum UnifiedWorkflowExecutionEvent {
    case agentStateChanged(oldState: AgentState, newState: AgentState)
    case workflowProgressUpdated(progress: MCPWorkflowProgress)
    case ruleActivated(ruleId: String)
    case ruleDeactivated(ruleId: String)
    case ruleExecuted(ruleId: String, success: Bool)
    case sharedDataUpdated(key: String, value: String)
    case errorOccurred(error: Error, component: UnifiedWorkflowComponent)
    case integrationCompleted(success: Bool, duration: TimeInterval)
}

/// Component that can cause errors in unified workflow
public enum UnifiedWorkflowComponent {
    case agent
    case workflow
    case mcpTool
    case integrationRule
    case system
}

/// Unified agent workflow result
public struct UnifiedAgentWorkflowResult {
    public let workflowId: String
    public let executionId: String
    public let success: Bool
    public let agentResult: AgentExecutionResult?
    public let workflowResult: MCPWorkflowResult?
    public let mcpResults: [String: MCPToolResult]
    public let integrationEvents: [UnifiedWorkflowExecutionEvent]
    public let sharedData: [String: Any]
    public let executionTime: TimeInterval
    public let errors: [Error]
    public let startTime: Date
    public let endTime: Date

    public init(
        workflowId: String,
        executionId: String,
        success: Bool,
        agentResult: AgentExecutionResult? = nil,
        workflowResult: MCPWorkflowResult? = nil,
        mcpResults: [String: MCPToolResult] = [:],
        integrationEvents: [UnifiedWorkflowExecutionEvent] = [],
        sharedData: [String: Any] = [:],
        executionTime: TimeInterval,
        errors: [Error] = [],
        startTime: Date,
        endTime: Date
    ) {
        self.workflowId = workflowId
        self.executionId = executionId
        self.success = success
        self.agentResult = agentResult
        self.workflowResult = workflowResult
        self.mcpResults = mcpResults
        self.integrationEvents = integrationEvents
        self.sharedData = sharedData
        self.executionTime = executionTime
        self.errors = errors
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Unified Agent Workflow Orchestrator

/// Orchestrator for unified agent workflows
public final class UnifiedAgentWorkflowOrchestrator {
    private let agentSystem: AutonomousAgentSystem
    private let workflowOrchestrator: AdvancedMCPWorkflowOrchestrator
    private let mcpSystem: MCPCompleteSystemIntegration
    private var activeWorkflows: [String: UnifiedAgentWorkflowContext] = [:]
    private var integrationRules: [AgentWorkflowIntegrationRule] = []
    private let queue = DispatchQueue(
        label: "unified.workflow.orchestrator", attributes: .concurrent
    )

    public init(
        agentSystem: AutonomousAgentSystem,
        workflowOrchestrator: AdvancedMCPWorkflowOrchestrator,
        mcpSystem: MCPCompleteSystemIntegration
    ) {
        self.agentSystem = agentSystem
        self.workflowOrchestrator = workflowOrchestrator
        self.mcpSystem = mcpSystem
    }

    /// Execute a unified agent workflow
    public func executeUnifiedWorkflow(_ unifiedWorkflow: UnifiedAgentWorkflow) async throws
        -> UnifiedAgentWorkflowResult
    {
        let startTime = Date()
        let executionId = UUID().uuidString

        var context = UnifiedAgentWorkflowContext(
            workflowId: unifiedWorkflow.id,
            executionId: executionId,
            agent: unifiedWorkflow.agent,
            workflow: unifiedWorkflow.workflow,
            mcpTools: unifiedWorkflow.mcpTools,
            startTime: startTime
        )

        // Store context
        queue.async(flags: .barrier) {
            self.activeWorkflows[executionId] = context
        }

        do {
            // Set up integration rules
            context.activeRules = unifiedWorkflow.integrationRules.filter(\.enabled)

            // Start agent and workflow execution concurrently
            async let agentTask = executeAgentWorkflow(&context)
            async let workflowTask = executeMCPWorkflow(&context)

            let (agentResult, workflowResult) = try await (agentTask, workflowTask)

            // Execute MCP tools based on results
            let mcpResults = try await executeMCPTools(
                &context, agentResult: agentResult, workflowResult: workflowResult
            )

            // Process integration rules
            try await processIntegrationRules(&context)

            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)

            let result = UnifiedAgentWorkflowResult(
                workflowId: unifiedWorkflow.id,
                executionId: executionId,
                success: (agentResult?.success ?? false) && (workflowResult?.success ?? false),
                agentResult: agentResult,
                workflowResult: workflowResult,
                mcpResults: mcpResults,
                integrationEvents: context.executionHistory,
                sharedData: context.sharedData,
                executionTime: executionTime,
                startTime: startTime,
                endTime: endTime
            )

            // Clean up
            queue.async(flags: .barrier) {
                self.activeWorkflows.removeValue(forKey: executionId)
            }

            return result

        } catch {
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)

            // Record error
            context.executionHistory.append(.errorOccurred(error: error, component: .system))

            let result = UnifiedAgentWorkflowResult(
                workflowId: unifiedWorkflow.id,
                executionId: executionId,
                success: false,
                integrationEvents: context.executionHistory,
                sharedData: context.sharedData,
                executionTime: executionTime,
                errors: [error],
                startTime: startTime,
                endTime: endTime
            )

            // Clean up
            queue.async(flags: .barrier) {
                self.activeWorkflows.removeValue(forKey: executionId)
            }

            throw error
        }
    }

    /// Add integration rule
    public func addIntegrationRule(_ rule: AgentWorkflowIntegrationRule) {
        queue.async(flags: .barrier) {
            self.integrationRules.append(rule)
        }
    }

    /// Remove integration rule
    public func removeIntegrationRule(_ ruleId: String) {
        queue.async(flags: .barrier) {
            self.integrationRules.removeAll { $0.id == ruleId }
        }
    }

    /// Get active workflows
    public func getActiveWorkflows() -> [UnifiedAgentWorkflowContext] {
        queue.sync {
            Array(activeWorkflows.values)
        }
    }

    // MARK: - Private Methods

    private func executeAgentWorkflow(_ context: inout UnifiedAgentWorkflowContext) async throws
        -> AgentExecutionResult?
    {
        context.updateAgentState(.running)

        do {
            // Create agent task based on workflow requirements
            let agentTask = AgentTask(
                id: UUID().uuidString,
                description: "Execute workflow: \(context.workflow.name)",
                priority: .high,
                parameters: ["workflow_id": context.workflowId]
            )

            let result = try await agentSystem.executeTask(agentTask)
            context.updateAgentState(.completed)

            return result

        } catch {
            context.updateAgentState(.error)
            context.executionHistory.append(.errorOccurred(error: error, component: .agent))
            throw error
        }
    }

    private func executeMCPWorkflow(_ context: inout UnifiedAgentWorkflowContext) async throws
        -> MCPWorkflowResult?
    {
        do {
            let result = try await workflowOrchestrator.orchestrateWorkflow(context.workflow)

            // Update progress
            let progress = MCPWorkflowProgress(
                workflowId: context.workflowId,
                executionId: context.executionId,
                totalSteps: context.workflow.steps.count,
                completedSteps: result.stepResults.filter { $0.state == .completed }.count,
                failedSteps: result.stepResults.filter { $0.state == .failed }.count
            )
            context.updateWorkflowProgress(progress)

            return result

        } catch {
            context.executionHistory.append(.errorOccurred(error: error, component: .workflow))
            throw error
        }
    }

    private func executeMCPTools(
        _ context: inout UnifiedAgentWorkflowContext,
        agentResult: AgentExecutionResult?,
        workflowResult: MCPWorkflowResult?
    ) async throws -> [String: MCPToolResult] {
        var results: [String: MCPToolResult] = [:]

        for tool in context.mcpTools {
            do {
                // Prepare parameters based on agent and workflow results
                var parameters: [String: Any] = [:]

                if let agentResult {
                    parameters["agent_output"] = agentResult.output
                }

                if let workflowResult {
                    parameters["workflow_output"] = workflowResult.output
                }

                // Add shared data
                for (key, value) in context.sharedData {
                    parameters["shared_\(key)"] = value
                }

                let result = try await mcpSystem.executeWorkflow(
                    MCPWorkflow(
                        id: UUID().uuidString,
                        name: "MCP Tool Execution: \(tool.id())",
                        description: "Execute MCP tool as part of unified workflow",
                        steps: [
                            MCPWorkflowStep(
                                id: "tool_execution",
                                toolId: tool.id(),
                                parameters: parameters,
                                dependencies: []
                            ),
                        ]
                    ))

                if let toolResult = result.stepResults.first?.output as? MCPToolResult {
                    await results[tool.id()] = toolResult
                }

            } catch {
                context.executionHistory.append(.errorOccurred(error: error, component: .mcpTool))
                // Continue with other tools
            }
        }

        return results
    }

    private func processIntegrationRules(_ context: inout UnifiedAgentWorkflowContext) async throws {
        for rule in context.activeRules where rule.enabled {
            do {
                // Check if rule conditions are met
                if try await evaluateRuleConditions(rule, context: context) {
                    // Execute rule actions
                    try await executeRuleActions(rule, context: &context)
                    context.executionHistory.append(.ruleExecuted(ruleId: rule.id, success: true))
                }
            } catch {
                context.executionHistory.append(.ruleExecuted(ruleId: rule.id, success: false))
                context.executionHistory.append(
                    .errorOccurred(error: error, component: .integrationRule))
            }
        }
    }

    private func evaluateRuleConditions(
        _ rule: AgentWorkflowIntegrationRule, context: UnifiedAgentWorkflowContext
    ) async throws -> Bool {
        for condition in rule.conditions {
            let conditionMet = try await evaluateCondition(condition, context: context)

            switch condition.logic {
            case .and:
                if !conditionMet { return false }
            case .or:
                if conditionMet { return true }
            case .not:
                if conditionMet { return false }
            }
        }

        return rule.conditions.isEmpty || rule.conditions.contains(where: { $0.logic == .or })
    }

    private func evaluateCondition(
        _ condition: AgentWorkflowCondition, context: UnifiedAgentWorkflowContext
    ) async throws -> Bool {
        switch condition.type {
        case let .agentState(agentId, requiredState):
            return context.agentState == requiredState

        case let .workflowProgress(workflowId, minProgress):
            return context.workflowProgress.progress >= minProgress

        case let .mcpToolSuccess(toolId, minSuccessRate):
            // Check MCP tool success rate from history
            let toolEvents = context.executionHistory.filter { event in
                if case let .errorOccurred(_, component) = event, component == .mcpTool {
                    return true
                }
                return false
            }
            let successRate = toolEvents.isEmpty ? 1.0 : 0.0 // Simplified calculation
            return successRate >= minSuccessRate

        case let .systemHealth(minHealth):
            let health = await mcpSystem.getSystemStatus()
            return health.overallHealth.rawValue >= minHealth.rawValue

        case let .timeWindow(start, end):
            let now = Date()
            return now >= start && now <= end

        case let .custom(conditionId, parameters):
            // Custom condition evaluation logic would go here
            return true // Placeholder
        }
    }

    private func executeRuleActions(
        _ rule: AgentWorkflowIntegrationRule, context: inout UnifiedAgentWorkflowContext
    ) async throws {
        for action in rule.actions {
            if action.delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(action.delay * 1_000_000_000))
            }

            try await executeAction(action, context: &context)
        }
    }

    private func executeAction(
        _ action: AgentWorkflowAction, context: inout UnifiedAgentWorkflowContext
    ) async throws {
        switch action.type {
        case let .executeWorkflow(workflowId):
            // Trigger additional workflow execution
            _ = try await workflowOrchestrator.orchestrateWorkflow(context.workflow)

        case let .triggerAgentDecision(agentId, decision):
            // Trigger agent decision
            context.setSharedData("agent_decision", decision)

        case let .invokeMCPTool(toolId, parameters):
            // Invoke MCP tool
            _ = try await mcpSystem.executeWorkflow(
                MCPWorkflow(
                    id: UUID().uuidString,
                    name: "Integration Rule MCP Tool",
                    description: "MCP tool invoked by integration rule",
                    steps: [
                        MCPWorkflowStep(
                            id: "rule_tool_execution",
                            toolId: toolId,
                            parameters: parameters,
                            dependencies: []
                        ),
                    ]
                ))

        case let .updateWorkflowStep(stepId, stepAction):
            // Update workflow step (would need workflow modification capabilities)
            context.setSharedData("workflow_step_update", ["stepId": stepId, "action": stepAction])

        case let .sendSystemEvent(event):
            // Send system event
            await mcpSystem.eventSystem.publish(event)

        case let .pauseWorkflow(workflowId):
            // Pause workflow
            try await workflowOrchestrator.pauseWorkflow(workflowId)

        case let .resumeWorkflow(workflowId):
            // Resume workflow
            try await workflowOrchestrator.resumeWorkflow(workflowId)

        case let .custom(actionId, parameters):
            // Custom action execution logic would go here
            context.setSharedData(
                "custom_action", ["actionId": actionId, "parameters": parameters]
            )
        }
    }
}

// MARK: - Unified Agent Workflow Builder

/// Builder for creating unified agent workflows
public final class UnifiedAgentWorkflowBuilder {
    private var id: String?
    private var name: String = ""
    private var description: String = ""
    private var agent: AutonomousAgentSystem?
    private var workflow: MCPWorkflow?
    private var mcpTools: [any MCPTool] = []
    private var integrationRules: [AgentWorkflowIntegrationRule] = []
    private var metadata: [String: AnyCodable] = [:]

    public init() {}

    public func withId(_ id: String) -> UnifiedAgentWorkflowBuilder {
        self.id = id
        return self
    }

    public func withName(_ name: String) -> UnifiedAgentWorkflowBuilder {
        self.name = name
        return self
    }

    public func withDescription(_ description: String) -> UnifiedAgentWorkflowBuilder {
        self.description = description
        return self
    }

    public func withAgent(_ agent: AutonomousAgentSystem) -> UnifiedAgentWorkflowBuilder {
        self.agent = agent
        return self
    }

    public func withWorkflow(_ workflow: MCPWorkflow) -> UnifiedAgentWorkflowBuilder {
        self.workflow = workflow
        return self
    }

    public func withMCPTools(_ tools: [any MCPTool]) -> UnifiedAgentWorkflowBuilder {
        self.mcpTools = tools
        return self
    }

    public func addMCPTool(_ tool: any MCPTool) -> UnifiedAgentWorkflowBuilder {
        self.mcpTools.append(tool)
        return self
    }

    public func withIntegrationRules(_ rules: [AgentWorkflowIntegrationRule])
        -> UnifiedAgentWorkflowBuilder
    {
        self.integrationRules = rules
        return self
    }

    public func addIntegrationRule(_ rule: AgentWorkflowIntegrationRule)
        -> UnifiedAgentWorkflowBuilder
    {
        self.integrationRules.append(rule)
        return self
    }

    public func withMetadata(_ metadata: [String: AnyCodable]) -> UnifiedAgentWorkflowBuilder {
        self.metadata = metadata
        return self
    }

    public func addMetadata(_ key: String, value: AnyCodable) -> UnifiedAgentWorkflowBuilder {
        self.metadata[key] = value
        return self
    }

    public func build() throws -> UnifiedAgentWorkflow {
        guard let agent else {
            throw UnifiedWorkflowError.missingAgent
        }

        guard let workflow else {
            throw UnifiedWorkflowError.missingWorkflow
        }

        return UnifiedAgentWorkflow(
            id: id ?? UUID().uuidString,
            name: name,
            description: description,
            agent: agent,
            workflow: workflow,
            mcpTools: mcpTools,
            integrationRules: integrationRules,
            metadata: metadata
        )
    }
}

// MARK: - Unified Workflow Error

/// Errors that can occur in unified workflows
public enum UnifiedWorkflowError: Error {
    case missingAgent
    case missingWorkflow
    case invalidConfiguration(String)
    case executionFailed(String)
    case integrationFailed(String)
    case timeout(String)
}

// MARK: - Convenience Extensions

extension UnifiedAgentWorkflowOrchestrator {
    /// Create a simple unified workflow with default integration rules
    public func createSimpleUnifiedWorkflow(
        name: String,
        description: String,
        agent: AutonomousAgentSystem,
        workflow: MCPWorkflow,
        mcpTools: [any MCPTool] = []
    ) -> UnifiedAgentWorkflow {
        let rules = createDefaultIntegrationRules(workflowId: UUID().uuidString)
        return UnifiedAgentWorkflow(
            name: name,
            description: description,
            agent: agent,
            workflow: workflow,
            mcpTools: mcpTools,
            integrationRules: rules
        )
    }

    private func createDefaultIntegrationRules(workflowId: String) -> [AgentWorkflowIntegrationRule] {
        [
            // Rule: If workflow fails, trigger agent recovery
            AgentWorkflowIntegrationRule(
                trigger: .workflowStep(stepId: "any", state: .failed),
                conditions: [],
                actions: [
                    AgentWorkflowAction(
                        type: .triggerAgentDecision(
                            agentId: "recovery_agent",
                            decision: .custom("recovery", ["action": "retry_workflow"])
                        ),
                        delay: 1.0
                    ),
                ],
                priority: 10
            ),

            // Rule: If agent completes successfully, optimize workflow
            AgentWorkflowIntegrationRule(
                trigger: .agentDecision(agentId: "any", decision: .completed),
                conditions: [
                    AgentWorkflowCondition(
                        type: .workflowProgress(workflowId: workflowId, minProgress: 0.8),
                        logic: .and
                    ),
                ],
                actions: [
                    AgentWorkflowAction(
                        type: .custom("optimize", ["target": "workflow_performance"]),
                        delay: 0
                    ),
                ],
                priority: 5
            ),
        ]
    }
}
