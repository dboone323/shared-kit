//
//  AdvancedErrorHandling.swift
//  Comprehensive Error Handling System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Combine
import Foundation
import os.log
import SwiftUI

// MARK: - Required Imports and Type Definitions

// Analytics service protocol (simplified for error handling)
public protocol AnalyticsServiceProtocol {
    func track(event: String, properties: [String: Any]?, userId: String?) async
}

// Mock analytics service for compilation
public class MockAnalyticsService: AnalyticsServiceProtocol {
    public func track(event: String, properties _: [String: Any]?, userId _: String?) async {
        print("📊 Analytics: \(event)")
    }
}

// Mock dependency injection for error handling
@propertyWrapper
public struct MockInjected<T> {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - Core Error Handling Protocols

/// Protocol for all application errors
public protocol AppErrorProtocol: Error, LocalizedError, CustomStringConvertible, Codable {
    /// Unique error identifier
    var errorId: String { get }

    /// Error severity level
    var severity: ErrorSeverity { get }

    /// Error category for grouping
    var category: ErrorCategory { get }

    /// Timestamp when error occurred
    var timestamp: Date { get }

    /// Context information for debugging
    var context: [String: Any] { get }

    /// User-friendly error message
    var userMessage: String { get }

    /// Technical error details for developers
    var technicalDetails: String { get }

    /// Recovery suggestions for users
    var recoverySuggestions: [String] { get }

    /// Whether this error should be reported to analytics
    var shouldReport: Bool { get }

    /// Whether this error can be recovered from automatically
    var isRecoverable: Bool { get }
}

/// Error severity levels
public enum ErrorSeverity: String, CaseIterable, Codable {
    case low
    case medium
    case high
    case critical

    public var priority: Int {
        switch self {
        case .low: 1
        case .medium: 2
        case .high: 3
        case .critical: 4
        }
    }

    public var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .critical: "Critical"
        }
    }
}

/// Error categories for organization
public enum ErrorCategory: String, CaseIterable, Codable {
    case validation
    case network
    case data
    case authentication
    case authorization
    case business
    case system
    case ui
    case integration
    case unknown

    public var displayName: String {
        switch self {
        case .validation: "Validation Error"
        case .network: "Network Error"
        case .data: "Data Error"
        case .authentication: "Authentication Error"
        case .authorization: "Authorization Error"
        case .business: "Business Logic Error"
        case .system: "System Error"
        case .ui: "User Interface Error"
        case .integration: "Integration Error"
        case .unknown: "Unknown Error"
        }
    }
}

// MARK: - Base Error Implementation

/// Base implementation of AppErrorProtocol
public struct AppError: AppErrorProtocol {
    public let errorId: String
    public let severity: ErrorSeverity
    public let category: ErrorCategory
    public let timestamp: Date
    public let context: [String: Any]
    public let userMessage: String
    public let technicalDetails: String
    public let recoverySuggestions: [String]
    public let shouldReport: Bool
    public let isRecoverable: Bool

    // MARK: - Error Protocol Conformance

    public var errorDescription: String? {
        userMessage
    }

    public var failureReason: String? {
        technicalDetails
    }

    public var recoverySuggestion: String? {
        recoverySuggestions.first
    }

    public var helpAnchor: String? {
        "error_help_\(category.rawValue)"
    }

    public var description: String {
        "[\(severity.displayName)] \(category.displayName): \(userMessage)"
    }

    // MARK: - Codable Implementation

    private enum CodingKeys: String, CodingKey {
        case errorId, severity, category, timestamp, userMessage, technicalDetails, recoverySuggestions, shouldReport, isRecoverable
        case contextData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        errorId = try container.decode(String.self, forKey: .errorId)
        severity = try container.decode(ErrorSeverity.self, forKey: .severity)
        category = try container.decode(ErrorCategory.self, forKey: .category)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        userMessage = try container.decode(String.self, forKey: .userMessage)
        technicalDetails = try container.decode(String.self, forKey: .technicalDetails)
        recoverySuggestions = try container.decode([String].self, forKey: .recoverySuggestions)
        shouldReport = try container.decode(Bool.self, forKey: .shouldReport)
        isRecoverable = try container.decode(Bool.self, forKey: .isRecoverable)

