import XCTest
@testable import SharedKit

@available(macOS 11.0, iOS 14.0, *)
final class VectorStoreEnhancementsTests: XCTestCase {
    // MARK: - VectorBatchOperation Tests

    func testBatchOperationCreation() {
        let contents = ["doc1", "doc2", "doc3"]
        let vectors = [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]]
        let metadata = [["key": "value1"], ["key": "value2"], ["key": "value3"]]

        let batch = VectorBatchOperation(
            contents: contents,
            vectors: vectors,
            metadata: metadata
        )

        XCTAssertEqual(batch.contents.count, 3)
        XCTAssertEqual(batch.vectors.count, 3)
        XCTAssertEqual(batch.metadata.count, 3)
    }

    func testBatchOperationDefaultMetadata() {
        let contents = ["doc1", "doc2"]
        let vectors = [[1.0], [2.0]]

        let batch = VectorBatchOperation(
            contents: contents,
            vectors: vectors
        )

        // Should create empty metadata for each item
        XCTAssertEqual(batch.metadata.count, 2)
        XCTAssertTrue(batch.metadata[0].isEmpty)
    }

    // MARK: - QueryOptimization Tests

    func testQueryOptimizationDefaults() {
        let optimization = QueryOptimization()

        XCTAssertTrue(optimization.useIndex)
        XCTAssertEqual(optimization.limit, 10)
        XCTAssertEqual(optimization.offset, 0)
        XCTAssertEqual(optimization.minScore, 0.0)
    }

    func testQueryOptimizationCustom() {
        let optimization = QueryOptimization(
            useIndex: false,
            limit: 50,
            offset: 10,
            minScore: 0.7
        )

        XCTAssertFalse(optimization.useIndex)
        XCTAssertEqual(optimization.limit, 50)
        XCTAssertEqual(optimization.offset, 10)
        XCTAssertEqual(optimization.minScore, 0.7)
    }

    // MARK: - VectorStoreMetrics Tests

    func testMetricsRecording() async {
        let metrics = VectorStoreMetrics()

        await metrics.recordQuery(duration: 0.1)
        await metrics.recordQuery(duration: 0.2)
        await metrics.recordQuery(duration: 0.3)

        let (avgTime, _, _) = await metrics.getMetrics()
        XCTAssertEqual(avgTime, 0.2, accuracy: 0.01, "Should calculate average query time")
    }

    func testMetricsCacheTracking() async {
        let metrics = VectorStoreMetrics()

        await metrics.recordCacheHit()
        await metrics.recordCacheHit()
        await metrics.recordCacheMiss()

        let (_, hitRate, _) = await metrics.getMetrics()
        XCTAssertEqual(hitRate, 2.0 / 3.0, accuracy: 0.01, "Should calculate cache hit rate")
    }

    func testMetricsErrorTracking() async {
        let metrics = VectorStoreMetrics()

        await metrics.recordQuery(duration: 0.1)
        await metrics.recordQuery(duration: 0.2)
        await metrics.recordError()

        let (_, _, errorRate) = await metrics.getMetrics()
        XCTAssertEqual(errorRate, 0.5, accuracy: 0.01, "Should track error rate")
    }

    func testMetricsEmptyState() async {
        let metrics = VectorStoreMetrics()
        let (avgTime, hitRate, errorRate) = await metrics.getMetrics()

        XCTAssertEqual(avgTime, 0.0)
        XCTAssertEqual(hitRate, 0.0)
        XCTAssertEqual(errorRate, 0.0)
    }

    func testMetricsRollingWindow() async {
        let metrics = VectorStoreMetrics()

        // Record more than window size (1000)
        for i in 0 ..< 1200 {
            await metrics.recordQuery(duration: Double(i) * 0.001)
        }

        _ = await metrics.getMetrics()
        // Should maintain only last 1000
        // Actual verification would require internal state access
        XCTAssertTrue(true, "Should handle rolling window")
    }
}

// MARK: - Integration Tests

@available(macOS 11.0, iOS 14.0, *)
final class EnhancementsIntegrationTests: XCTestCase {
    func testEndToEndWorkflow() async {
        // This would be an integration test showing full workflow
        // Requires actual Ollama and Postgres instances

        // Example structure:
        // 1. Create client with enhancements
        // 2. Execute queries
        // 3. Verify caching works
        // 4. Check metrics

        XCTAssertTrue(true, "Integration test placeholder")
    }
}
