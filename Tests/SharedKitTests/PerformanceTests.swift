import XCTest

@testable import SharedKit

final class PerformanceTests: XCTestCase {
    func testToolExecutionResultParsingPerformance() {
        let rawOutput = String(repeating: "db running healthy\n", count: 2_000)
            + "Warning: deprecated flag\n"
            + "Error: timeout from service"

        measure {
            _ = ToolExecutionResult.parse(toolName: "status", rawOutput: rawOutput)
        }
    }

    func testEntityExtractionPerformance() {
        let text = String(repeating: "postgres redis ollama /var/log/service.log error ", count: 800)

        measure {
            var memory = EntityMemory()
            for _ in 0..<50 {
                memory.extractEntities(from: text)
            }
            XCTAssertTrue(memory.services.contains("postgres"))
        }
    }

    @available(macOS 12.0, iOS 15.0, *)
    func testSemanticCacheRoundTripPerformance() async {
        let intelligence = Intelligence()
        let embeddings = Array(repeating: Float(0.2), count: 64)

        let start = Date()
        for index in 0..<200 {
            let query = "query-\(index)"
            let expected = "result-\(index)"
            await intelligence.cacheResult(expected, for: query, embeddings: embeddings)
            let hit = await intelligence.retrieveCachedResult(for: query, embeddings: embeddings)
            XCTAssertEqual(hit, expected)
        }

        let duration = Date().timeIntervalSince(start)
        XCTAssertLessThan(duration, 2.0, "Semantic cache round-trip took too long: \(duration)s")
    }
}