        // Decode context as string dictionary and convert to Any
        if let contextData = try? container.decode([String: String].self, forKey: .contextData) {
            context = contextData
        } else {
            context = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(errorId, forKey: .errorId)
        try container.encode(severity, forKey: .severity)
        try container.encode(category, forKey: .category)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(userMessage, forKey: .userMessage)
        try container.encode(technicalDetails, forKey: .technicalDetails)
        try container.encode(recoverySuggestions, forKey: .recoverySuggestions)
        try container.encode(shouldReport, forKey: .shouldReport)
        try container.encode(isRecoverable, forKey: .isRecoverable)

        // Encode context as string dictionary
        let contextData = context.compactMapValues { "\($0)" }
        try container.encode(contextData, forKey: .contextData)
    }

    // MARK: - Initialization

    public init(
        errorId: String = UUID().uuidString,
        severity: ErrorSeverity,
        category: ErrorCategory,
        userMessage: String,
        technicalDetails: String,
        context: [String: Any] = [:],
        recoverySuggestions: [String] = [],
        shouldReport: Bool = true,
        isRecoverable: Bool = false
    ) {
        self.errorId = errorId
        self.severity = severity
        self.category = category
        timestamp = Date()
        self.context = context
        self.userMessage = userMessage
        self.technicalDetails = technicalDetails
        self.recoverySuggestions = recoverySuggestions
        self.shouldReport = shouldReport
        self.isRecoverable = isRecoverable
    }
}

// MARK: - Specialized Error Types

/// Validation errors for data validation failures
public struct ValidationError: AppErrorProtocol {
    public let errorId: String
    public let severity: ErrorSeverity = .medium
    public let category: ErrorCategory = .validation
    public let timestamp: Date
    public let context: [String: Any]
    public let userMessage: String
    public let technicalDetails: String
    public let recoverySuggestions: [String]
    public let shouldReport: Bool = false
    public let isRecoverable: Bool = true

    // Validation-specific properties
    public let field: String
    public let validationRule: String
    public let providedValue: Any?
    public let expectedFormat: String?

    public var errorDescription: String? { userMessage }
    public var failureReason: String? { technicalDetails }
    public var recoverySuggestion: String? { recoverySuggestions.first }
    public var helpAnchor: String? { "validation_help_\(field)" }
    public var description: String { "Validation Error: \(userMessage)" }

    public init(
        field: String,
        validationRule: String,
        providedValue: Any?,
        expectedFormat: String? = nil,
        userMessage: String? = nil,
        recoverySuggestions: [String] = []
    ) {
        errorId = UUID().uuidString
        timestamp = Date()
        self.field = field
        self.validationRule = validationRule
        self.providedValue = providedValue
        self.expectedFormat = expectedFormat

        self.userMessage = userMessage ?? "Invalid value for \(field)"
        technicalDetails = "Validation failed for field '\(field)' with rule '\(validationRule)'"
        self.recoverySuggestions = recoverySuggestions.isEmpty ? ["Please check the \(field) field and try again"] : recoverySuggestions

        var contextDict: [String: Any] = [
            "field": field,
            "validation_rule": validationRule,
        ]
        if let value = providedValue {
            contextDict["provided_value"] = value
        }
        if let format = expectedFormat {
            contextDict["expected_format"] = format
        }
        context = contextDict
    }

    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        errorId = try container.decode(String.self, forKey: .errorId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        userMessage = try container.decode(String.self, forKey: .userMessage)
        technicalDetails = try container.decode(String.self, forKey: .technicalDetails)
        recoverySuggestions = try container.decode([String].self, forKey: .recoverySuggestions)
        field = try container.decode(String.self, forKey: .field)
        validationRule = try container.decode(String.self, forKey: .validationRule)
        providedValue = try? container.decode(String.self, forKey: .providedValue)
        expectedFormat = try? container.decode(String.self, forKey: .expectedFormat)
        context = try container.decode([String: String].self, forKey: .context)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(errorId, forKey: .errorId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(userMessage, forKey: .userMessage)
        try container.encode(technicalDetails, forKey: .technicalDetails)
        try container.encode(recoverySuggestions, forKey: .recoverySuggestions)
        try container.encode(field, forKey: .field)
        try container.encode(validationRule, forKey: .validationRule)
        if let value = providedValue {
            try container.encode("\(value)", forKey: .providedValue)
        }
        try container.encodeIfPresent(expectedFormat, forKey: .expectedFormat)
        let contextData = context.compactMapValues { "\($0)" }
        try container.encode(contextData, forKey: .context)
    }

    private enum CodingKeys: String, CodingKey {
        case errorId, timestamp, userMessage, technicalDetails, recoverySuggestions
        case field, validationRule, providedValue, expectedFormat, context
    }
}

/// Network errors for connectivity and API failures
public struct NetworkError: AppErrorProtocol {
    public let errorId: String
    public let severity: ErrorSeverity
    public let category: ErrorCategory = .network
    public let timestamp: Date
    public let context: [String: Any]
    public let userMessage: String
    public let technicalDetails: String
    public let recoverySuggestions: [String]
    public let shouldReport: Bool = true
    public let isRecoverable: Bool = true

