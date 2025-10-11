//
//  AIServiceProtocols.swift
//  SharedKit
//
//  Created by AI Enhancement System on 10/11/2025
//  Shared AI service protocols for consistent integration across all Quantum-workspace projects

import Foundation

// MARK: - Core AI Service Protocols

/// Protocol for AI text generation services
public protocol AITextGenerationService {
    /// Generate text using AI
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Creativity parameter (0.0-1.0)
    /// - Returns: Generated text
    func generateText(prompt: String, maxTokens: Int, temperature: Double) async throws -> String

    /// Check if the service is available
    func isAvailable() async -> Bool

    /// Get service health status
    func getHealthStatus() async -> ServiceHealth
}

/// Protocol for AI code analysis services
public protocol AICodeAnalysisService {
    /// Analyze code for quality and issues
    /// - Parameters:
    ///   - code: The code to analyze
    ///   - language: Programming language
    ///   - analysisType: Type of analysis to perform
    /// - Returns: Analysis results
    func analyzeCode(code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult

    /// Generate documentation for code
    /// - Parameters:
    ///   - code: The code to document
    ///   - language: Programming language
    /// - Returns: Generated documentation
    func generateDocumentation(code: String, language: String) async throws -> String

    /// Generate unit tests for code
    /// - Parameters:
    ///   - code: The code to test
    ///   - language: Programming language
    /// - Returns: Generated test code
    func generateTests(code: String, language: String) async throws -> String
}

/// Protocol for AI code generation services
public protocol AICodeGenerationService {
    /// Generate code from description
    /// - Parameters:
    ///   - description: Description of the code to generate
    ///   - language: Programming language
    ///   - context: Additional context
    /// - Returns: Generated code
    func generateCode(description: String, language: String, context: String?) async throws -> CodeGenerationResult

    /// Generate code with fallback support
    /// - Parameters:
    ///   - description: Description of the code to generate
    ///   - language: Programming language
    ///   - context: Additional context
    /// - Returns: Generated code with fallback handling
    func generateCodeWithFallback(description: String, language: String, context: String?) async throws -> CodeGenerationResult
}

/// Protocol for AI caching services
public protocol AICachingService {
    /// Cache AI response
    /// - Parameters:
    ///   - key: Cache key
    ///   - response: Response to cache
    ///   - metadata: Additional metadata
    func cacheResponse(key: String, response: String, metadata: [String: Any]?) async

    /// Retrieve cached response
    /// - Parameter key: Cache key
    /// - Returns: Cached response if available
    func getCachedResponse(key: String) async -> String?

    /// Clear cache
    func clearCache() async

    /// Get cache statistics
    func getCacheStats() async -> CacheStats
}

/// Protocol for AI performance monitoring
public protocol AIPerformanceMonitoring {
    /// Record AI operation performance
    /// - Parameters:
    ///   - operation: Operation name
    ///   - duration: Operation duration
    ///   - success: Whether operation succeeded
    ///   - metadata: Additional metadata
    func recordOperation(operation: String, duration: TimeInterval, success: Bool, metadata: [String: Any]?) async

    /// Get performance metrics
    func getPerformanceMetrics() async -> PerformanceMetrics

    /// Reset performance metrics
    func resetMetrics() async
}

/// Protocol for AI service coordination
public protocol AIServiceCoordinator {
    /// Get available AI services
    func getAvailableServices() async -> [AIServiceInfo]

    /// Execute AI operation with automatic service selection
    /// - Parameters:
    ///   - operation: The operation to perform
    ///   - context: Operation context
    /// - Returns: Operation result
    func executeOperation(operation: AIOperation, context: [String: Any]) async throws -> AIOperationResult

    /// Get service health overview
    func getServiceHealthOverview() async -> ServiceHealthOverview
}

/// Protocol for AI configuration management
public protocol AIConfigurationService {
    /// Get configuration for service
    /// - Parameter serviceId: Service identifier
    /// - Returns: Service configuration
    func getConfiguration(for serviceId: String) async -> AIServiceConfiguration?

    /// Update service configuration
    /// - Parameters:
    ///   - serviceId: Service identifier
    ///   - configuration: New configuration
    func updateConfiguration(for serviceId: String, configuration: AIServiceConfiguration) async

    /// Reset configuration to defaults
    /// - Parameter serviceId: Service identifier
    func resetConfiguration(for serviceId: String) async
}

// MARK: - Data Models

/// Service health information
public struct ServiceHealth: Codable, Sendable {
    public let serviceName: String
    public let isRunning: Bool
    public let modelsAvailable: Bool
    public let responseTime: TimeInterval?
    public let errorRate: Double
    public let lastChecked: Date
    public let recommendations: [String]

