//
//  MCPEnhancedAgentSystems.swift
//  Quantum-workspace
//
//  Created by Daniel Stevens on 2024
//
//  Phase 9D: Agent-Workflow-MCP Integration
//  MCP-Enhanced Agent Systems for Universal Agent Era
//
//  This framework provides agents with advanced MCP tool integration,
//  enabling intelligent tool selection, execution, and orchestration
//  within autonomous agent workflows.
//

import Combine
import Foundation

// MARK: - MCP Tool Integration Protocols

/// Protocol for MCP tool integration within agents
@available(macOS 14.0, *)
public protocol MCPToolIntegrable {
    /// Available MCP tools for this agent
    var availableTools: [MCPTool] { get }

    /// Execute an MCP tool with given parameters
    func executeTool(_ tool: MCPTool, parameters: [String: Any]) async throws -> MCPToolResult

    /// Get tool recommendations based on current context
    func recommendTools(for context: AgentContext) -> [MCPToolRecommendation]

    /// Validate tool execution results
    func validateToolResult(_ result: MCPToolResult, for tool: MCPTool) -> Bool
}

/// MCP tool recommendation with confidence score
@available(macOS 14.0, *)
public struct MCPToolRecommendation {
    public let tool: MCPTool
    public let confidence: Double
    public let reasoning: String
    public let estimatedExecutionTime: TimeInterval

    public init(tool: MCPTool, confidence: Double, reasoning: String, estimatedExecutionTime: TimeInterval) {
        self.tool = tool
        self.confidence = confidence
        self.reasoning = reasoning
        self.estimatedExecutionTime = estimatedExecutionTime
    }
}

// MARK: - Enhanced Agent with MCP Integration

/// Enhanced agent with full MCP tool integration capabilities
@available(macOS 14.0, *)
@MainActor
public final class MCPEnhancedAgent: AutonomousAgent, MCPToolIntegrable, Sendable {
    // MARK: - Properties

    public let id: UUID
    public let name: String
    public let capabilities: [AgentCapability]
    public private(set) var state: AgentState
    public private(set) var isActive: Bool = false

    /// MCP system integration
    private let mcpSystem: MCPSystemIntegration

    /// Tool execution history for learning
    private var toolExecutionHistory: [MCPToolExecution] = []

    /// Performance metrics
    private var performanceMetrics = AgentPerformanceMetrics()

