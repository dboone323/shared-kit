import XCTest

@testable import SharedKit

private actor InvocationCounter {
    private(set) var count = 0

    func increment() -> Int {
        count += 1
        return count
    }
}

@available(macOS 12.0, iOS 15.0, *)
final class RAGIntegrationTests: XCTestCase {
    func testIntelligenceCacheRoundTrip() async {
        let intelligence = Intelligence()
        let query = "What port is postgres running on?"
        let embeddings = Array(repeating: Float(0.15), count: 64)

        await intelligence.cacheResult("postgres runs on 5432", for: query, embeddings: embeddings)
        let hit = await intelligence.retrieveCachedResult(for: query, embeddings: embeddings)

        XCTAssertEqual(hit, "postgres runs on 5432")
    }

    func testReliabilityDeduplicatesConcurrentRequests() async throws {
        let reliability = Reliability()
        let counter = InvocationCounter()

        async let first = reliability.executeDeduplicated(id: "status-request") {
            _ = await counter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return "ok"
        }

        async let second = reliability.executeDeduplicated(id: "status-request") {
            _ = await counter.increment()
            return "ok"
        }

        let (firstResult, secondResult) = try await (first, second)
        XCTAssertEqual(firstResult, "ok")
        XCTAssertEqual(secondResult, "ok")
        let deduplicatedInvocations = await counter.count
        XCTAssertEqual(deduplicatedInvocations, 1)
    }

    func testReliabilityRetryRecoversFromTransientFailure() async throws {
        let reliability = Reliability()
        let counter = InvocationCounter()

        let result: String = try await reliability.executeWithRetry {
            let currentAttempt = await counter.increment()
            if currentAttempt == 1 {
                throw URLError(.timedOut)
            }
            return "recovered"
        }

        XCTAssertEqual(result, "recovered")
        let attempts = await counter.count
        XCTAssertEqual(attempts, 2)
    }

    func testParsedToolOutputFeedsEntityMemory() {
        let output = """
            db running healthy
            Error: redis timeout on /var/log/redis.log
            """

        let parsed = ToolExecutionResult.parse(toolName: "status", rawOutput: output)
        var memory = EntityMemory()
        memory.extractEntities(from: parsed.output)

        XCTAssertFalse(parsed.success)
        XCTAssertTrue(memory.services.contains("redis"))
        XCTAssertTrue(memory.mentionedFiles.contains("/var/log/redis.log"))
        XCTAssertFalse(memory.recentErrors.isEmpty)
    }
}
