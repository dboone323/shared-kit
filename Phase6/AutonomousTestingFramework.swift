//
//  AutonomousTestingFramework.swift
//  Quantum-workspace
//
//  Created by Phase 6 Implementation
//  Task 47: Autonomous Testing Framework
//
//  This file implements an autonomous testing framework that self-evolves test suites,
//  optimizes coverage, and adapts testing strategies based on code changes and failure patterns.
//

import Combine
import Foundation
import os.log

/// Represents different types of test cases
public enum TestCaseType: String, Codable {
    case unit
    case integration
    case ui
    case performance
    case security
    case mutation
    case property
}

/// Test execution result
public enum TestResult: String, Codable {
    case passed
    case failed
    case skipped
    case error
    case timeout
}

/// Represents a test case
public struct TestCase: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let type: TestCaseType
    public let target: String // Class, function, or component being tested
    public var priority: TestPriority
    public let estimatedDuration: TimeInterval
    public let dependencies: [String]
    public var tags: [String]
    public let created: Date
    public var lastExecuted: Date?
    public var executionCount: Int
    public var successRate: Double
    public var coverage: Double

    public init(
        name: String, type: TestCaseType, target: String,
        priority: TestPriority = .medium, estimatedDuration: TimeInterval = 1.0,
        dependencies: [String] = [], tags: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.target = target
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.dependencies = dependencies
        self.tags = tags
        self.created = Date()
        self.lastExecuted = nil
        self.executionCount = 0
        self.successRate = 0.0
        self.coverage = 0.0
    }
}

/// Test execution record
public struct TestExecution: Codable {
    public let id: UUID
    public let testCaseId: UUID
    public let timestamp: Date
    public let result: TestResult
    public let duration: TimeInterval
    public let output: String
    public let coverage: Double
    public let metadata: [String: String]

    public init(
        testCaseId: UUID, result: TestResult, duration: TimeInterval,
        output: String = "", coverage: Double = 0.0, metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.testCaseId = testCaseId
        self.timestamp = Date()
        self.result = result
        self.duration = duration
        self.output = output
        self.coverage = coverage
        self.metadata = metadata
    }
}

/// Test priority levels
public enum TestPriority: String, Codable {
    case critical
    case high
    case medium
    case low
}

/// Test suite configuration
public struct TestSuite: Codable {
    public let id: UUID
    public let name: String
    public var testCases: [UUID]
    public let targetComponents: [String]
    public var executionStrategy: ExecutionStrategy
    public let coverageTarget: Double
    public let maxDuration: TimeInterval
    public let created: Date
    public var lastModified: Date

    public init(
        name: String, testCases: [UUID] = [], targetComponents: [String] = [],
        executionStrategy: ExecutionStrategy = .parallel, coverageTarget: Double = 0.8,
        maxDuration: TimeInterval = 300.0
    ) {
        self.id = UUID()
        self.name = name
        self.testCases = testCases
        self.targetComponents = targetComponents
        self.executionStrategy = executionStrategy
        self.coverageTarget = coverageTarget
        self.maxDuration = maxDuration
        self.created = Date()
        self.lastModified = Date()
    }
}

/// Test execution strategy
public enum ExecutionStrategy: String, Codable {
    case sequential
    case parallel
    case prioritized
    case adaptive
}

/// Coverage analysis result
public struct CoverageAnalysis: Codable {
    public let component: String
    public let linesCovered: Int
    public let totalLines: Int
    public let coveragePercentage: Double
    public let uncoveredLines: [Int]
    public let riskAreas: [String]

    public init(
        component: String, linesCovered: Int, totalLines: Int,
        uncoveredLines: [Int] = [], riskAreas: [String] = []
    ) {
        self.component = component
        self.linesCovered = linesCovered
        self.totalLines = totalLines
        self.coveragePercentage = totalLines > 0 ? Double(linesCovered) / Double(totalLines) : 0.0
        self.uncoveredLines = uncoveredLines
        self.riskAreas = riskAreas
    }
}

/// Autonomous testing framework
@MainActor
public final class AutonomousTestingFramework: ObservableObject {

    // MARK: - Properties

    public static let shared = AutonomousTestingFramework()

    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var currentTestSuite: TestSuite?
    @Published public private(set) var testResults: [TestExecution] = []
    @Published public private(set) var coverageAnalysis: [CoverageAnalysis] = []
    @Published public private(set) var overallCoverage: Double = 0.0

