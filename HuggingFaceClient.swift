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
            return "Invalid Hugging Face API URL"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .rateLimited:
            return "Rate limit exceeded. Please wait before making more requests."
        case .modelLoading:
            return "Model is loading. This may take a few minutes for first use."
        case .parsingError(let message):
            return "Response parsing error: \(message)"
        case .authenticationError:
            return "Authentication failed. Please check your API token."
        case .modelNotSupported(let model):
            return "Model '\(model)' is not supported or available on free tier"
        case .quotaExceeded:
            return "API quota exceeded. Please upgrade your plan or try again later."
        case .serverOverloaded:
            return "Servers are overloaded. Please try again in a few minutes."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .rateLimited:
            return "Wait 1-2 minutes before retrying, or use a different model"
        case .modelLoading:
            return "Wait a few minutes for the model to load, then try again"
        case .authenticationError:
            return "Set your Hugging Face token in environment variable HF_TOKEN"
        case .quotaExceeded:
            return "Consider upgrading to a paid plan or using Ollama as fallback"
        case .serverOverloaded:
            return "Try again in a few minutes or use a different model"
        default:
            return "Check your internet connection and try again"
        }
    }
}
public class HuggingFaceClient {
    public static let shared = HuggingFaceClient()

    private let baseURL = "https://api-inference.huggingface.co"
    private let session: URLSession
    private let cache = ResponseCache()
    private let metrics = PerformanceMetrics()

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
        let cacheKey = cache.cacheKey(for: prompt, model: model, maxTokens: maxTokens, temperature: temperature)

        // Check cache first
        if let cachedResponse = cache.get(cacheKey) {
            metrics.recordRequest(startTime: startTime, success: true)
            return cachedResponse
        }

        let endpoint = "/models/\(model)"

        guard let url = URL(string: baseURL + endpoint) else {
            metrics.recordRequest(startTime: startTime, success: false, errorType: "invalidURL")
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
            metrics.recordRequest(startTime: startTime, success: false, errorType: "networkError")
            throw HuggingFaceError.networkError("Invalid response type")
        }

