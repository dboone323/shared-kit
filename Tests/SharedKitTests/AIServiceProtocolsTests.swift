//
// AIServiceProtocolsTests.swift
// SharedKitTests
//

import Foundation
import Testing

@testable import SharedKit

@Suite("AI Service Protocols Tests")
struct AIServiceProtocolsTests {
    // MARK: - ServiceHealth Tests

    @Test("ServiceHealth Default Initialization")
    func serviceHealthDefaultInit() {
        let health = ServiceHealth()
        #expect(health.serviceName == "")
        #expect(health.isRunning == false)
        #expect(health.modelsAvailable == false)
        #expect(health.errorRate == 0.0)
    }

    @Test("ServiceHealth Custom Initialization")
    func serviceHealthCustomInit() {
        let health = ServiceHealth(
            serviceName: "ollama",
            isRunning: true,
            modelsAvailable: true,
            responseTime: 0.5,
            errorRate: 0.01
        )
        #expect(health.serviceName == "ollama")
        #expect(health.isRunning == true)
        #expect(health.responseTime == 0.5)
    }

    @Test("ServiceHealth Codable Support")
    func serviceHealthCodable() throws {
        let health = ServiceHealth(serviceName: "test", isRunning: true)
        let data = try JSONEncoder().encode(health)
        let decoded = try JSONDecoder().decode(ServiceHealth.self, from: data)
        #expect(decoded.serviceName == "test")
        #expect(decoded.isRunning == true)
    }

    // MARK: - AICodeIssue Tests

    @Test("AICodeIssue Default Initialization")
    func codeIssueDefaultInit() {
        let issue = AICodeIssue(description: "Test issue")
        #expect(issue.severity == .medium)
        #expect(issue.lineNumber == nil)
        #expect(issue.category == "general")
    }

    @Test("AICodeIssue Custom Initialization")
    func codeIssueCustomInit() {
        let issue = AICodeIssue(
            description: "Critical bug",
            severity: .critical,
            lineNumber: 42,
            category: "security"
        )
        #expect(issue.description == "Critical bug")
        #expect(issue.severity == .critical)
        #expect(issue.lineNumber == 42)
        #expect(issue.category == "security")
    }

    // MARK: - AIIssueSeverity Tests

    @Test("AIIssueSeverity Raw Values")
    func issueSeverityRawValues() {
        #expect(AIIssueSeverity.low.rawValue == "low")
        #expect(AIIssueSeverity.medium.rawValue == "medium")
        #expect(AIIssueSeverity.high.rawValue == "high")
        #expect(AIIssueSeverity.critical.rawValue == "critical")
    }

    // MARK: - AICodeAnalysisType Tests

    @Test("AICodeAnalysisType Raw Values")
    func analysisTypeRawValues() {
        #expect(AICodeAnalysisType.bugs.rawValue == "bugs")
        #expect(AICodeAnalysisType.performance.rawValue == "performance")
        #expect(AICodeAnalysisType.security.rawValue == "security")
        #expect(AICodeAnalysisType.comprehensive.rawValue == "comprehensive")
    }

    // MARK: - CodeAnalysisResult Tests

    @Test("CodeAnalysisResult Initialization")
    func codeAnalysisResultInit() {
        let result = CodeAnalysisResult(
            analysis: "No issues found",
            language: "swift",
            analysisType: .bugs
        )
        #expect(result.analysis == "No issues found")
        #expect(result.language == "swift")
        #expect(result.analysisType == .bugs)
        #expect(result.issues.isEmpty)
    }

    @Test("CodeAnalysisResult with Issues")
    func codeAnalysisResultWithIssues() {
        let issues = [
            AICodeIssue(description: "Issue 1"),
            AICodeIssue(description: "Issue 2"),
        ]
        let result = CodeAnalysisResult(
            analysis: "Found issues",
            issues: issues,
            language: "python",
            analysisType: .security
        )
        #expect(result.issues.count == 2)
    }

    // MARK: - CodeGenerationResult Tests

    @Test("CodeGenerationResult Initialization")
    func codeGenerationResultInit() {
        let result = CodeGenerationResult(
            code: "func hello() {}",
            language: "swift"
        )
        #expect(result.code == "func hello() {}")
        #expect(result.complexity == .standard)
    }

    @Test("AICodeComplexity Raw Values")
    func codeComplexityRawValues() {
        #expect(AICodeComplexity.simple.rawValue == "simple")
        #expect(AICodeComplexity.standard.rawValue == "standard")
        #expect(AICodeComplexity.advanced.rawValue == "advanced")
    }

    // MARK: - CacheStats Tests

    @Test("CacheStats Default Initialization")
    func cacheStatsDefaultInit() {
        let stats = CacheStats()
        #expect(stats.totalEntries == 0)
        #expect(stats.hitRate == 0.0)
        #expect(stats.lastCleanup == nil)
    }

    // MARK: - PerformanceMetrics Tests