    // Network-specific properties
    public let statusCode: Int?
    public let endpoint: String?
    public let httpMethod: String?
    public let responseData: Data?

    public var errorDescription: String? { userMessage }
    public var failureReason: String? { technicalDetails }
    public var recoverySuggestion: String? { recoverySuggestions.first }
    public var helpAnchor: String? { "network_help" }
    public var description: String { "Network Error: \(userMessage)" }

    public init(
        statusCode: Int? = nil,
        endpoint: String? = nil,
        httpMethod: String? = nil,
        responseData: Data? = nil,
        userMessage: String? = nil,
        technicalDetails: String? = nil
    ) {
        errorId = UUID().uuidString
        timestamp = Date()
        self.statusCode = statusCode
        self.endpoint = endpoint
        self.httpMethod = httpMethod
        self.responseData = responseData

        // Determine severity based on status code
        severity = NetworkError.determineSeverity(statusCode: statusCode)

        // Generate user-friendly message
        self.userMessage = userMessage ?? NetworkError.generateUserMessage(statusCode: statusCode)

        // Generate technical details
        self.technicalDetails = technicalDetails ?? NetworkError.generateTechnicalDetails(
            statusCode: statusCode,
            endpoint: endpoint,
            httpMethod: httpMethod
        )

        // Generate recovery suggestions
        recoverySuggestions = NetworkError.generateRecoverySuggestions(statusCode: statusCode)

        // Build context
        var contextDict: [String: Any] = [:]
        if let code = statusCode {
            contextDict["status_code"] = code
        }
        if let url = endpoint {
            contextDict["endpoint"] = url
        }
        if let method = httpMethod {
            contextDict["http_method"] = method
        }
        if let data = responseData {
            contextDict["response_size"] = data.count
        }
        context = contextDict
    }

    private static func determineSeverity(statusCode: Int?) -> ErrorSeverity {
        guard let code = statusCode else { return .medium }

        switch code {
        case 400 ... 499: return .medium
        case 500 ... 599: return .high
        default: return .low
        }
    }

    private static func generateUserMessage(statusCode: Int?) -> String {
        guard let code = statusCode else {
            return "Network connection failed. Please check your internet connection."
        }

        switch code {
        case 400: return "Invalid request. Please check your input and try again."
        case 401: return "Authentication required. Please sign in and try again."
        case 403: return "Access denied. You don't have permission to perform this action."
        case 404: return "Resource not found. The requested item may have been moved or deleted."
        case 429: return "Too many requests. Please wait a moment and try again."
        case 500 ... 599: return "Server error. Please try again later."
        default: return "Network error occurred. Please check your connection and try again."
        }
    }

    private static func generateTechnicalDetails(statusCode: Int?, endpoint: String?, httpMethod: String?) -> String {
        var detailsParts = ["Network request failed"]

        if let method = httpMethod, let url = endpoint {
            detailsParts.append(" (\(method) \(url))")
        }

        if let code = statusCode {
            detailsParts.append(" with status code \(code)")
        }

        return detailsParts.joined()
    }