    private let logger = Logger(subsystem: "com.quantum.workspace", category: "AutonomousTesting")
    private var monitoringTask: Task<Void, Never>?
    private var evolutionTask: Task<Void, Never>?
    private var executionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let monitoringInterval: TimeInterval = 3600.0 // 1 hour
    private let evolutionInterval: TimeInterval = 86400.0 // 24 hours
    private let coverageTarget: Double = 0.85 // 85% target coverage
    private let maxTestDuration: TimeInterval = 300.0 // 5 minutes per test

    // State
    private var testCases = [UUID: TestCase]()
    private var testSuites = [UUID: TestSuite]()
    private var executionHistory = [TestExecution]()
    private var coverageHistory = [CoverageAnalysis]()

    // MARK: - Initialization

    private init() {
        setupTestMonitoring()
        loadExistingTests()
    }

    // MARK: - Public Interface

    /// Start the autonomous testing framework
    public func start() async {
        guard !isActive else { return }

        logger.info("🚀 Starting Autonomous Testing Framework")
        isActive = true

        // Start monitoring task
        monitoringTask = Task {
            await startMonitoringLoop()
        }

        // Start evolution task
        evolutionTask = Task {
            await startEvolutionLoop()
        }

        // Start execution task
        executionTask = Task {
            await startExecutionLoop()
        }

        logger.info("✅ Autonomous Testing Framework started successfully")
    }

    /// Stop the autonomous testing framework
    public func stop() async {
        guard isActive else { return }

        logger.info("🛑 Stopping Autonomous Testing Framework")
        isActive = false

        // Cancel all tasks
        monitoringTask?.cancel()
        evolutionTask?.cancel()
        executionTask?.cancel()

        monitoringTask = nil
        evolutionTask = nil
        executionTask = nil

        logger.info("✅ Autonomous Testing Framework stopped")
    }

    /// Execute a specific test suite
    public func executeTestSuite(_ suiteId: UUID) async -> [TestExecution] {
        guard let suite = testSuites[suiteId] else {
            logger.error("❌ Test suite not found: \(suiteId)")
            return []
        }

        logger.info("🧪 Executing test suite: \(suite.name)")

        await MainActor.run {
            currentTestSuite = suite
        }

        let results = await executeTestCases(suite.testCases, strategy: suite.executionStrategy)

        await MainActor.run {
            testResults = results
            currentTestSuite = nil
        }

        // Update test case statistics
        await updateTestStatistics(results)

        // Analyze coverage
        await analyzeCoverage()

        logger.info("✅ Test suite execution completed: \(results.count) tests run")
        return results
    }

    /// Generate new test cases based on code analysis
    public func generateTestCases(for components: [String]) async -> [TestCase] {
        logger.info("🤖 Generating test cases for components: \(components.joined(separator: ", "))")

        var newTestCases = [TestCase]()

        for component in components {
            let componentTests = await generateTestsForComponent(component)
            newTestCases.append(contentsOf: componentTests)
        }

        // Add generated tests to the framework
        for testCase in newTestCases {
            testCases[testCase.id] = testCase
        }

        logger.info("✅ Generated \(newTestCases.count) new test cases")
        return newTestCases
    }

    /// Optimize test suite for better coverage and efficiency
    public func optimizeTestSuite(_ suiteId: UUID) async {
        guard var suite = testSuites[suiteId] else {
            logger.error("❌ Test suite not found: \(suiteId)")
            return
        }

        logger.info("🔧 Optimizing test suite: \(suite.name)")

        // Analyze current coverage and performance
        let currentCoverage = await calculateSuiteCoverage(suite.testCases)
        let performanceMetrics = await analyzeTestPerformance(suite.testCases)

        // Generate optimization recommendations
        let recommendations = await generateOptimizationRecommendations(
            coverage: currentCoverage,
            performance: performanceMetrics,
            existingTests: suite.testCases
        )

        // Apply optimizations
        suite.testCases = recommendations.optimizedTestCases
        suite.executionStrategy = recommendations.recommendedStrategy
        suite.lastModified = Date()

        testSuites[suiteId] = suite

        logger.info("✅ Test suite optimization completed")
    }

    /// Get current test coverage analysis
    public func getCoverageAnalysis() -> [CoverageAnalysis] {
        coverageAnalysis
    }

    /// Get test execution history
    public func getTestHistory() -> [TestExecution] {
        executionHistory
    }

