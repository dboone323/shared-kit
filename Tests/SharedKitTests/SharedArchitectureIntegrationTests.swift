import SwiftData
import XCTest

@testable import SharedTestSupport

/// Integration tests for shared architecture across all projects
class SharedArchitectureIntegrationTests: SharedViewModelTestCase {
    var testContainer: ModelContainer!

    override func setupTestEnvironment() {
        super.setupTestEnvironment()
        // Skip test container creation for now since we don't have specific models to test
        // self.testContainer = try TestUtilities.createTestContainer(for: [])
    }

    override func cleanupTestEnvironment() {
        self.testContainer = nil
        super.cleanupTestEnvironment()
    }

    // MARK: - Mock Data Generation Tests

    func testCrossProjectMockDataGeneration() {
        // Test that mock data generators work for all projects
        let habitData = generateTestData(for: .habitQuest, count: 5)
        XCTAssertEqual(habitData.count, 5)
        XCTAssertTrue(habitData.allSatisfy { $0["name"] as? String != nil })

        let financeData = generateTestData(for: .momentumFinance, count: 3)
        XCTAssertEqual(financeData.count, 3)
        XCTAssertTrue(financeData.allSatisfy { $0["amount"] as? Double != nil })

        let codeData = generateTestData(for: .codingReviewer, count: 2)
        XCTAssertEqual(codeData.count, 2)
        XCTAssertTrue(codeData.allSatisfy { $0["language"] as? String != nil })

        let plannerData = generateTestData(for: .plannerApp, count: 4)
        XCTAssertEqual(plannerData.count, 4)
        XCTAssertTrue(plannerData.allSatisfy { $0["title"] as? String != nil })

        let gameData = generateTestData(for: .avoidObstaclesGame, count: 1)
        XCTAssertEqual(gameData.count, 1)
        XCTAssertTrue(gameData.allSatisfy { $0["score"] as? Int != nil })
    }

    // MARK: - Test Utilities Tests

    func testMockDataConsistency() {
        // Test that same seed produces consistent results (basic consistency check)
        let data1 = MockDataGenerator.generateHabits(count: 3)
        let data2 = MockDataGenerator.generateHabits(count: 3)

        // Data should have same structure even if values differ (random generation)
        XCTAssertEqual(data1.count, data2.count)
        XCTAssertEqual(data1.count, 3)

        for (item1, item2) in zip(data1, data2) {
            XCTAssertNotNil(item1["id"] as? String)
            XCTAssertNotNil(item2["id"] as? String)
            XCTAssertNotNil(item1["name"] as? String)
            XCTAssertNotNil(item2["name"] as? String)
        }
    }

    // MARK: - Performance Testing

    func testSharedArchitecturePerformance() async {
        // Test performance of mock data generation
        let startTime = Date()
        let result = MockDataGenerator.generateHabits(count: 100)
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(duration, 1.0, "Mock data generation took \(duration)s, expected < 1.0s")
        XCTAssertEqual(result.count, 100)
    }

    // MARK: - Memory Leak Tests

    func testNoMemoryLeaksInMockDataGeneration() async {
        await assertNoMemoryLeaks(in: {
            _ = MockDataGenerator.generateTransactions(count: 50)
            return ()
        })
    }

    // MARK: - Async Testing Helpers

    func testAsyncTestingHelpers() async {
        // Test that async testing helpers work correctly
        var executionCount = 0

        await assertAsyncCompletes({
            executionCount += 1
            return executionCount
        })

        XCTAssertEqual(executionCount, 1)

        // Test async throws - just verify it throws, don't check exact error
        var didThrow = false
        do {
            _ = try await waitForAsync(
                timeout: 5.0,
                operation: {
                    throw NSError(domain: "TestError", code: 1, userInfo: nil)
                })
        } catch {
            didThrow = true
        }
        XCTAssertTrue(didThrow, "Expected operation to throw an error")
    }

    // MARK: - State Testing Helpers

    func testStateTestingHelpers() async {
        var counter = 0

        do {
            // Test state change
            try await assertStateChange(
                initialState: 0,
                operation: {
                    counter = 5
                    return counter
                })

            // Test state becomes
            try await assertStateBecomes(
                10,
                operation: {
                    counter = 10
                    return counter
                })
        } catch {
            XCTFail("State testing failed: \(error)")
        }
    }
}