    public init(
        serviceName: String = "",
        isRunning: Bool = false,
        modelsAvailable: Bool = false,
        responseTime: TimeInterval? = nil,
        errorRate: Double = 0.0,
        lastChecked: Date = Date(),
        recommendations: [String] = []
    ) {
        self.serviceName = serviceName
        self.isRunning = isRunning
        self.modelsAvailable = modelsAvailable
        self.responseTime = responseTime
        self.errorRate = errorRate
        self.lastChecked = lastChecked
        self.recommendations = recommendations
    }
}

/// Code analysis result
public struct CodeAnalysisResult: Codable, Sendable {
    public let analysis: String
    public let issues: [CodeIssue]
    public let suggestions: [String]
    public let language: String
    public let analysisType: AnalysisType
    public let timestamp: Date

    public init(
        analysis: String,
        issues: [CodeIssue] = [],
        suggestions: [String] = [],
        language: String,
        analysisType: AnalysisType,
        timestamp: Date = Date()
    ) {
        self.analysis = analysis
        self.issues = issues
        self.suggestions = suggestions
        self.language = language
        self.analysisType = analysisType
        self.timestamp = timestamp
    }
}

/// Code issue information
public struct CodeIssue: Codable, Sendable {
    public let description: String
    public let severity: IssueSeverity
    public let lineNumber: Int?
    public let category: String

    public init(
        description: String,
        severity: IssueSeverity = .medium,
        lineNumber: Int? = nil,
        category: String = "general"
    ) {
        self.description = description
        self.severity = severity
        self.lineNumber = lineNumber
        self.category = category
    }
}

/// Issue severity levels
public enum IssueSeverity: String, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Analysis types
public enum AnalysisType: String, Codable, Sendable {
    case bugs
    case performance
    case security
    case comprehensive
}

/// Code generation result
public struct CodeGenerationResult: Codable, Sendable {
    public let code: String
    public let analysis: String
    public let language: String
    public let complexity: CodeComplexity
    public let timestamp: Date

    public init(
        code: String,
        analysis: String = "",
        language: String,
        complexity: CodeComplexity = .standard,
        timestamp: Date = Date()
    ) {
        self.code = code
        self.analysis = analysis
        self.language = language
        self.complexity = complexity
        self.timestamp = timestamp
    }
}

/// Code complexity levels
public enum CodeComplexity: String, Codable, Sendable {
    case simple
    case standard
    case advanced
}

/// Cache statistics
public struct CacheStats: Codable, Sendable {
    public let totalEntries: Int
    public let hitRate: Double
    public let averageResponseTime: TimeInterval
    public let cacheSize: Int
    public let lastCleanup: Date?

    public init(
        totalEntries: Int = 0,
        hitRate: Double = 0.0,
        averageResponseTime: TimeInterval = 0.0,
        cacheSize: Int = 0,
        lastCleanup: Date? = nil
    ) {
        self.totalEntries = totalEntries
        self.hitRate = hitRate
        self.averageResponseTime = averageResponseTime
        self.cacheSize = cacheSize
        self.lastCleanup = lastCleanup
    }
}

/// Performance metrics
public struct PerformanceMetrics: Codable, Sendable {
    public let totalOperations: Int
    public let successRate: Double
    public let averageResponseTime: TimeInterval
    public let errorBreakdown: [String: Int]
    public let peakConcurrentOperations: Int
    public let uptime: TimeInterval

    public init(
        totalOperations: Int = 0,
        successRate: Double = 0.0,
        averageResponseTime: TimeInterval = 0.0,
        errorBreakdown: [String: Int] = [:],
        peakConcurrentOperations: Int = 0,
        uptime: TimeInterval = 0.0
    ) {
        self.totalOperations = totalOperations
        self.successRate = successRate
        self.averageResponseTime = averageResponseTime
        self.errorBreakdown = errorBreakdown
        self.peakConcurrentOperations = peakConcurrentOperations
        self.uptime = uptime
    }
}

/// AI service information
public struct AIServiceInfo: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: AIServiceType
    public let capabilities: [AICapability]
    public let isAvailable: Bool
    public let priority: Int

    public init(
        id: String,
        name: String,
        type: AIServiceType,
        capabilities: [AICapability] = [],
        isAvailable: Bool = true,
        priority: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.capabilities = capabilities
        self.isAvailable = isAvailable
        self.priority = priority
    }
}

/// AI service types
public enum AIServiceType: String, Codable, Sendable {
    case local
    case cloud
    case hybrid
}

/// AI capabilities
public enum AICapability: String, Codable, Sendable {
    case textGeneration
    case codeGeneration
    case codeAnalysis
    case documentation
    case testing
    case imageProcessing
    case naturalLanguage
}

/// AI operation definition
public struct AIOperation: Codable, Sendable {
    public let id: String
    public let type: AIOperationType
    public let parameters: [String: AnyCodable]
    public let priority: OperationPriority

    public init(
        id: String = UUID().uuidString,
        type: AIOperationType,
        parameters: [String: AnyCodable] = [:],
        priority: OperationPriority = .normal
    ) {
        self.id = id
        self.type = type
        self.parameters = parameters
        self.priority = priority
    }
}