    // MARK: - Private Methods

    private func setupTestMonitoring() {
        // Monitor code changes to trigger test generation
        // This would integrate with file system monitoring in a real implementation
    }

    private func loadExistingTests() {
        // Load existing test cases from the workspace
        // This would scan for existing test files and parse them
        logger.info("📚 Loading existing test cases...")

        // Create some initial test suites
        let unitSuite = TestSuite(
            name: "Unit Tests",
            targetComponents: ["Models", "Utilities", "Services"],
            executionStrategy: .parallel,
            coverageTarget: 0.9
        )

        let integrationSuite = TestSuite(
            name: "Integration Tests",
            targetComponents: ["API", "Database", "External"],
            executionStrategy: .sequential,
            coverageTarget: 0.75
        )

        testSuites[unitSuite.id] = unitSuite
        testSuites[integrationSuite.id] = integrationSuite

        logger.info("✅ Loaded \(self.testSuites.count) test suites")
    }

    private func startMonitoringLoop() async {
        while isActive && !Task.isCancelled {
            await performTestMonitoring()
            try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
        }
    }

    private func startEvolutionLoop() async {
        while isActive && !Task.isCancelled {
            await performTestEvolution()
            try? await Task.sleep(nanoseconds: UInt64(evolutionInterval * 1_000_000_000))
        }
    }

    private func startExecutionLoop() async {
        // Execute tests based on schedule or triggers
        // This would be more sophisticated in a real implementation
    }

    private func performTestMonitoring() async {
        logger.info("👀 Performing test monitoring...")

        // Check for code changes that might require new tests
        let codeChanges = await detectCodeChanges()
        if !codeChanges.isEmpty {
            let newTests = await generateTestCases(for: codeChanges)
            logger.info("📝 Generated \(newTests.count) tests for code changes")
        }

        // Check test effectiveness
        await evaluateTestEffectiveness()

        // Update coverage analysis
        await analyzeCoverage()
    }

    private func performTestEvolution() async {
        logger.info("🧬 Performing test evolution...")

        // Evolve existing test cases
        await evolveTestCases()

        // Optimize test suites
        for suiteId in testSuites.keys {
            await optimizeTestSuite(suiteId)
        }

        // Generate mutation tests
        await generateMutationTests()

        // Update test priorities based on failure patterns
        await updateTestPriorities()
    }

    private func detectCodeChanges() async -> [String] {
        // Simplified code change detection
        // In a real implementation, this would monitor git changes or file system events

        // Simulate detecting changes in key components
        let components = ["Models", "Views", "Controllers", "Services"]
        return components.filter { _ in Bool.random() } // Randomly detect changes for demo
    }

    private func generateTestsForComponent(_ component: String) async -> [TestCase] {
        var tests = [TestCase]()

        // Generate different types of tests based on component
        switch component {
        case "Models":
            tests.append(
                TestCase(
                    name: "test\(component)Initialization",
                    type: .unit,
                    target: component,
                    priority: .high,
                    tags: ["initialization", "models"]
                ))
            tests.append(
                TestCase(
                    name: "test\(component)Validation",
                    type: .unit,
                    target: component,
                    priority: .high,
                    tags: ["validation", "models"]
                ))
            tests.append(
                TestCase(
                    name: "test\(component)Serialization",
                    type: .unit,
                    target: component,
                    priority: .medium,
                    tags: ["serialization", "models"]
                ))

        case "Services":
            tests.append(
                TestCase(
                    name: "test\(component)APIIntegration",
                    type: .integration,
                    target: component,
                    priority: .high,
                    tags: ["api", "integration"]
                ))
            tests.append(
                TestCase(
                    name: "test\(component)ErrorHandling",
                    type: .unit,
                    target: component,
                    priority: .medium,
                    tags: ["error", "services"]
                ))

        case "Views":
            tests.append(
                TestCase(
                    name: "test\(component)Rendering",
                    type: .ui,
                    target: component,
                    priority: .medium,
                    tags: ["ui", "rendering"]
                ))
            tests.append(
                TestCase(
                    name: "test\(component)UserInteraction",
                    type: .ui,
                    target: component,
                    priority: .low,
                    tags: ["ui", "interaction"]
                ))

        default:
            tests.append(
                TestCase(
                    name: "test\(component)BasicFunctionality",
                    type: .unit,
                    target: component,
                    priority: .medium,
                    tags: ["basic", component.lowercased()]
                ))
        }

        return tests
    }