    private static func generateRecoverySuggestions(statusCode: Int?) -> [String] {
        guard let code = statusCode else {
            return [
                "Check your internet connection",
                "Try again in a few moments",
                "Contact support if the problem persists",
            ]
        }

        switch code {
        case 400: return ["Check your input data", "Verify required fields are filled", "Contact support if needed"]
        case 401: return ["Sign in to your account", "Check your credentials", "Reset password if necessary"]
        case 403: return ["Contact administrator for access", "Check your account permissions"]
        case 404: return ["Verify the resource exists", "Check the URL", "Try refreshing the page"]
        case 429: return ["Wait a few moments before trying again", "Reduce request frequency"]
        case 500 ... 599: return ["Try again later", "Check service status", "Contact support if problem persists"]
        default: return ["Check your internet connection", "Try again", "Contact support if needed"]
        }
    }

    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        errorId = try container.decode(String.self, forKey: .errorId)
        severity = try container.decode(ErrorSeverity.self, forKey: .severity)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        userMessage = try container.decode(String.self, forKey: .userMessage)
        technicalDetails = try container.decode(String.self, forKey: .technicalDetails)
        recoverySuggestions = try container.decode([String].self, forKey: .recoverySuggestions)
        statusCode = try? container.decode(Int.self, forKey: .statusCode)
        endpoint = try? container.decode(String.self, forKey: .endpoint)
        httpMethod = try? container.decode(String.self, forKey: .httpMethod)
        responseData = try? container.decode(Data.self, forKey: .responseData)
        context = try container.decode([String: String].self, forKey: .context)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(errorId, forKey: .errorId)
        try container.encode(severity, forKey: .severity)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(userMessage, forKey: .userMessage)
        try container.encode(technicalDetails, forKey: .technicalDetails)
        try container.encode(recoverySuggestions, forKey: .recoverySuggestions)
        try container.encodeIfPresent(statusCode, forKey: .statusCode)
        try container.encodeIfPresent(endpoint, forKey: .endpoint)
        try container.encodeIfPresent(httpMethod, forKey: .httpMethod)
        try container.encodeIfPresent(responseData, forKey: .responseData)
        let contextData = context.compactMapValues { "\($0)" }
        try container.encode(contextData, forKey: .context)
    }

    private enum CodingKeys: String, CodingKey {
        case errorId, severity, timestamp, userMessage, technicalDetails, recoverySuggestions
        case statusCode, endpoint, httpMethod, responseData, context
    }
}

/// Business logic errors for domain-specific failures
public struct BusinessError: AppErrorProtocol {
    public let errorId: String
    public let severity: ErrorSeverity = .medium
    public let category: ErrorCategory = .business
    public let timestamp: Date
    public let context: [String: Any]
    public let userMessage: String
    public let technicalDetails: String
    public let recoverySuggestions: [String]
    public let shouldReport: Bool = true
    public let isRecoverable: Bool = true

    // Business-specific properties
    public let businessRule: String
    public let violatedConstraint: String
    public let affectedEntity: String?

    public var errorDescription: String? { userMessage }
    public var failureReason: String? { technicalDetails }
    public var recoverySuggestion: String? { recoverySuggestions.first }
    public var helpAnchor: String? { "business_help_\(businessRule)" }
    public var description: String { "Business Error: \(userMessage)" }

    public init(
        businessRule: String,
        violatedConstraint: String,
        affectedEntity: String? = nil,
        userMessage: String,
        recoverySuggestions: [String] = []
    ) {
        errorId = UUID().uuidString
        timestamp = Date()
        self.businessRule = businessRule
        self.violatedConstraint = violatedConstraint
        self.affectedEntity = affectedEntity
        self.userMessage = userMessage
        technicalDetails = "Business rule '\(businessRule)' violated: \(violatedConstraint)"
        self.recoverySuggestions = recoverySuggestions

        var contextDict: [String: Any] = [
            "business_rule": businessRule,
            "violated_constraint": violatedConstraint,
        ]
        if let entity = affectedEntity {
            contextDict["affected_entity"] = entity
        }
        context = contextDict
    }

    // Codable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        errorId = try container.decode(String.self, forKey: .errorId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        userMessage = try container.decode(String.self, forKey: .userMessage)
        technicalDetails = try container.decode(String.self, forKey: .technicalDetails)
        recoverySuggestions = try container.decode([String].self, forKey: .recoverySuggestions)
        businessRule = try container.decode(String.self, forKey: .businessRule)
        violatedConstraint = try container.decode(String.self, forKey: .violatedConstraint)
        affectedEntity = try? container.decode(String.self, forKey: .affectedEntity)
        context = try container.decode([String: String].self, forKey: .context)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(errorId, forKey: .errorId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(userMessage, forKey: .userMessage)
        try container.encode(technicalDetails, forKey: .technicalDetails)
        try container.encode(recoverySuggestions, forKey: .recoverySuggestions)
        try container.encode(businessRule, forKey: .businessRule)
        try container.encode(violatedConstraint, forKey: .violatedConstraint)
        try container.encodeIfPresent(affectedEntity, forKey: .affectedEntity)
        let contextData = context.compactMapValues { "\($0)" }
        try container.encode(contextData, forKey: .context)
    }

