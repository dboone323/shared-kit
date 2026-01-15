import Foundation

/// Enhanced connection pool for Ollama models
@available(macOS 11.0, iOS 14.0, *)
@MainActor
public class OllamaConnectionPool {
    public static let shared = OllamaConnectionPool()

    private var sessions: [String: URLSession] = [:]
    private let maxSessions = 5

    private init() {}

    /// Get or create URLSession for a model
    public func session(for model: String, timeout: TimeInterval = 120) -> URLSession {
        if let existing = sessions[model] {
            return existing
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.httpMaximumConnectionsPerHost = 4
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession(configuration: config)
        sessions[model] = session

        // Cleanup old sessions if too many
        if sessions.count > maxSessions {
            let oldest = sessions.keys.sorted().first!
            sessions[oldest]?.invalidateAndCancel()
            sessions.removeValue(forKey: oldest)
        }

        return session
    }

    /// Clear all sessions
    public func clearAll() {
        sessions.values.forEach { $0.invalidateAndCancel() }
        sessions.removeAll()
    }
}

/// Enhanced retry configuration with exponential backoff
public struct RetryConfig {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let jitterFactor: Double

    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        jitterFactor: Double = 0.1
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterFactor = jitterFactor
    }

    /// Calculate delay with exponential backoff and jitter
    public func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let cappedDelay = min(exponentialDelay, maxDelay)
        let jitter = cappedDelay * jitterFactor * Double.random(in: -1...1)
        return max(0, cappedDelay + jitter)
    }
}

/// Request queue for rate limiting
@available(macOS 11.0, iOS 14.0, *)
@MainActor
public class OllamaRequestQueue {
    private var pendingRequests: [(priority: Int, block: () async throws -> Void)] = []
    private var activeRequests = 0
    private let maxConcurrent = 3
    private var isProcessing = false

    public init() {}

    /// Enqueue a request with priority
    public func enqueue(priority: Int = 5, block: @escaping () async throws -> Void) async throws {
        pendingRequests.append((priority, block))
        pendingRequests.sort { $0.priority > $1.priority }

        try await processQueue()
    }

    private func processQueue() async throws {
        guard !isProcessing else { return }
        isProcessing = true

        while !pendingRequests.isEmpty && activeRequests < maxConcurrent {
            let request = pendingRequests.removeFirst()
            activeRequests += 1

            Task {
                defer {
                    Task { @MainActor in
                        self.activeRequests -= 1
                        try? await self.processQueue()
                    }
                }
                try? await request.block()
            }
        }

        isProcessing = false
    }
}

/// Model health tracker
@available(macOS 11.0, iOS 14.0, *)
@MainActor
public class ModelHealthTracker {
    private var healthScores: [String: Double] = [:]
    private var lastChecked: [String: Date] = [:]
    private let healthThreshold = 0.5
    private let checkInterval: TimeInterval = 300  // 5 minutes

    public init() {}

    /// Record successful request
    public func recordSuccess(for model: String) {
        healthScores[model] = min(1.0, (healthScores[model] ?? 1.0) + 0.1)
    }

    /// Record failed request
    public func recordFailure(for model: String) {
        healthScores[model] = max(0.0, (healthScores[model] ?? 1.0) - 0.2)
    }

    /// Check if model is healthy
    public func isHealthy(_ model: String) -> Bool {
        return (healthScores[model] ?? 1.0) >= healthThreshold
    }

    /// Get health score
    public func score(for model: String) -> Double {
        return healthScores[model] ?? 1.0
    }

    /// Get healthiest model from list
    public func healthiestModel(from models: [String]) -> String? {
        models.max { score(for: $0) < score(for: $1) }
    }
}
