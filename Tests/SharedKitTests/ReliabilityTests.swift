import XCTest
@testable import SharedKit

@available(macOS 12.0, iOS 15.0, *)
final class ReliabilityTests: XCTestCase {
    // MARK: - Rate Limiting

    func testTokenBucketRateLimiter() async {
        // Capacity 2, refill 10/sec (very fast refill, but we check instantaneous consumption)
        let limiter = TokenBucketRateLimiter(capacity: 2, refillRate: 1)

        // Should allow 2 immediately
        let allowed1 = await limiter.allow(tokens: 1)
        let allowed2 = await limiter.allow(tokens: 1)
        XCTAssertTrue(allowed1)
        XCTAssertTrue(allowed2)

        // Third should fail immediately
        let allowed3 = await limiter.allow(tokens: 1)
        XCTAssertFalse(allowed3)
    }

    func testTokenBucketRefill() async throws {
        let limiter = TokenBucketRateLimiter(capacity: 1, refillRate: 10) // 10 tokens/sec = 0.1s for 1 token

        _ = await limiter.allow(tokens: 1)
        let allowedImmediately = await limiter.allow(tokens: 1)
        XCTAssertFalse(allowedImmediately)

        // Wait for refill (> 0.1s)
        try await Task.sleep(nanoseconds: 150_000_000)

        let allowedAfterRefill = await limiter.allow(tokens: 1)
        XCTAssertTrue(allowedAfterRefill)
    }

    // MARK: - Deduplication

    func testRequestDeduplicator() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = Counter()

        // Launch two concurrent requests with same ID
        async let result1 = deduplicator.execute(id: "req1") {
            try await Task.sleep(nanoseconds: 100_000_000)
            await counter.increment()
            return "done"
        }

        async let result2 = deduplicator.execute(id: "req1") {
            try await Task.sleep(nanoseconds: 100_000_000)
            await counter.increment()
            return "done"
        }

        let (r1, r2) = try await (result1, result2)

        XCTAssertEqual(r1, "done")
        XCTAssertEqual(r2, "done")

        // Should have only executed once
        let count = await counter.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - Retry Handler

    func testSmartRetrySuccess() async throws {
        let handler = SmartRetryHandler()
        let result = try await handler.execute { "success" }
        XCTAssertEqual(result, "success")
    }

    func testSmartRetryFailures() async {
        let handler = SmartRetryHandler()
        let counter = Counter()

        do {
            try await handler.execute {
                await counter.increment()
                throw URLError(.timedOut) // Retryable
            }
            XCTFail("Should have thrown after retries")
        } catch {
            // Success
        }

        // Should have retried 3 times (initial + 2 retries? implementation has attempt < maxRetries loop starting at 0)
        // Implementation:
        // while attempt < maxRetries (3)
        //   try... catch... attempt++
        // So 3 attempts total.
        let count = await counter.count
        XCTAssertEqual(count, 3)
    }

    func testNonRetryableError() async {
        let handler = SmartRetryHandler()
        let counter = Counter()

        do {
            try await handler.execute {
                await counter.increment()
                throw URLError(.badURL) // Not in retry list
            }
            XCTFail("Should have thrown immediately")
        } catch {
            // Success
        }

        // Should execute once and fail
        let count = await counter.count
        XCTAssertEqual(count, 1)
    }
}

private actor Counter {
    var count = 0
    func increment() {
        count += 1
    }
}
