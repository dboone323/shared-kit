import XCTest

@testable import SharedKit

final class RAGComponentsTests: XCTestCase {
    func testToolExecutionResultParsesWarningsAndErrors() {
        let rawOutput = """
            Container status: 3 running
            Warning: deprecated endpoint
            Error: failed to connect to redis
            """

        let result = ToolExecutionResult.parse(toolName: "status", rawOutput: rawOutput)

        XCTAssertFalse(result.success)
        XCTAssertEqual(result.toolName, "status")
        XCTAssertFalse(result.warnings.isEmpty)
        XCTAssertFalse(result.suggestions.isEmpty)
    }

    func testToolExecutionResultExtractsContainerMetrics() {
        let rawOutput = "5 running healthy containers"
        let result = ToolExecutionResult.parse(toolName: "status", rawOutput: rawOutput)

        XCTAssertEqual(result.metrics["containers_running"], "5")
        XCTAssertTrue(result.success)
    }

    func testEntityMemoryExtractsServicesAndFiles() {
        var memory = EntityMemory()
        memory.extractEntities(
            from: "postgres and redis failed. See /var/log/postgres.log for error details")

        XCTAssertTrue(memory.services.contains("postgres"))
        XCTAssertTrue(memory.services.contains("redis"))
        XCTAssertTrue(memory.mentionedFiles.contains("/var/log/postgres.log"))
        XCTAssertFalse(memory.recentErrors.isEmpty)
    }

    func testEntityMemoryRetainsOnlyRecentErrors() {
        var memory = EntityMemory()
        for index in 0..<10 {
            memory.extractEntities(from: "error \(index)")
        }

        XCTAssertEqual(memory.recentErrors.count, 5)
    }
}