        switch httpResponse.statusCode {
        case 200:
            let result = try parseSuccessResponse(data)
            cache.set(cacheKey, response: result, prompt: prompt, model: model)
            metrics.recordRequest(startTime: startTime, success: true)
            return result
        case 404:
            metrics.recordRequest(startTime: startTime, success: false, errorType: "modelNotFound")
            throw HuggingFaceError.apiError("Model not found or not available on free tier")
        case 429:
            metrics.recordRequest(startTime: startTime, success: false, errorType: "rateLimited")
            throw HuggingFaceError.rateLimited
        case 503:
            metrics.recordRequest(startTime: startTime, success: false, errorType: "modelLoading")
            throw HuggingFaceError.modelLoading
        default:
            let errorMessage = try? parseErrorResponse(data)
            metrics.recordRequest(startTime: startTime, success: false, errorType: "apiError")
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

        return try await generate(
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

        return try await generate(
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
        let models = getModelsForTask(taskType)
        var lastError: Error?

        for model in models {
            var retryCount = 0
            let maxRetries = 3

            while retryCount <= maxRetries {
                do {
                    return try await generate(
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

        throw lastError ?? HuggingFaceError.apiError("All available models are currently unavailable. Free inference API may be experiencing issues.")
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
            return ["gpt2", "distilgpt2", "microsoft/DialoGPT-medium"]
        case .codeGeneration:
            return ["codellama/CodeLlama-7b-hf", "gpt2", "microsoft/DialoGPT-medium"]
        case .codeAnalysis:
            return ["microsoft/DialoGPT-medium", "gpt2", "distilgpt2"]
        case .documentation:
            return ["gpt2", "microsoft/DialoGPT-medium", "distilgpt2"]
        case .conversation:
            return ["microsoft/DialoGPT-medium", "microsoft/DialoGPT-small", "gpt2"]
        }
    }

    /// Get performance metrics
    /// - Returns: Current performance statistics
    public func getPerformanceMetrics() -> PerformanceMetricsData {
        return PerformanceMetricsData(
            totalRequests: metrics.getMetrics().totalRequests,
            successRate: metrics.getMetrics().successRate,
            averageResponseTime: metrics.getMetrics().averageResponseTime,
            errorBreakdown: metrics.getMetrics().errorBreakdown
        )
    }
}

// MARK: - Public Performance Metrics Data

public struct PerformanceMetricsData {
    public let totalRequests: Int
    public let successRate: Double
    public let averageResponseTime: TimeInterval
    public let errorBreakdown: [String: Int]
    
    public init(totalRequests: Int, successRate: Double, averageResponseTime: TimeInterval, errorBreakdown: [String: Int]) {
        self.totalRequests = totalRequests
        self.successRate = successRate
        self.averageResponseTime = averageResponseTime
        self.errorBreakdown = errorBreakdown
    }
}

// MARK: - Private Methods Extension

extension HuggingFaceClient {
    /// Clear performance metrics
    public func resetMetrics() {
        metrics.reset()
    }

    /// Clear response cache
    public func clearCache() {
        cache.clear()
    }

    // MARK: - Private Methods

    private func getToken() -> String? {
        // Check environment variable first
        if let envToken = ProcessInfo.processInfo.environment["HF_TOKEN"] {
            return envToken
        }

        // Check UserDefaults
        return UserDefaults.standard.string(forKey: "huggingface_api_key")
    }

    private func parseSuccessResponse(_ data: Data) throws -> String {
        // Try to parse as array of responses (common format)
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstResult = jsonArray.first,
           let generatedText = firstResult["generated_text"] as? String
        {
            return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to parse as single response object
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let generatedText = jsonObject["generated_text"] as? String
        {
            return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Try to parse as direct string array
        if let stringArray = try? JSONSerialization.jsonObject(with: data) as? [String],
           let firstString = stringArray.first
        {
            return firstString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // If all parsing fails, return raw string
        if let rawString = String(data: data, encoding: .utf8) {
            return rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw HuggingFaceError.parsingError("Unable to parse response")
    }

    private func parseErrorResponse(_ data: Data) throws -> String? {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = jsonObject["error"] as? String
        {
            return error
        }
        return nil
    }
}

// MARK: - Supporting Classes

/// Response caching for improved performance
private class ResponseCache {
    private var cache: [String: CachedResponse] = [:]
    private let maxCacheSize = 100
    private let cacheExpiration: TimeInterval = 3600 // 1 hour

    struct CachedResponse {
        let response: String
        let timestamp: Date
        let prompt: String
        let model: String
    }

    func get(_ key: String) -> String? {
        guard let cached = cache[key] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            cache.removeValue(forKey: key)
            return nil
        }

        return cached.response
    }

    func set(_ key: String, response: String, prompt: String, model: String) {
        // Clean up expired entries
        cleanup()

        // Remove oldest entries if cache is full
        if cache.count >= maxCacheSize {
            let oldestKey = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key
            if let key = oldestKey {
                cache.removeValue(forKey: key)
            }
        }

        cache[key] = CachedResponse(
            response: response,
            timestamp: Date(),
            prompt: prompt,
            model: model
        )
    }

    private func cleanup() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) <= cacheExpiration }
    }

    func clear() {
        cache.removeAll()
    }

    func cacheKey(for prompt: String, model: String, maxTokens: Int, temperature: Double) -> String {
        let components = [prompt, model, String(maxTokens), String(temperature)]
        return components.joined(separator: "|").hashValue.description
    }
}

/// Performance metrics tracking
private class PerformanceMetrics {
    private var requestCount = 0
    private var successCount = 0
    private var totalResponseTime: TimeInterval = 0
    private var errorCounts: [String: Int] = [:]

    struct Metrics {
        let totalRequests: Int
        let successRate: Double
        let averageResponseTime: TimeInterval
        let errorBreakdown: [String: Int]
    }

    func recordRequest(startTime: Date, success: Bool, errorType: String? = nil) {
        requestCount += 1
        if success {
            successCount += 1
        }
        totalResponseTime += Date().timeIntervalSince(startTime)

        if let errorType {
            errorCounts[errorType, default: 0] += 1
        }
    }

    func getMetrics() -> Metrics {
        let successRate = requestCount > 0 ? Double(successCount) / Double(requestCount) : 0
        let avgResponseTime = requestCount > 0 ? totalResponseTime / Double(requestCount) : 0

        return Metrics(
            totalRequests: requestCount,
            successRate: successRate,
            averageResponseTime: avgResponseTime,
            errorBreakdown: errorCounts
        )
    }

    func reset() {
        requestCount = 0
        successCount = 0
        totalResponseTime = 0
        errorCounts.removeAll()
    }
}