    private enum CodingKeys: String, CodingKey {
        case errorId, timestamp, userMessage, technicalDetails, recoverySuggestions
        case businessRule, violatedConstraint, affectedEntity, context
    }
}

// MARK: - Error Handler Manager

/// Central error handling coordinator
@MainActor
public final class ErrorHandlerManager: ObservableObject {
    public static let shared = ErrorHandlerManager()

    // MARK: - Published Properties

    @Published public private(set) var recentErrors: [any AppErrorProtocol] = []
    @Published public private(set) var criticalErrors: [any AppErrorProtocol] = []
    @Published public private(set) var isProcessingRecovery = false
    @Published public private(set) var globalErrorState: GlobalErrorState = .normal

    // MARK: - Private Properties

    private var errorHistory: [any AppErrorProtocol] = []
    private var recoveryStrategies: [ErrorCategory: [RecoveryStrategy]] = [:]
    private var errorReporters: [ErrorReporter] = []
    private let logger = Logger(subsystem: "QuantumWorkspace", category: "ErrorHandling")
    private let maxRecentErrors = 50
    private let maxErrorHistory = 500

    @MockInjected private var analyticsService: AnalyticsServiceProtocol

    private init() {
        _analyticsService = MockInjected(wrappedValue: MockAnalyticsService())
        setupDefaultRecoveryStrategies()
        setupDefaultErrorReporters()
    }

    // MARK: - Public Error Handling Interface

    /// Handle an error with full error processing pipeline
    public func handleError(_ error: any AppErrorProtocol) async {
        logger.error("Error occurred: \(error.description)")

        // Add to error tracking
        addToErrorHistory(error)

        // Report error if needed
        if error.shouldReport {
            await reportError(error)
        }

        // Update global error state
        updateGlobalErrorState(with: error)

        // Attempt automatic recovery if possible
        if error.isRecoverable {
            _ = await attemptRecovery(for: error)
        }

        // Track error analytics
        await analyticsService.track(
            event: "error_handled",
            properties: [
                "error_id": error.errorId,
                "category": error.category.rawValue,
                "severity": error.severity.rawValue,
                "recoverable": error.isRecoverable,
            ],
            userId: nil as String?
        )
    }

    /// Handle standard Swift Error by converting to AppError
    public func handleStandardError(
        _ error: Error,
        category: ErrorCategory = .unknown,
        severity: ErrorSeverity = .medium,
        userMessage: String? = nil,
        context: [String: Any] = [:]
    ) async {
        let appError = AppError(
            severity: severity,
            category: category,
            userMessage: userMessage ?? error.localizedDescription,
            technicalDetails: "\(error)",
            context: context,
            recoverySuggestions: ["Try again", "Check your input", "Contact support if the problem persists"],
            shouldReport: severity.priority > ErrorSeverity.low.priority,
            isRecoverable: false
        )

        await handleError(appError)
    }

    /// Handle validation errors from form inputs
    public func handleValidationError(
        field: String,
        value: Any?,
        rule: String,
        userMessage: String? = nil
    ) async {
        let validationError = ValidationError(
            field: field,
            validationRule: rule,
            providedValue: value,
            userMessage: userMessage
        )

        await handleError(validationError)
    }

    /// Handle network errors from API calls
    public func handleNetworkError(
        statusCode: Int? = nil,
        endpoint: String? = nil,
        method: String? = nil,
        data: Data? = nil
    ) async {
        let networkError = NetworkError(
            statusCode: statusCode,
            endpoint: endpoint,
            httpMethod: method,
            responseData: data
        )

        await handleError(networkError)
    }

    /// Handle business logic errors
    public func handleBusinessError(
        rule: String,
        constraint: String,
        entity: String? = nil,
        message: String,
        suggestions: [String] = []
    ) async {
        let businessError = BusinessError(
            businessRule: rule,
            violatedConstraint: constraint,
            affectedEntity: entity,
            userMessage: message,
            recoverySuggestions: suggestions
        )

        await handleError(businessError)
    }

