import Foundation

/// Represents a single message in the conversation history.
public struct ConversationMessage: Sendable {
    public let role: String // "user" or "assistant"
    public let content: String
    public let timestamp: Date

    public init(role: String, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

@available(macOS 12.0, *)
@MainActor
public final class AggregatorAgent: Sendable {
    public static let shared = AggregatorAgent()

    private let embeddingService = CoreMLEmbeddingService.shared
    private let vectorStore = PostgresVectorStore.shared
    private let llmClient: OllamaClient

    /// Conversation history for context
    @Published public private(set) var conversationHistory: [ConversationMessage] = []

    /// Entity memory for tracking services, errors, files
    private var entityMemory = EntityMemory()

    /// Maximum messages to keep in context
    private let maxHistorySize = 20

    /// Tool execution history for learning
    private var toolHistory: [ToolExecutionResult] = []

    // Production enhancements
    private let contextManager = ContextWindowManager(maxTokens: 4096)
    private let toolCache = ToolResultCache()
    private let coordinator = ToolExecutionCoordinator()
    private let learningSystem = ToolLearningSystem()

    private init() {
        // Use qwen2.5-coder if available (user's preferred), fallback to llama2
        let config = OllamaConfig(
            defaultModel: "qwen2.5-coder:7b",
            timeout: 120, // Longer timeout for planning
            enableAutoModelDownload: false, // Avoid 405 on api/pull
            fallbackModels: ["llama2", "mistral", "phi3"]
        )
        self.llmClient = OllamaClient(config: config)
    }

    /// Learn a new fact by storing it in the vector database.
    public func learn(fact: String, metadata: [String: String] = [:]) async throws {
        try await vectorStore.connect()
        let vector = try await embeddingService.embed(fact)
        try await vectorStore.save(content: fact, vector: vector, metadata: metadata)
        SecureLogger.info("Agent: Learned new fact (\(fact.prefix(50))...)", category: .ai)
    }

    /// Clear conversation history
    public func clearHistory() {
        conversationHistory = []
        SecureLogger.info("Agent: Conversation history cleared", category: .ai)
    }

    /// Main entry point for processing a user query using the RAG + Tool pipeline.
    public func process(query: String) async throws -> String {
        SecureLogger.info("Aggregator: Received query: '\(query)'", category: .ai)

        // Ensure DB connection
        try await vectorStore.connect()

        // 1. Retrieve Context (RAG)
        let queryVector = try await embeddingService.embed(query)
        let context = try await vectorStore.search(queryVector: queryVector, limit: 3)
        SecureLogger.info("Aggregator: RAG Context found: \(context.count) items", category: .ai)
        let contextString = context.map(\.content).joined(separator: "\n- ")

        // 2. Plan: Decompose query using LLM
        let plan = try await performPlanning(query: query, context: contextString)
        let cleanPlan = plan.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        SecureLogger.info("Aggregator: Plan created: \(cleanPlan)", category: .ai)

        // 3. Act: Execute Tools based on plan with retry logic
        var toolResult: ToolExecutionResult?

        if cleanPlan.contains("TOOL: status") || cleanPlan.contains("TOOL: health") {
            SecureLogger.info("Aggregator: Delegating to Tool: status", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "status")
            toolResult = ToolExecutionResult.parse(toolName: "status", rawOutput: output)
        } else if cleanPlan.contains("TOOL: logs") {
            SecureLogger.info("Aggregator: Delegating to Tool: logs", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "logs", args: ["db"])
            toolResult = ToolExecutionResult.parse(toolName: "logs", rawOutput: output)
        } else if cleanPlan.contains("TOOL: build") {
            SecureLogger.info("Aggregator: Delegating to Tool: build", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "build")
            toolResult = ToolExecutionResult.parse(toolName: "build", rawOutput: output)
        } else if cleanPlan.contains("TOOL: deploy") {
            SecureLogger.info("Aggregator: Delegating to Tool: deploy", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "start", args: ["core"])
            toolResult = ToolExecutionResult.parse(toolName: "deploy", rawOutput: output)
        } else if cleanPlan.contains("TOOL: metrics") {
            SecureLogger.info("Aggregator: Delegating to Tool: metrics", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "ps")
            toolResult = ToolExecutionResult.parse(toolName: "metrics", rawOutput: output)
        } else if cleanPlan.contains("TOOL: backup") {
            SecureLogger.info("Aggregator: Delegating to Tool: backup", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(
                command: "exec", args: ["db", "pg_dump", "-U", "sonar", "sonar"]
            )
            toolResult = ToolExecutionResult.parse(toolName: "backup", rawOutput: output)
        } else if cleanPlan.contains("TOOL: ai-fix") {
            SecureLogger.info("Aggregator: Delegating to Tool: ai-fix", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(
                command: "ai-fix", args: ["tools-automation"]
            )
            toolResult = ToolExecutionResult.parse(toolName: "ai-fix", rawOutput: output)
        } else if cleanPlan.contains("TOOL: start") {
            SecureLogger.info("Aggregator: Delegating to Tool: start", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "start", args: ["core"])
            toolResult = ToolExecutionResult.parse(toolName: "start", rawOutput: output)
        } else if cleanPlan.contains("TOOL: stop") {
            SecureLogger.info("Aggregator: Delegating to Tool: stop", category: .toolExecution)
            let output = try await runDockerManagerWithRetry(command: "stop", args: ["core"])
            toolResult = ToolExecutionResult.parse(toolName: "stop", rawOutput: output)
        }

        // 4. Track tool execution and extract entities
        if let result = toolResult {
            toolHistory.append(result)
            if toolHistory.count > 10 {
                toolHistory.removeFirst()
            }
            entityMemory.extractEntities(from: result.output)
            entityMemory.extractEntities(from: query)
        }

        // 5. Synthesize final answer
        let response: String
        if let result = toolResult {
            // Enhanced synthesis with structured feedback
            var feedbackContext = "Tool: \(result.toolName)\nSuccess: \(result.success)\n"
            if !result.metrics.isEmpty {
                feedbackContext += "Metrics: \(result.metrics)\n"
            }
            if !result.warnings.isEmpty {
                feedbackContext += "Warnings: \(result.warnings.joined(separator: ", "))\n"
            }
            feedbackContext += "\nOutput:\n\(result.output.prefix(1000))"

            response = try await synthesizeResponse(
                query: query, context: contextString, toolOutput: feedbackContext
            )
        } else {
            // No tool needed - answer directly with LLM
            var enhancedContext = contextString
            if !entityMemory.services.isEmpty {
                enhancedContext +=
                    "\n\nTracked Services: \(entityMemory.services.joined(separator: ", "))"
            }
            response = try await llmClient.generate(
                prompt:
                "Based on this context:\n\(enhancedContext)\n\nAnswer the user's question: \(query)",
                temperature: 0.5,
                maxTokens: 500
            )
        }

        // 5. Track conversation history
        conversationHistory.append(ConversationMessage(role: "user", content: query))
        conversationHistory.append(ConversationMessage(role: "assistant", content: response))

        // Trim history if needed
        if conversationHistory.count > maxHistorySize {
            conversationHistory = Array(conversationHistory.suffix(maxHistorySize))
        }

        return response
    }

    private func performPlanning(query: String, context: String) async throws -> String {
        let systemPrompt = """
        You are the 'Aggregator Agent', an AI orchestrator for a Docker-based DevOps system.
        Your goal is to parse user queries and decide which TOOL to use.

        Available Tools:
        1. status/health: Get status of all Docker services. Use for 'health', 'status', 'check system', 'what's running'.
        2. logs: View container logs. Use for 'logs', 'show logs', 'errors', 'debug'.
        3. build: Build Docker images. Use for 'build', 'compile', 'create image'.
        4. deploy: Deploy/start services. Use for 'deploy', 'release', 'go live'.
        5. metrics: Get system metrics and stats. Use for 'metrics', 'stats', 'performance'.
        6. backup: Create database backup. Use for 'backup', 'save data', 'dump'.
        7. ai-fix: Attempt to fix issues automatically. Use for 'fix', 'repair', 'solve', 'diagnose'.
        8. start: Start Docker services. Use for 'start', 'run', 'launch', 'boot'.
        9. stop: Stop Docker services. Use for 'stop', 'halt', 'shutdown'.

        Context from Memory:
        \(context)

        Instructions:
        - Parse the user's query and determine the best tool.
        - Output ONLY one of: "TOOL: status", "TOOL: logs", "TOOL: ai-fix", "TOOL: start", "TOOL: stop", or "ACTION: answer"
        - If the user just wants information or a general question, output "ACTION: answer"

        Return ONLY the decision string, nothing else.
        """

        return try await llmClient.generate(
            model: nil,
            prompt: "\(systemPrompt)\n\nUser Question: \(query)",
            temperature: 0.1,
            maxTokens: 30
        )
    }

    private func synthesizeResponse(query: String, context: String, toolOutput: String) async throws
        -> String
    {
        // Summarize tool output with LLM
        let prompt = """
        You executed a tool and got this output:
        ```
        \(toolOutput.prefix(2000))
        ```

        The user asked: "\(query)"

        Provide a concise, helpful summary of what happened and the current state.
        """

        return try await llmClient.generate(
            prompt: prompt,
            temperature: 0.4,
            maxTokens: 300
        )
    }

    private func runDockerManager(command: String, args: [String] = []) async throws -> String {
        let process = Process()
        let pipe = Pipe()

        let executablePath = "/Users/danielstevens/github-projects/tools-automation/docker-manager"
        let projectPath = "/Users/danielstevens/github-projects/tools-automation"

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.currentDirectoryURL = URL(fileURLWithPath: projectPath)
        process.arguments = [command] + args
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Run docker-manager with retry logic and exponential backoff
    private func runDockerManagerWithRetry(
        command: String, args: [String] = [], maxRetries: Int = 3
    ) async throws -> String {
        var lastError: Error?
        var delay: UInt64 = 1_000_000_000 // 1 second in nanoseconds

        for attempt in 0 ..< maxRetries {
            do {
                return try await runDockerManager(command: command, args: args)
                // Success - return immediately
            } catch {
                lastError = error
                SecureLogger.error(
                    "Attempt \(attempt + 1)/\(maxRetries) for command '\(command)' failed: \(error.localizedDescription)",
                    category: .toolExecution, error: error
                )

                // Don't delay after the last attempt
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2 // Exponential backoff
                }
            }
        }

        // All retries exhausted
        throw lastError
            ?? NSError(
                domain: "AggregatorAgent", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "All retries failed"]
            )
    }
}
