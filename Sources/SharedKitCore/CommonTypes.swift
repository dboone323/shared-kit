//
//  CommonTypes.swift
//  SharedKit
//
//  Created on February 14, 2026
//  Common type definitions to resolve naming conflicts across the codebase
//

import Foundation

// MARK: - Validation Types

/// Comprehensive validation result that covers all use cases across frameworks
public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let score: Double?
    public let confidence: Double?
    public let warnings: [ValidationWarning]
    public let errors: [ValidationIssue]
    public let issues: [ValidationIssue]
    public let recommendations: [String]

    public init(
        isValid: Bool,
        score: Double? = nil,
        confidence: Double? = nil,
        warnings: [ValidationWarning] = [],
        errors: [ValidationIssue] = [],
        issues: [ValidationIssue] = [],
        recommendations: [String] = []
    ) {
        self.isValid = isValid
        self.score = score
        self.confidence = confidence
        self.warnings = warnings
        self.errors = errors
        self.issues = issues
        self.recommendations = recommendations
    }

    // Convenience initializers for backward compatibility
    public static func success(
        score: Double? = nil,
        confidence: Double? = nil,
        warnings: [ValidationWarning] = [],
        recommendations: [String] = []
    ) -> ValidationResult {
        ValidationResult(
            isValid: true,
            score: score,
            confidence: confidence,
            warnings: warnings,
            errors: [],
            issues: [],
            recommendations: recommendations
        )
    }

    public static func failure(
        errors: [ValidationIssue] = [],
        issues: [ValidationIssue] = [],
        warnings: [ValidationWarning] = [],
        recommendations: [String] = []
    ) -> ValidationResult {
        ValidationResult(
            isValid: false,
            warnings: warnings,
            errors: errors,
            issues: issues,
            recommendations: recommendations
        )
    }
}

/// Validation warning with severity information
public struct ValidationWarning: Sendable {
    public let message: String
    public let severity: ValidationSeverity
    public let suggestion: String

    public init(message: String, severity: ValidationSeverity, suggestion: String) {
        self.message = message
        self.severity = severity
        self.suggestion = suggestion
    }
}

/// Validation error with detailed information
public struct ValidationIssue: Sendable {
    public let parameter: String?
    public let issue: String
    public let severity: ValidationSeverity?
    public let suggestion: String?

    public init(
        parameter: String? = nil,
        issue: String,
        severity: ValidationSeverity? = nil,
        suggestion: String? = nil
    ) {
        self.parameter = parameter
        self.issue = issue
        self.severity = severity
        self.suggestion = suggestion
    }
}

/// Validation severity levels
public enum ValidationSeverity: String, Sendable {
    case info
    case warning
    case error
    case critical
}

// MARK: - Reality Parameter Types

/// Standard reality parameters for operations
public struct RealityParameters: Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let intensity: Double
    public let scope: String
    public let constraints: [String: AnyCodable]?

    public init(id: UUID = UUID(), timestamp: Date = Date(), intensity: Double, scope: String, constraints: [String: AnyCodable]? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.intensity = intensity
        self.scope = scope
        self.constraints = constraints
    }
}

// MARK: - Priority and Severity Types

/// Standard priority levels
public enum PriorityLevel: String, Codable, Sendable, CaseIterable {
    case low, medium, high, critical
}

/// Standard severity levels
public enum SeverityLevel: String, Codable, Sendable, CaseIterable {
    case low, medium, high, critical
}

// MARK: - Goal Types

/// Standard goal types
public enum GoalType: String, Codable, Sendable {
    case performance, stability, security, innovation, efficiency
}

/// Standard goal priorities
public enum GoalPriority: String, Codable, Sendable, CaseIterable {
    case low, medium, high, critical
}

// MARK: - Optimization Types

/// Standard optimization goals
public struct OptimizationGoal: Codable, Sendable {
    public let type: GoalType
    public let targetValue: Double
    public let priority: GoalPriority
    public let measurement: String

    public init(type: GoalType, targetValue: Double, priority: GoalPriority = .medium, measurement: String) {
        self.type = type
        self.targetValue = targetValue
        self.priority = priority
        self.measurement = measurement
    }
}

// MARK: - Risk and Tolerance Types

/// Standard risk tolerance levels
public enum RiskTolerance: String, Codable, Sendable {
    case conservative, moderate, aggressive, extreme
}

// MARK: - Consciousness Types

/// Standard consciousness alignment levels
public enum ConsciousnessAlignment: String, Codable, Sendable {
    case minimal, standard, enhanced, transcendent, universal
}

// MARK: - Status Types

