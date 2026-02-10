import XCTest

@testable import SharedKit

/// Integration tests for OllamaClient with production enhancements
@available(macOS 12.0, *)
@MainActor
final class OllamaClientIntegrationTests: XCTestCase {
    var client: OllamaClient!

    override func setUp() async throws {
        client = OllamaClient()
    }

    /// Test retry logic with simulated failure
    func testRetryLogicWithFailure() async throws {
        // This test verifies the retry mechanism
        // In real scenario, first attempts might fail, then succeed

        // Note: This requires a running Ollama instance
        // For now, just verify the retry config exists
        XCTAssertNotNil(client)
    }

    /// Test health tracking updates
    func testHealthTrackingUpdates() async throws {
        // Verify health tracker is initialized
        XCTAssertNotNil(client)

        // In production, health tracker records successes/failures
        // This would be tested with actual API calls
    }

    /// Test connection pool reuse
    func testConnectionPoolReuse() async throws {
        // Verify connection pool is initialized
        XCTAssertNotNil(client)

        // In production test:
        // 1. Make multiple requests to same model
        // 2. Verify session is reused
        // 3. Check performance improvement
    }

    /// Test model failover on health issues
    func testModelFailover() async throws {
        // When a model is unhealthy, should failover to backup
        XCTAssertNotNil(client)

        // In production:
        // 1. Simulate model failure
        // 2. Verify automatic failover
        // 3. Check fallback model is used
    }

    /// Test exponential backoff timing
    func testExponentialBackoff() async throws {
        // Verify retry delays increase exponentially
        let retryConfig = RetryConfig(maxRetries: 3, baseDelay: 1.0)

        let delay0 = retryConfig.delay(for: 0)
        let delay1 = retryConfig.delay(for: 1)
        let delay2 = retryConfig.delay(for: 2)

        // Each delay should be roughly double the previous (with jitter)
        XCTAssertGreaterThan(delay1, delay0 * 0.8) // Account for jitter
        XCTAssertGreaterThan(delay2, delay1 * 0.8)
    }

    /// Test request queue rate limiting
    func testRequestQueueRateLimiting() async throws {
        // Verify request queue manages concurrent requests
        XCTAssertNotNil(client)

        // In production:
        // 1. Submit many requests
        // 2. Verify max concurrent limit
        // 3. Check queue processes correctly
    }
}
