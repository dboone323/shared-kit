import Foundation
// import SharedKit // Will be available when integrated into package

/// Unified Ollama Integration Framework
/// Provides a clean, unified interface for all Ollama-powered automation
/// Completely free alternative to paid AI services

// MARK: - Core Integration Manager

public class OllamaIntegrationManager: AITextGenerationService, AICodeAnalysisService, AICodeGenerationService, AICachingService, AIPerformanceMonitoring {
    private let client: OllamaClient
    private let config: OllamaConfig
    private let logger = IntegrationLogger()
    private let cache = AIResponseCache()
    private let performanceMonitor = AIOperationMonitor()
    private let healthMonitor = AIHealthMonitor()
    private let retryManager = RetryManager()

    public init(config: OllamaConfig = .default) {
        self.config = config
        self.client = OllamaClient(config: config)
    }

    // MARK: - AITextGenerationService Protocol

    public func generateText(prompt: String, maxTokens: Int, temperature: Double) async throws -> String {
        let startTime = Date()
        let cacheKey = cache.generateKey(for: prompt, model: "llama2", maxTokens: maxTokens, temperature: temperature)

        // Check cache first
        if let cachedResponse = await cache.getCachedResponse(key: cacheKey) {
            await performanceMonitor.recordOperation(
                operation: "generateText",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": true, "cacheKey": cacheKey]
            )
            return cachedResponse
        }

        // Use retry manager for robust error handling
        let result = try await retryManager.retry {
            try await self.client.generate(
                model: "llama2",
                prompt: prompt,
                temperature: temperature,
                maxTokens: maxTokens
            )
        }

        // Cache the result
        await cache.cacheResponse(key: cacheKey, response: result, metadata: [
            "operation": "generateText",
            "model": "llama2",
            "maxTokens": maxTokens,
            "temperature": temperature
        ])

        await performanceMonitor.recordOperation(
            operation: "generateText",
            duration: Date().timeIntervalSince(startTime),
            success: true,
            metadata: ["cached": false, "cacheKey": cacheKey]
        )

        return result
    }

    public func isAvailable() async -> Bool {
        let health = await getHealthStatus()
        return health.isRunning
    }

