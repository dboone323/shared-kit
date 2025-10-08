import Combine
import Foundation
import OSLog

/// Enhanced Free AI Client for Ollama with Quantum Performance
/// Zero-cost AI inference with advanced error handling, caching, and monitoring
/// Enhanced by AI System v2.1 on 9/12/25

// MARK: - Configuration

// Shared type definitions such as `OllamaConfig` live in `OllamaTypes.swift`.

// MARK: - Enhanced Quantum Ollama Client

@MainActor
public class OllamaClient: ObservableObject {
    private let config: OllamaConfig
    private let session: URLSession
    private let logger: Logger
    private let cache: OllamaCache
    private let metrics: OllamaMetrics
    private var lastRequestTime: Date = .distantPast

    @Published public var isConnected = false
    @Published public var availableModels: [String] = []
    @Published public var currentModel: String = ""
    @Published public var serverStatus: OllamaServerStatus?

    public init(config: OllamaConfig = .default) {
        self.config = config

        // Enhanced URLSession configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        configuration.timeoutIntervalForResource = config.timeout * 2
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: configuration)

        // Enhanced logging
        self.logger = Logger(subsystem: "OllamaClient", category: "AI")

        // Cache and metrics
        self.cache = OllamaCache(enabled: config.enableCaching, expiryTime: config.cacheExpiryTime)
        self.metrics = OllamaMetrics(enabled: config.enableMetrics)
        self.currentModel = config.defaultModel