    /// Get recent errors for display in UI
    public func getRecentErrors(severity: ErrorSeverity? = nil, category: ErrorCategory? = nil) -> [any AppErrorProtocol] {
        var filteredErrors = recentErrors

        if let severity {
            filteredErrors = filteredErrors.filter { $0.severity == severity }
        }

        if let category {
            filteredErrors = filteredErrors.filter { $0.category == category }
        }

        return filteredErrors
    }

    /// Clear error history
    public func clearErrorHistory() {
        recentErrors.removeAll()
        criticalErrors.removeAll()
        errorHistory.removeAll()
        globalErrorState = .normal
    }

    /// Export error report for support
    public func exportErrorReport() -> ErrorReport {
        ErrorReport(
            generatedAt: Date(),
            recentErrors: recentErrors.compactMap { $0 as? AppError },
            criticalErrors: criticalErrors.compactMap { $0 as? AppError },
            globalState: globalErrorState,
            systemInfo: collectSystemInfo()
        )
    }

    // MARK: - Recovery Management

    /// Register a custom recovery strategy
    public func registerRecoveryStrategy(_ strategy: RecoveryStrategy, for category: ErrorCategory) {
        if recoveryStrategies[category] == nil {
            recoveryStrategies[category] = []
        }
        recoveryStrategies[category]?.append(strategy)
    }

    /// Attempt manual recovery for a specific error
    public func attemptManualRecovery(for error: any AppErrorProtocol) async -> RecoveryResult {
        await attemptRecovery(for: error)
    }

    // MARK: - Error Reporting

    /// Register a custom error reporter
    public func registerErrorReporter(_ reporter: ErrorReporter) {
        errorReporters.append(reporter)
    }

    // MARK: - Private Methods

    private func addToErrorHistory(_ error: any AppErrorProtocol) {
        // Add to recent errors
        recentErrors.insert(error, at: 0)
        if recentErrors.count > maxRecentErrors {
            recentErrors.removeLast()
        }

        // Add to critical errors if severity is high
        if error.severity.priority >= ErrorSeverity.high.priority {
            criticalErrors.insert(error, at: 0)
            if criticalErrors.count > 10 {
                criticalErrors.removeLast()
            }
        }

        // Add to full error history
        errorHistory.insert(error, at: 0)
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeLast()
        }
    }

    private func updateGlobalErrorState(with error: any AppErrorProtocol) {
        switch error.severity {
        case .critical:
            globalErrorState = .critical
        case .high:
            if globalErrorState != .critical {
                globalErrorState = .degraded
            }
        case .medium, .low:
            if globalErrorState == .normal {
                // Check if we have multiple recent errors
                let recentHighSeverityErrors = recentErrors.prefix(5).filter { $0.severity.priority >= ErrorSeverity.medium.priority }
                if recentHighSeverityErrors.count >= 3 {
                    globalErrorState = .degraded
                }
            }
        }
    }

    private func attemptRecovery(for error: any AppErrorProtocol) async -> RecoveryResult {
        isProcessingRecovery = true
        defer { isProcessingRecovery = false }

        logger.info("Attempting recovery for error: \(error.errorId)")

        guard let strategies = recoveryStrategies[error.category] else {
            return RecoveryResult(success: false, message: "No recovery strategies available")
        }

        for strategy in strategies {
            do {
                if try await strategy.canRecover(error) {
                    let result = try await strategy.attemptRecovery(error)

                    if result.success {
                        logger.info("Recovery successful for error: \(error.errorId)")

                        await analyticsService.track(
                            event: "error_recovery_success",
                            properties: [
                                "error_id": error.errorId,
                                "strategy": strategy.name,
                                "category": error.category.rawValue,
                            ],
                            userId: nil
                        )

                        return result
                    }
                }
            } catch {
                logger.error("Recovery strategy failed: \(error)")
                continue
            }
        }

        logger.warning("All recovery strategies failed for error: \(error.errorId)")

        await analyticsService.track(
            event: "error_recovery_failed",
            properties: [
                "error_id": error.errorId,
                "category": error.category.rawValue,
                "strategies_attempted": strategies.count,
            ],
            userId: nil
        )

        return RecoveryResult(success: false, message: "All recovery attempts failed")
    }

    private func reportError(_ error: any AppErrorProtocol) async {
        for reporter in errorReporters {
            do {
                try await reporter.reportError(error)
            } catch {
                logger.error("Error reporter failed: \(error)")
            }
        }
    }