/// Standard operational status
public enum OperationalStatus: String, Codable, Sendable {
    case operational, degraded, offline, maintenance
}

/// Standard health status
public enum HealthStatus: String, Codable, Sendable {
    case healthy, warning, critical, unknown
}

// MARK: - Configuration Types

/// Standard configuration parameters
public struct ConfigurationParameters: Codable, Sendable {
    public let id: String
    public let parameters: [String: AnyCodable]
    public let version: String
    public let updatedAt: Date

    public init(id: String, parameters: [String: AnyCodable], version: String = "1.0", updatedAt: Date = Date()) {
        self.id = id
        self.parameters = parameters
        self.version = version
        self.updatedAt = updatedAt
    }
}

// MARK: - Metrics Types

/// Standard performance metrics
public struct PerformanceMetrics: Codable, Sendable {
    public let totalOperations: Int
    public let successRate: Double
    public let averageResponseTime: TimeInterval
    public let errorRate: Double
    public let lastUpdated: Date

    public init(totalOperations: Int = 0, successRate: Double = 0.0, averageResponseTime: TimeInterval = 0.0, errorRate: Double = 0.0, lastUpdated: Date = Date()) {
        self.totalOperations = totalOperations
        self.successRate = successRate
        self.averageResponseTime = averageResponseTime
        self.errorRate = errorRate
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Error Types

/// Comprehensive validation error types covering all use cases
public enum ValidationError: Error, LocalizedError {
    // Basic validation errors
    case emptyInput
    case invalidLength(min: Int, max: Int)
    case inputTooLong(maxLength: Int)
    case belowMinimumLength(min: Int)
    case exceedsMaximumLength(max: Int)

    // Content validation errors
    case invalidFormat(description: String)
    case invalidCharacters
    case containsInvalidCharacters(characters: String)
    case maliciousContent
    case unsafeContent

    // Specific type validation errors
    case invalidEmail
    case invalidURL
    case invalidURLScheme
    case internalURLNotAllowed
    case invalidPhoneNumber
    case invalidNumericValue
    case invalidDate

    // Security validation errors
    case containsSQLInjection
    case containsXSS
    case containsPathTraversal

    // Value range errors
    case valueTooLow(minimum: String)
    case valueTooHigh(maximum: String)

    // Model validation errors
    case required(field: String)
    case invalid(field: String, reason: String)
    case outOfRange(field: String, min: String?, max: String?)

    // Custom errors
    case custom(message: String)
    case tooLong

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input cannot be empty"
        case let .invalidLength(min, max):
            return "Input length must be between \(min) and \(max) characters"
        case let .inputTooLong(maxLength):
            return "Input exceeds maximum length of \(maxLength) characters"
        case let .belowMinimumLength(min):
            return "Input is below minimum length of \(min) characters"
        case let .exceedsMaximumLength(max):
            return "Input exceeds maximum length of \(max) characters"
        case let .invalidFormat(description):
            return description
        case .invalidCharacters:
            return "Input contains invalid characters"
        case let .containsInvalidCharacters(characters):
            return "Input contains invalid characters: \(characters)"
        case .maliciousContent:
            return "Input contains potentially malicious content"
        case .unsafeContent:
            return "Input contains unsafe content"
        case .invalidEmail:
            return "Invalid email format"
        case .invalidURL:
            return "Invalid URL format"
        case .invalidURLScheme:
            return "URL scheme not allowed"
        case .internalURLNotAllowed:
            return "Internal URLs are not allowed in production"
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .invalidNumericValue:
            return "Invalid numeric value"
        case .invalidDate:
            return "Invalid date format"
        case .containsSQLInjection:
            return "Input contains potential SQL injection"
        case .containsXSS:
            return "Input contains potential cross-site scripting"
        case .containsPathTraversal:
            return "Input contains potential path traversal"
        case let .valueTooLow(minimum):
            return "Value is below minimum allowed value of \(minimum)"
        case let .valueTooHigh(maximum):
            return "Value is above maximum allowed value of \(maximum)"
        case let .required(field):
            return "\(field) is required"
        case let .invalid(field, reason):
            return "\(field) is invalid: \(reason)"
        case let .outOfRange(field, min, max):
            return "\(field) is out of range (\(min ?? "nil") - \(max ?? "nil"))"
        case let .custom(message):
            return message
        case .tooLong:
            return "Input is too long"
        }
    }
}

/// Standard error types
public enum StandardError: Error {
    case invalidInput(String)
    case operationFailed(String)
    case configurationError(String)
    case networkError(String)
    case timeout(String)
    case unknown(String)
}
