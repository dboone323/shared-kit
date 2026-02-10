//
// AIServiceProtocolsTests.swift
// SharedKitTests
//

import XCTest
@testable import SharedKit

final class AIServiceProtocolsTests: XCTestCase {
    // MARK: - ServiceHealth Tests

    func testServiceHealthDefaultInit() {
        let health = ServiceHealth()
        XCTAssertEqual(health.serviceName, "")
        XCTAssertFalse(health.isRunning)
        XCTAssertFalse(health.modelsAvailable)
        XCTAssertEqual(health.errorRate, 0.0)
    }

    func testServiceHealthCustomInit() {
        let health = ServiceHealth(
            serviceName: "ollama",
            isRunning: true,
            modelsAvailable: true,
            responseTime: 0.5,
            errorRate: 0.01
        )
        XCTAssertEqual(health.serviceName, "ollama")
        XCTAssertTrue(health.isRunning)
        XCTAssertEqual(health.responseTime, 0.5)
    }

    func testServiceHealthCodable() throws {
        let health = ServiceHealth(serviceName: "test", isRunning: true)
        let data = try JSONEncoder().encode(health)
        let decoded = try JSONDecoder().decode(ServiceHealth.self, from: data)
        XCTAssertEqual(decoded.serviceName, "test")
        XCTAssertTrue(decoded.isRunning)
    }

    // MARK: - CodeIssue Tests

    func testCodeIssueDefaultInit() {
        let issue = CodeIssue(description: "Test issue")
        XCTAssertEqual(issue.severity, .medium)
        XCTAssertNil(issue.lineNumber)
        XCTAssertEqual(issue.category, "general")
    }

    func testCodeIssueCustomInit() {
        let issue = CodeIssue(
            description: "Critical bug",
            severity: .critical,
            lineNumber: 42,
            category: "security"
        )
        XCTAssertEqual(issue.description, "Critical bug")
        XCTAssertEqual(issue.severity, .critical)
        XCTAssertEqual(issue.lineNumber, 42)
        XCTAssertEqual(issue.category, "security")
    }

    // MARK: - IssueSeverity Tests

    func testIssueSeverityRawValues() {
        XCTAssertEqual(IssueSeverity.low.rawValue, "low")
        XCTAssertEqual(IssueSeverity.medium.rawValue, "medium")
        XCTAssertEqual(IssueSeverity.high.rawValue, "high")
        XCTAssertEqual(IssueSeverity.critical.rawValue, "critical")
    }

    // MARK: - AnalysisType Tests

    func testAnalysisTypeRawValues() {
        XCTAssertEqual(AnalysisType.bugs.rawValue, "bugs")
        XCTAssertEqual(AnalysisType.performance.rawValue, "performance")
        XCTAssertEqual(AnalysisType.security.rawValue, "security")
        XCTAssertEqual(AnalysisType.comprehensive.rawValue, "comprehensive")
    }

    // MARK: - CodeAnalysisResult Tests

    func testCodeAnalysisResultInit() {
        let result = CodeAnalysisResult(
            analysis: "No issues found",
            language: "swift",
            analysisType: .bugs
        )
        XCTAssertEqual(result.analysis, "No issues found")
        XCTAssertEqual(result.language, "swift")
        XCTAssertEqual(result.analysisType, .bugs)
        XCTAssertTrue(result.issues.isEmpty)
    }

    func testCodeAnalysisResultWithIssues() {
        let issues = [
            CodeIssue(description: "Issue 1"),
            CodeIssue(description: "Issue 2"),
        ]
        let result = CodeAnalysisResult(
            analysis: "Found issues",
            issues: issues,
            language: "python",
            analysisType: .security
        )
        XCTAssertEqual(result.issues.count, 2)
    }

    // MARK: - CodeGenerationResult Tests

    func testCodeGenerationResultInit() {
        let result = CodeGenerationResult(
            code: "func hello() {}",
            language: "swift"
        )
        XCTAssertEqual(result.code, "func hello() {}")
        XCTAssertEqual(result.complexity, .standard)
    }

    func testCodeComplexityRawValues() {
        XCTAssertEqual(CodeComplexity.simple.rawValue, "simple")
        XCTAssertEqual(CodeComplexity.standard.rawValue, "standard")
        XCTAssertEqual(CodeComplexity.advanced.rawValue, "advanced")
    }

    // MARK: - CacheStats Tests

    func testCacheStatsDefaultInit() {
        let stats = CacheStats()
        XCTAssertEqual(stats.totalEntries, 0)
        XCTAssertEqual(stats.hitRate, 0.0)
        XCTAssertNil(stats.lastCleanup)
    }

    // MARK: - PerformanceMetrics Tests

    func testPerformanceMetricsDefaultInit() {
        let metrics = PerformanceMetrics()
        XCTAssertEqual(metrics.totalOperations, 0)
        XCTAssertEqual(metrics.successRate, 0.0)
        XCTAssertTrue(metrics.errorBreakdown.isEmpty)
    }

