import Foundation
import HuggingFaceClient

/// Unified Ollama Integration Framework
/// Complete free AI solution for code generation, analysis, and automation
/// No API costs, runs locally on your machine

// MARK: - Core Types

public struct OllamaConfig {
    public let baseURL: String
    public let defaultModel: String
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let temperature: Double
    public let maxTokens: Int

    public init(
        baseURL: String = "http://localhost:11434",
        defaultModel: String = "llama2",
        timeout: TimeInterval = 60.0,
        maxRetries: Int = 3,
        temperature: Double = 0.7,
        maxTokens: Int = 2048
    ) {
        self.baseURL = baseURL
        self.defaultModel = defaultModel
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    public static let `default` = OllamaConfig()
    public static let codeGeneration = OllamaConfig(defaultModel: "codellama", temperature: 0.2, maxTokens: 4096)
    public static let analysis = OllamaConfig(defaultModel: "llama2", temperature: 0.3, maxTokens: 2048)
    public static let creative = OllamaConfig(defaultModel: "llama2", temperature: 0.8, maxTokens: 1024)
}

public struct OllamaMessage: Codable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct OllamaGenerateResponse: Codable {
    public let model: String
    public let created_at: String
    public let response: String
    public let done: Bool
    public let context: [Int]?
    public let total_duration: Int?
    public let load_duration: Int?
    public let prompt_eval_count: Int?
    public let prompt_eval_duration: Int?
    public let eval_count: Int?
    public let eval_duration: Int?
}

public struct OllamaServerStatus {
    public let running: Bool
    public let modelCount: Int
    public let models: [String]
}

public enum OllamaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case httpError(Int)
    case modelPullFailed
    case serverNotRunning
    case modelNotAvailable(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Ollama server URL"
        case .invalidResponse:
            return "Invalid response from Ollama server"
        case let .httpError(code):
            return "HTTP error: \(code)"
        case .invalidResponseFormat:
            return "Invalid response format from Ollama"
        case .modelPullFailed:
            return "Failed to pull model from Ollama"
        case .serverNotRunning:
            return "Ollama server is not running"
        case let .modelNotAvailable(model):
            return "Model '\(model)' is not available"
        }
    }
}

// MARK: - Ollama Client

public class OllamaClient {
    private let config: OllamaConfig
    private let session: URLSession
    private let logger = OllamaLogger()

    public init(config: OllamaConfig = .default) {
        self.config = config
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        self.session = URLSession(configuration: configuration)
    }

    public func generate(
        model: String? = nil,
        prompt: String,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) async throws -> String {
        let requestModel = model ?? config.defaultModel
        let requestTemp = temperature ?? config.temperature
        let requestMaxTokens = maxTokens ?? config.maxTokens

        let requestBody: [String: Any] = [
            "model": requestModel,
            "prompt": prompt,
            "temperature": requestTemp,
            "num_predict": requestMaxTokens,
            "stream": false,
        ]

        logger.log("Generating with model: \(requestModel), prompt length: \(prompt.count)")

        let response = try await performRequest(endpoint: "api/generate", body: requestBody)
        return response["response"] as? String ?? ""
    }

    public func chat(
        model: String,
        messages: [OllamaMessage],
        temperature: Double = 0.7
    ) async throws -> String {
        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": temperature,
            "stream": false,
        ]

        let response = try await performRequest(endpoint: "api/chat", body: requestBody)

        guard let message = response["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw OllamaError.invalidResponseFormat
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func listModels() async throws -> [String] {
        let response = try await performRequest(endpoint: "api/tags", body: [:])
        let models = response["models"] as? [[String: Any]] ?? []
        return models.compactMap { $0["name"] as? String }
    }

    public func isServerRunning() async -> Bool {
        do {
            let _ = try await performRequest(endpoint: "api/tags", body: [:])
            return true
        } catch {
            return false
        }
    }

    public func getServerStatus() async -> OllamaServerStatus {
        do {
            let response = try await performRequest(endpoint: "api/tags", body: [:])
            let models = response["models"] as? [[String: Any]] ?? []
            return OllamaServerStatus(running: true, modelCount: models.count, models: models.compactMap { $0["name"] as? String })
        } catch {
            return OllamaServerStatus(running: false, modelCount: 0, models: [])
        }
    }

    private func performRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        let url = URL(string: "\(config.baseURL)/\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OllamaError.invalidResponseFormat
        }

        return json
    }
}