    public func getHealthStatus() async -> ServiceHealth {
        let startTime = Date()
        let serverStatus = await client.getServerStatus()
        let llama2Available = await client.checkModelAvailability("llama2")
        let codellamaAvailable = await client.checkModelAvailability("codellama")
        let availableModels = llama2Available && codellamaAvailable

        let health = ServiceHealth(
            serviceName: "Ollama",
            isRunning: serverStatus.running,
            modelsAvailable: availableModels,
            responseTime: Date().timeIntervalSince(startTime),
            errorRate: await performanceMonitor.getErrorRate(for: "ollama"),
            lastChecked: Date(),
            recommendations: generateHealthRecommendations(serverStatus, availableModels)
        )

        return health
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

    // MARK: - AICodeAnalysisService Protocol

    public func analyzeCode(code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult {
        let startTime = Date()
        let cacheKey = cache.generateKey(for: code, model: "llama2", analysisType: analysisType.rawValue)

        // Check cache first
        if let cachedResponse = await cache.getCachedResponse(key: cacheKey) {
            await performanceMonitor.recordOperation(
                operation: "analyzeCode",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": true, "language": language, "analysisType": analysisType.rawValue]
            )
            // Parse cached response back to CodeAnalysisResult
            return try parseAnalysisResult(from: cachedResponse, language: language, analysisType: analysisType)
        }

        // Use retry manager for robust error handling
        let result = try await retryManager.retry {
            try await self.analyzeCodebase(code: code, language: language, analysisType: analysisType)
        }

        // Cache the result as JSON string
        let jsonData = try JSONEncoder().encode(result)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        await cache.cacheResponse(key: cacheKey, response: jsonString, metadata: [
            "operation": "analyzeCode",
            "language": language,
            "analysisType": analysisType.rawValue
        ])

        await performanceMonitor.recordOperation(
            operation: "analyzeCode",
            duration: Date().timeIntervalSince(startTime),
            success: true,
            metadata: ["cached": false, "language": language, "analysisType": analysisType.rawValue]
        )

        return result
    }

    public func generateDocumentation(code: String, language: String) async throws -> String {
        let startTime = Date()
        let cacheKey = cache.generateKey(for: code, model: "llama2", operation: "documentation")

        if let cachedResponse = await cache.getCachedResponse(key: cacheKey) {
            await performanceMonitor.recordOperation(
                operation: "generateDocumentation",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": true, "language": language]
            )
            return cachedResponse
        }

        do {
            let result = try await generateDocumentation(code: code, language: language).documentation

            await cache.cacheResponse(key: cacheKey, response: result, metadata: [
                "operation": "generateDocumentation",
                "language": language
            ])

            await performanceMonitor.recordOperation(
                operation: "generateDocumentation",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": false, "language": language]
            )

            return result
        } catch {
            await performanceMonitor.recordOperation(
                operation: "generateDocumentation",
                duration: Date().timeIntervalSince(startTime),
                success: false,
                metadata: ["error": error.localizedDescription, "language": language]
            )
            throw error
        }
    }

    public func generateTests(code: String, language: String) async throws -> String {
        let startTime = Date()
        let cacheKey = cache.generateKey(for: code, model: "codellama", operation: "tests")

        if let cachedResponse = await cache.getCachedResponse(key: cacheKey) {
            await performanceMonitor.recordOperation(
                operation: "generateTests",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": true, "language": language]
            )
            return cachedResponse
        }

        do {
            let result = try await generateTests(code: code, language: language).testCode

            await cache.cacheResponse(key: cacheKey, response: result, metadata: [
                "operation": "generateTests",
                "language": language
            ])

            await performanceMonitor.recordOperation(
                operation: "generateTests",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": false, "language": language]
            )

            return result
        } catch {
            await performanceMonitor.recordOperation(
                operation: "generateTests",
                duration: Date().timeIntervalSince(startTime),
                success: false,
                metadata: ["error": error.localizedDescription, "language": language]
            )
            throw error
        }
    }

    // MARK: - AICodeGenerationService Protocol

    public func generateCode(description: String, language: String, context: String?) async throws -> CodeGenerationResult {
        let startTime = Date()
        let cacheKey = cache.generateKey(for: description, model: "codellama", context: context)

        if let cachedResponse = await cache.getCachedResponse(key: cacheKey) {
            await performanceMonitor.recordOperation(
                operation: "generateCode",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": true, "language": language]
            )
            return try parseCodeGenerationResult(from: cachedResponse, language: language)
        }

        do {
            let result = try await generateCode(
                description: description,
                language: language,
                context: context,
                complexity: .standard
            )

            // Cache the result
            let jsonData = try JSONEncoder().encode(result)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            await cache.cacheResponse(key: cacheKey, response: jsonString, metadata: [
                "operation": "generateCode",
                "language": language,
                "context": context ?? ""
            ])

            await performanceMonitor.recordOperation(
                operation: "generateCode",
                duration: Date().timeIntervalSince(startTime),
                success: true,
                metadata: ["cached": false, "language": language]
            )

            return result
        } catch {
            await performanceMonitor.recordOperation(
                operation: "generateCode",
                duration: Date().timeIntervalSince(startTime),
                success: false,
                metadata: ["error": error.localizedDescription, "language": language]
            )
            throw error
        }
    }

    public func generateCodeWithFallback(description: String, language: String, context: String?) async throws -> CodeGenerationResult {
        do {
            return try await generateCode(description: description, language: language, context: context)
        } catch {
            logger.log("Ollama code generation failed, trying Hugging Face fallback: \(error.localizedDescription)")

            // Fallback to Hugging Face
            let prompt = buildCodeGenerationPrompt(description, language, context, .standard)
            let fallbackResult = try await HuggingFaceClient.shared.generateWithFallback(
                prompt: prompt,
                maxTokens: 500,
                temperature: 0.3,
                taskType: .codeGeneration
            )

            return CodeGenerationResult(
                code: fallbackResult,
                analysis: "Generated via Hugging Face fallback",
                language: language,
                complexity: .standard
            )
        }
    }

    private func buildCodeGenerationPrompt(
        _ description: String,
        _ language: String,
        _ context: String?,
        _ complexity: CodeComplexity
    ) -> String {
        var promptParts = [
            """
            Generate \(language) code for: \(description)

            Requirements:
            - Use modern \(language) best practices
            - Include proper error handling
            - Add meaningful comments
            - Follow naming conventions
            """,
        ]

        if let context {
            promptParts.append("\n\nContext: \(context)")
        }

        switch complexity {
        case .simple:
            promptParts.append("\n- Keep it simple and focused")
        case .standard:
            promptParts.append("\n- Include comprehensive functionality")
        case .advanced:
            promptParts.append("\n- Implement advanced features and optimizations")
        }

        return promptParts.joined()
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

        return try await self.client.generate(model: "codellama", prompt: prompt, temperature: 0.2)
    }

    // MARK: - Code Analysis

    public func analyzeCodebase(
        code: String,
        language: String,
        analysisType: AnalysisType = .comprehensive
    ) async throws -> CodeAnalysisResult {
        let prompt = self.buildAnalysisPrompt(code, language, analysisType)
        let analysis = try await client.generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.3,
            maxTokens: 1500
        )

        let issues = self.extractIssues(from: analysis)
        let suggestions = self.extractSuggestions(from: analysis)

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
                line.lowercased().contains("issue") || line.lowercased().contains("problem") {
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
            coverage: self.estimateTestCoverage(testCode)
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
            self.logger.log("Processing task: \(task.description)")

            do {
                let result = try await processTask(task)
                results.append(result)
            } catch {
                self.logger.log("Task failed: \(task.description) - \(error.localizedDescription)")
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

// MARK: - Logger

private class IntegrationLogger {
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] OllamaIntegration: \(message)")
    }
}

    // MARK: - AICachingService Protocol

    public func cacheResponse(key: String, response: String, metadata: [String: Any]?) async {
        await cache.cacheResponse(key: key, response: response, metadata: metadata)
    }

    public func getCachedResponse(key: String) async -> String? {
        await cache.getCachedResponse(key: key)
    }

    public func clearCache() async {
        await cache.clearCache()
    }

    public func getCacheStats() async -> CacheStats {
        await cache.getCacheStats()
    }

    // MARK: - AIPerformanceMonitoring Protocol

    public func recordOperation(operation: String, duration: TimeInterval, success: Bool, metadata: [String: Any]?) async {
        await performanceMonitor.recordOperation(operation: operation, duration: duration, success: success, metadata: metadata)
    }

    public func getPerformanceMetrics() async -> PerformanceMetrics {
        await performanceMonitor.getPerformanceMetrics()
    }

    public func resetMetrics() async {
        await performanceMonitor.resetMetrics()
    }
    /// Generate text with Ollama primary, Hugging Face fallback
    func generateWithFallback(
        prompt: String,
        model: String = "llama2",
        maxTokens: Int = 100,
        temperature: Double = 0.7
    ) async throws -> String {
        do {
            // Try Ollama first (preferred - local, fast, free)
            return try await self.client.generate(
                prompt: prompt,
                model: model,
                maxTokens: maxTokens,
                temperature: temperature
            )
        } catch {
            self.logger.log("Ollama generation failed, trying Hugging Face fallback: \(error.localizedDescription)")

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
            self.logger.log("Ollama analysis failed, trying Hugging Face fallback: \(error.localizedDescription)")

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
            return try await self.generateDocumentation(code: code, language: language)
        } catch {
            self.logger.log("Ollama documentation failed, trying Hugging Face fallback: \(error.localizedDescription)")

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

/// Health monitoring for AI services
public class AIHealthMonitor {
    public static let shared = AIHealthMonitor()

    private var ollamaHealthHistory: [Date: Bool] = [:]
    private var huggingFaceHealthHistory: [Date: Bool] = [:]
    private let maxHistorySize = 100

    private init() {}

    /// Record health status for Ollama
    public func recordOllamaHealth(_ healthy: Bool) {
        self.recordHealth(&self.ollamaHealthHistory, healthy: healthy)
    }

    /// Record health status for Hugging Face
    public func recordHuggingFaceHealth(_ healthy: Bool) {
        self.recordHealth(&self.huggingFaceHealthHistory, healthy: healthy)
    }

    /// Get health statistics
    public func getHealthStats() -> HealthStats {
        let ollamaUptime = self.calculateUptime(self.ollamaHealthHistory)
        let huggingFaceUptime = self.calculateUptime(self.huggingFaceHealthHistory)

        return HealthStats(
            ollamaUptime: ollamaUptime,
            huggingFaceUptime: huggingFaceUptime,
            lastOllamaCheck: self.ollamaHealthHistory.keys.max(),
            lastHuggingFaceCheck: self.huggingFaceHealthHistory.keys.max()
        )
    }

    /// Get current health status
    public func getCurrentHealth() async -> CurrentHealth {
        let ollamaHealthy = await OllamaIntegrationManager().healthCheck()
        let huggingFaceHealthy = await HuggingFaceClient.shared.isAvailable()

        self.recordOllamaHealth(ollamaHealthy)
        self.recordHuggingFaceHealth(huggingFaceHealthy)

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
        if history.count > self.maxHistorySize {
            let oldestKeys = history.keys.sorted().prefix(history.count - self.maxHistorySize)
            for key in oldestKeys {
                history.removeValue(forKey: key)
            }
        }
    }

    private func calculateUptime(_ history: [Date: Bool]) -> Double {
        guard !history.isEmpty else { return 0.0 }

        let healthyCount = history.values.count(where: { $0 })
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

// MARK: - Retry Manager

/// Intelligent retry manager with exponential backoff and circuit breaker pattern
private actor RetryManager {
    private var failureCounts: [String: Int] = [:]
    private var lastFailureTimes: [String: Date] = [:]
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    private let circuitBreakerThreshold = 5
    private let circuitBreakerTimeout: TimeInterval = 60.0 // 1 minute

    func retry<T>(
        operation: String = "unknown",
        _ block: @escaping () async throws -> T
    ) async throws -> T {
        let circuitBreakerKey = operation

        // Check circuit breaker
        if isCircuitBreakerOpen(for: circuitBreakerKey) {
            throw AIError.serviceUnavailable("Circuit breaker open for operation: \(operation)")
        }

        var lastError: Error?
        var attempt = 0

        while attempt < maxRetries {
            do {
                let result = try await block()
                // Success - reset failure count
                await resetFailureCount(for: circuitBreakerKey)
                return result
            } catch {
                lastError = error
                attempt += 1

                // Record failure for circuit breaker
                await recordFailure(for: circuitBreakerKey)

                // Don't retry on certain errors
                if shouldNotRetry(error) {
                    break
                }

                // Calculate delay with exponential backoff and jitter
                if attempt < maxRetries {
                    let delay = calculateDelay(for: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? AIError.operationFailed("All retry attempts failed for operation: \(operation)")
    }

    private func shouldNotRetry(_ error: Error) -> Bool {
        // Don't retry authentication or configuration errors
        if let aiError = error as? AIError {
            switch aiError {
            case .authenticationFailed, .invalidConfiguration:
                return true
            default:
                return false
            }
        }
        return false
    }

    private func calculateDelay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return min(exponentialDelay + jitter, 30.0) // Cap at 30 seconds
    }

    private func isCircuitBreakerOpen(for key: String) -> Bool {
        guard let failureCount = failureCounts[key],
              let lastFailure = lastFailureTimes[key] else {
            return false
        }

        if failureCount >= circuitBreakerThreshold {
            let timeSinceLastFailure = Date().timeIntervalSince(lastFailure)
            return timeSinceLastFailure < circuitBreakerTimeout
        }

        return false
    }

    private func recordFailure(for key: String) {
        failureCounts[key, default: 0] += 1
        lastFailureTimes[key] = Date()
    }

    private func resetFailureCount(for key: String) {
        failureCounts[key] = 0
        lastFailureTimes.removeValue(forKey: key)
    }
}

// MARK: - Private Helper Classes

/// Enhanced AI response caching with TTL and metadata support
private actor AIResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private var accessOrder: [String] = [] // For LRU eviction
    private let maxCacheSize = 200
    private let defaultExpiration: TimeInterval = 1800 // 30 minutes
    private var accessCounts: [String: Int] = [:]
    private var hitCount = 0
    private var missCount = 0

    struct CachedResponse {
        let response: String
        let metadata: [String: Any]?
        let timestamp: Date
        let expirationDate: Date
        let accessCount: Int
        let size: Int // Response size in bytes
    }

    func generateKey(for prompt: String, model: String, maxTokens: Int? = nil, temperature: Double? = nil, analysisType: String? = nil, context: String? = nil, operation: String? = nil) -> String {
        var components = [prompt, model]
        if let maxTokens { components.append(String(maxTokens)) }
        if let temperature { components.append(String(temperature)) }
        if let analysisType { components.append(analysisType) }
        if let context { components.append(context) }
        if let operation { components.append(operation) }
        return components.joined(separator: "|").hashValue.description
    }

    func cacheResponse(key: String, response: String, metadata: [String: Any]? = nil, expiration: TimeInterval? = nil) {
        let expirationDate = Date().addingTimeInterval(expiration ?? defaultExpiration)
        let size = response.utf8.count
        let accessCount = accessCounts[key, default: 0]

        let cachedResponse = CachedResponse(
            response: response,
            metadata: metadata,
            timestamp: Date(),
            expirationDate: expirationDate,
            accessCount: accessCount,
            size: size
        )

        // Clean up expired entries first
        cleanup()

        // Remove existing entry if present
        if let existingIndex = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: existingIndex)
        }

        // Check cache size and evict if necessary
        while cache.count >= maxCacheSize {
            evictLRU()
        }

        cache[key] = cachedResponse
        accessOrder.append(key) // Most recently used
        accessCounts[key, default: 0] += 1
    }

    func getCachedResponse(key: String) -> String? {
        guard let cached = cache[key] else {
            missCount += 1
            return nil
        }

        // Check if expired
        if Date() > cached.expirationDate {
            cache.removeValue(forKey: key)
            accessCounts.removeValue(forKey: key)
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
            missCount += 1
            return nil
        }

        // Update LRU order
        if let index = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: index)
        }
        accessOrder.append(key)

        accessCounts[key, default: 0] += 1
        hitCount += 1
        return cached.response
    }

    func clearCache() {
        cache.removeAll()
        accessCounts.removeAll()
    }

    func getCacheStats() -> CacheStats {
        cleanup()

        let totalEntries = cache.count
        let totalRequests = hitCount + missCount
        let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0

        let responseTimes = cache.values.map { Date().timeIntervalSince($0.timestamp) }
        let averageResponseTime = responseTimes.isEmpty ? 0.0 : responseTimes.reduce(0, +) / Double(responseTimes.count)

        let cacheSize = cache.values.reduce(0) { $0 + $1.size }

        return CacheStats(
            totalEntries: totalEntries,
            hitRate: hitRate,
            averageResponseTime: averageResponseTime,
            cacheSize: cacheSize,
            lastCleanup: Date()
        )
    }

    private func evictLRU() {
        // Remove least recently used item
        if let lruKey = accessOrder.first {
            cache.removeValue(forKey: lruKey)
            accessCounts.removeValue(forKey: lruKey)
            accessOrder.removeFirst()
        }
    }

    private func cleanup() {
        let now = Date()
        let expiredKeys = cache.filter { now > $0.value.expirationDate }.keys
        for key in expiredKeys {
            cache.removeValue(forKey: key)
            accessCounts.removeValue(forKey: key)
            if let index = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: index)
            }
        }
    }
}

/// Performance monitoring for AI operations
private actor AIOperationMonitor {
    private var operations: [String: [OperationRecord]] = [:]
    private let maxHistorySize = 1000
    private var startTime: Date = Date()

    struct OperationRecord {
        let duration: TimeInterval
        let success: Bool
        let timestamp: Date
        let metadata: [String: Any]?
    }

    func recordOperation(operation: String, duration: TimeInterval, success: Bool, metadata: [String: Any]? = nil) {
        let record = OperationRecord(
            duration: duration,
            success: success,
            timestamp: Date(),
            metadata: metadata
        )

        operations[operation, default: []].append(record)

        // Keep only recent history
        if operations[operation]!.count > maxHistorySize {
            operations[operation]!.removeFirst(operations[operation]!.count - maxHistorySize)
        }
    }

    func getPerformanceMetrics() -> PerformanceMetrics {
        let allRecords = operations.values.flatMap { $0 }
        let totalOperations = allRecords.count
        let successfulOperations = allRecords.filter { $0.success }.count
        let successRate = totalOperations > 0 ? Double(successfulOperations) / Double(totalOperations) : 0.0

        let durations = allRecords.map { $0.duration }
        let averageResponseTime = durations.isEmpty ? 0.0 : durations.reduce(0, +) / Double(durations.count)

        let errorBreakdown = operations.mapValues { records in
            records.filter { !$0.success }.count
        }

        let peakConcurrent = 1 // Simplified - would need more sophisticated tracking

        return PerformanceMetrics(
            totalOperations: totalOperations,
            successRate: successRate,
            averageResponseTime: averageResponseTime,
            errorBreakdown: errorBreakdown,
            peakConcurrentOperations: peakConcurrent,
            uptime: Date().timeIntervalSince(startTime)
        )
    }

    func getErrorRate(for operation: String) -> Double {
        guard let records = operations[operation], !records.isEmpty else { return 0.0 }
        let failedOperations = records.filter { !$0.success }.count
        return Double(failedOperations) / Double(records.count)
    }

    func resetMetrics() {
        operations.removeAll()
        startTime = Date()
    }
}

// MARK: - Helper Methods

extension OllamaIntegrationManager {
    private func parseAnalysisResult(from jsonString: String, language: String, analysisType: AnalysisType) throws -> CodeAnalysisResult {
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(CodeAnalysisResult.self, from: jsonData)
    }

    private func parseCodeGenerationResult(from jsonString: String, language: String) throws -> CodeGenerationResult {
        let jsonData = jsonString.data(using: .utf8) ?? Data()
        return try JSONDecoder().decode(CodeGenerationResult.self, from: jsonData)
    }
}
