import Foundation
import OSLog

/// Enhanced Hugging Face API Client with Quantum Performance
/// Provides access to Hugging Face's free inference API with advanced features
/// Enhanced by AI System v2.1 on 9/12/25

// MARK: - Enhanced Error Types

public enum HuggingFaceError: LocalizedError {
    case invalidURL
    case networkError(String)
    case apiError(String)
    case rateLimited
    case modelLoading
    case parsingError(String)
    case authenticationError
    case modelNotSupported(String)
    case quotaExceeded
    case serverOverloaded

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid Hugging Face API URL"
        case let .networkError(message):
            "Network error: \(message)"
        case let .apiError(message):
            "API error: \(message)"
        case .rateLimited:
            "Rate limit exceeded. Please wait before making more requests."
        case .modelLoading:
            "Model is loading. This may take a few minutes for first use."
        case let .parsingError(message):
            "Response parsing error: \(message)"
        case .authenticationError:
            "Authentication failed. Please check your API token."
        case let .modelNotSupported(model):
            "Model '\(model)' is not supported or available on free tier"
        case .quotaExceeded:
            "API quota exceeded. Please upgrade your plan or try again later."
        case .serverOverloaded:
            "Servers are overloaded. Please try again in a few minutes."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .rateLimited:
            "Wait 1-2 minutes before retrying, or use a different model"
        case .modelLoading:
            "Wait a few minutes for the model to load, then try again"
        case .authenticationError:
            "Set your Hugging Face token in environment variable HF_TOKEN"
        case .quotaExceeded:
            "Consider upgrading to a paid plan or using Ollama as fallback"
        case .serverOverloaded:
            "Try again in a few minutes or use a different model"
        default:
            "Check your internet connection and try again"
        }
    }
}

import Foundation
import OSLog
// import SharedKit // Will be available when integrated into package

/// Enhanced Hugging Face API Client with Quantum Performance
/// Provides access to Hugging Face's free inference API with advanced features
/// Enhanced by AI System v2.1 on 9/12/25

public class HuggingFaceClient {
    public static let shared = HuggingFaceClient()