        Task {
            await self.initializeConnection()
        }
    }

    // MARK: - Connection Management

    private func initializeConnection() async {
        do {
            let serverRunning = await isServerRunning()
            self.isConnected = serverRunning
            if self.isConnected {
                let models = try await listModels()
                self.availableModels = models
                self.serverStatus = await self.getServerStatus()
                self.logger.info("Connected to Ollama server with \(models.count) models")
            }
        } catch {
            self.logger.error("Failed to initialize connection: \(error.localizedDescription)")
        }
    }

    private func ensureModelAvailable(_ model: String) async throws {
        if !self.availableModels.contains(model), self.config.enableAutoModelDownload {
            self.logger.info("Auto-downloading model: \(model)")
            try await self.pullModel(model)
            self.availableModels = try await self.listModels()
        } else if !self.availableModels.contains(model) {
            // Try fallback models
            for fallback in self.config.fallbackModels {
                if self.availableModels.contains(fallback) {
                    self.logger.info("Using fallback model: \(fallback) instead of \(model)")
                    return
                }
            }
            throw OllamaError.modelNotAvailable(model)
        }
    }

    // MARK: - Cloud Model Utilities

    private func isCloudModel(_ model: String) -> Bool {
        model.hasSuffix("-cloud") || model.contains(":") && model.hasSuffix("-cloud")
    }

    private func getCloudModels() -> [String] {
        [
            "qwen3-coder:480b-cloud", "gpt-oss:120b-cloud", "gpt-oss:20b-cloud",
            "deepseek-v3.1:671b-cloud",
        ]
    }

    private func selectOptimalModel(_ preferredModel: String?) async throws -> String {
        let targetModel = preferredModel ?? self.config.defaultModel

        // If cloud models are enabled and preferred, try cloud models first
        if self.config.enableCloudModels,
            self.config.preferCloudModels || self.isCloudModel(targetModel)
        {
            if self.isCloudModel(targetModel) {
                return targetModel
            }

            // Find best cloud alternative
            if self.getCloudModels().contains(targetModel + "-cloud") {
                return targetModel + "-cloud"
            }
        }

        // Check local availability or use fallbacks
        try await self.ensureModelAvailable(targetModel)
        return targetModel
    }

    // MARK: - Enhanced Generation Methods

    public func generate(
        model: String? = nil,
        prompt: String,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        useCache: Bool = true
    ) async throws -> String {
        let requestModel = try await selectOptimalModel(model)
        let requestTemp = temperature ?? self.config.temperature
        let requestMaxTokens = maxTokens ?? self.config.maxTokens

        // Check cache first
        if useCache, self.config.enableCaching {
            let cacheKey = "\(requestModel):\(prompt.hashValue):\(requestTemp)"
            if let cached = cache.get(cacheKey) {
                self.metrics.recordCacheHit()
                return cached
            }
        }

        // Apply rate limiting
        await self.throttleRequest()

        let startTime = Date()
        let requestBody: [String: Any] = [
            "model": requestModel,
            "prompt": prompt,
            "temperature": requestTemp,
            "num_predict": requestMaxTokens,
            "stream": false,
        ]

        self.logger.info("Generating with model: \(requestModel), prompt length: \(prompt.count)")

        do {
            let response = try await performRequestWithRetry(
                endpoint: "api/generate", body: requestBody)
            guard let result = response["response"] as? String else {
                throw OllamaError.invalidResponseFormat
            }

            // Cache successful response
            if useCache, self.config.enableCaching {
                let cacheKey = "\(requestModel):\(prompt.hashValue):\(requestTemp)"
                self.cache.set(cacheKey, value: result)
            }

            // Record metrics
            let duration = Date().timeIntervalSince(startTime)
            self.metrics.recordRequest(
                model: requestModel, duration: duration, tokenCount: result.count / 4)

            return result

        } catch {
            self.metrics.recordError(error: error)
            throw error
        }
    }

    public func generateWithProgress(
        model: String? = nil,
        prompt: String,
        temperature: Double? = nil,
        progressHandler: @escaping (String) -> Void
    ) async throws -> String {
        let requestModel = try await selectOptimalModel(model)

        // This would implement streaming generation
        // For now, we'll simulate progress
        progressHandler("Starting generation...")
        let result = try await generate(
            model: requestModel, prompt: prompt, temperature: temperature)
        progressHandler("Generation complete")
        return result
    }

    // MARK: - Quantum Chat Interface

    public func quantumChat(
        model: String,
        messages: [OllamaMessage],
        temperature: Double = 0.7,
        contextOptimization: Bool = true
    ) async throws -> String {
        let optimizedMessages =
            contextOptimization ? self.optimizeMessageContext(messages) : messages

        let requestBody: [String: Any] = [
            "model": model,
            "messages": optimizedMessages.map { ["role": $0.role, "content": $0.content] },
            "temperature": temperature,
            "stream": false,
            "options": [
                "num_ctx": 4096,
                "num_thread": ProcessInfo.processInfo.processorCount,
                "num_gpu": 1,
            ],
        ]

        let response = try await performRequestWithRetry(endpoint: "api/chat", body: requestBody)

        guard let message = response["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw OllamaError.invalidResponseFormat
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Helper Methods

    private func throttleRequest() async {
        let timeSinceLastRequest = Date().timeIntervalSince(self.lastRequestTime)
        if timeSinceLastRequest < self.config.requestThrottleDelay {
            let delay = self.config.requestThrottleDelay - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        self.lastRequestTime = Date()
    }

    private func performRequestWithRetry(endpoint: String, body: [String: Any]) async throws
        -> [String: Any]
    {
        var lastError: Error?

        for attempt in 0..<self.config.maxRetries {
            do {
                return try await self.performRequest(endpoint: endpoint, body: body)
            } catch {
                lastError = error
                if attempt < self.config.maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))  // Exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? OllamaError.invalidResponse
    }

    private func optimizeMessageContext(_ messages: [OllamaMessage]) -> [OllamaMessage] {
        // Implement context window optimization
        // For now, just return the last N messages to fit context window
        let maxMessages = 10
        return Array(messages.suffix(maxMessages))
    }

    // MARK: - Core Generation Methods

    public func generateAdvanced(
        model: String,
        prompt: String,
        system: String? = nil,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        topK: Int = 40,
        maxTokens: Int = 500,
        context: [Int]? = nil
    ) async throws -> OllamaGenerateResponse {
        var requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "temperature": temperature,
            "top_p": topP,
            "top_k": topK,
            "num_predict": maxTokens,
            "stream": false,
        ]

        if let system {
            requestBody["system"] = system
        }

        if let context {
            requestBody["context"] = context
        }

        let response = try await performRequest(endpoint: "api/generate", body: requestBody)
        let data = try JSONSerialization.data(withJSONObject: response)
        return try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
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

    // MARK: - Model Management

    public func listModels() async throws -> [String] {
        let response = try await performRequest(endpoint: "api/tags", body: [:])
        let models = response["models"] as? [[String: Any]] ?? []
        return models.compactMap { $0["name"] as? String }
    }

    public func pullModel(_ modelName: String) async throws {
        let requestBody: [String: Any] = [
            "name": modelName,
            "stream": false,
        ]

        _ = try await self.performRequest(endpoint: "api/pull", body: requestBody)
    }

    public func checkModelAvailability(_ model: String) async -> Bool {
        do {
            let models = try await listModels()
            return models.contains(model)
        } catch {
            return false
        }
    }

    // MARK: - Health & Status

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
            return OllamaServerStatus(
                running: true, modelCount: models.count,
                models: models.compactMap { $0["name"] as? String })
        } catch {
            return OllamaServerStatus(running: false, modelCount: 0, models: [])
        }
    }

    // MARK: - Private Methods

    private func performRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any]
    {
        // Validate URL construction for security
        let urlString = "\(config.baseURL)/\(endpoint)"
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            throw OllamaError.invalidConfiguration("Invalid URL: \(urlString)")
        }

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

