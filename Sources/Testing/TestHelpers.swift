//
// TestHelpers.swift
// SharedKit
//
// Common testing utilities
//

import XCTest

public extension XCTestCase {
    /// Asserts that the result is a success and returns the value
    func assertSuccess<T, E>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> T? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)", file: file, line: line)
            return nil
        }
    }
    
    /// Asserts that the result is a failure and returns the error
    func assertFailure<T, E>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> E? {
        switch result {
        case .success(let value):
            XCTFail("Expected failure but got success: \(value)", file: file, line: line)
            return nil
        case .failure(let error):
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