    /// Learning system for tool optimization
    private let learningSystem: MCPToolLearningSystem

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        capabilities: [AgentCapability],
        mcpSystem: MCPSystemIntegration
    ) {
        self.id = id
        self.name = name
        self.capabilities = capabilities
        self.state = .idle
        self.mcpSystem = mcpSystem
        self.learningSystem = MCPToolLearningSystem()
    }

    // MARK: - AutonomousAgent Protocol

    public func start() async {
        guard !isActive else { return }
        isActive = true
        state = .active
        await initializeMCPIntegration()
    }

    public func stop() async {
        guard isActive else { return }
        isActive = false
        state = .idle
        await cleanupMCPIntegration()
    }

    public func process(task: AgentTask) async throws -> AgentResult {
        guard isActive else { throw AgentError.notActive }

        state = .processing(task)
        defer { state = .idle }

        do {
            let startTime = Date()

            // Analyze task and recommend tools
            let context = AgentContext(task: task, agent: self)
            let recommendations = recommendTools(for: context)

            // Execute recommended tools
            var results: [MCPToolResult] = []
            for recommendation in recommendations where recommendation.confidence > 0.7 {
                let result = try await executeTool(recommendation.tool, parameters: task.parameters)
                results.append(result)

                // Learn from execution
                await learningSystem.recordExecution(
                    tool: recommendation.tool,
                    result: result,
                    context: context,
                    executionTime: Date().timeIntervalSince(startTime)
                )
            }

            let executionTime = Date().timeIntervalSince(startTime)
            performanceMetrics.recordExecution(success: true, duration: executionTime)

            return AgentResult(
                taskId: task.id,
                success: true,
                data: ["toolResults": results],
                executionTime: executionTime
            )

        } catch {
            performanceMetrics.recordExecution(success: false, duration: 0)
            throw error
        }
    }

    // MARK: - MCPToolIntegrable Protocol

    public var availableTools: [MCPTool] {
        mcpSystem.getAvailableTools()
    }

    public func executeTool(_ tool: MCPTool, parameters: [String: Any]) async throws -> MCPToolResult {
        let execution = MCPToolExecution(
            tool: tool,
            parameters: parameters,
            startTime: Date()
        )

        do {
            let result = try await mcpSystem.executeTool(tool, parameters: parameters)
            execution.endTime = Date()
            execution.result = result
            toolExecutionHistory.append(execution)

            return result
        } catch {
            execution.endTime = Date()
            execution.error = error
            toolExecutionHistory.append(execution)
            throw error
        }
    }

    public func recommendTools(for context: AgentContext) -> [MCPToolRecommendation] {
        let allTools = availableTools

        return allTools.compactMap { tool in
            let score = calculateToolScore(tool, for: context)
            guard score.confidence > 0.3 else { return nil }

            return MCPToolRecommendation(
                tool: tool,
                confidence: score.confidence,
                reasoning: score.reasoning,
                estimatedExecutionTime: score.estimatedTime
            )
        }.sorted { $0.confidence > $1.confidence }
    }

    public func validateToolResult(_ result: MCPToolResult, for tool: MCPTool) -> Bool {
        // Validate result structure and content
        switch tool.category {
        case .textProcessing:
            return result.data is String || result.data is [String]
        case .dataAnalysis:
            return result.data is [String: Any] || result.data is [[String: Any]]
        case .fileOperations:
            return result.success // File operations are validated by success flag
        case .networkOperations:
            return result.data is [String: Any]
        case .systemOperations:
            return result.success
        case .aiProcessing:
            return result.data is String || result.data is [String: Any]
        case .workflowOrchestration:
            return result.data is [String: Any]
        case .securityOperations:
            return result.success
        case .monitoring:
            return result.data is [String: Any]
        case .optimization:
            return result.data is [String: Any]
        }
    }

    // MARK: - Private Methods

    private func initializeMCPIntegration() async {
        // Register agent with MCP system
        await mcpSystem.registerAgent(self)

        // Load tool execution history for learning
        await learningSystem.loadHistoricalData(from: toolExecutionHistory)
    }

    private func cleanupMCPIntegration() async {
        // Unregister from MCP system
        await mcpSystem.unregisterAgent(self)

        // Save learning data
        await learningSystem.saveHistoricalData()
    }

    private func calculateToolScore(_ tool: MCPTool, for context: AgentContext) -> ToolScore {
        var confidence = 0.5
        var reasoning = "Basic tool match"
        var estimatedTime = tool.estimatedExecutionTime

        // Analyze task requirements
        let taskDescription = context.task.description.lowercased()
        let toolName = tool.name.lowercased()
        let toolDescription = tool.description.lowercased()

        // Keyword matching
        let keywords = extractKeywords(from: taskDescription)
        let toolKeywords = extractKeywords(from: toolDescription)

        let matchingKeywords = keywords.intersection(toolKeywords)
        if !matchingKeywords.isEmpty {
            confidence += Double(matchingKeywords.count) * 0.1
            reasoning = "Matches keywords: \(matchingKeywords.joined(separator: ", "))"
        }

        // Category-based scoring
        switch tool.category {
        case .textProcessing where taskDescription.contains("text") || taskDescription.contains("content"):
            confidence += 0.3
            reasoning = "Text processing tool for text-related task"
        case .dataAnalysis where taskDescription.contains("data") || taskDescription.contains("analyze"):
            confidence += 0.3
            reasoning = "Data analysis tool for data processing task"
        case .fileOperations where taskDescription.contains("file") || taskDescription.contains("document"):
            confidence += 0.3
            reasoning = "File operations tool for file management task"
        case .aiProcessing where taskDescription.contains("ai") || taskDescription.contains("intelligent"):
            confidence += 0.3
            reasoning = "AI processing tool for intelligent task"
        default:
            break
        }

        // Learning-based adjustment
        let historicalScore = learningSystem.getHistoricalScore(for: tool, in: context)
        confidence = (confidence + historicalScore) / 2.0

        // Performance-based time estimation
        estimatedTime = learningSystem.estimateExecutionTime(for: tool, in: context)

        return ToolScore(
            confidence: min(confidence, 1.0),
            reasoning: reasoning,
            estimatedTime: estimatedTime
        )
    }

    private func extractKeywords(from text: String) -> Set<String> {
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return Set(words.filter { $0.count > 2 }.map { $0.lowercased() })
    }
}

// MARK: - Supporting Types

/// Tool execution record for learning
@available(macOS 14.0, *)
private struct MCPToolExecution {
    let tool: MCPTool
    let parameters: [String: Any]
    let startTime: Date
    var endTime: Date?
    var result: MCPToolResult?
    var error: Error?
}

/// Tool scoring for recommendations
@available(macOS 14.0, *)
private struct ToolScore {
    let confidence: Double
    let reasoning: String
    let estimatedTime: TimeInterval
}