    private let baseURL = "https://api-inference.huggingface.co"
    private let session: URLSession
    private let cache = ResponseCache()
    private let metrics = PerformanceMetricsTracker()
    private let circuitBreaker = CircuitBreaker()
    private let retryManager = RetryManager()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 300.0
        self.session = URLSession(configuration: config)
    }

    /// Generate text using Hugging Face free inference API
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - model: The model to use (default: gpt2)
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Creativity parameter (0.0-1.0)
    /// - Returns: Generated text response
    public func generate(
        prompt: String,
        model: String = "gpt2",
        maxTokens: Int = 100,
        temperature: Double = 0.7
    ) async throws -> String {
        let startTime = Date()
        let cacheKey = self.cache.cacheKey(for: prompt, model: model, maxTokens: maxTokens, temperature: temperature)

        // Check circuit breaker
        guard await circuitBreaker.canExecute(operation: "generate") else {
            metrics.recordRequest(startTime: startTime, success: false, errorType: "circuitBreaker")
            throw HuggingFaceError.apiError("Circuit breaker open - service temporarily unavailable")
        }

        // Check cache first
        if let cachedResponse = cache.get(cacheKey) {
            self.metrics.recordRequest(startTime: startTime, success: true)
            return cachedResponse
        }

        // Use retry manager with circuit breaker integration
        let result = try await retryManager.retry(operation: "generate") {
            try await self.performGenerateRequest(
                prompt: prompt,
                model: model,
                maxTokens: maxTokens,
                temperature: temperature
            )
        }

        self.cache.set(cacheKey, response: result, prompt: prompt, model: model)
        self.metrics.recordRequest(startTime: startTime, success: true)
        return result
    }

    private func performGenerateRequest(
        prompt: String,
        model: String,
        maxTokens: Int,
        temperature: Double
    ) async throws -> String {
        let endpoint = "/models/\(model)"

        guard let url = URL(string: baseURL + endpoint) else {
            throw HuggingFaceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add authorization header if token is available
        if let token = getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "max_length": min(maxTokens, 100), // Free tier limit
                "temperature": temperature,
                "do_sample": true,
                "return_full_text": false,
            ],
            "options": [
                "wait_for_model": true,
                "use_cache": true,
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HuggingFaceError.networkError("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200:
            return try parseSuccessResponse(data)
        case 404:
            throw HuggingFaceError.apiError("Model not found or not available on free tier")
        case 429:
            await circuitBreaker.recordFailure(operation: "generate")
            throw HuggingFaceError.rateLimited
        case 503:
            await circuitBreaker.recordFailure(operation: "generate")
            throw HuggingFaceError.modelLoading
        default:
            let errorMessage = try? parseErrorResponse(data)
            throw HuggingFaceError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage ?? "Unknown error")")
        }
    }

    /// Analyze code using a code-specific model
    /// - Parameters:
    ///   - code: The code to analyze
    ///   - language: Programming language
    ///   - task: Analysis task (documentation, review, etc.)
    /// - Returns: Analysis result
    public func analyzeCode(
        code: String,
        language: String,
        task: String = "analyze"
    ) async throws -> String {
        let prompt = """
        Analyze this \(language) code and provide insights:

        ```\(language)
        \(code)
        ```

        Task: \(task)
        Please provide a clear, concise analysis focusing on:
        - Code quality and structure
        - Potential improvements
        - Best practices
        - Any issues or concerns

        Keep the response under 200 words.
        """

        return try await self.generate(
            prompt: prompt,
            model: "microsoft/DialoGPT-medium",
            maxTokens: 150,
            temperature: 0.3
        )
    }

    /// Generate documentation for code
    /// - Parameters:
    ///   - code: The code to document
    ///   - language: Programming language
    /// - Returns: Generated documentation
    public func generateDocumentation(
        code: String,
        language: String
    ) async throws -> String {
        let prompt = """
        Generate clear, concise documentation for this \(language) code:

        ```\(language)
        \(code)
        ```

        Include:
        - Brief description of what the code does
        - Key functions/methods and their purposes
        - Important parameters or return values
        - Any notable patterns or design decisions

        Format as clean markdown documentation.
        """

        return try await self.generate(
            prompt: prompt,
            model: "microsoft/DialoGPT-medium",
            maxTokens: 200,
            temperature: 0.2
        )
    }

    /// Generate text with automatic model fallback and retry logic
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Creativity parameter (0.0-1.0)
    ///   - taskType: Type of task for model selection
    /// - Returns: Generated text response
    public func generateWithFallback(
        prompt: String,
        maxTokens: Int = 100,
        temperature: Double = 0.7,
        taskType: TaskType = .general
    ) async throws -> String {
        let models = self.getModelsForTask(taskType)
        var lastError: Error?

        for model in models {
            var retryCount = 0
            let maxRetries = 3

            while retryCount <= maxRetries {
                do {
                    return try await self.generate(
                        prompt: prompt,
                        model: model,
                        maxTokens: maxTokens,
                        temperature: temperature
                    )
                } catch let error as HuggingFaceError {
                    lastError = error

                    // Don't retry for certain errors
                    if case .invalidURL = error {
                        break
                    }

                    // Don't retry for model not found
                    if case let .apiError(message) = error, message.contains("not found") {
                        break
                    }

                    // Exponential backoff for rate limits and model loading
                    if case .rateLimited = error {
                        let delay = pow(2.0, Double(retryCount)) * 1.0 // 1, 2, 4 seconds
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        retryCount += 1
                        continue
                    }

                    if case .modelLoading = error {
                        let delay = pow(2.0, Double(retryCount)) * 2.0 // 2, 4, 8 seconds
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        retryCount += 1
                        continue
                    }

                    // For other API errors, try next model
                    break
                } catch {
                    lastError = error
                    break
                }
            }
        }

        throw lastError ?? HuggingFaceError
            .apiError("All available models are currently unavailable. Free inference API may be experiencing issues.")
    }

    /// Task types for intelligent model selection
    public enum TaskType {
        case general
        case codeGeneration
        case codeAnalysis
        case documentation
        case conversation
    }

    /// Get models optimized for specific task types
    private func getModelsForTask(_ taskType: TaskType) -> [String] {
        switch taskType {
        case .general:
            ["gpt2", "distilgpt2", "microsoft/DialoGPT-medium"]
        case .codeGeneration:
            ["codellama/CodeLlama-7b-hf", "gpt2", "microsoft/DialoGPT-medium"]
        case .codeAnalysis:
            ["microsoft/DialoGPT-medium", "gpt2", "distilgpt2"]
        case .documentation:
            ["gpt2", "microsoft/DialoGPT-medium", "distilgpt2"]
        case .conversation:
            ["microsoft/DialoGPT-medium", "microsoft/DialoGPT-small", "gpt2"]
        }
    }

    /// Get performance metrics
    /// - Returns: Current performance statistics
    public func getPerformanceMetrics() -> PerformanceMetrics {
        let metrics = self.metrics.getMetrics()
        return PerformanceMetrics(
            totalOperations: metrics.totalRequests,
            successRate: metrics.successRate,
            averageResponseTime: metrics.averageResponseTime,
            errorBreakdown: metrics.errorBreakdown
        )
    }

    /// Check if Hugging Face service is available
    public func isAvailable() async -> Bool {
        do {
            // Try a simple request to check availability
            _ = try await generate(prompt: "test", model: "gpt2", maxTokens: 10, temperature: 0.1)
            return true
        } catch {
            return false
        }
    }

    /// Get service health status
    /// - Returns: Health status with metrics
    public func getHealthStatus() async -> ServiceHealth {
        let metrics = self.metrics.getMetrics()
        let isHealthy = self.metrics.isHealthy()

        return ServiceHealth(
            serviceName: "HuggingFace",
            isRunning: isHealthy,
            modelsAvailable: true, // Assume models are available if service is healthy
            responseTime: metrics.averageResponseTime,
            errorRate: 1.0 - metrics.successRate,
            lastChecked: Date(),
            recommendations: isHealthy ? [] : ["Check network connectivity", "Verify API key if configured"]
        )
    }
}

