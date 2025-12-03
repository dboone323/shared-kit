//
// ResultExtensions.swift
// SharedKit
//
// Extensions for Swift's Result type to improve error handling ergonomics
//

import Foundation

public extension Result {
    /// Returns the success value if available, otherwise nil
    var value: Success? {
        switch self {
        case let .success(value): return value
        case .failure: return nil
        }
    }

    /// Returns the error if available, otherwise nil
    var error: Failure? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }

    /// Returns true if the result is a success
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    /// Returns true if the result is a failure
    var isFailure: Bool {
        !isSuccess
    }
}