    @Test("PerformanceMetrics Default Initialization")
    func performanceMetricsDefaultInit() {
        let metrics = PerformanceMetrics()
        #expect(metrics.totalOperations == 0)
        #expect(metrics.successRate == 0.0)
        #expect(metrics.errorBreakdown.isEmpty)
    }

    // MARK: - AIServiceInfo Tests

    @Test("AIServiceInfo Initialization")
    func aiServiceInfoInit() {
        let info = AIServiceInfo(
            id: "ollama-1",
            name: "Ollama",
            type: .local,
            capabilities: [.textGeneration, .codeGeneration]
        )
        #expect(info.id == "ollama-1")
        #expect(info.type == .local)
        #expect(info.capabilities.count == 2)
        #expect(info.isAvailable == true)
    }

    @Test("AIServiceType Raw Values")
    func aiServiceTypeRawValues() {
        #expect(AIServiceType.local.rawValue == "local")
        #expect(AIServiceType.cloud.rawValue == "cloud")
        #expect(AIServiceType.hybrid.rawValue == "hybrid")
    }

    // MARK: - AICapability Tests

    @Test("AICapability Raw Values")
    func aiCapabilityRawValues() {
        #expect(AICapability.textGeneration.rawValue == "textGeneration")
        #expect(AICapability.codeGeneration.rawValue == "codeGeneration")
        #expect(AICapability.codeAnalysis.rawValue == "codeAnalysis")
        #expect(AICapability.documentation.rawValue == "documentation")
        #expect(AICapability.testing.rawValue == "testing")
    }

    // MARK: - AIOperation Tests

    @Test("AIOperation Initialization")
    func aiOperationInit() {
        let op = AIOperation(type: .generateText)
        #expect(op.type == .generateText)
        #expect(op.priority == .normal)
        #expect(!op.id.isEmpty)
    }

    @Test("AIOperationType Raw Values")
    func aiOperationTypeRawValues() {
        #expect(AIOperationType.generateText.rawValue == "generateText")
        #expect(AIOperationType.generateCode.rawValue == "generateCode")
        #expect(AIOperationType.analyzeCode.rawValue == "analyzeCode")
    }

    @Test("OperationPriority Raw Values")
    func operationPriorityRawValues() {
        #expect(OperationPriority.low.rawValue == "low")
        #expect(OperationPriority.normal.rawValue == "normal")
        #expect(OperationPriority.high.rawValue == "high")
        #expect(OperationPriority.critical.rawValue == "critical")
    }

    // MARK: - AIOperationResult Tests

    @Test("AIOperationResult Success")
    func aiOperationResultSuccess() {
        let result = AIOperationResult(
            operationId: "op-1",
            success: true,
            executionTime: 0.5,
            serviceUsed: "ollama"
        )
        #expect(result.success == true)
        #expect(result.error == nil)
        #expect(result.executionTime == 0.5)
    }

    @Test("AIOperationResult Failure")
    func aiOperationResultFailure() {
        let result = AIOperationResult(
            operationId: "op-2",
            success: false,
            error: "Service unavailable",
            executionTime: 1.0,
            serviceUsed: "ollama"
        )
        #expect(result.success == false)
        #expect(result.error == "Service unavailable")
    }

    // MARK: - RateLimit Tests

    @Test("RateLimit Default Initialization")
    func rateLimitDefaultInit() {
        let limit = RateLimit()
        #expect(limit.requestsPerMinute == 60)
        #expect(limit.requestsPerHour == 1000)
        #expect(limit.burstLimit == 10)
    }

    @Test("RateLimit Custom Initialization")
    func rateLimitCustomInit() {
        let limit = RateLimit(requestsPerMinute: 30, requestsPerHour: 500, burstLimit: 5)
        #expect(limit.requestsPerMinute == 30)
        #expect(limit.requestsPerHour == 500)
    }

    // MARK: - AIServiceConfiguration Tests

    @Test("AIServiceConfiguration Initialization")
    func aiServiceConfigurationInit() {
        let config = AIServiceConfiguration(
            serviceId: "openai",
            apiKey: "sk-xxx",
            baseURL: "https://api.openai.com",
            timeout: 60
        )
        #expect(config.serviceId == "openai")
        #expect(config.timeout == 60)
        #expect(config.maxRetries == 3)
    }

    // MARK: - AIError Tests

    @Test("AIError Descriptions")
    func aiErrorDescriptions() {
        let error1 = AIError.serviceNotImplemented("test")
        #expect(error1.errorDescription?.contains("not implemented") == true)

        let error2 = AIError.rateLimitExceeded
        #expect(error2.errorDescription?.contains("rate limit") == true)

        let error3 = AIError.authenticationFailed
        #expect(error3.errorDescription?.contains("authentication") == true)
    }

    // MARK: - ServiceHealthOverview Tests

    @Test("ServiceHealthOverview Default Initialization")
    func serviceHealthOverviewDefaultInit() {
        let overview = ServiceHealthOverview()
        #expect(overview.totalServices == 0)
        #expect(overview.availableServices == 0)
        #expect(overview.overallHealthScore == 0.0)
    }
}
