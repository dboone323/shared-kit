import Foundation

/// Reliability enhancements for Shared-Kit
/// Covers Steps 36-40: Rate Limiting, Circuit Breakers, Deduplication, Retry, Connection Optimization

@available(macOS 12.0, iOS 15.0, *)
public actor Reliability {
    public static let shared = Reliability()

    // Feature components
    private let rateLimiter = TokenBucketRateLimiter(capacity: 50, refillRate: 10) // 50 tokens, 10/sec
    private let circuitBreaker = CircuitBreakerManager()
    private let deduplicator = RequestDeduplicator()
    private let retryHandler = SmartRetryHandler()

    public init() {}

    /// Check if request is allowed (Rate Limiting)
    public func allowRequest(tokens: Int = 1) async -> Bool {
        await rateLimiter.allow(tokens: tokens)
    }

    /// Execute with Circuit Breaker protection
    public func executeProtected<T: Sendable>(
        service: String, operation: @Sendable () async throws -> T
    )
        async throws -> T
    {
        try await circuitBreaker.execute(service: service, operation: operation)
    }

    /// Deduplicate identical requests
    public func executeDeduplicated<T: Sendable>(
        id: String, operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await deduplicator.execute(id: id, operation: operation)
    }

    /// Execute with Smart Retry
    public func executeWithRetry<T: Sendable>(operation: @Sendable () async throws -> T)
        async throws -> T
    {
        try await retryHandler.execute(operation: operation)
    }
}

// MARK: - Step 36: Rate Limiting (Token Bucket)

@available(macOS 12.0, iOS 15.0, *)
actor TokenBucketRateLimiter {
    private let capacity: Double
    private let refillRate: Double // tokens per second
    private var tokens: Double
    private var lastRefill: Date

    init(capacity: Double, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = capacity
        self.lastRefill = Date()
    }

    func allow(tokens requested: Int) -> Bool {
        refill()
        if tokens >= Double(requested) {
            tokens -= Double(requested)
            return true
        }
        return false
    }

    private func refill() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRefill)
        let newTokens = elapsed * refillRate

        tokens = min(capacity, tokens + newTokens)
        lastRefill = now
    }
}

// MARK: - Step 37: Circuit Breakers

@available(macOS 12.0, iOS 15.0, *)
actor CircuitBreakerManager {
    enum State: Equatable {
        case closed // Normal operation
        case open(until: Date) // Failed, blocking requests
        case halfOpen // Testing recovery
    }

    private struct CircuitState {
        var state: State
        var failures: Int
        var successCount: Int
    }

    private var circuits: [String: CircuitState] = [:]
    private let failureThreshold = 5
    private let resetTimeout: TimeInterval = 60 // 1 minute
    private let halfOpenSuccessThreshold = 3

    func execute<T>(service: String, operation: () async throws -> T) async throws -> T {
        try checkState(service)

        do {
            let result = try await operation()
            recordSuccess(service)
            return result
        } catch {
            recordFailure(service)
            throw error
        }
    }

    private func checkState(_ service: String) throws {
        guard let circuit = circuits[service] else { return }

        switch circuit.state {
        case .closed:
            return
        case let .open(until):
            if Date() > until {
                circuits[service]?.state = .halfOpen
                circuits[service]?.successCount = 0
                return
            }
            throw CircuitError.circuitOpen(service: service)
        case .halfOpen:
            return // Allow basic throughput
        }
    }

    private func recordSuccess(_ service: String) {
        var circuit =
            circuits[service] ?? CircuitState(state: .closed, failures: 0, successCount: 0)

        if case .halfOpen = circuit.state {
            circuit.successCount += 1
            if circuit.successCount >= halfOpenSuccessThreshold {
                circuit.state = .closed
                circuit.failures = 0
            }
        } else {
            circuit.failures = 0
        }
        circuits[service] = circuit
    }

    private func recordFailure(_ service: String) {
        var circuit =
            circuits[service] ?? CircuitState(state: .closed, failures: 0, successCount: 0)

        circuit.failures += 1
        if circuit.failures >= failureThreshold || (circuit.state == .halfOpen) { // modified to fix warning
            // In half-open, single failure re-opens
            circuit.state = .open(until: Date().addingTimeInterval(resetTimeout))
        }

        circuits[service] = circuit
    }
}

enum CircuitError: Error {
    case circuitOpen(service: String)
}

// MARK: - Step 38: Request Deduplication

@available(macOS 12.0, iOS 15.0, *)
actor RequestDeduplicator {
    private var activeTaskWrappers: [String: Any] = [:] // Stores Task<Sendable, Error>

    func execute<T: Sendable>(id: String, operation: @Sendable @escaping () async throws -> T)
        async throws -> T
    {
        // Check if task exists
        if let wrapper = activeTaskWrappers[id], let task = wrapper as? Task<T, Error> {
            return try await task.value
        }

        let task = Task {
            defer {
                // remove is an actor method, but since we are in a detached Task, we treat it as async call to actor.
                // However, if the warning says "no async operations", it implies context is already actor? No, Task
                // inherits priority but not actor context unless specified.
                // It might be because we are inside the actor? No, Task escapes.
                // Let's rely on Task to handle it, just call it.
                Task { await self.remove(id: id) }
            }
            // Ensure operation result is Sendable to pass out of actor
            return try await operation()
        }

        activeTaskWrappers[id] = task
        return try await task.value
    }

    private func remove(id: String) {
        activeTaskWrappers.removeValue(forKey: id)
    }
}

// MARK: - Step 39 & 40: Smart Retry & Connection Optimization

@available(macOS 12.0, iOS 15.0, *)
actor SmartRetryHandler {
    // Step 40: Connection Optimization is handled via URLSession configuration
    // and pooling in OllamaConnectionPool. Here we focus on logic.

    func execute<T>(operation: () async throws -> T) async throws -> T {
        let maxRetries = 3
        var attempt = 0
        var lastError: Error?

        while attempt < maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1

                // Smart Retry: Analyze error type
                if !shouldRetry(error) {
                    throw error
                }

                // Exponential backoff
                let delay = pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError!
    }

    private func shouldRetry(_ error: Error) -> Bool {
        // Don't retry client errors (4xx), only server/network (5xx)
        // Simplified logic for this implementation
        if let err = error as? URLError {
            // Retry network connection issues
            return [.timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost]
                .contains(err.code)
        }
        return true // Default conservative retry
    }
}
