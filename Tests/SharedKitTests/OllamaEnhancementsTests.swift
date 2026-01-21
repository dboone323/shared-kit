import XCTest

@testable import SharedKit

@available(macOS 11.0, iOS 14.0, *)
final class OllamaEnhancementsTests: XCTestCase {
    // MARK: - RetryConfig Tests

    func testRetryConfigBasicDelay() {
        let config = RetryConfig(maxRetries: 3, baseDelay: 1.0, maxDelay: 10.0, jitterFactor: 0.1)

        // Test exponential backoff
        let delay0 = config.delay(for: 0)
        let delay1 = config.delay(for: 1)
        let delay2 = config.delay(for: 2)

        // Should be approximately 1s, 2s, 4s (±10% jitter)
        XCTAssertEqual(delay0, 1.0, accuracy: 0.2, "First retry should be ~1s")
        XCTAssertEqual(delay1, 2.0, accuracy: 0.4, "Second retry should be ~2s")
        XCTAssertEqual(delay2, 4.0, accuracy: 0.8, "Third retry should be ~4s")
    }

    func testRetryConfigMaxDelay() {
        let config = RetryConfig(maxRetries: 10, baseDelay: 1.0, maxDelay: 5.0, jitterFactor: 0.1)

        // Even with many retries, should cap at maxDelay
        let delay10 = config.delay(for: 10)
        XCTAssertLessThanOrEqual(delay10, 5.5, "Should not exceed max delay + jitter")
    }

    func testRetryConfigJitter() {
        let config = RetryConfig(maxRetries: 3, baseDelay: 10.0, maxDelay: 100.0, jitterFactor: 0.2)

        // Multiple calls should produce different results due to jitter
        let delays = (0..<5).map { _ in config.delay(for: 1) }
        let allSame = delays.allSatisfy { $0 == delays.first }

        XCTAssertFalse(allSame, "Jitter should produce varying delays")
    }

    // MARK: - ModelHealthTracker Tests

    @MainActor
    func testHealthTrackerSuccess() async {
        let tracker = ModelHealthTracker()

        // New model should start healthy
        XCTAssertTrue(tracker.isHealthy("test-model"))
        XCTAssertEqual(tracker.score(for: "test-model"), 1.0)

        // Success should maintain/improve health
        tracker.recordSuccess(for: "test-model")
        XCTAssertTrue(tracker.isHealthy("test-model"))
        XCTAssertEqual(tracker.score(for: "test-model"), 1.0)  // Already at max
    }

    @MainActor
    func testHealthTrackerFailure() async {
        let tracker = ModelHealthTracker()

        // Multiple failures should degrade health
        for _ in 0..<5 {
            tracker.recordFailure(for: "test-model")
        }

        XCTAssertFalse(tracker.isHealthy("test-model"))
        XCTAssertLessThan(tracker.score(for: "test-model"), 0.5)
    }

    @MainActor
    func testHealthTrackerHealthiestModel() async {
        let tracker = ModelHealthTracker()

        // Setup different health scores
        tracker.recordSuccess(for: "model-a")
        tracker.recordSuccess(for: "model-a")

        tracker.recordFailure(for: "model-b")
        tracker.recordFailure(for: "model-b")

        let healthiest = tracker.healthiestModel(from: ["model-a", "model-b"])
        XCTAssertEqual(healthiest, "model-a")
    }

    // MARK: - OllamaConnectionPool Tests

    @MainActor
    func testConnectionPoolReuse() {
        let pool = OllamaConnectionPool.shared

        let session1 = pool.session(for: "test-model")
        let session2 = pool.session(for: "test-model")

        // Should return same session for same model
        XCTAssertTrue(session1 === session2, "Should reuse session for same model")
    }

    @MainActor
    func testConnectionPoolDifferentModels() {
        let pool = OllamaConnectionPool.shared

        let session1 = pool.session(for: "model-1")
        let session2 = pool.session(for: "model-2")

        // Should return different sessions for different models
        XCTAssertFalse(
            session1 === session2, "Should create separate sessions for different models")
    }
}