// MARK: - AI Service Protocol Implementations

extension HuggingFaceClient: AITextGenerationService, AICodeAnalysisService, AICodeGenerationService, AICachingService, AIPerformanceMonitoring {
    // MARK: - AITextGenerationService Implementation

    public func generateText(prompt: String, maxTokens: Int, temperature: Double) async throws -> String {
        return try await generate(
            prompt: prompt,
            model: "gpt2",
            maxTokens: maxTokens,
            temperature: temperature
        )
    }

    // MARK: - AICodeAnalysisService Implementation

    public func analyzeCode(code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult {
        let analysis = try await analyzeCode(code: code, language: language, task: analysisType.rawValue)

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

    private func extractIssues(from analysis: String) -> [CodeIssue] {
        let lines = analysis.components(separatedBy: "\n")
        var issues: [CodeIssue] = []

        for line in lines {
            if line.lowercased().contains("error") ||
               line.lowercased().contains("bug") ||
               line.lowercased().contains("issue") ||
               line.lowercased().contains("problem") ||
               line.lowercased().contains("warning") {
                issues.append(CodeIssue(description: line.trimmingCharacters(in: .whitespaces), severity: .medium))
            }
        }

        return issues
    }

    private func extractSuggestions(from analysis: String) -> [String] {
        let lines = analysis.components(separatedBy: "\n")
        return lines.filter { line in
            line.lowercased().contains("suggest") ||
            line.lowercased().contains("recommend") ||
            line.lowercased().contains("improve") ||
            line.lowercased().contains("consider") ||
            line.lowercased().contains("should")
        }.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - AICodeGenerationService Implementation

    public func generateCode(description: String, language: String, context: String?) async throws -> CodeGenerationResult {
        let fullPrompt = """
        Generate \(language) code based on this request: \(description)
        \(context != nil ? "Context: \(context!)" : "")
        Provide only the code without explanation or markdown formatting.
        """

        let code = try await generateWithFallback(
            prompt: fullPrompt,
            maxTokens: 200,
            temperature: 0.3,
            taskType: .codeGeneration
        )

        return CodeGenerationResult(
            code: code,
            analysis: "Generated via Hugging Face API",
            language: language,
            complexity: .standard
        )
    }

    public func generateFunction(name: String, parameters: [String: String], returnType: String, language: String, description: String?) async throws -> String {
        let paramString = parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let prompt = """
        Generate a \(language) function named '\(name)' with parameters (\(paramString)) returning \(returnType).
        \(description != nil ? "Description: \(description!)" : "")
        Provide only the function code without explanation.
        """

        return try await generateWithFallback(
            prompt: prompt,
            maxTokens: 150,
            temperature: 0.3,
            taskType: .codeGeneration
        )
    }

    public func generateClass(name: String, properties: [String: String], methods: [String], language: String, description: String?) async throws -> String {
        let propString = properties.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
        let methodString = methods.joined(separator: ", ")
        let prompt = """
        Generate a \(language) class named '\(name)' with these properties:
        \(propString)

        And these methods: \(methodString)
        \(description != nil ? "Description: \(description!)" : "")
        Provide only the class code without explanation.
        """

        return try await generateWithFallback(
            prompt: prompt,
            maxTokens: 250,
            temperature: 0.3,
            taskType: .codeGeneration
        )
    }

    public func refactorCode(code: String, language: String, improvement: String) async throws -> String {
        let prompt = """
        Refactor this \(language) code to \(improvement):

        \(code)

        Provide only the refactored code without explanation.
        """

        return try await generateWithFallback(
            prompt: prompt,
            maxTokens: 300,
            temperature: 0.5,
            taskType: .codeGeneration
        )
    }

    // MARK: - AICachingService Implementation

    public func cacheResponse(key: String, response: String, metadata: [String: Any]?) async {
        // Convert metadata to string for storage
        let metadataString = metadata?.description ?? ""
        cache.set(key, response: response, prompt: key, model: "huggingface")
    }

    public func getCachedResponse(key: String) async -> String? {
        return cache.get(key)
    }

    public func clearCache() async {
        cache.clear()
    }

    public func getCacheStats() async -> CacheStats {
        // Simplified cache stats - could be enhanced
        return CacheStats(
            totalEntries: 0, // Not tracked in current implementation
            hitRate: 0.0,
            averageResponseTime: 0.0,
            cacheSize: 0,
            lastCleanup: Date()
        )
    }

    // MARK: - AIPerformanceMonitoring Implementation

    public func recordOperation(operation: String, duration: TimeInterval, success: Bool, metadata: [String: Any]?) async {
        let errorType = metadata?["error"] as? String
        metrics.recordRequest(startTime: Date().addingTimeInterval(-duration), success: success, errorType: errorType)
    }

    public func getPerformanceMetrics() async -> PerformanceMetrics {
        let metricsData = getPerformanceMetrics()
        return PerformanceMetrics(
            totalOperations: metricsData.totalOperations,
            successRate: metricsData.successRate,
            averageResponseTime: metricsData.averageResponseTime,
            errorBreakdown: metricsData.errorBreakdown,
            peakConcurrentOperations: 1, // Simplified
            uptime: 0.0 // Not tracked
        )
    }

    public func resetMetrics() async {
        metrics.reset()
    }
}

// MARK: - Supporting Classes

/// Circuit breaker for fault tolerance
private actor CircuitBreaker {
    private var failureCounts: [String: Int] = [:]
    private var lastFailureTimes: [String: Date] = [:]
    private let failureThreshold = 5
    private let recoveryTimeout: TimeInterval = 60.0 // 1 minute

    func canExecute(operation: String) -> Bool {
        guard let failureCount = failureCounts[operation],
              let lastFailure = lastFailureTimes[operation] else {
            return true
        }

        if failureCount >= failureThreshold {
            let timeSinceLastFailure = Date().timeIntervalSince(lastFailure)
            return timeSinceLastFailure >= recoveryTimeout
        }

        return true
    }

    func recordFailure(operation: String) {
        failureCounts[operation, default: 0] += 1
        lastFailureTimes[operation] = Date()
    }

    func recordSuccess(operation: String) {
        failureCounts[operation] = 0
        lastFailureTimes.removeValue(forKey: operation)
    }
}

/// Intelligent retry manager with exponential backoff
private actor RetryManager {
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0

    func retry<T>(
        operation: String,
        _ block: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var attempt = 0

        while attempt < maxRetries {
            do {
                let result = try await block()
                // Record success for circuit breaker
                await CircuitBreaker().recordSuccess(operation: operation)
                return result
            } catch {
                lastError = error
                attempt += 1

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

        throw lastError ?? HuggingFaceError.apiError("All retry attempts failed")
    }

    private func shouldNotRetry(_ error: Error) -> Bool {
        if let hfError = error as? HuggingFaceError {
            switch hfError {
            case .invalidURL, .authenticationError, .modelNotSupported:
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
}

/// Response caching for improved performance
private class ResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private var accessOrder: [String] = [] // For LRU eviction
    private let maxCacheSize = 100
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    private var hitCount = 0
    private var missCount = 0

    struct CachedResponse {
        let response: String
        let timestamp: Date
        let prompt: String
        let model: String
        let accessCount: Int
    }

    func get(_ key: String) -> String? {
        guard let cached = cache[key] else {
            missCount += 1
            return nil
        }

        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > self.cacheExpiration {
            self.cache.removeValue(forKey: key)
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

        hitCount += 1
        return cached.response
    }

    func set(_ key: String, response: String, prompt: String, model: String) {
        // Clean up expired entries
        self.cleanup()

        // Remove existing entry if present
        if let existingIndex = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: existingIndex)
        }

        // Check cache size and evict if necessary
        while self.cache.count >= self.maxCacheSize {
            self.evictLRU()
        }

        self.cache[key] = CachedResponse(
            response: response,
            timestamp: Date(),
            prompt: prompt,
            model: model,
            accessCount: 0
        )
        self.accessOrder.append(key) // Most recently used
    }

    private func evictLRU() {
        // Remove least recently used item
        if let lruKey = accessOrder.first {
            cache.removeValue(forKey: lruKey)
            accessOrder.removeFirst()
        }
    }

    private func cleanup() {
        let now = Date()
        self.cache = self.cache.filter { now.timeIntervalSince($0.value.timestamp) <= self.cacheExpiration }
        // Update access order to remove expired keys
        self.accessOrder = self.accessOrder.filter { self.cache[$0] != nil }
    }

    func clear() {
        self.cache.removeAll()
        self.accessOrder.removeAll()
        self.hitCount = 0
        self.missCount = 0
    }

    func cacheKey(for prompt: String, model: String, maxTokens: Int, temperature: Double) -> String {
        let components = [prompt, model, String(maxTokens), String(temperature)]
        return components.joined(separator: "|").hashValue.description
    }

    func getStats() -> (hitRate: Double, totalRequests: Int, cacheSize: Int) {
        let totalRequests = hitCount + missCount
        let hitRate = totalRequests > 0 ? Double(hitCount) / Double(totalRequests) : 0.0
        return (hitRate, totalRequests, cache.count)
    }
}

/// Performance metrics tracking
private class PerformanceMetricsTracker {
    private var requestCount = 0
    private var successCount = 0
    private var totalResponseTime: TimeInterval = 0
    private var errorCounts: [String: Int] = [:]
    private var lastHealthCheck = Date()
    private var consecutiveFailures = 0
    private var maxConsecutiveFailures = 0

    struct Metrics {
        let totalRequests: Int
        let successRate: Double
        let averageResponseTime: TimeInterval
        let errorBreakdown: [String: Int]
        let consecutiveFailures: Int
        let maxConsecutiveFailures: Int
    }

    func recordRequest(startTime: Date, success: Bool, errorType: String? = nil) {
        self.requestCount += 1
        if success {
            self.successCount += 1
            self.consecutiveFailures = 0
        } else {
            self.consecutiveFailures += 1
            self.maxConsecutiveFailures = max(self.maxConsecutiveFailures, self.consecutiveFailures)
        }
        self.totalResponseTime += Date().timeIntervalSince(startTime)

        if let errorType {
            self.errorCounts[errorType, default: 0] += 1
        }
    }

    func getMetrics() -> Metrics {
        let successRate = self.requestCount > 0 ? Double(self.successCount) / Double(self.requestCount) : 0
        let avgResponseTime = self.requestCount > 0 ? self.totalResponseTime / Double(self.requestCount) : 0

        return Metrics(
            totalRequests: self.requestCount,
            successRate: successRate,
            averageResponseTime: avgResponseTime,
            errorBreakdown: self.errorCounts,
            consecutiveFailures: self.consecutiveFailures,
            maxConsecutiveFailures: self.maxConsecutiveFailures
        )
    }

    func reset() {
        self.requestCount = 0
        self.successCount = 0
        self.totalResponseTime = 0
        self.errorCounts.removeAll()
        self.lastHealthCheck = Date()
        self.consecutiveFailures = 0
        self.maxConsecutiveFailures = 0
    }

    func isHealthy() -> Bool {
        let metrics = getMetrics()
        return metrics.successRate > 0.5 && metrics.consecutiveFailures < 5
    }
}

// MARK: - Supporting Classes
