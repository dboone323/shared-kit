import XCTest

@testable import SharedKit

@available(macOS 11.0, iOS 14.0, *)
final class AgentEnhancementsTests: XCTestCase {

    // MARK: - ContextWindowManager Tests

    func testContextWindowOptimization() {
        let manager = ContextWindowManager(maxTokens: 100)

        // Create messages that exceed token limit
        let messages = (0..<20).map { i in
            ConversationMessage(role: "user", content: "Message \(i) with some content")
        }

        let optimized = manager.optimizeMessages(messages)

        // Should reduce to fit within window
        XCTAssertLessThan(optimized.count, messages.count, "Should reduce message count")

        // Should keep most recent
        XCTAssertEqual(
            optimized.last?.content.contains("19"), true, "Should keep most recent message")
    }

    func testContextWindowEmptyMessages() {
        let manager = ContextWindowManager(maxTokens: 1000)
        let optimized = manager.optimizeMessages([])

        XCTAssertEqual(optimized.count, 0, "Empty input should return empty output")
    }

    // MARK: - ToolResultCache Tests

    func testToolResultCacheSetAndGet() async {
        let cache = ToolResultCache()

        await cache.set("result value", for: "test-key")
        let retrieved = await cache.get(for: "test-key")

        XCTAssertEqual(retrieved, "result value")
    }

    func testToolResultCacheMiss() async {
        let cache = ToolResultCache()
        let retrieved = await cache.get(for: "nonexistent-key")

        XCTAssertNil(retrieved, "Should return nil for cache miss")
    }

    // Note: TTL expiration test would require waiting 5+ minutes or modifying TTL

    // MARK: - ToolExecutionCoordinator Tests

    func testParallelExecution() async throws {
        let coordinator = ToolExecutionCoordinator()

        let tools: [@Sendable () async throws -> String] = [
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "result1"
            },
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "result2"
            },
            {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "result3"
            },
        ]

        let startTime = Date()
        let results = try await coordinator.executeParallel(tools: tools)
        let duration = Date().timeIntervalSince(startTime)

        // Should execute in parallel (< 0.5s for 3x 0.1s tasks)
        XCTAssertLessThan(duration, 0.5, "Should execute in parallel")
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0], "result1")
        XCTAssertEqual(results[1], "result2")
        XCTAssertEqual(results[2], "result3")
    }

    func testExecuteWithTimeout() async throws {
        let coordinator = ToolExecutionCoordinator()

        // Task that completes quickly
        let result = try await coordinator.executeWithTimeout(seconds: 1.0) {
            return "success"
        }

        XCTAssertEqual(result, "success")
    }

    func testExecuteWithTimeoutExpires() async {
        let coordinator = ToolExecutionCoordinator()

        do {
            // Task that takes too long
            _ = try await coordinator.executeWithTimeout(seconds: 0.5) {
                try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
                return "should not reach"
            }

            XCTFail("Should have thrown timeout error")
        } catch {
            // Expected timeout
            XCTAssertTrue(error is TimeoutError)
        }
    }

    // MARK: - ToolLearningSystem Tests

    func testToolLearningSuccessRate() async {
        let learning = ToolLearningSystem()

        // Record outcomes
        await learning.recordOutcome(tool: "test-tool", success: true)
        await learning.recordOutcome(tool: "test-tool", success: true)
        await learning.recordOutcome(tool: "test-tool", success: false)

        let rate = await learning.successRate(for: "test-tool")
        XCTAssertEqual(rate, 2.0 / 3.0, accuracy: 0.01, "Should calculate correct success rate")
    }

    func testToolLearningUnknownTool() async {
        let learning = ToolLearningSystem()
        let rate = await learning.successRate(for: "unknown-tool")

        XCTAssertEqual(rate, 0.5, "Unknown tools should default to 0.5")
    }

    func testToolLearningRecommendation() async {
        let learning = ToolLearningSystem()

        // Setup different success rates
        await learning.recordOutcome(tool: "good-tool", success: true)
        await learning.recordOutcome(tool: "good-tool", success: true)

        await learning.recordOutcome(tool: "bad-tool", success: false)
        await learning.recordOutcome(tool: "bad-tool", success: false)

        let recommended = await learning.recommendTool(from: ["good-tool", "bad-tool"])
        XCTAssertEqual(recommended, "good-tool")
    }
}