// MARK: - Integration Manager

public class OllamaIntegrationManager {
    private let client: OllamaClient
    private let config: OllamaConfig
    private let logger = IntegrationLogger()

    public init(config: OllamaConfig = .default) {
        self.config = config
        self.client = OllamaClient(config: config)
    }

    public func checkServiceHealth() async -> ServiceHealth {
        let serverStatus = await client.getServerStatus()
        let llama2Available = await checkModel("llama2")
        let codellamaAvailable = await checkModel("codellama")
        let availableModels = llama2Available && codellamaAvailable

        return ServiceHealth(
            ollamaRunning: serverStatus.running,
            modelsAvailable: availableModels,
            modelCount: serverStatus.modelCount,
            recommendedActions: generateHealthRecommendations(serverStatus, availableModels)
        )
    }

    private func checkModel(_ model: String) async -> Bool {
        do {
            let models = try await client.listModels()
            return models.contains(model)
        } catch {
            return false
        }
    }

    private func generateHealthRecommendations(_ status: OllamaServerStatus, _ modelsAvailable: Bool) -> [String] {
        var recommendations: [String] = []

        if !status.running {
            recommendations.append("Start Ollama server: 'ollama serve'")
        }

        if !modelsAvailable {
            recommendations.append("Pull required models: 'ollama pull llama2' and 'ollama pull codellama'")
        }

        if status.modelCount == 0 {
            recommendations.append("No models available - install Ollama and pull models")
        }

        return recommendations
    }

    public func generateCode(
        description: String,
        language: String,
        context: String? = nil,
        complexity: CodeComplexity = .standard
    ) async throws -> CodeGenerationResult {

        let prompt = buildCodeGenerationPrompt(description, language, context, complexity)
        let generatedCode = try await client.generate(
            model: "codellama",
            prompt: prompt,
            temperature: complexity.temperature,
            maxTokens: complexity.maxTokens
        )

        let analysis = try await analyzeGeneratedCode(generatedCode, language)

        return CodeGenerationResult(
            code: generatedCode,
            analysis: analysis,
            language: language,
            complexity: complexity
        )
    }

    private func buildCodeGenerationPrompt(
        _ description: String,
        _ language: String,
        _ context: String?,
        _ complexity: CodeComplexity
    ) -> String {
        var prompt = """
        Generate \(language) code for: \(description)

        Requirements:
        - Use modern \(language) best practices
        - Include proper error handling
        - Add meaningful comments
        - Follow naming conventions
        """

        if let context {
            prompt += "\n\nContext: \(context)"
        }

        switch complexity {
        case .simple:
            prompt += "\n- Keep it simple and focused"
        case .standard:
            prompt += "\n- Include comprehensive functionality"
        case .advanced:
            prompt += "\n- Implement advanced features and optimizations"
        }

        return prompt
    }

    private func analyzeGeneratedCode(_ code: String, _ language: String) async throws -> String {
        let prompt = """
        Analyze this generated \(language) code for quality and correctness:

        \(code)

        Provide a brief assessment covering:
        1. Code correctness
        2. Best practices compliance
        3. Potential improvements
        """

        return try await client.generate(model: "codellama", prompt: prompt, temperature: 0.2)
    }

    public func analyzeCodebase(
        code: String,
        language: String,
        analysisType: AnalysisType = .comprehensive
    ) async throws -> CodeAnalysisResult {

        let prompt = buildAnalysisPrompt(code, language, analysisType)
        let analysis = try await client.generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.3,
            maxTokens: 1500
        )

        let issues = extractIssues(from: analysis)
        let suggestions = extractSuggestions(from: analysis)

