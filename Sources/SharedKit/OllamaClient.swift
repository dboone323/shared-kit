import Foundation

#if canImport(OSLog)
    import OSLog
#endif

#if canImport(Combine)
    import Combine
#else
    import Foundation

    public protocol ObservableObject: AnyObject {}

    @propertyWrapper
    public struct Published<Value> {
        public var wrappedValue: Value
        public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
        public var projectedValue: Published<Value> { self }
    }
#endif

// MARK: - Cloud Fallback Policy (Shared-Kit)

private struct CloudFallbackPolicy {
    let configPath: String
    let quotaTrackerPath: String
    let escalationLogPath: String

    private(set) var enabled: Bool = false
    private var config: [String: Any] = [:]

    init(
        configPath: String = "config/cloud_fallback_config.json",
        quotaTrackerPath: String = "metrics/quota_tracker.json",
        escalationLogPath: String = "logs/cloud_escalation_log.jsonl"
    ) {
        self.configPath = configPath
        self.quotaTrackerPath = quotaTrackerPath
        self.escalationLogPath = escalationLogPath
        self.reload()
    }

    mutating func reload() {
        guard let cfg = Self.readJSON(path: configPath) else { return }
        self.config = cfg
        self.enabled = true
    }

    func allowed(priority: String) -> Bool {
        guard enabled else { return true }
        let allowed = config["allowed_priority_levels"] as? [String] ?? []
        return allowed.contains(priority)
    }

    mutating func recordFailure(priority: String) {
        guard enabled else { return }
        var tracker = Self.readJSON(path: quotaTrackerPath) ?? [:]
        var cb = (tracker["circuit_breaker"] as? [String: Any]) ?? [:]
        var pcb =
            (cb[priority] as? [String: Any]) ?? [
                "state": "closed", "failure_count": 0, "last_failure": NSNull(),
                "opened_at": NSNull(),
            ]
        let now = Self.iso8601Now()
        let failures = ((pcb["failure_count"] as? Int) ?? 0) + 1
        pcb["failure_count"] = failures
        pcb["last_failure"] = now
        let threshold =
            ((config["circuit_breaker"] as? [String: Any])?["failure_threshold"] as? Int) ?? 3
        if failures >= threshold {
            pcb["state"] = "open"
            pcb["opened_at"] = now
        }
        cb[priority] = pcb
        tracker["circuit_breaker"] = cb
        Self.writeJSON(path: quotaTrackerPath, object: tracker)
    }

    func checkCircuit(priority: String) -> Bool {
        guard enabled else { return true }
        guard let tracker = Self.readJSON(path: quotaTrackerPath),
              let cb = tracker["circuit_breaker"] as? [String: Any],
              let pcb = cb[priority] as? [String: Any]
        else { return true }
        let state = (pcb["state"] as? String) ?? "closed"
        if state == "open" {
            return false
        }
        return true
    }

    func checkQuota(priority: String) -> Bool {
        guard enabled else { return true }
        guard let tracker = Self.readJSON(path: quotaTrackerPath),
              let quotas = tracker["quotas"] as? [String: Any],
              let pq = quotas[priority] as? [String: Any]
        else { return false }
        let dailyUsed = (pq["daily_used"] as? Int) ?? 0
        let hourlyUsed = (pq["hourly_used"] as? Int) ?? 0
        let dailyLimit = (pq["daily_limit"] as? Int) ?? Int.max
        let hourlyLimit = (pq["hourly_limit"] as? Int) ?? Int.max
        return dailyUsed < dailyLimit && hourlyUsed < hourlyLimit
    }

    func logEscalation(
        task: String, priority: String, reason: String, modelAttempted: String, provider: String
    ) {
        guard enabled else { return }
        let now = Self.iso8601Now()
        let line: [String: Any] = [
            "timestamp": now,
            "task": task,
            "priority": priority,
            "reason": reason,
            "model_attempted": modelAttempted,
            "cloud_provider": provider,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: line),
           let s = String(data: data, encoding: .utf8)
        {
            if FileManager.default.fileExists(atPath: escalationLogPath) == false {
                FileManager.default.createFile(atPath: escalationLogPath, contents: nil)
            }
            if let h = try? FileHandle(forWritingTo: URL(fileURLWithPath: escalationLogPath)) {
                h.seekToEndOfFile()
                h.write(Data((s + "\n").utf8))
                try? h.close()
            }
        }
    }