    private func executeTestCases(_ testCaseIds: [UUID], strategy: ExecutionStrategy) async
        -> [TestExecution]
    {
        var results = [TestExecution]()

        switch strategy {
        case .sequential:
            for testId in testCaseIds {
                if let result = await executeTestCase(testId) {
                    results.append(result)
                }
            }

        case .parallel:
            await withTaskGroup(of: TestExecution?.self) { group in
                for testId in testCaseIds {
                    group.addTask {
                        await self.executeTestCase(testId)
                    }
                }

                for await result in group {
                    if let result {
                        results.append(result)
                    }
                }
            }

        case .prioritized:
            let sortedIds = testCaseIds.sorted { lhs, rhs in
                guard let leftTest = testCases[lhs], let rightTest = testCases[rhs] else {
                    return false
                }
                return leftTest.priority.sortOrder > rightTest.priority.sortOrder
            }

            for testId in sortedIds {
                if let result = await executeTestCase(testId) {
                    results.append(result)
                }
            }

        case .adaptive:
            // Adaptive execution based on previous results and system load
            let adaptiveResults = await executeAdaptive(testCaseIds)
            results.append(contentsOf: adaptiveResults)
        }

        return results
    }

    private func executeTestCase(_ testId: UUID) async -> TestExecution? {
        guard var testCase = testCases[testId] else { return nil }

        let startTime = Date()

        // Simulate test execution
        let (result, output) = await simulateTestExecution(testCase)

        let duration = Date().timeIntervalSince(startTime)
        let coverage = Double.random(in: 0.1 ... 1.0) // Simulated coverage

        let execution = TestExecution(
            testCaseId: testId,
            result: result,
            duration: duration,
            output: output,
            coverage: coverage
        )

        // Update test case statistics
        testCase.executionCount += 1
        testCase.lastExecuted = Date()

        let successRate = result == .passed ? 1.0 : 0.0
        testCase.successRate =
            (testCase.successRate * Double(testCase.executionCount - 1) + successRate)
                / Double(testCase.executionCount)
        testCase.coverage = coverage

        testCases[testId] = testCase
        executionHistory.append(execution)

        return execution
    }

    private func simulateTestExecution(_ testCase: TestCase) async -> (TestResult, String) {
        // Simulate test execution with realistic outcomes
        try? await Task.sleep(nanoseconds: UInt64(testCase.estimatedDuration * 1_000_000_000))

        let random = Double.random(in: 0 ... 1)

        // Base success rate depends on test type and priority
        var successRate = 0.85 // 85% base success rate

        switch testCase.type {
        case .unit:
            successRate = 0.9
        case .integration:
            successRate = 0.75
        case .ui:
            successRate = 0.7
        case .performance:
            successRate = 0.8
        case .security:
            successRate = 0.85
        case .mutation:
            successRate = 0.6 // Mutation tests are more likely to fail initially
        case .property:
            successRate = 0.7
        }

        // Adjust based on priority
        switch testCase.priority {
        case .critical:
            successRate += 0.05
        case .high:
            successRate += 0.02
        case .low:
            successRate -= 0.05
        case .medium:
            break
        }

        if random < successRate {
            return (.passed, "Test passed successfully")
        } else if random < successRate + 0.1 {
            return (.failed, "Test assertion failed: expected true, got false")
        } else if random < successRate + 0.15 {
            return (.error, "Test threw unexpected error: \(testCase.name)")
        } else {
            return (.timeout, "Test timed out after \(maxTestDuration) seconds")
        }
    }

    private func executeAdaptive(_ testCaseIds: [UUID]) async -> [TestExecution] {
        var results = [TestExecution]()
        var remainingTests = testCaseIds

        // Execute critical tests first
        let criticalTests = remainingTests.filter {
            self.testCases[$0]?.priority == .critical
        }

        for testId in criticalTests {
            if let result = await executeTestCase(testId) {
                results.append(result)
            }
            remainingTests.removeAll { $0 == testId }
        }

        // Execute remaining tests in parallel, but limit concurrency
        let semaphore = AsyncSemaphore(value: 3) // Max 3 concurrent tests

        await withTaskGroup(of: TestExecution?.self) { group in
            for testId in remainingTests {
                group.addTask {
                    await semaphore.wait()
                    let result = await self.executeTestCase(testId)
                    await semaphore.signal()
                    return result
                }
            }

            for await result in group {
                if let result {
                    results.append(result)
                }
            }
        }

        return results
    }