    private func setupDefaultRecoveryStrategies() {
        // Network recovery strategies
        registerRecoveryStrategy(NetworkRetryStrategy(), for: .network)
        registerRecoveryStrategy(NetworkFallbackStrategy(), for: .network)

        // Data recovery strategies
        registerRecoveryStrategy(DataRefreshStrategy(), for: .data)
        registerRecoveryStrategy(DataCacheStrategy(), for: .data)

        // Validation recovery strategies
        registerRecoveryStrategy(ValidationRetryStrategy(), for: .validation)

        // System recovery strategies
        registerRecoveryStrategy(SystemRestartStrategy(), for: .system)
    }

    private func setupDefaultErrorReporters() {
        errorReporters.append(ConsoleErrorReporter())
        errorReporters.append(AnalyticsErrorReporter(analyticsService: analyticsService))

        #if DEBUG
            errorReporters.append(DebugErrorReporter())
        #else
            errorReporters.append(CrashReporter())
        #endif
    }

    private func collectSystemInfo() -> SystemInfo {
        SystemInfo(
            platform: "iOS", // Would be determined at runtime
            version: "1.0.0",
            device: "iPhone", // Would be determined at runtime
            memory: ProcessInfo.processInfo.physicalMemory,
            diskSpace: 0, // Would be calculated
            networkStatus: "Connected", // Would be determined
            timestamp: Date()
        )
    }
}

// MARK: - Recovery System

/// Protocol for error recovery strategies
public protocol RecoveryStrategy {
    var name: String { get }
    func canRecover(_ error: any AppErrorProtocol) async throws -> Bool
    func attemptRecovery(_ error: any AppErrorProtocol) async throws -> RecoveryResult
}

/// Result of a recovery attempt
public struct RecoveryResult {
    public let success: Bool
    public let message: String
    public let recoveredData: Any?

    public init(success: Bool, message: String, recoveredData: Any? = nil) {
        self.success = success
        self.message = message
        self.recoveredData = recoveredData
    }
}

/// Global error state enumeration
public enum GlobalErrorState: String, Codable {
    case normal
    case degraded
    case critical

    public var displayName: String {
        switch self {
        case .normal: "Normal"
        case .degraded: "Degraded"
        case .critical: "Critical"
        }
    }
}

// MARK: - Error Reporting System

/// Protocol for error reporters
public protocol ErrorReporter {
    func reportError(_ error: any AppErrorProtocol) async throws
}

/// Console error reporter for development
public struct ConsoleErrorReporter: ErrorReporter {
    public func reportError(_ error: any AppErrorProtocol) async throws {
        print("🚨 ERROR REPORTED 🚨")
        print("ID: \(error.errorId)")
        print("Category: \(error.category.displayName)")
        print("Severity: \(error.severity.displayName)")
        print("Message: \(error.userMessage)")
        print("Technical: \(error.technicalDetails)")
        print("Context: \(error.context)")
        print("Timestamp: \(error.timestamp)")
        print("---")
    }
}

/// Analytics error reporter
public struct AnalyticsErrorReporter: ErrorReporter {
    private let analyticsService: AnalyticsServiceProtocol

    public init(analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }

    public func reportError(_ error: any AppErrorProtocol) async throws {
        await analyticsService.track(
            event: "error_occurred",
            properties: [
                "error_id": error.errorId,
                "category": error.category.rawValue,
                "severity": error.severity.rawValue,
                "user_message": error.userMessage,
                "technical_details": error.technicalDetails,
                "timestamp": error.timestamp.timeIntervalSince1970,
                "context": error.context,
            ],
            userId: nil
        )
    }
}

/// Debug error reporter with detailed logging
public struct DebugErrorReporter: ErrorReporter {
    private let logger = Logger(subsystem: "QuantumWorkspace", category: "ErrorReporting")

    public func reportError(_ error: any AppErrorProtocol) async throws {
        logger
            .fault(
                "ERROR: [\(error.category.displayName)] \(error.userMessage) | Technical: \(error.technicalDetails) | Context: \(error.context)"
            )
    }
}

/// Crash reporter for production builds
public struct CrashReporter: ErrorReporter {
    public func reportError(_ error: any AppErrorProtocol) async throws {
        // In a real implementation, this would send errors to crash reporting service
        // like Crashlytics, Bugsnag, or Sentry
        print("Would report to crash service: \(error.errorId)")
    }
}

