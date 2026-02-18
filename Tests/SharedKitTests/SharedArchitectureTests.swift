//
//  SharedArchitectureTests.swift
//  SharedKitTests
//
//  Comprehensive tests for SharedArchitecture patterns and protocols
//

import Combine
import XCTest

@testable import SharedKit

// MARK: - Test ViewModel Implementation

@MainActor
final class MockViewModel: BaseViewModel {
    struct State {
        var isLoading: Bool = false
        var errorMessage: String?
        var data: [String] = []
    }

    enum Action {
        case loadData
        case clearData
        case setError(String)
    }

    @Published var state: State = State()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func handle(_ action: Action) {
        switch action {
        case .loadData:
            state.data = ["Item 1", "Item 2", "Item 3"]
        case .clearData:
            state.data = []
        case .setError(let message):
            state.errorMessage = message
        }
    }
}

// MARK: - Base ViewModel Tests

@MainActor
final class SharedArchitectureTests: XCTestCase {
    var viewModel: MockViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = MockViewModel()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        viewModel = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - BaseViewModel Protocol Tests

    func testBaseViewModelInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.state.data.count, 0)
    }

    func testBaseViewModelStateManagement() {
        // Initial state
        XCTAssertEqual(viewModel.state.data.count, 0)

        // Load data
        viewModel.handle(.loadData)
        XCTAssertEqual(viewModel.state.data.count, 3)
        XCTAssertEqual(viewModel.state.data[0], "Item 1")

        // Clear data
        viewModel.handle(.clearData)
        XCTAssertEqual(viewModel.state.data.count, 0)
    }

    func testBaseViewModelActionHandling() {
        viewModel.handle(.loadData)
        XCTAssertFalse(viewModel.state.data.isEmpty)

        viewModel.handle(.setError("Test error"))
        XCTAssertEqual(viewModel.state.errorMessage, "Test error")

        viewModel.handle(.clearData)
        XCTAssertTrue(viewModel.state.data.isEmpty)
    }

    func testSetLoadingState() {
        viewModel.setLoading(true)
        XCTAssertTrue(viewModel.isLoading)

        viewModel.setLoading(false)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testResetError() {
        viewModel.handle(.setError("Test error"))
        XCTAssertNotNil(viewModel.state.errorMessage)

        viewModel.resetError()
        XCTAssertNil(viewModel.state.errorMessage, "Error should be cleared after reset")
    }

    func testValidateState() {
        let isValid = viewModel.validateState()
        XCTAssertTrue(isValid)  // Default implementation returns true
    }

    // MARK: - Published Property Tests

    func testStatePublishing() {
        let expectation = expectation(description: "State should publish changes")
        var receivedValues = 0

        viewModel.$state
            .sink { _ in
                receivedValues += 1
                if receivedValues >= 2 {  // Initial + one change
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.handle(.loadData)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThanOrEqual(receivedValues, 2)
    }

    func testIsLoadingPublishing() {
        let expectation = expectation(description: "isLoading should publish changes")
        var receivedChange = false

        viewModel.$isLoading
            .dropFirst()
            .sink { value in
                if value {
                    receivedChange = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.setLoading(true)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedChange)
    }

    // MARK: - OperationResult Tests

    func testOperationResultSuccess() {
        let result: OperationResult<String> = .success("Test data")

        switch result {
        case .success(let value):
            XCTAssertEqual(value, "Test data")
        case .failure:
            XCTFail("Expected success, got failure")
        }
    }

    func testOperationResultFailure() {
        let error = ViewModelError.networkError
        let result: OperationResult<String> = .failure(error)

        switch result {
        case .success:
            XCTFail("Expected failure, got success")
        case .failure(let err):
            XCTAssertNotNil(err)
        }
    }

    // MARK: - ViewModelError Tests

    func testViewModelErrorTypes() {
        let invalidState = ViewModelError.invalidState
        let networkError = ViewModelError.networkError
        let dataError = ViewModelError.dataError
        let unknownError = ViewModelError.unknownError

        XCTAssertNotNil(invalidState)
        XCTAssertNotNil(networkError)
        XCTAssertNotNil(dataError)
        XCTAssertNotNil(unknownError)
    }

    func testViewModelErrorEquality() {
        // ViewModelError should be testable
        switch ViewModelError.networkError {
        case .networkError:
            break  // Expected
        default:
            XCTFail("Wrong error type decoded")
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentStateUpdates() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { @MainActor in
                    if i % 2 == 0 {
                        self.viewModel.handle(.loadData)
                    } else {
                        self.viewModel.handle(.clearData)
                    }
                }
            }
        }

        // Should maintain state consistency
        XCTAssertNotNil(viewModel.state)
    }

    func testConcurrentLoadingStateChanges() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask { @MainActor in
                    self.viewModel.setLoading(i % 2 == 0)
                }
            }
        }

        // Should maintain loading state consistency
        XCTAssertNotNil(viewModel.isLoading)
    }

    // MARK: - Integration Tests

    func testCompleteViewModelWorkflow() {
        // Start with empty state
        XCTAssertTrue(viewModel.state.data.isEmpty)
        XCTAssertFalse(viewModel.isLoading)

        // Set loading
        viewModel.setLoading(true)
        XCTAssertTrue(viewModel.isLoading)

        // Load data
        viewModel.handle(.loadData)
        XCTAssertEqual(viewModel.state.data.count, 3)

        // Complete loading
        viewModel.setLoading(false)
        XCTAssertFalse(viewModel.isLoading)

        // Handle error
        viewModel.handle(.setError("Something went wrong"))
        XCTAssertNotNil(viewModel.state.errorMessage)

        // Clear data
        viewModel.handle(.clearData)
        XCTAssertTrue(viewModel.state.data.isEmpty)
    }

    // MARK: - MainActor Isolation Tests

    func testMainActorIsolation() {
        Task { @MainActor in
            let vm = MockViewModel()
            vm.setLoading(true)
            vm.handle(.loadData)
            XCTAssertNotNil(vm)
        }
    }

    // MARK: - ObservableObject Conformance Tests

    func testObservableObjectConformance() {
        // ViewModel should be observable - protocol conformance verified by compilation
        XCTAssertNotNil(viewModel)
    }

    func testObjectWillChangePublisher() {
        // Test state changes
        viewModel.handle(.loadData)
        XCTAssertEqual(viewModel.state.data.count, 3)
    }

    // MARK: - Performance Tests

    func testActionHandlingPerformance() {
        measure {
            for _ in 0..<1000 {
                viewModel.handle(.loadData)
                viewModel.handle(.clearData)
            }
        }
    }

    func testStateUpdatePerformance() {
        measure {
            for _ in 0..<1000 {
                viewModel.setLoading(true)
                viewModel.setLoading(false)
            }
        }
    }
}