    private static func readJSON(path: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    private static func writeJSON(path: String, object: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    private static func iso8601Now() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: Date())
    }
}

// Enhanced Free AI Client for Ollama with Quantum Performance
// Zero-cost AI inference with advanced error handling, caching, and monitoring
// Enhanced by AI System v2.1 on 9/12/25

// MARK: - Configuration

// Shared type definitions such as `OllamaConfig` live in `OllamaTypes.swift`.

// MARK: - Enhanced Quantum Ollama Client

@MainActor
public class OllamaClient: ObservableObject {
    private let config: OllamaConfig
    private let session: URLSession

    private let cache: OllamaCache
    private let metrics: OllamaMetrics
    private var lastRequestTime: Date = .distantPast
    private var policy = CloudFallbackPolicy()

    // Production enhancements
    private let connectionPool = OllamaConnectionPool.shared
    private let healthTracker = ModelHealthTracker()
    private let requestQueue = OllamaRequestQueue()
    private let retryConfig = RetryConfig(maxRetries: 3, baseDelay: 1.0)

    @Published public var isConnected = false
    @Published public var availableModels: [String] = []
    @Published public var currentModel: String = ""
    @Published public var serverStatus: OllamaServerStatus?

    public init(config: OllamaConfig = .default, session: URLSession? = nil) {
        self.config = config

        // Enhanced URLSession configuration
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = config.timeout
            configuration.timeoutIntervalForResource = config.timeout * 2
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.httpMaximumConnectionsPerHost = 4
            self.session = URLSession(configuration: configuration)
        }

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
                Logger.logInfo("Connected to Ollama server with \(models.count) models")
            }
        } catch {
            Logger.logError(error, context: "Failed to initialize connection")
        }
    }

    private func ensureModelAvailable(_ model: String) async throws {
        // Refresh model list if potentially stale (not yet initialized)
        if self.availableModels.isEmpty {
            self.availableModels = try await self.listModels()
        }
        if !self.availableModels.contains(model), self.config.enableAutoModelDownload {
            Logger.logInfo("Auto-downloading model: \(model)")
            try await self.pullModel(model)
            self.availableModels = try await self.listModels()
        } else if !self.availableModels.contains(model) {
            // Try fallback models
            for fallback in self.config.fallbackModels {
                if self.availableModels.contains(fallback) {
                    Logger.logInfo("Using fallback model: \(fallback) instead of \(model)")
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
                // Gate cloud by policy; default priority medium (shared-kit)
                let priority = "medium"
                if policy
                    .enabled == false
                    || (policy.allowed(priority: priority) && policy.checkQuota(priority: priority)
                        && policy
                        .checkCircuit(priority: priority))
                {
                    // Cloud disabled in config by default; log and fall back to local
                    policy.logEscalation(
                        task: "sharedKit.generate",
                        priority: priority,
                        reason: "cloud_disabled_or_logged_only",
                        modelAttempted: targetModel,
                        provider: "ollama_cloud"
                    )
                    try await self.ensureModelAvailable(preferredModel ?? self.config.defaultModel)
                    return preferredModel ?? self.config.defaultModel
                } else {
                    // Not allowed by policy; log and use local
                    policy.logEscalation(
                        task: "sharedKit.generate",
                        priority: priority,
                        reason: "policy_blocked",
                        modelAttempted: targetModel,
                        provider: "ollama_cloud"
                    )
                    try await self.ensureModelAvailable(preferredModel ?? self.config.defaultModel)
                    return preferredModel ?? self.config.defaultModel
                }
            }

            // Find best cloud alternative -> gate via policy and then prefer local
            if self.getCloudModels().contains(targetModel + "-cloud") {
                let priority = "medium"
                policy.logEscalation(
                    task: "sharedKit.generate",
                    priority: priority,
                    reason: "cloud_candidate_logged_only",
                    modelAttempted: targetModel + "-cloud",
                    provider: "ollama_cloud"
                )
                try await self.ensureModelAvailable(targetModel)
                return targetModel
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

        Logger.logInfo("Generating with model: \(requestModel), prompt length: \(prompt.count)")

        do {
            let response = try await performRequestWithRetry(
                endpoint: "api/generate", body: requestBody
            )
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
                model: requestModel, duration: duration, tokenCount: result.count / 4
            )

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
            model: requestModel, prompt: prompt, temperature: temperature
        )
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

        for attempt in 0 ..< self.config.maxRetries {
            do {
                return try await self.performRequest(endpoint: endpoint, body: body)
            } catch {
                lastError = error
                if attempt < self.config.maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        // Record failure for circuit breaker (shared-kit default medium priority)
        policy.recordFailure(priority: "medium")
        throw lastError ?? OllamaError.invalidResponse
    }

    private func optimizeMessageContext(_ messages: [OllamaMessage]) -> [OllamaMessage] {
        // Implement context window optimization
        // For now, just return the last N messages to fit context window
        let maxMessages = 10
        return Array(messages.suffix(maxMessages))
    }

    // MARK: - Core Generation Methods

    public func generate(
        model: String,
        prompt: String,
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        stream: Bool = false
    ) async throws -> String {
        // Use health tracker to select best model
        let selectedModel = await chooseHealthyModel(preferred: model)

        // Retry with exponential backoff
        var lastError: Error?
        for attempt in 0 ..< retryConfig.maxRetries {
            do {
                let result = try await executeGenerate(
                    model: selectedModel,
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    temperature: temperature,
                    stream: stream
                )

                // Record success
                healthTracker.recordSuccess(for: selectedModel)
                return result
            } catch {
                lastError = error
                healthTracker.recordFailure(for: selectedModel)

                if attempt < retryConfig.maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt)) * retryConfig.baseDelay
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? OllamaError.serverError("Failed after \(retryConfig.maxRetries) retries")
    }

    /// Choose healthy model with fallback
    private func chooseHealthyModel(preferred: String) async -> String {
        // Check if preferred model is healthy
        if healthTracker.isHealthy(preferred) {
            return preferred
        }

        // Try fallback models
        let allModels = [preferred] + config.fallbackModels
        if let healthy = healthTracker.healthiestModel(from: allModels) {
            SecureLogger.info(
                "Switching from \(preferred) to healthier model \(healthy)",
                category: .ai
            )
            return healthy
        }

        return preferred // Use preferred even if unhealthy
    }

    /// Execute generation (original logic)
    private func executeGenerate(
        model: String,
        prompt: String,
        systemPrompt: String? = nil,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        topK: Int = 40,
        maxTokens: Int = 500,
        context: [Int]? = nil,
        stream: Bool = false
    ) async throws -> String {
        var requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "temperature": temperature,
            "top_p": topP,
            "top_k": topK,
            "num_predict": maxTokens,
            "stream": false,
        ]

        if let systemPrompt {
            requestBody["system"] = systemPrompt
        }

        if let context {
            requestBody["context"] = context
        }

        let response = try await performRequest(endpoint: "api/generate", body: requestBody)
        let data = try JSONSerialization.data(withJSONObject: response)
        let decoded = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return decoded.response
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

        return content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    // MARK: - Model Management

    public func listModels() async throws -> [String] {
        let response = try await performGetRequest(endpoint: "api/tags")
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
            _ = try await performGetRequest(endpoint: "api/tags")
            return true
        } catch {
            return healthTracker.isHealthy("unknown")
        }
    }

    public func getServerStatus() async -> OllamaServerStatus {
        do {
            let response = try await performGetRequest(endpoint: "api/tags")
            let models = response["models"] as? [[String: Any]] ?? []
            return OllamaServerStatus(
                running: true, modelCount: models.count,
                models: models.compactMap { $0["name"] as? String }
            )
        } catch {
            return OllamaServerStatus(running: false, modelCount: 0, models: [])
        }
    }

    // MARK: - Private Request Methods

    private func getEffectiveBaseURL() async -> String {
        if config.baseURL == OllamaConfig.defaultEndpoint {
            return await SecretsManager.shared.getOllamaEndpoint()
        }
        return config.baseURL
    }

    private func performRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        let baseUrl = await getEffectiveBaseURL()
        guard let url = URL(string: "\(baseUrl)/\(endpoint)") else {
            throw OllamaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        SecureLogger.debug("OllamaClient requesting: \(url.absoluteString)", category: .network)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.connectionFailed
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaError.serverError("Status code: \(httpResponse.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OllamaError.invalidResponseFormat
        }

        return json
    }

    private func performGetRequest(endpoint: String) async throws -> [String: Any] {
        let baseUrl = await getEffectiveBaseURL()
        let urlString = "\(baseUrl)/\(endpoint)"
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            throw OllamaError.invalidConfiguration("Invalid URL: \(urlString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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

private class OllamaCache: @unchecked Sendable {
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

public extension OllamaClient {
    func generateCode(
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

    func analyzeCode(
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

    func generateDocumentation(
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