        return CodeAnalysisResult(
            analysis: analysis,
            issues: issues,
            suggestions: suggestions,
            language: language,
            analysisType: analysisType
        )
    }

    private func buildAnalysisPrompt(_ code: String, _ language: String, _ type: AnalysisType) -> String {
        let basePrompt = "Analyze this \(language) code:"

        switch type {
        case .bugs:
            return """
            \(basePrompt)
            Focus on identifying potential bugs, logic errors, and runtime issues.

            Code:
            \(code)

            List specific issues with line numbers and severity levels.
            """
        case .performance:
            return """
            \(basePrompt)
            Focus on performance optimization opportunities.

            Code:
            \(code)

            Identify bottlenecks, inefficient algorithms, and optimization suggestions.
            """
        case .security:
            return """
            \(basePrompt)
            Focus on security vulnerabilities and best practices.

            Code:
            \(code)

            Identify security risks and provide mitigation recommendations.
            """
        case .comprehensive:
            return """
            \(basePrompt)
            Provide comprehensive analysis covering bugs, performance, security, and best practices.

            Code:
            \(code)

            Structure your response with clear sections for each analysis category.
            """
        }
    }

    private func extractIssues(from analysis: String) -> [CodeIssue] {
        let lines = analysis.components(separatedBy: "\n")
        var issues: [CodeIssue] = []

        for line in lines {
            if line.lowercased().contains("error") || line.lowercased().contains("bug") ||
                line.lowercased().contains("issue") || line.lowercased().contains("problem")
            {
                issues.append(CodeIssue(description: line.trimmingCharacters(in: .whitespaces), severity: .medium))
            }
        }

        return issues
    }

    private func extractSuggestions(from analysis: String) -> [String] {
        let lines = analysis.components(separatedBy: "\n")
        return lines.filter { line in
            line.lowercased().contains("suggest") || line.lowercased().contains("recommend") ||
                line.lowercased().contains("improve") || line.lowercased().contains("consider")
        }.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    public func generateDocumentation(
        code: String,
        language: String,
        includeExamples: Bool = true
    ) async throws -> DocumentationResult {

        let prompt = """
        Generate comprehensive documentation for this \(language) code:

        Code:
        \(code)

        Include:
        1. Overview and purpose
        2. Function/method descriptions with parameters and return values
        3. Usage examples
        4. Important notes and considerations
        \(includeExamples ? "5. Code examples showing common use cases" : "")

        Format as clean, readable documentation with proper markdown formatting.
        """

        let documentation = try await client.generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.1,
            maxTokens: 2000
        )

        return DocumentationResult(
            documentation: documentation,
            language: language,
            includesExamples: includeExamples
        )
    }

    public func generateTests(
        code: String,
        language: String,
        testFramework: String = "XCTest"
    ) async throws -> TestGenerationResult {

        let prompt = """
        Generate comprehensive \(testFramework) unit tests for this \(language) code:

        Code to test:
        \(code)

        Requirements:
        1. Test all public methods and functions
        2. Include edge cases and error conditions
        3. Test both success and failure scenarios
        4. Use descriptive test method names
        5. Include setup and teardown methods where appropriate
        6. Add comments explaining what each test validates

        Generate the complete test file with proper structure and imports.
        """

        let testCode = try await client.generate(
            model: "codellama",
            prompt: prompt,
            temperature: 0.1,
            maxTokens: 3000
        )

        return TestGenerationResult(
            testCode: testCode,
            language: language,
            testFramework: testFramework,
            coverage: estimateTestCoverage(testCode)
        )
    }

    private func estimateTestCoverage(_ testCode: String) -> Double {
        let testMethods = testCode.components(separatedBy: "func test").count - 1
        return min(Double(testMethods) * 15.0, 85.0)
    }

    public func processBatchTasks(_ tasks: [AutomationTask]) async throws -> [TaskResult] {
        var results: [TaskResult] = []

        for task in tasks {
            logger.log("Processing task: \(task.description)")

            do {
                let result = try await processTask(task)
                results.append(result)
            } catch {
                logger.log("Task failed: \(task.description) - \(error.localizedDescription)")
                results.append(TaskResult(task: task, success: false, error: error))
            }
        }

        return results
    }

    private func processTask(_ task: AutomationTask) async throws -> TaskResult {
        switch task.type {
        case .codeGeneration:
            let result = try await generateCode(
                description: task.description,
                language: task.language ?? "Swift"
            )
            return TaskResult(task: task, success: true, codeGenerationResult: result)

        case .codeAnalysis:
            guard let code = task.code else {
                throw IntegrationError.missingRequiredData("code")
            }
            let result = try await analyzeCodebase(code: code, language: task.language ?? "Swift")
            return TaskResult(task: task, success: true, analysisResult: result)

        case .documentation:
            guard let code = task.code else {
                throw IntegrationError.missingRequiredData("code")
            }
            let result = try await generateDocumentation(code: code, language: task.language ?? "Swift")
            return TaskResult(task: task, success: true, documentationResult: result)

        case .testing:
            guard let code = task.code else {
                throw IntegrationError.missingRequiredData("code")
            }
            let result = try await generateTests(code: code, language: task.language ?? "Swift")
            return TaskResult(task: task, success: true, testResult: result)
        }
    }
}