    private func updateTestStatistics(_ executions: [TestExecution]) async {
        for execution in executions {
            guard var testCase = testCases[execution.testCaseId] else { continue }

            testCase.executionCount += 1
            testCase.lastExecuted = execution.timestamp

            let successRate = execution.result == .passed ? 1.0 : 0.0
            testCase.successRate =
                (testCase.successRate * Double(testCase.executionCount - 1) + successRate)
                    / Double(testCase.executionCount)
            testCase.coverage = execution.coverage

            testCases[execution.testCaseId] = testCase
        }
    }

    private func analyzeCoverage() async {
        var analyses = [CoverageAnalysis]()

        // Analyze coverage for different components
        let components = ["Models", "Views", "Controllers", "Services", "Utilities"]

        for component in components {
            let analysis = await analyzeComponentCoverage(component)
            analyses.append(analysis)
        }

        await MainActor.run {
            coverageAnalysis = analyses
            overallCoverage =
                analyses.map(\.coveragePercentage).reduce(0, +) / Double(analyses.count)
        }
    }

    private func analyzeComponentCoverage(_ component: String) async -> CoverageAnalysis {
        // Simulate coverage analysis
        let totalLines = Int.random(in: 100 ... 1000)
        let coveredLines = Int(Double(totalLines) * Double.random(in: 0.6 ... 0.95))
        let coveragePercentage = Double(coveredLines) / Double(totalLines)

        // Identify uncovered lines (simplified)
        let uncoveredLines = (1 ... totalLines).filter { _ in
            Double.random(in: 0 ... 1) > coveragePercentage
        }

        // Identify risk areas
        var riskAreas = [String]()
        if coveragePercentage < 0.7 {
            riskAreas.append("Low overall coverage")
        }
        if uncoveredLines.count > totalLines / 10 {
            riskAreas.append("Many uncovered lines")
        }

        return CoverageAnalysis(
            component: component,
            linesCovered: coveredLines,
            totalLines: totalLines,
            uncoveredLines: Array(uncoveredLines.prefix(10)), // Limit to first 10
            riskAreas: riskAreas
        )
    }

    private func calculateSuiteCoverage(_ testCaseIds: [UUID]) async -> Double {
        let executions = executionHistory.filter { testCaseIds.contains($0.testCaseId) }
        guard !executions.isEmpty else { return 0.0 }

        let totalCoverage = executions.reduce(0.0) { $0 + $1.coverage }
        return totalCoverage / Double(executions.count)
    }

    private func analyzeTestPerformance(_ testCaseIds: [UUID]) async -> [String: Double] {
        let executions = executionHistory.filter { testCaseIds.contains($0.testCaseId) }

        var metrics = [String: Double]()
        metrics["averageDuration"] =
            executions.map(\.duration).reduce(0, +) / Double(executions.count)
        metrics["successRate"] =
            Double(executions.filter { $0.result == .passed }.count) / Double(executions.count)
        metrics["failureRate"] =
            Double(executions.filter { $0.result == .failed }.count) / Double(executions.count)

        return metrics
    }

    private func generateOptimizationRecommendations(
        coverage: Double, performance: [String: Double], existingTests: [UUID]
    ) async -> (optimizedTestCases: [UUID], recommendedStrategy: ExecutionStrategy) {
        var optimizedTests = existingTests

        // Add tests for low coverage areas
        if coverage < coverageTarget {
            let newTests = await generateCoverageTests()
            optimizedTests.append(contentsOf: newTests.map(\.id))
        }

        // Optimize execution strategy based on performance
        var strategy = ExecutionStrategy.parallel

        if let avgDuration = performance["averageDuration"], avgDuration > 10.0 {
            strategy = .prioritized // Prioritize fast tests
        }

        if let failureRate = performance["failureRate"], failureRate > 0.2 {
            strategy = .sequential // Run failing tests sequentially for better debugging
        }

        return (optimizedTests, strategy)
    }

    private func generateCoverageTests() async -> [TestCase] {
        // Generate tests for uncovered code paths
        [
            TestCase(
                name: "testUncoveredFunctionality",
                type: .unit,
                target: "CoverageGap",
                priority: .high,
                tags: ["coverage", "generated"]
            ),
        ]
    }