// MARK: - Enhanced Cache System

private class OllamaCache {
    private var cache: [String: CacheEntry] = [:]
    private let enabled: Bool
    private let expiryTime: TimeInterval
    private let queue = DispatchQueue(label: "ollama.cache", attributes: .concurrent)

    struct CacheEntry {
        let value: String
        let timestamp: Date

        func isExpired(expiryTime: TimeInterval) -> Bool {
            Date().timeIntervalSince(self.timestamp) > expiryTime
        }
    }

    init(enabled: Bool, expiryTime: TimeInterval) {
        self.enabled = enabled
        self.expiryTime = expiryTime
    }

    func get(_ key: String) -> String? {
        guard self.enabled else { return nil }

        return self.queue.sync {
            guard let entry = cache[key], !entry.isExpired(expiryTime: expiryTime) else {
                self.cache.removeValue(forKey: key)
                return nil
            }
            return entry.value
        }
    }

    func set(_ key: String, value: String) {
        guard self.enabled else { return }

        self.queue.async(flags: .barrier) {
            self.cache[key] = CacheEntry(value: value, timestamp: Date())

            // Clean expired entries periodically
            if self.cache.count > 100 {
                self.cleanExpiredEntries()
            }
        }
    }

    private func cleanExpiredEntries() {
        self.cache = self.cache.filter { !$0.value.isExpired(expiryTime: self.expiryTime) }
    }
}

// MARK: - Metrics System

private class OllamaMetrics {
    private let enabled: Bool
    private var requestCount: Int = 0
    private var errorCount: Int = 0
    private var cacheHits: Int = 0
    private var totalTokens: Int = 0
    private var totalDuration: TimeInterval = 0

    init(enabled: Bool) {
        self.enabled = enabled
    }

    func recordRequest(model _: String, duration: TimeInterval, tokenCount: Int) {
        guard self.enabled else { return }
        self.requestCount += 1
        self.totalTokens += tokenCount
        self.totalDuration += duration
    }

    func recordError(error _: Error) {
        guard self.enabled else { return }
        self.errorCount += 1
    }

    func recordCacheHit() {
        guard self.enabled else { return }
        self.cacheHits += 1
    }

    var averageResponseTime: TimeInterval {
        guard self.requestCount > 0 else { return 0 }
        return self.totalDuration / TimeInterval(self.requestCount)
    }

    var cacheHitRate: Double {
        guard self.requestCount > 0 else { return 0 }
        return Double(self.cacheHits) / Double(self.requestCount)
    }
}

// MARK: - Convenience Extensions

extension OllamaClient {
    public func generateCode(
        language: String,
        task: String,
        context: String? = nil
    ) async throws -> String {
        let userPrompt = """
            Language: \(language)
            Task: \(task)
            \(context != nil ? "Context: \(context!)" : "")
            """

        return try await self.generate(
            model: "codellama",
            prompt: userPrompt,
            temperature: 0.2,
            maxTokens: 2048
        )
    }

    public func analyzeCode(
        code: String,
        language: String
    ) async throws -> String {
        let prompt = """
            Analyze this \(language) code for:
            1. Potential bugs or issues
            2. Performance improvements
            3. Best practices compliance
            4. Security concerns

            Code:
            \(code)
            """

        return try await self.generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.3,
            maxTokens: 1024
        )
    }

    public func generateDocumentation(
        code: String,
        language: String
    ) async throws -> String {
        let prompt = """
            Generate comprehensive documentation for this \(language) code including:
            - Function/class purpose
            - Parameters and return values
            - Usage examples
            - Important notes

            Code:
            \(code)
            """

        return try await self.generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.4,
            maxTokens: 1024
        )
    }
}