// MARK: - Integration Types

public struct ServiceHealth {
    public let ollamaRunning: Bool
    public let modelsAvailable: Bool
    public let modelCount: Int
    public let recommendedActions: [String]
}

public enum CodeComplexity {
    case simple
    case standard
    case advanced

    var temperature: Double {
        switch self {
        case .simple: return 0.1
        case .standard: return 0.3
        case .advanced: return 0.5
        }
    }

    var maxTokens: Int {
        switch self {
        case .simple: return 1000
        case .standard: return 2000
        case .advanced: return 4000
        }
    }
}

public enum AnalysisType {
    case bugs
    case performance
    case security
    case comprehensive
}

public struct CodeGenerationResult {
    public let code: String
    public let analysis: String
    public let language: String
    public let complexity: CodeComplexity
}

public struct CodeAnalysisResult {
    public let analysis: String
    public let issues: [CodeIssue]
    public let suggestions: [String]
    public let language: String
    public let analysisType: AnalysisType
}

public struct CodeIssue {
    public let description: String
    public let severity: IssueSeverity
}

public enum IssueSeverity {
    case low
    case medium
    case high
    case critical
}

public struct DocumentationResult {
    public let documentation: String
    public let language: String
    public let includesExamples: Bool
}

public struct TestGenerationResult {
    public let testCode: String
    public let language: String
    public let testFramework: String
    public let coverage: Double
}

public struct AutomationTask {
    public let id: String
    public let type: TaskType
    public let description: String
    public let language: String?
    public let code: String?

    public enum TaskType {
        case codeGeneration
        case codeAnalysis
        case documentation
        case testing
    }
}

public struct TaskResult {
    public let task: AutomationTask
    public let success: Bool
    public let error: Error?
    public let codeGenerationResult: CodeGenerationResult?
    public let analysisResult: CodeAnalysisResult?
    public let documentationResult: DocumentationResult?
    public let testResult: TestGenerationResult?

    public init(
        task: AutomationTask,
        success: Bool,
        error: Error? = nil,
        codeGenerationResult: CodeGenerationResult? = nil,
        analysisResult: CodeAnalysisResult? = nil,
        documentationResult: DocumentationResult? = nil,
        testResult: TestGenerationResult? = nil
    ) {
        self.task = task
        self.success = success
        self.error = error
        self.codeGenerationResult = codeGenerationResult
        self.analysisResult = analysisResult
        self.documentationResult = documentationResult
        self.testResult = testResult
    }
}

public enum IntegrationError: Error {
    case missingRequiredData(String)
    case serviceUnavailable
    case invalidConfiguration
}

// MARK: - Convenience Extensions

public extension OllamaIntegrationManager {
    func quickCodeGeneration(description: String, language: String = "Swift") async throws -> String {
        let result = try await generateCode(description: description, language: language, complexity: .simple)
        return result.code
    }

    func quickAnalysis(code: String, language: String = "Swift") async throws -> String {
        let result = try await analyzeCodebase(code: code, language: language, analysisType: .comprehensive)
        return result.analysis
    }

    func healthCheck() async -> Bool {
        let health = await checkServiceHealth()
        return health.ollamaRunning && health.modelsAvailable
    }
}

// MARK: - Logger Classes

private class OllamaLogger {
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] OllamaClient: \(message)")
    }
}

private class IntegrationLogger {
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] OllamaIntegration: \(message)")
    }
}
