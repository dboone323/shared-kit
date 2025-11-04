//
//  SharedArchitecture.swift
//  Quantum-workspace
//
//  Shared architecture patterns and protocols used across all projects
//

import Foundation
import SwiftUI

// MARK: - Base ViewModel Protocol

/// Base protocol for all ViewModels in the Quantum Workspace
/// Provides consistent state management and action handling patterns
@MainActor
public protocol BaseViewModel: ObservableObject {
    associatedtype State
    associatedtype Action

    var state: State { get set }
    var isLoading: Bool { get set }

    func handle(_ action: Action)
}

// MARK: - Base ViewModel Extensions

extension BaseViewModel {
    /// Reset error state
    public func resetError() {
        // Default implementation - can be overridden
    }

    /// Set loading state
    public func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    /// Set error state
    public func setError(_ error: Error) {
        // Default implementation - can be overridden
    }

    /// Validate current state
    public func validateState() -> Bool {
        // Default implementation - can be overridden
        return true
    }
}

// MARK: - Common Result Types

/// Standardized result type for operations
public enum OperationResult<T> {
    case success(T)
    case failure(Error)
}

/// Standardized error types
public enum ViewModelError: Error {
    case invalidState
    case networkError
    case dataError
    case unknownError
}

// MARK: - Common State Management

/// Base state structure for ViewModels
public protocol ViewModelState {
    /// Indicates if the view is currently loading
    var isLoading: Bool { get set }

    /// Current error message, if any
    var errorMessage: String? { get set }
}

/// Default implementation for ViewModelState
extension ViewModelState {
    public mutating func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    public mutating func setError(_ message: String?) {
        errorMessage = message
    }

    public mutating func clearError() {
        errorMessage = nil
    }
}