/// Learning system for tool optimization
@available(macOS 14.0, *)
private actor MCPToolLearningSystem {
    private var historicalData: [String: [ToolPerformance]] = [:]

    struct ToolPerformance {
        let success: Bool
        let executionTime: TimeInterval
        let contextSimilarity: Double
    }

    func recordExecution(tool: MCPTool, result: MCPToolResult, context: AgentContext, executionTime: TimeInterval) {
        let performance = ToolPerformance(
            success: result.success,
            executionTime: executionTime,
            contextSimilarity: 1.0 // Simplified - could be more sophisticated
        )

        let key = tool.id.uuidString
        historicalData[key, default: []].append(performance)

        // Keep only recent performances
        if historicalData[key]!.count > 100 {
            historicalData[key]!.removeFirst()
        }
    }

    func getHistoricalScore(for tool: MCPTool, in context: AgentContext) -> Double {
        guard let performances = historicalData[tool.id.uuidString], !performances.isEmpty else {
            return 0.5 // Neutral score for unknown tools
        }

        let successRate = Double(performances.filter(\.success).count) / Double(performances.count)
        let avgTime = performances.map(\.executionTime).reduce(0, +) / Double(performances.count)

        // Score based on success rate and reasonable execution time
        let timeScore = avgTime < 30.0 ? 1.0 : max(0.1, 30.0 / avgTime)
        return (successRate + timeScore) / 2.0
    }

    func estimateExecutionTime(for tool: MCPTool, in context: AgentContext) -> TimeInterval {
        guard let performances = historicalData[tool.id.uuidString], !performances.isEmpty else {
            return tool.estimatedExecutionTime
        }

        let avgTime = performances.map(\.executionTime).reduce(0, +) / Double(performances.count)
        return avgTime
    }

    func loadHistoricalData(from executions: [MCPToolExecution]) {
        // Load from execution history
        for execution in executions {
            if let result = execution.result,
               let endTime = execution.endTime
            {
                let performance = ToolPerformance(
                    success: result.success,
                    executionTime: endTime.timeIntervalSince(execution.startTime),
                    contextSimilarity: 1.0
                )
                let key = execution.tool.id.uuidString
                historicalData[key, default: []].append(performance)
            }
        }
    }

    func saveHistoricalData() {
        // In a real implementation, this would persist to disk
        // For now, data is kept in memory
    }
}

// MARK: - Agent Performance Metrics

/// Performance tracking for MCP-enhanced agents
@available(macOS 14.0, *)
public struct AgentPerformanceMetrics {
    private var executions: [(success: Bool, duration: TimeInterval, timestamp: Date)] = []

    mutating func recordExecution(success: Bool, duration: TimeInterval) {
        executions.append((success, duration, Date()))

        // Keep only recent executions
        if executions.count > 1000 {
            executions.removeFirst()
        }
    }

    func getSuccessRate() -> Double {
        guard !executions.isEmpty else { return 0.0 }
        let successful = executions.filter(\.success).count
        return Double(successful) / Double(executions.count)
    }

    func getAverageExecutionTime() -> TimeInterval {
        guard !executions.isEmpty else { return 0.0 }
        let totalTime = executions.map(\.duration).reduce(0, +)
        return totalTime / Double(executions.count)
    }

    func getRecentPerformance(window: TimeInterval = 3600) -> (successRate: Double, avgTime: TimeInterval) {
        let recent = executions.filter { Date().timeIntervalSince($0.timestamp) <= window }
        guard !recent.isEmpty else { return (0.0, 0.0) }

        let successCount = recent.filter(\.success).count
        let successRate = Double(successCount) / Double(recent.count)
        let avgTime = recent.map(\.duration).reduce(0, +) / Double(recent.count)

        return (successRate, avgTime)
    }
}

// MARK: - Factory and Management

/// Factory for creating MCP-enhanced agents
@available(macOS 14.0, *)
public final class MCPEnhancedAgentFactory {
    private let mcpSystem: MCPSystemIntegration

    public init(mcpSystem: MCPSystemIntegration) {
        self.mcpSystem = mcpSystem
    }

    public func createAgent(
        name: String,
        capabilities: [AgentCapability]
    ) -> MCPEnhancedAgent {
        MCPEnhancedAgent(
            name: name,
            capabilities: capabilities,
            mcpSystem: mcpSystem
        )
    }

    public func createSpecializedAgent(for domain: AgentDomain) -> MCPEnhancedAgent {
        let capabilities = getCapabilitiesForDomain(domain)
        return createAgent(
            name: "\(domain.rawValue) Agent",
            capabilities: capabilities
        )
    }

    private func getCapabilitiesForDomain(_ domain: AgentDomain) -> [AgentCapability] {
        switch domain {
        case .development:
            return [.codeAnalysis, .testing, .documentation]
        case .data:
            return [.dataProcessing, .analytics, .visualization]
        case .automation:
            return [.workflowOrchestration, .taskAutomation, .monitoring]
        case .security:
            return [.securityAnalysis, .threatDetection, .compliance]
        case .ai:
            return [.aiProcessing, .modelTraining, .inference]
        }
    }
}

/// Agent domain specialization
public enum AgentDomain: String {
    case development
    case data
    case automation
    case security
    case ai
}
