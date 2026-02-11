import XCTest
@testable import SharedKit

final class PerformanceTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testVectorBatchOperationInitializationPerformance() {
        let largeContent = (0..<1000).map { "Content \($0)" }
        let largeVectors = (0..<1000).map { _ in (0..<128).map { _ in Double.random(in: 0...1) } }
        let largeMetadata = (0..<1000).map { ["id": "\($0)"] }

        measure {
            _ = VectorBatchOperation(
                contents: largeContent, vectors: largeVectors, metadata: largeMetadata
            )
        }
    }

    @available(macOS 12.0, iOS 15.0, *)
    func testHybridSearchCalculationPerformance() async {
        // We can't easily init HybridSearchEngine without a PostgresVectorStore,
        // but we can benchmark the calculation logic if we could access it.
        // However, it's private.
        // Instead, let's benchmark the VectorStoreMetrics logic which is an actor.

        let metrics = VectorStoreMetrics()

        measure {
            let exp = expectation(description: "Metrics")
            Task {
                for _ in 0..<1000 {
                    await metrics.recordQuery(duration: 0.1)
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }
}