    // MARK: - AIServiceInfo Tests

    func testAIServiceInfoInit() {
        let info = AIServiceInfo(
            id: "ollama-1",
            name: "Ollama",
            type: .local,
            capabilities: [.textGeneration, .codeGeneration]
        )
        XCTAssertEqual(info.id, "ollama-1")
        XCTAssertEqual(info.type, .local)
        XCTAssertEqual(info.capabilities.count, 2)
        XCTAssertTrue(info.isAvailable)
    }

    func testAIServiceTypeRawValues() {
        XCTAssertEqual(AIServiceType.local.rawValue, "local")
        XCTAssertEqual(AIServiceType.cloud.rawValue, "cloud")
        XCTAssertEqual(AIServiceType.hybrid.rawValue, "hybrid")
    }

    // MARK: - AICapability Tests

    func testAICapabilityRawValues() {
        XCTAssertEqual(AICapability.textGeneration.rawValue, "textGeneration")
        XCTAssertEqual(AICapability.codeGeneration.rawValue, "codeGeneration")
        XCTAssertEqual(AICapability.codeAnalysis.rawValue, "codeAnalysis")
        XCTAssertEqual(AICapability.documentation.rawValue, "documentation")
        XCTAssertEqual(AICapability.testing.rawValue, "testing")
    }

    // MARK: - AIOperation Tests

    func testAIOperationInit() {
        let op = AIOperation(type: .generateText)
        XCTAssertEqual(op.type, .generateText)
        XCTAssertEqual(op.priority, .normal)
        XCTAssertFalse(op.id.isEmpty)
    }

    func testAIOperationTypeRawValues() {
        XCTAssertEqual(AIOperationType.generateText.rawValue, "generateText")
        XCTAssertEqual(AIOperationType.generateCode.rawValue, "generateCode")
        XCTAssertEqual(AIOperationType.analyzeCode.rawValue, "analyzeCode")
    }

    func testOperationPriorityRawValues() {
        XCTAssertEqual(OperationPriority.low.rawValue, "low")
        XCTAssertEqual(OperationPriority.normal.rawValue, "normal")
        XCTAssertEqual(OperationPriority.high.rawValue, "high")
        XCTAssertEqual(OperationPriority.critical.rawValue, "critical")
    }

    // MARK: - AIOperationResult Tests

    func testAIOperationResultSuccess() {
        let result = AIOperationResult(
            operationId: "op-1",
            success: true,
            executionTime: 0.5,
            serviceUsed: "ollama"
        )
        XCTAssertTrue(result.success)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.executionTime, 0.5)
    }

    func testAIOperationResultFailure() {
        let result = AIOperationResult(
            operationId: "op-2",
            success: false,
            error: "Service unavailable",
            executionTime: 1.0,
            serviceUsed: "ollama"
        )
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.error, "Service unavailable")
    }

    // MARK: - RateLimit Tests

    func testRateLimitDefaultInit() {
        let limit = RateLimit()
        XCTAssertEqual(limit.requestsPerMinute, 60)
        XCTAssertEqual(limit.requestsPerHour, 1000)
        XCTAssertEqual(limit.burstLimit, 10)
    }

    func testRateLimitCustomInit() {
        let limit = RateLimit(requestsPerMinute: 30, requestsPerHour: 500, burstLimit: 5)
        XCTAssertEqual(limit.requestsPerMinute, 30)
        XCTAssertEqual(limit.requestsPerHour, 500)
    }

    // MARK: - AIServiceConfiguration Tests

    func testAIServiceConfigurationInit() {
        let config = AIServiceConfiguration(
            serviceId: "openai",
            apiKey: "sk-xxx",
            baseURL: "https://api.openai.com",
            timeout: 60
        )
        XCTAssertEqual(config.serviceId, "openai")
        XCTAssertEqual(config.timeout, 60)
        XCTAssertEqual(config.maxRetries, 3)
    }

    // MARK: - AIError Tests

    func testAIErrorDescriptions() {
        let error1 = AIError.serviceNotImplemented("test")
        XCTAssertTrue(error1.errorDescription?.contains("not implemented") ?? false)

        let error2 = AIError.rateLimitExceeded
        XCTAssertTrue(error2.errorDescription?.contains("rate limit") ?? false)

        let error3 = AIError.authenticationFailed
        XCTAssertTrue(error3.errorDescription?.contains("authentication") ?? false)
    }

    // MARK: - ServiceHealthOverview Tests

    func testServiceHealthOverviewDefaultInit() {
        let overview = ServiceHealthOverview()
        XCTAssertEqual(overview.totalServices, 0)
        XCTAssertEqual(overview.availableServices, 0)
        XCTAssertEqual(overview.overallHealthScore, 0.0)
    }
}