    private func evaluateTestEffectiveness() async {
        // Evaluate which tests are most effective at catching bugs
        let recentExecutions = executionHistory.suffix(100)

        for (testId, testCase) in testCases {
            let testExecutions = recentExecutions.filter { $0.testCaseId == testId }
            if testExecutions.isEmpty { continue }

            let effectiveness = calculateTestEffectiveness(testExecutions)
            logger.debug("Test effectiveness for \(testCase.name): \(effectiveness)")
        }
    }

    private func calculateTestEffectiveness(_ executions: [TestExecution]) -> Double {
        let successRate =
            Double(executions.filter { $0.result == .passed }.count) / Double(executions.count)
        let avgCoverage = executions.map(\.coverage).reduce(0, +) / Double(executions.count)

        // Effectiveness is a combination of reliability and coverage
        return (successRate * 0.7) + (avgCoverage * 0.3)
    }

    private func evolveTestCases() async {
        // Evolve test cases based on failure patterns and code changes
        for (testId, testCase) in testCases {
            if testCase.successRate < 0.8 {
                // Evolve failing tests
                let evolvedTest = await evolveTest(testCase)
                testCases[testId] = evolvedTest
            }
        }
    }

    private func evolveTest(_ testCase: TestCase) async -> TestCase {
        // Simple evolution: increase priority for failing tests
        var evolvedTest = testCase

        if testCase.successRate < 0.5 {
            evolvedTest.priority = .critical
        } else if testCase.successRate < 0.7 {
            evolvedTest.priority = .high
        }

        // Add debugging tags for failing tests
        if !evolvedTest.tags.contains("failing") {
            evolvedTest.tags.append("failing")
        }

        return evolvedTest
    }

    private func generateMutationTests() async {
        // Generate mutation tests to test code robustness
        let mutationTests = testCases.values.filter { $0.type == .unit }.prefix(5)

        for testCase in mutationTests {
            let mutationTest = TestCase(
                name: "\(testCase.name)Mutation",
                type: .mutation,
                target: testCase.target,
                priority: .medium,
                tags: ["mutation", "robustness"]
            )
            testCases[mutationTest.id] = mutationTest
        }
    }

    private func updateTestPriorities() async {
        // Update test priorities based on recent failure patterns
        let recentFailures = executionHistory.suffix(50).filter { $0.result == .failed }

        for failure in recentFailures {
            if var testCase = testCases[failure.testCaseId] {
                // Increase priority for frequently failing tests
                switch testCase.priority {
                case .low:
                    testCase.priority = .medium
                case .medium:
                    testCase.priority = .high
                case .high:
                    testCase.priority = .critical
                case .critical:
                    break // Already critical
                }
                testCases[failure.testCaseId] = testCase
            }
        }
    }
}

// MARK: - Supporting Types

/// Async semaphore for controlling concurrency
private actor AsyncSemaphore {
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(value: Int) {
        self.value = value
    }

    func wait() async {
        if value > 0 {
            value -= 1
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func signal() async {
        value += 1
        if let waiter = waiters.first {
            waiters.removeFirst()
            waiter.resume()
        }
    }
}

// MARK: - Extensions

extension TestPriority {
    var sortOrder: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

public extension AutonomousTestingFramework {
    /// Get test cases for a specific component
    func getTestCases(for component: String) -> [TestCase] {
        testCases.values.filter { $0.target == component }
    }

    /// Get test suites
    func getTestSuites() -> [TestSuite] {
        Array(testSuites.values)
    }

    /// Create a new test suite
    func createTestSuite(name: String, targetComponents: [String]) -> UUID {
        let suite = TestSuite(name: name, targetComponents: targetComponents)
        testSuites[suite.id] = suite
        return suite.id
    }

    /// Export test results for analysis
    func exportTestResults() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(executionHistory)
    }
}

// MARK: - Convenience Functions

/// Global function to run autonomous tests
public func runAutonomousTests() async {
    await AutonomousTestingFramework.shared.start()
}

/// Global function to get current test coverage
public func getCurrentTestCoverage() async -> Double {
    await AutonomousTestingFramework.shared.overallCoverage
}

/// Global function to execute a test suite
public func executeTestSuite(_ suiteName: String) async -> [TestExecution] {
    let framework = await AutonomousTestingFramework.shared
    let suites = await framework.getTestSuites()
    guard let suite = suites.first(where: { $0.name == suiteName }) else {
        return []
    }

    return await framework.executeTestSuite(suite.id)
}
