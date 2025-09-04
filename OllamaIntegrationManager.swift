import Foundation
import HuggingFaceClient

/// Unified Ollama Integration Framework
/// Provides a clean, unified interface for all Ollama-powered automation
/// Completely free alternative to paid AI services

// MARK: - Core Integration Manager

public class OllamaIntegrationManager {
    private let client: OllamaClient
    private let config: OllamaConfig
    private let logger = IntegrationLogger()

    public init(config: OllamaConfig = .default) {
        self.config = config
        self.client = OllamaClient(config: config)
    }

    // MARK: - Service Status

    public func checkServiceHealth() async -> ServiceHealth {
        let serverStatus = await client.getServerStatus()
        let llama2Available = await client.checkModelAvailability("llama2")
        let codellamaAvailable = await client.checkModelAvailability("codellama")
        let availableModels = llama2Available && codellamaAvailable

        return ServiceHealth(
            ollamaRunning: serverStatus.running,
            modelsAvailable: availableModels,
            modelCount: serverStatus.modelCount,
            recommendedActions: generateHealthRecommendations(serverStatus, availableModels)
        )
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

    // MARK: - Code Generation

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

    // MARK: - Code Analysis

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
        // Simple extraction - could be enhanced with more sophisticated parsing
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

    // MARK: - Documentation Generation

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

    // MARK: - Test Generation

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
        // Simple estimation based on test method count
        let testMethods = testCode.components(separatedBy: "func test").count - 1
        // Rough estimation: more test methods = higher coverage
        return min(Double(testMethods) * 15.0, 85.0)
    }

    // MARK: - Batch Processing

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

// MARK: - Supporting Types

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

// MARK: - Logger

private class IntegrationLogger {
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] OllamaIntegration: \(message)")
    }
}

// MARK: - Fallback Integration with Hugging Face

public extension OllamaIntegrationManager {
    /// Generate text with Ollama primary, Hugging Face fallback
    func generateWithFallback(
        prompt: String,
        model: String = "llama2",
        maxTokens: Int = 100,
        temperature: Double = 0.7
    ) async throws -> String {
        do {
            // Try Ollama first (preferred - local, fast, free)
            return try await client.generate(
                prompt: prompt,
                model: model,
                maxTokens: maxTokens,
                temperature: temperature
            )
        } catch {
            logger.log("Ollama generation failed, trying Hugging Face fallback: \(error.localizedDescription)")

            // Fallback to Hugging Face (online, rate-limited but still free)
            return try await HuggingFaceClient.shared.generateWithFallback(
                prompt: prompt,
                maxTokens: maxTokens,
                temperature: temperature,
                taskType: .general
            )
        }
    }

    /// Analyze code with Ollama primary, Hugging Face fallback
    func analyzeCodeWithFallback(
        code: String,
        language: String,
        analysisType: AnalysisType = .comprehensive
    ) async throws -> String {
        do {
            // Try Ollama first
            let result = try await analyzeCodebase(code: code, language: language, analysisType: analysisType)
            return result.analysis
        } catch {
            logger.log("Ollama analysis failed, trying Hugging Face fallback: \(error.localizedDescription)")

            // Fallback to Hugging Face
            return try await HuggingFaceClient.shared.generateWithFallback(
                prompt: code,
                maxTokens: 150,
                temperature: 0.3,
                taskType: .codeAnalysis
            )
        }
    }

    /// Generate documentation with Ollama primary, Hugging Face fallback
    func generateDocumentationWithFallback(
        code: String,
        language: String
    ) async throws -> String {
        do {
            // Try Ollama first
            return try await generateDocumentation(code: code, language: language)
        } catch {
            logger.log("Ollama documentation failed, trying Hugging Face fallback: \(error.localizedDescription)")

            // Fallback to Hugging Face
            return try await HuggingFaceClient.shared.generateWithFallback(
                prompt: code,
                maxTokens: 200,
                temperature: 0.2,
                taskType: .documentation
            )
        }
    }

    /// Check if any free AI service is available
    func checkAnyServiceAvailable() async -> Bool {
        let ollamaHealth = await checkServiceHealth()
        let huggingFaceAvailable = await HuggingFaceClient.shared.isAvailable()

        return ollamaHealth.ollamaRunning || huggingFaceAvailable
    }

    /// Get service availability status
    func getServiceStatus() async -> (ollama: Bool, huggingFace: Bool, anyAvailable: Bool) {
        let ollamaHealth = await checkServiceHealth()
        let huggingFaceAvailable = await HuggingFaceClient.shared.isAvailable()
        let anyAvailable = ollamaHealth.ollamaRunning || huggingFaceAvailable

        return (ollamaHealth.ollamaRunning, huggingFaceAvailable, anyAvailable)
    }
}

/// Health monitoring for AI services
public class AIHealthMonitor {
    public static let shared = AIHealthMonitor()

    private var ollamaHealthHistory: [Date: Bool] = [:]
    private var huggingFaceHealthHistory: [Date: Bool] = [:]
    private let maxHistorySize = 100

    private init() {}

    /// Record health status for Ollama
    public func recordOllamaHealth(_ healthy: Bool) {
        recordHealth(&ollamaHealthHistory, healthy: healthy)
    }

    /// Record health status for Hugging Face
    public func recordHuggingFaceHealth(_ healthy: Bool) {
        recordHealth(&huggingFaceHealthHistory, healthy: healthy)
    }

    /// Get health statistics
    public func getHealthStats() -> HealthStats {
        let ollamaUptime = calculateUptime(ollamaHealthHistory)
        let huggingFaceUptime = calculateUptime(huggingFaceHealthHistory)

        return HealthStats(
            ollamaUptime: ollamaUptime,
            huggingFaceUptime: huggingFaceUptime,
            lastOllamaCheck: ollamaHealthHistory.keys.max(),
            lastHuggingFaceCheck: huggingFaceHealthHistory.keys.max()
        )
    }

    /// Get current health status
    public func getCurrentHealth() async -> CurrentHealth {
        let ollamaHealthy = await OllamaIntegrationManager().healthCheck()
        let huggingFaceHealthy = await HuggingFaceClient.shared.isAvailable()

        recordOllamaHealth(ollamaHealthy)
        recordHuggingFaceHealth(huggingFaceHealthy)

        return CurrentHealth(
            ollamaHealthy: ollamaHealthy,
            huggingFaceHealthy: huggingFaceHealthy,
            anyServiceAvailable: ollamaHealthy || huggingFaceHealthy
        )
    }

    private func recordHealth(_ history: inout [Date: Bool], healthy: Bool) {
        let now = Date()
        history[now] = healthy

        // Keep only recent history
        if history.count > maxHistorySize {
            let oldestKeys = history.keys.sorted().prefix(history.count - maxHistorySize)
            for key in oldestKeys {
                history.removeValue(forKey: key)
            }
        }
    }

    private func calculateUptime(_ history: [Date: Bool]) -> Double {
        guard !history.isEmpty else { return 0.0 }

        let healthyCount = history.values.filter { $0 }.count
        return Double(healthyCount) / Double(history.count)
    }
}

public struct HealthStats {
    public let ollamaUptime: Double
    public let huggingFaceUptime: Double
    public let lastOllamaCheck: Date?
    public let lastHuggingFaceCheck: Date?
}

public struct CurrentHealth {
    public let ollamaHealthy: Bool
    public let huggingFaceHealthy: Bool
    public let anyServiceAvailable: Bool
}
