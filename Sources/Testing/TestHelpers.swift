//
// TestHelpers.swift
// SharedKit
//
// Common testing utilities
//

import XCTest

public extension XCTestCase {
    /// Asserts that the result is a success and returns the value
    func assertSuccess<T>(_ result: Result<T, some Any>, file: StaticString = #file, line: UInt = #line) -> T? {
        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            XCTFail("Expected success but got failure: \(error)", file: file, line: line)
            return nil
        }
    }

    /// Asserts that the result is a failure and returns the error
    func assertFailure<E>(_ result: Result<some Any, E>, file: StaticString = #file, line: UInt = #line) -> E? {
        switch result {
        case let .success(value):
            XCTFail("Expected failure but got success: \(value)", file: file, line: line)
            return nil
        case let .failure(error):
            return error
        }
    }

    /// Waits for a specific duration
    func wait(for duration: TimeInterval) {
        let expectation = XCTestExpectation(description: "Wait for \(duration) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: duration + 1.0)
    }
}
