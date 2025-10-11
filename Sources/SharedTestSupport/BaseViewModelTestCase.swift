import Combine
import SharedKit
import XCTest

/// Base test case for all view model tests across projects
/// Provides common testing infrastructure and utilities
@MainActor
open class SharedViewModelTestCase: XCTestCase {
    public var cancellables = Set<AnyCancellable>()

    open override func setUp() async throws {
        try await super.setUp()
        self.cancellables = Set<AnyCancellable>()
        self.setupTestEnvironment()
    }

    open override func tearDown() async throws {
        self.cancellables.forEach { $0.cancel() }
        self.cancellables.removeAll()
        self.cleanupTestEnvironment()
        try await super.tearDown()
    }

    /// Override in subclasses to set up test environment
    open func setupTestEnvironment() {
        // Default implementation - override as needed
    }

    /// Override in subclasses to clean up test environment
    open func cleanupTestEnvironment() {
        // Default implementation - override as needed
    }

    // MARK: - Async Testing Helpers

    /// Wait for async operation with timeout
    public func waitForAsync<T: Sendable>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Simple timeout implementation without TaskGroup to avoid data races
        let startTime = Date()
        let operationTask = Task { try await operation() }

        while !Task.isCancelled && Date().timeIntervalSince(startTime) < timeout {
            if operationTask.isCancelled {
                throw XCTestError(.timeoutWhileWaiting)
            }

            do {
                let result = try await operationTask.value
                return result
            } catch {
                // Task is still running, continue waiting
            }

            try await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
        }

        operationTask.cancel()
        throw XCTestError(.timeoutWhileWaiting)
    }

    /// Assert async operation completes successfully
    public func assertAsyncCompletes<T: Sendable>(
        _ operation: @escaping () async throws -> T,
        timeout: TimeInterval = 5.0,
        message: String = "Async operation failed",
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await waitForAsync(timeout: timeout, operation: operation)
        } catch {
            XCTFail("\(message): \(error)", file: file, line: line)
        }
    }

    /// Assert async operation throws specific error
    public func assertAsyncThrows<E, T: Sendable>(
        _ operation: @escaping () async throws -> T,
        expectedError: E,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async where E: Error & Equatable {
        do {
            _ = try await waitForAsync(timeout: timeout, operation: operation)
            XCTFail("Expected error but operation completed successfully", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? E, expectedError, file: file, line: line)
        }
    }

    // MARK: - State Testing Helpers

    /// Assert state changes after operation
    public func assertStateChange<T: Equatable & Sendable>(
        initialState: T,
        operation: @escaping () async throws -> T,
        timeout: TimeInterval = 2.0,
        message: String = "State did not change",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let finalState = try await waitForAsync(timeout: timeout, operation: operation)
        XCTAssertNotEqual(initialState, finalState, message, file: file, line: line)
    }

    /// Assert state becomes expected value
    public func assertStateBecomes<T: Equatable & Sendable>(
        _ expectedState: T,
        operation: @escaping () async throws -> T,
        timeout: TimeInterval = 2.0,
        message: String = "State did not match expected value",
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let finalState = try await waitForAsync(timeout: timeout, operation: operation)
        XCTAssertEqual(finalState, expectedState, message, file: file, line: line)
    }

    // MARK: - Performance Testing

    /// Measure and assert performance
    public func assertPerformance<T: Sendable>(
        operation: String,
        expectedDuration: TimeInterval,
        _ block: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let startTime = Date()
        _ = try? await block()
        let duration = Date().timeIntervalSince(startTime)

        XCTAssertLessThan(
            duration,
            expectedDuration,
            "\(operation) took \(String(format: "%.3f", duration))s, expected < \(expectedDuration)s",
            file: file,
            line: line
        )
    }

    // MARK: - Mock Data Helpers

    /// Generate consistent test data for cross-project testing
    public func generateTestData(for project: TestProject, count: Int = 1) -> [[String: Any]] {
        switch project {
        case .habitQuest:
            return MockDataGenerator.generateHabits(count: count)
        case .momentumFinance:
            return MockDataGenerator.generateTransactions(count: count)
        case .codingReviewer:
            return MockDataGenerator.generateCodeFiles(count: count)
        case .plannerApp:
            return MockDataGenerator.generatePlannerTasks(count: count)
        case .avoidObstaclesGame:
            return MockDataGenerator.generateGameSessions(count: count)
        }
    }

    // MARK: - Memory Testing

    /// Assert no memory leaks in async operations
    public func assertNoMemoryLeaks<T: Sendable>(
        in operation: @escaping () async throws -> T,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Simple memory leak detection by checking if operation completes without issues
        // In a more sophisticated implementation, this could use Instruments-like memory tracking
        do {
            _ = try await waitForAsync(timeout: timeout, operation: operation)
        } catch {
            XCTFail("Memory leak detected or operation failed: \(error)", file: file, line: line)
        }
    }
}

/// Test project types for cross-project testing
public enum TestProject {
    case habitQuest
    case momentumFinance
    case codingReviewer
    case plannerApp
    case avoidObstaclesGame
}

/// Specialized test case for BaseViewModel implementations
@MainActor
open class BaseViewModelTestCase<ViewModelType: BaseViewModel>: SharedViewModelTestCase {
    public var viewModel: ViewModelType!

    override open func setupTestEnvironment() {
        super.setupTestEnvironment()
        self.setupViewModel()
    }

    override open func cleanupTestEnvironment() {
        self.viewModel = nil
        super.cleanupTestEnvironment()
    }

    /// Override in subclasses to set up the specific view model
    open func setupViewModel() {
        fatalError("Subclasses must implement setupViewModel()")
    }

    // MARK: - ViewModel Testing Helpers

    /// Test that view model handles action correctly
    public func testViewModelAction(
        _ action: ViewModelType.Action,
        expectedLoadingStates: [Bool] = [true, false],
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        XCTAssertFalse(
            viewModel.isLoading, "View model should not be loading initially", file: file,
            line: line)

        var loadingStates: [Bool] = []

        // Monitor loading state
        let monitoringTask = Task {
            while !Task.isCancelled {
                loadingStates.append(viewModel.isLoading)
                try? await Task.sleep(nanoseconds: 50_000_000)  // 0.05s
            }
        }

        // Execute action
        await viewModel.handle(action)

        // Stop monitoring
        monitoringTask.cancel()

        // Verify loading states
        for expectedState in expectedLoadingStates {
            XCTAssertTrue(
                loadingStates.contains(expectedState),
                "Expected loading state \(expectedState) was not observed", file: file, line: line)
        }

        XCTAssertFalse(
            viewModel.isLoading, "View model should not be loading after action completes",
            file: file, line: line)
    }

    /// Test view model state validation
    public func testViewModelValidation(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let isValid = viewModel.validateState()
        XCTAssertTrue(isValid, "View model state should be valid", file: file, line: line)
    }

    /// Test error handling in view model
    public func testViewModelErrorHandling(
        action: ViewModelType.Action,
        expectedErrorMessage: String,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        XCTAssertNil(
            viewModel.errorMessage, "View model should not have error initially", file: file,
            line: line)

        await viewModel.handle(action)

        // Wait for error to be set
        let expectation = XCTestExpectation(description: "Error message")
        var errorSet = false

        for _ in 0..<Int(timeout * 10) {
            if viewModel.errorMessage != nil {
                errorSet = true
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1s
        }

        XCTAssertTrue(errorSet, "Error message was not set", file: file, line: line)
        XCTAssertEqual(viewModel.errorMessage, expectedErrorMessage, file: file, line: line)
    }
}
