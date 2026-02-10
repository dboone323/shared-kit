//
//  Swift6ConcurrencyUtilities.swift
//  SharedKit
//
//  Shared utilities for Swift 6.0 concurrency and actor isolation patterns
//  Created to reduce code duplication across Swift 6.0 migration PRs
//

import Foundation

#if canImport(SwiftUI)
    import SwiftUI
#endif

// MARK: - Actor Boundary Utilities

/// Executes a block on the MainActor and returns its result
/// Reduces duplication of MainActor.run calls across the codebase
@MainActor
public func onMainActor<T>(_ block: @MainActor () async throws -> T) async rethrows -> T {
    try await block()
}

/// Executes a void block on the MainActor
/// Convenience for fire-and-forget MainActor operations
@MainActor
public func onMainActor(_ block: @MainActor () async throws -> Void) async rethrows {
    try await block()
}

// MARK: - Sendable Type Aliases

/// Common Sendable closure types to reduce repetition
public typealias SendableVoidClosure = @Sendable () -> Void
public typealias SendableAsyncVoidClosure = @Sendable () async -> Void
public typealias SendableThrowingAsyncVoidClosure = @Sendable () async throws -> Void
public typealias SendableResultClosure<T: Sendable> = @Sendable () -> T
public typealias SendableAsyncResultClosure<T: Sendable> = @Sendable () async -> T
public typealias SendableThrowingAsyncResultClosure<T: Sendable> = @Sendable () async throws -> T

// MARK: - Common Sendable Protocols

/// Protocol for ViewModels that need to be used with @MainActor
/// Reduces boilerplate of @MainActor @Observable ViewModel declarations
@MainActor
public protocol MainActorViewModel: AnyObject, Observable {
    /// Common initialization for ViewModels
    init()
}

/// Base error type that is Sendable-compliant
/// Use this as a base for custom errors to ensure Sendable conformance
public protocol SendableError: Error, Sendable {
    var localizedDescription: String { get }
}

// MARK: - Sendable Wrappers

/// Thread-safe wrapper for non-Sendable types
/// Use sparingly and only when necessary - prefer making types Sendable directly
public actor SendableBox<T> {
    private var value: T

    public init(_ value: T) {
        self.value = value
    }

    public func get() -> T {
        value
    }

    public func set(_ newValue: T) {
        self.value = newValue
    }

    public func modify(_ modifier: (inout T) -> Void) {
        modifier(&value)
    }
}

/// Unchecked Sendable wrapper for types that are conceptually Sendable but don't conform
/// WARNING: Only use this when you're certain the type is thread-safe
/// Prefer making types explicitly Sendable instead
public struct UncheckedSendableBox<T>: @unchecked Sendable {
    private let value: T

    public init(_ value: T) {
        self.value = value
    }

    public func get() -> T {
        value
    }
}

// MARK: - Collection Extensions for Actor Isolation

public extension Collection {
    /// Thread-safe isEmpty check that works across actor boundaries
    /// Note: In most cases, standard isEmpty should work fine
    /// This is provided for consistency in actor-isolated contexts
    @Sendable
    var sendableIsEmpty: Bool {
        isEmpty
    }

    /// Thread-safe count check
    @Sendable
    var sendableCount: Int {
        count
    }
}

// MARK: - Task Utilities

/// Utilities for managing Tasks with proper cancellation
public enum TaskUtilities {
    /// Runs a task with a timeout
    /// Throws if the task doesn't complete within the specified duration
    public static func runWithTimeout<T: Sendable>(
        _ duration: Duration,
        operation: @Sendable @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(for: duration)
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }

    /// Timeout error
    public struct TimeoutError: SendableError {
        public var localizedDescription: String {
            "Operation timed out"
        }

        public init() {}
    }
}

#if canImport(SwiftUI)

    // MARK: - SwiftUI Helpers

    /// Common color utilities for Swift 6.0 migration
    /// Provides fixed color alternatives to system colors for isolation safety
    public enum Swift6Colors {
        /// Fixed white background (replacement for .systemBackground in isolated contexts)
        public static let fixedWhiteBackground = Color.white.opacity(0.95)

        /// Fixed black background
        public static let fixedBlackBackground = Color.black.opacity(0.95)

        /// Fixed light gray background
        public static let fixedLightGray = Color.gray.opacity(0.1)

        /// Fixed dark gray background
        public static let fixedDarkGray = Color.gray.opacity(0.8)
    }

    /// Extension for common @MainActor view modifiers
    public extension View {
        /// Apply @MainActor animation safely
        @MainActor
        func mainActorAnimation(
            _ value: some Equatable
        ) -> some View {
            animation(.default, value: value)
        }
    }
#endif

// MARK: - Error Handling Utilities

/// Standard error types for Swift 6.0 contexts
public enum Swift6Error: SendableError {
    case actorIsolationViolation(String)
    case invalidState(String)
    case operationCancelled
    case notImplemented(String)

    public var localizedDescription: String {
        switch self {
        case let .actorIsolationViolation(message):
            "Actor isolation violation: \(message)"
        case let .invalidState(message):
            "Invalid state: \(message)"
        case .operationCancelled:
            "Operation was cancelled"
        case let .notImplemented(message):
            "Not implemented: \(message)"
        }
    }
}

// MARK: - Logging Utilities

/// Thread-safe logging for actor-isolated contexts
public actor Swift6Logger {
    private var logMessages: [LogMessage] = []

    public init() {}

    public func log(_ message: String, level: LogLevel = .info) {
        let logMessage = LogMessage(message: message, level: level, timestamp: Date())
        logMessages.append(logMessage)

        // Print to console
        print("[\(level.rawValue)] \(message)")
    }

    public func getLogs() -> [LogMessage] {
        logMessages
    }

    public func clearLogs() {
        logMessages.removeAll()
    }

    public struct LogMessage: Sendable {
        public let message: String
        public let level: LogLevel
        public let timestamp: Date
    }

    public enum LogLevel: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
}

// MARK: - Shared Singleton Pattern

/// Base protocol for services that need to be Sendable singletons
/// Provides a standard pattern for shared services across actor boundaries
public protocol SendableService: Actor {
    static var shared: Self { get }
}

// MARK: - Documentation

/*
 Usage Examples:

 1. MainActor operations:
 ```swift
 let result = await onMainActor {
     // Your @MainActor code here
     return someValue
 }
 ```

 2. Sendable closures:
 ```swift
 func doSomething(completion: SendableAsyncVoidClosure) async {
     await completion()
 }
 ```

 3. ViewModel base:
 ```swift
 @MainActor
 @Observable
 final class MyViewModel: MainActorViewModel {
     required init() {
         // Initialize
     }
 }
 ```

 4. Sendable box for non-Sendable types:
 ```swift
 let box = SendableBox(nonSendableValue)
 await box.set(newValue)
 let value = await box.get()
 ```

 5. Fixed colors for isolated contexts:
 ```swift
 .background(Swift6Colors.fixedWhiteBackground)
 ```

 6. Task timeout:
 ```swift
 let result = try await TaskUtilities.runWithTimeout(.seconds(30)) {
     await longRunningOperation()
 }
 ```
 */
