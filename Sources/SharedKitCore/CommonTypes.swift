//
//  CommonTypes.swift
//  SharedKit
//
//  Created on February 14, 2026
//  Common type definitions to resolve naming conflicts across the codebase
//

import Foundation

// MARK: - Core Dynamic Value Types

public enum ProjectType: String, Codable, CaseIterable, Sendable {
    case avoidObstacles = "avoid-obstacles-game"
    case momentumFinance = "momentum-finance"
    case habitQuest = "habit-quest"
    case plannerApp = "planner-app"
    case sharedKit = "shared-kit"
    case toolsAutomation = "tools-automation"
    case codingReviewer = "coding-reviewer"

    public var displayName: String {
        return self.rawValue.components(separatedBy: "-").map { $0.capitalized }.joined(
            separator: " ")
    }
}

public struct ExternalReference: Codable, Identifiable, Sendable {
    public let id: UUID
    public let projectContext: ProjectType  // Changed from ProjectContext enum to ProjectType
    public let modelType: String
    public let modelId: String
    public let relationshipType: String
    public let createdAt: Date

    // The ProjectContext enum is removed as projectContext now directly uses ProjectType
    // public enum ProjectContext: String, CaseIterable, Codable, Sendable {
    //     case habitQuest
    //     case momentumFinance
    //     case plannerApp
    //     case codingReviewer
    //     case avoidObstaclesGame
    // }

    public init(
        projectContext: ProjectType, modelType: String, modelId: String, relationshipType: String
    ) {
        self.id = UUID()
        self.projectContext = projectContext
        self.modelType = modelType
        self.modelId = modelId
        self.relationshipType = relationshipType
        self.createdAt = Date()
    }
}

public enum AccountType: String, Codable, CaseIterable, Sendable {
    case checking, savings, credit, investment, cash, loan, retirement, other

    public var displayName: String {
        switch self {
        case .checking: "Checking"
        case .savings: "Savings"
        case .credit: "Credit Card"
        case .investment: "Investment"
        case .cash: "Cash"
        case .loan: "Loan"
        case .retirement: "Retirement"
        case .other: "Other"
        }
    }
}

public enum EnergyLevel: String, CaseIterable, Codable, Sendable {
    case low, medium, high
}

public enum TransactionType: String, CaseIterable, Codable, Sendable {
    case deposit
    case withdrawal
    case transfer
    case payment
    case investment
    case income
    case expense
    case trade
    case donation
    case loan
    case grant

    public var displayName: String {
        self.rawValue.capitalized
    }
}

public typealias StateValue = SharedStateValue

public enum SharedStateValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case uuid(UUID)
    case date(Date)
    case accountType(AccountType)
    case energyLevel(EnergyLevel)

    public var stringValue: String? {
        if case .string(let value) = self { return value }
        if case .uuid(let value) = self { return value.uuidString }
        if case .accountType(let value) = self { return value.rawValue }
        if case .energyLevel(let value) = self { return value.rawValue }
        return nil
    }

    public var doubleValue: Double? {
        if case .double(let value) = self { return value }
        if case .int(let value) = self { return Double(value) }
        return nil
    }

    public var anyValue: Any {
        switch self {
        case .string(let v): v
        case .int(let v): v
        case .double(let v): v
        case .bool(let v): v
        case .uuid(let v): v.uuidString
        case .date(let v): v
        case .accountType(let v): v.rawValue
        case .energyLevel(let v): v.rawValue
        }
    }
}

public struct AnyEncodable: Encodable, @unchecked Sendable {
    private let encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ wrapped: T) {
        self.encode = { try wrapped.encode(to: $0) }
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

public enum StateChangeType: String, Sendable {
    case create, update, delete, sync, reset

    public var description: String {
        self.rawValue.capitalized
    }
}

// MARK: - Time Periods

public enum DatePeriod: String, CaseIterable, Codable, Sendable {
    case thisWeek, lastWeek, thisMonth, lastMonth, thisQuarter, thisYear, allTime

    public var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start, now)
        case .lastWeek:
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let start = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? now
            let end = thisWeekStart
            return (start, end)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (start, now)
        case .lastMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
            let end = thisMonthStart
            return (start, end)
        case .thisQuarter:
            // Simplified
            let start = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return (start, now)
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (start, now)
        case .allTime:
            return (Date.distantPast, Date.distantFuture)
        }
    }
}

// MARK: - Legacy Compatibility

@propertyWrapper
public struct MockInjected<T: Sendable>: Sendable {
    public var wrappedValue: T

    public init() {
        // This is a mock implementation - in production, this would resolve from DependencyContainer
        fatalError("Mock injection not implemented for type \(T.self)")
    }

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

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

    public init(
        id: UUID = UUID(), timestamp: Date = Date(), intensity: Double, scope: String,
        constraints: [String: AnyCodable]? = nil
    ) {
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

    public init(
        type: GoalType, targetValue: Double, priority: GoalPriority = .medium, measurement: String
    ) {
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

    public init(
        id: String, parameters: [String: AnyCodable], version: String = "1.0",
        updatedAt: Date = Date()
    ) {
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

    public init(
        totalOperations: Int = 0, successRate: Double = 0.0,
        averageResponseTime: TimeInterval = 0.0, errorRate: Double = 0.0, lastUpdated: Date = Date()
    ) {
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
    case outOfRange(field: String, min: Int?, max: Int?)
    case invalidData(String)

    // Custom errors
    case custom(message: String)
    case tooLong

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input cannot be empty"
        case .invalidLength(let min, let max):
            return "Input length must be between \(min) and \(max) characters"
        case .inputTooLong(let maxLength):
            return "Input exceeds maximum length of \(maxLength) characters"
        case .belowMinimumLength(let min):
            return "Input is below minimum length of \(min) characters"
        case .exceedsMaximumLength(let max):
            return "Input exceeds maximum length of \(max) characters"
        case .invalidFormat(let description):
            return description
        case .invalidCharacters:
            return "Input contains invalid characters"
        case .containsInvalidCharacters(let characters):
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
        case .valueTooLow(let minimum):
            return "Value is below minimum allowed value of \(minimum)"
        case .valueTooHigh(let maximum):
            return "Value is above maximum allowed value of \(maximum)"
        case .required(let field):
            return "\(field) is required"
        case .invalid(let field, let reason):
            return "\(field) is invalid: \(reason)"
        case .outOfRange(let field, let min, let max):
            let minStr = min.map { String($0) } ?? "nil"
            let maxStr = max.map { String($0) } ?? "nil"
            return "\(field) is out of range (\(minStr) - \(maxStr))"
        case .custom(let message):
            return message
        case .tooLong:
            return "Input is too long"
        case .invalidData(let message):
            return "Invalid data: \(message)"
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
