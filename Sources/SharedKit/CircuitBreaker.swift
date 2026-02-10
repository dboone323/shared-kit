import Foundation

/// Circuit breaker pattern for resilient service calls
@available(macOS 12.0, *)
public actor CircuitBreaker {
    public enum State: Sendable {
        case closed // Normal operation
        case open // Too many failures, reject calls
        case halfOpen // Testing if service recovered
    }

    private var state: State = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private var successCount: Int = 0

    private let failureThreshold: Int
    private let timeout: TimeInterval
    private let halfOpenSuccessThreshold: Int

    public init(
        failureThreshold: Int = 5,
        timeout: TimeInterval = 60,
        halfOpenSuccessThreshold: Int = 2
    ) {
        self.failureThreshold = failureThreshold
        self.timeout = timeout
        self.halfOpenSuccessThreshold = halfOpenSuccessThreshold
    }

    /// Execute a call through the circuit breaker
    public func execute<T>(_ operation: () async throws -> T) async throws -> T {
        // Check if circuit should transition from open to half-open
        if state == .open, let lastFailure = lastFailureTime {
            if Date().timeIntervalSince(lastFailure) > timeout {
                print("⚡ Circuit: Transitioning to half-open (testing recovery)")
                state = .halfOpen
                successCount = 0
            } else {
                throw CircuitBreakerError.circuitOpen
            }
        }

        // Reject calls if circuit is open
        if state == .open {
            throw CircuitBreakerError.circuitOpen
        }

        do {
            let result = try await operation()
            await recordSuccess()
            return result
        } catch {
            await recordFailure()
            throw error
        }
    }

    private func recordSuccess() {
        successCount += 1

        switch state {
        case .halfOpen:
            if successCount >= halfOpenSuccessThreshold {
                print("✅ Circuit: Recovered - transitioning to closed")
                state = .closed
                failureCount = 0
            }
        case .closed:
            // Reset failure count on success
            failureCount = 0
        case .open:
            break
        }
    }

    private func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()

        switch state {
        case .closed:
            if failureCount >= failureThreshold {
                print("❌ Circuit: Too many failures - opening circuit")
                state = .open
            }
        case .halfOpen:
            print("❌ Circuit: Recovery failed - reopening circuit")
            state = .open
            successCount = 0
        case .open:
            break
        }
    }

    public func reset() {
        state = .closed
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
        print("🔄 Circuit: Manually reset to closed")
    }

    public func getCurrentState() -> State {
        state
    }
}

public enum CircuitBreakerError: Error, LocalizedError {
    case circuitOpen

    public var errorDescription: String? {
        switch self {
        case .circuitOpen:
            "Circuit breaker is open - service temporarily unavailable"
        }
    }
}
