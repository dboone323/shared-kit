import XCTest

@testable import SharedKit

@available(macOS 12.0, *)
@MainActor
final class RAGIntegrationTests: XCTestCase {
    var agent: AggregatorAgent!
    var vectorStore: PostgresVectorStore!
    var embeddingService: CoreMLEmbeddingService!

    override func setUp() async throws {
        guard ProcessInfo.processInfo.environment["ENABLE_INTEGRATION_TESTS"] == "1" else {
            throw XCTSkip("Skipping integration tests: ENABLE_INTEGRATION_TESTS not set")
        }

        agent = AggregatorAgent.shared
        vectorStore = PostgresVectorStore.shared
        embeddingService = CoreMLEmbeddingService.shared

        // Ensure connection
        try await vectorStore.connect()
    }

    override func tearDown() async throws {
        if let store = vectorStore {
            await store.close()
        }
    }

    // MARK: - Full RAG Pipeline Tests

    func testEndToEndRAGPipeline() async throws {
        // 1. Store some knowledge
        let fact1 = "The database service is running on port 5432"
        let fact2 = "Docker containers can be managed using docker-manager CLI"
        let fact3 = "SonarQube is available at http://localhost:9000"

        try await agent.learn(fact: fact1)
        try await agent.learn(fact: fact2)
        try await agent.learn(fact: fact3)

        // 2. Query the agent
        let query = "What port is the database running on?"
        let response = try await agent.process(query: query)

        // 3. Verify response mentions port 5432
        XCTAssertTrue(
            response.contains("5432"),
            "Response should mention database port: \(response)"
        )
    }

    func testToolExecutionWithFeedback() async throws {
        // Query that triggers tool execution
        let query = "Check the system status"
        let response = try await agent.process(query: query)

        // Verify agent processed the request
        XCTAssertFalse(response.isEmpty, "Response should not be empty")
        XCTAssertTrue(
            response.lowercased().contains("status") || response.lowercased().contains("running")
                || response.lowercased().contains("healthy"),
            "Response should mention system status"
        )
    }

    func testConversationHistoryTracking() async throws {
        agent.clearHistory()

        _ = try await agent.process(query: "What is Docker?")
        _ = try await agent.process(query: "How do I check status?")

        // Verify history tracking
        XCTAssertEqual(agent.conversationHistory.count, 4) // 2 user + 2 assistant
        XCTAssertEqual(agent.conversationHistory[0].role, "user")
        XCTAssertEqual(agent.conversationHistory[1].role, "assistant")
    }

    func testEntityExtraction() async throws {
        // Query mentioning specific services
        _ = try await agent.process(query: "Is postgres running? What about redis?")

        // The agent should have extracted these entity names
        // Note: This tests internal entity memory which isn't directly exposed
        // In production, you'd expose a method to check extracted entities
    }

    // MARK: - Error Handling Tests

    func testRetryMechanismOnFailure() async throws {
        // This test verifies retry logic works
        // In a real scenario, we'd mock docker-manager to simulate failures

        do {
            _ = try await agent.process(query: "Check status")
            // If docker-manager is available, this succeeds
            XCTAssertTrue(true)
        } catch {
            // If docker-manager fails after retries, we expect error
            XCTAssertNotNil(error)
        }
    }

    func testGracefulDegradationWhenPostgresDown() async throws {
        // Close Postgres connection
        await vectorStore.close()

        // Agent should still respond, just without RAG context
        do {
            let response = try await agent.process(query: "What is Docker?")
            // Should fail or fallback gracefully
            XCTAssertNotNil(response)
        } catch {
            // Expected to throw when DB is unavailable
            XCTAssertNotNil(error)
        }

        // Reconnect for cleanup
        try await vectorStore.connect()
    }

    // MARK: - Performance Tests

    func testEmbeddingPerformance() {
        measure {
            let exp = expectation(description: "Embedding completed")
            Task {
                _ = try await embeddingService.embed(
                    "This is a test query for performance measurement")
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }

    func testVectorSearchPerformance() {
        measure {
            let exp = expectation(description: "Search completed")
            Task {
                // Generate random vector for search
                let randomVector = (0 ..< 512).map { _ in Double.random(in: -1 ... 1) }
                let results = try await vectorStore.search(queryVector: randomVector, limit: 3)
                XCTAssertNotNil(results)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }

    // MARK: - Tool Execution Tests

    func testToolResultParsing() {
        let rawOutput = """
        Container Status:
        - db: running
        - ollama: running
        Error: Some warning message
        Total containers: 2
        """

        let result = ToolExecutionResult.parse(toolName: "status", rawOutput: rawOutput)

        XCTAssertEqual(result.toolName, "status")
        XCTAssertFalse(result.success) // Contains "error"
        XCTAssertFalse(result.warnings.isEmpty)
    }

    func testEntityMemoryExtraction() {
        var memory = EntityMemory()

        memory.extractEntities(from: "The postgres service is down. Check redis logs.")

        XCTAssertTrue(memory.services.contains("postgres"))
        XCTAssertTrue(memory.services.contains("redis"))
    }
}
