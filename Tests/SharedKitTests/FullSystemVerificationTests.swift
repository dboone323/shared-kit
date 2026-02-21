import SharedKitCore
import XCTest

@testable import SharedKit

@available(macOS 12.0, iOS 15.0, *)
final class FullSystemVerificationTests: XCTestCase {
    func testIntelligenceModule() async {
        let intelligence = Intelligence.shared

        let tools = [
            ToolDescription(name: "search", description: "Search the web for information"),
            ToolDescription(name: "calculator", description: "Perform mathematical calculations"),
        ]

        let recommendations = await intelligence.recommendTools(
            for: "Find the capital of France", availableTools: tools
        )
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertEqual(recommendations.first, "search")

        let prediction = await intelligence.predictHealth(for: "llama2")
        XCTAssertEqual(prediction.status, .healthy)

        let query = "What is 2+2?"
        let embeddings = Array(repeating: Float(0.1), count: 64)

        let miss = await intelligence.retrieveCachedResult(for: query, embeddings: embeddings)
        XCTAssertNil(miss)

        await intelligence.cacheResult("4", for: query, embeddings: embeddings)
        let hit = await intelligence.retrieveCachedResult(for: query, embeddings: embeddings)
        XCTAssertEqual(hit, "4")
    }

    func testReliabilityModule() async throws {
        let reliability = Reliability.shared

        let allowed = await reliability.allowRequest()
        XCTAssertTrue(allowed)

        let protectedResult: String = try await reliability.executeProtected(service: "test-service") {
            "success"
        }
        XCTAssertEqual(protectedResult, "success")

        async let first: String = reliability.executeDeduplicated(id: "req-1") {
            try await Task.sleep(nanoseconds: 50_000_000)
            return "deduped"
        }
        async let second: String = reliability.executeDeduplicated(id: "req-1") {
            "deduped"
        }
        let (result1, result2) = try await (first, second)
        XCTAssertEqual(result1, "deduped")
        XCTAssertEqual(result2, "deduped")

        let retryResult: String = try await reliability.executeWithRetry {
            "retried"
        }
        XCTAssertEqual(retryResult, "retried")
    }

    func testSecurityModule() async throws {
        let security = SharedKitCore.SecurityFramework.shared

        try await security.validate(input: "test@example.com", type: .email)

        do {
            try await security.validate(input: "invalid-email", type: .email)
            XCTFail("Expected invalid email validation to throw")
        } catch {}

        let sanitized = await security.sanitize("DROP TABLE users';--")
        XCTAssertTrue(sanitized.contains("''"))

        let admin = UserContext(id: "1", role: .admin)
        let user = UserContext(id: "2", role: .user)

        try await security.checkPermission(user: admin, action: .delete)

        do {
            try await security.checkPermission(user: user, action: .delete)
            XCTFail("User should not be able to delete")
        } catch {}

        let secret = Data("Top Secret".utf8)
        let encrypted = try await security.encrypt(secret)
        XCTAssertNotEqual(encrypted, secret)

        let decrypted = try await security.decrypt(encrypted)
        XCTAssertEqual(decrypted, secret)
    }

    func testToolResultAndEntityIntegration() {
        let rawOutput = """
            Container Status:
            - db: running
            - redis: running
            Error: cache miss on /var/log/redis.log
            """

        let result = SharedKit.ToolExecutionResult.parse(toolName: "status", rawOutput: rawOutput)
        var memory = SharedKit.EntityMemory()
        memory.extractEntities(from: result.output)

        XCTAssertFalse(result.success)
        XCTAssertTrue(memory.services.contains("db"))
        XCTAssertTrue(memory.services.contains("redis"))
        XCTAssertTrue(memory.mentionedFiles.contains("/var/log/redis.log"))
        XCTAssertFalse(memory.recentErrors.isEmpty)
    }
}