// MARK: - Recovery Strategies

/// Network retry strategy
public struct NetworkRetryStrategy: RecoveryStrategy {
    public let name = "NetworkRetry"
    private let maxRetries = 3

    public func canRecover(_ error: any AppErrorProtocol) async throws -> Bool {
        guard let networkError = error as? NetworkError else { return false }

        // Can retry for temporary failures
        if let statusCode = networkError.statusCode {
            return statusCode >= 500 || statusCode == 429 || statusCode == 408
        }

        return true // Can retry connection failures
    }

    public func attemptRecovery(_ error: any AppErrorProtocol) async throws -> RecoveryResult {
        guard let networkError = error as? NetworkError else {
            return RecoveryResult(success: false, message: "Not a network error")
        }

        // Simulate retry logic
        for attempt in 1 ... maxRetries {
            try await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000)) // Wait 1, 2, 3 seconds

            // In real implementation, would retry the network request
            let simulatedSuccess = attempt == 2 // Succeed on second attempt

            if simulatedSuccess {
                return RecoveryResult(
                    success: true,
                    message: "Network request succeeded after \(attempt) attempts"
                )
            }
        }

        return RecoveryResult(success: false, message: "Network retry failed after \(maxRetries) attempts")
    }
}

/// Network fallback strategy
public struct NetworkFallbackStrategy: RecoveryStrategy {
    public let name = "NetworkFallback"

    public func canRecover(_ error: any AppErrorProtocol) async throws -> Bool {
        error is NetworkError
    }

    public func attemptRecovery(_: any AppErrorProtocol) async throws -> RecoveryResult {
        // In real implementation, would switch to fallback endpoint or cached data
        RecoveryResult(
            success: true,
            message: "Using cached data as fallback"
        )
    }
}

/// Data refresh strategy
public struct DataRefreshStrategy: RecoveryStrategy {
    public let name = "DataRefresh"

    public func canRecover(_ error: any AppErrorProtocol) async throws -> Bool {
        error.category == .data
    }

    public func attemptRecovery(_: any AppErrorProtocol) async throws -> RecoveryResult {
        // In real implementation, would refresh data from source
        RecoveryResult(
            success: true,
            message: "Data refreshed successfully"
        )
    }
}

/// Data cache strategy
public struct DataCacheStrategy: RecoveryStrategy {
    public let name = "DataCache"

    public func canRecover(_ error: any AppErrorProtocol) async throws -> Bool {
        error.category == .data
    }

    public func attemptRecovery(_: any AppErrorProtocol) async throws -> RecoveryResult {
        // In real implementation, would use cached data
        RecoveryResult(
            success: true,
            message: "Using cached data"
        )
    }
}

/// Validation retry strategy
public struct ValidationRetryStrategy: RecoveryStrategy {
    public let name = "ValidationRetry"

    public func canRecover(_ error: any AppErrorProtocol) async throws -> Bool {
        error is ValidationError
    }

    public func attemptRecovery(_: any AppErrorProtocol) async throws -> RecoveryResult {
        // Validation errors typically require user input, so automatic recovery is limited
        RecoveryResult(
            success: false,
            message: "Validation error requires user correction"
        )
    }
}

/// System restart strategy
public struct SystemRestartStrategy: RecoveryStrategy {
    public let name = "SystemRestart"

    public func canRecover(_ error: any AppErrorProtocol) async throws -> Bool {
        error.category == .system && error.severity == .critical
    }

    public func attemptRecovery(_: any AppErrorProtocol) async throws -> RecoveryResult {
        // In real implementation, would restart affected system components
        RecoveryResult(
            success: true,
            message: "System components restarted"
        )
    }
}

// MARK: - Supporting Types

/// Error report structure for export
public struct ErrorReport: Codable {
    public let generatedAt: Date
    public let recentErrors: [AppError] // Simplified for Codable
    public let criticalErrors: [AppError] // Simplified for Codable
    public let globalState: GlobalErrorState
    public let systemInfo: SystemInfo
}

/// System information for error context
public struct SystemInfo: Codable {
    public let platform: String
    public let version: String
    public let device: String
    public let memory: UInt64
    public let diskSpace: UInt64
    public let networkStatus: String
    public let timestamp: Date
}