/// AI operation types
public enum AIOperationType: String, Codable, Sendable {
    case generateText
    case generateCode
    case analyzeCode
    case generateDocumentation
    case generateTests
    case processImage
    case naturalLanguageProcessing
}

/// Operation priority levels
public enum OperationPriority: String, Codable, Sendable {
    case low
    case normal
    case high
    case critical
}

/// AI operation result
public struct AIOperationResult: Codable, Sendable {
    public let operationId: String
    public let success: Bool
    public let result: AnyCodable?
    public let error: String?
    public let executionTime: TimeInterval
    public let serviceUsed: String
    public let timestamp: Date

    public init(
        operationId: String,
        success: Bool,
        result: AnyCodable? = nil,
        error: String? = nil,
        executionTime: TimeInterval,
        serviceUsed: String,
        timestamp: Date = Date()
    ) {
        self.operationId = operationId
        self.success = success
        self.result = result
        self.error = error
        self.executionTime = executionTime
        self.serviceUsed = serviceUsed
        self.timestamp = timestamp
    }
}

/// Service health overview
public struct ServiceHealthOverview: Codable, Sendable {
    public let totalServices: Int
    public let availableServices: Int
    public let averageResponseTime: TimeInterval
    public let overallHealthScore: Double
    public let serviceStatuses: [String: ServiceHealth]
    public let recommendations: [String]

    public init(
        totalServices: Int = 0,
        availableServices: Int = 0,
        averageResponseTime: TimeInterval = 0.0,
        overallHealthScore: Double = 0.0,
        serviceStatuses: [String: ServiceHealth] = [:],
        recommendations: [String] = []
    ) {
        self.totalServices = totalServices
        self.availableServices = availableServices
        self.averageResponseTime = averageResponseTime
        self.overallHealthScore = overallHealthScore
        self.serviceStatuses = serviceStatuses
        self.recommendations = recommendations
    }
}

/// AI service configuration
public struct AIServiceConfiguration: Codable, Sendable {
    public let serviceId: String
    public let apiKey: String?
    public let baseURL: String?
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let rateLimit: RateLimit?
    public let enabledCapabilities: [AICapability]
    public let customParameters: [String: AnyCodable]

    public init(
        serviceId: String,
        apiKey: String? = nil,
        baseURL: String? = nil,
        timeout: TimeInterval = 30.0,
        maxRetries: Int = 3,
        rateLimit: RateLimit? = nil,
        enabledCapabilities: [AICapability] = [],
        customParameters: [String: AnyCodable] = [:]
    ) {
        self.serviceId = serviceId
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.rateLimit = rateLimit
        self.enabledCapabilities = enabledCapabilities
        self.customParameters = customParameters
    }
}

/// Rate limiting configuration
public struct RateLimit: Codable, Sendable {
    public let requestsPerMinute: Int
    public let requestsPerHour: Int
    public let burstLimit: Int

    public init(
        requestsPerMinute: Int = 60,
        requestsPerHour: Int = 1000,
        burstLimit: Int = 10
    ) {
        self.requestsPerMinute = requestsPerMinute
        self.requestsPerHour = requestsPerHour
        self.burstLimit = burstLimit
    }
}

/// Type-erased codable wrapper for Any values
public struct AnyCodable: Codable, Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self.value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            self.value = dictValue.mapValues { $0.value }
        } else {
            self.value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Default Implementations

extension AITextGenerationService {
    public func isAvailable() async -> Bool {
        let health = await getHealthStatus()
        return health.isRunning
    }
}

extension AICodeAnalysisService {
    public func generateDocumentation(code: String, language: String) async throws -> String {
        // Default implementation - should be overridden
        throw AIError.serviceNotImplemented("Documentation generation not implemented")
    }

    public func generateTests(code: String, language: String) async throws -> String {
        // Default implementation - should be overridden
        throw AIError.serviceNotImplemented("Test generation not implemented")
    }
}

extension AICodeGenerationService {
    public func generateCodeWithFallback(description: String, language: String, context: String?) async throws -> CodeGenerationResult {
        // Default implementation - just call regular generateCode
        return try await generateCode(description: description, language: language, context: context)
    }
}

// MARK: - Error Types

public enum AIError: Error, LocalizedError {
    case serviceNotImplemented(String)
    case serviceUnavailable(String)
    case invalidConfiguration(String)
    case operationFailed(String)
    case rateLimitExceeded
    case authenticationFailed
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .serviceNotImplemented(let service):
            "AI service not implemented: \(service)"
        case .serviceUnavailable(let service):
            "AI service unavailable: \(service)"
        case .invalidConfiguration(let details):
            "Invalid AI service configuration: \(details)"
        case .operationFailed(let details):
            "AI operation failed: \(details)"
        case .rateLimitExceeded:
            "AI service rate limit exceeded"
        case .authenticationFailed:
            "AI service authentication failed"
        case .networkError(let details):
            "AI service network error: \(details)"
        }
    }
}