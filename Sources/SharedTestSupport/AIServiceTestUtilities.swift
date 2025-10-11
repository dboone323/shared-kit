import Combine
import SharedKit
import XCTest

/// Testing utilities for AI services across projects
@MainActor
class AIServiceTestUtilities {
    /// Mock AI service for testing
    class MockAIService: AIServiceProtocol {
        var responses: [String: Any] = [:]
        var errors: [String: Error] = [:]
        var callHistory: [String] = []

        func recordCall(_ method: String, parameters: [String: Any] = [:]) {
            let call =
                "\(method)(\(parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")))"
            callHistory.append(call)
        }

        func setResponse<T>(_ response: T, for method: String) {
            responses[method] = response
        }

        func setError(_ error: Error, for method: String) {
            errors[method] = error
        }

        // MARK: - AIServiceProtocol Implementation

        func analyzeCode(_ code: String, language: String) async throws -> CodeAnalysis {
            recordCall("analyzeCode", parameters: ["codeLength": code.count, "language": language])

            if let error = errors["analyzeCode"] {
                throw error
            }

            if let response = responses["analyzeCode"] as? CodeAnalysis {
                return response
            }

            // Default mock response
            return CodeAnalysis(
                complexity: 5,
                issues: [],
                suggestions: ["Consider adding documentation"],
                estimatedTime: 30
            )
        }

        func generateCode(prompt: String, language: String, context: [String: Any]) async throws
            -> CodeGeneration
        {
            recordCall(
                "generateCode",
                parameters: ["prompt": prompt, "language": language, "context": context])

            if let error = errors["generateCode"] {
                throw error
            }

            if let response = responses["generateCode"] as? CodeGeneration {
                return response
            }

            // Default mock response
            return CodeGeneration(
                code: "// Generated code\nprint(\"Hello, World!\")",
                explanation: "Generated sample code",
                confidence: 0.8
            )
        }

        func reviewCode(_ code: String, language: String, criteria: [String]) async throws
            -> CodeReview
        {
            recordCall(
                "reviewCode",
                parameters: ["codeLength": code.count, "language": language, "criteria": criteria])

            if let error = errors["reviewCode"] {
                throw error
            }

            if let response = responses["reviewCode"] as? CodeReview {
                return response
            }

            // Default mock response
            return CodeReview(
                overallScore: 8,
                comments: ["Good code structure", "Consider adding error handling"],
                approved: true,
                suggestions: ["Add unit tests"]
            )
        }

        func optimizeCode(_ code: String, language: String, target: OptimizationTarget) async throws
            -> CodeOptimization
        {
            recordCall(
                "optimizeCode",
                parameters: ["codeLength": code.count, "language": language, "target": target])

            if let error = errors["optimizeCode"] {
                throw error
            }

            if let response = responses["optimizeCode"] as? CodeOptimization {
                return response
            }

            // Default mock response
            return CodeOptimization(
                optimizedCode: code,  // Return original for simplicity
                improvements: ["Code is already optimized"],
                performanceGain: 0.1,
                explanation: "No significant optimizations needed"
            )
        }

        func generateTests(for code: String, language: String) async throws -> TestGeneration {
            recordCall(
                "generateTests", parameters: ["codeLength": code.count, "language": language])

            if let error = errors["generateTests"] {
                throw error
            }

            if let response = responses["generateTests"] as? TestGeneration {
                return response
            }

            // Default mock response
            return TestGeneration(
                testCode: "// Generated tests\nfunc testExample() {\n    XCTAssertTrue(true)\n}",
                coverage: 0.85,
                testCases: ["testExample"]
            )
        }

        func reset() {
            responses.removeAll()
            errors.removeAll()
            callHistory.removeAll()
        }
    }

    /// Test case for AI service testing
    class AIServiceTestCase: SharedViewModelTestCase {
        var mockAIService: MockAIService!

        override func setupTestEnvironment() {
            super.setupTestEnvironment()
            self.mockAIService = MockAIService()
        }

        override func cleanupTestEnvironment() {
            self.mockAIService = nil
            super.cleanupTestEnvironment()
        }

        // MARK: - AI Service Testing Helpers

        func testAIServiceCall<T>(
            method: String,
            operation: @escaping () async throws -> T,
            expectedResult: T,
            timeout: TimeInterval = 5.0,
            file: StaticString = #file,
            line: UInt = #line
        ) async throws where T: Equatable & Sendable {
            let result = try await waitForAsync(timeout: timeout, operation: operation)

            XCTAssertEqual(result, expectedResult, file: file, line: line)
            XCTAssertTrue(
                mockAIService.callHistory.contains(where: { $0.contains(method) }),
                "Method \(method) was not called", file: file, line: line)
        }

        func testAIServiceError<T: Sendable>(
            method: String,
            operation: @escaping () async throws -> T,
            expectedError: Error,
            timeout: TimeInterval = 5.0,
            file: StaticString = #file,
            line: UInt = #line
        ) async {
            mockAIService.setError(expectedError, for: method)

            do {
                _ = try await waitForAsync(timeout: timeout, operation: operation)
                XCTFail(
                    "Expected error but operation completed successfully", file: file, line: line)
            } catch {
                // Error was thrown as expected
                XCTAssertTrue(
                    mockAIService.callHistory.contains(where: { $0.contains(method) }),
                    "Method \(method) was not called", file: file, line: line)
            }
        }

        func testAIServicePerformance<T: Sendable>(
            method: String,
            operation: @escaping () async throws -> T,
            maxDuration: TimeInterval = 2.0,
            file: StaticString = #file,
            line: UInt = #line
        ) async {
            await assertPerformance(
                operation: method,
                expectedDuration: maxDuration,
                operation,
                file: file,
                line: line
            )

            XCTAssertTrue(
                mockAIService.callHistory.contains(where: { $0.contains(method) }),
                "Method \(method) was not called", file: file, line: line)
        }
    }
}

// MARK: - AI Service Protocol (for testing)

/// Protocol defining AI service capabilities for testing
protocol AIServiceProtocol {
    func analyzeCode(_ code: String, language: String) async throws -> CodeAnalysis
    func generateCode(prompt: String, language: String, context: [String: Any]) async throws
        -> CodeGeneration
    func reviewCode(_ code: String, language: String, criteria: [String]) async throws -> CodeReview
    func optimizeCode(_ code: String, language: String, target: OptimizationTarget) async throws
        -> CodeOptimization
    func generateTests(for code: String, language: String) async throws -> TestGeneration
}

// MARK: - AI Service Response Types

struct CodeAnalysis {
    let complexity: Int
    let issues: [String]
    let suggestions: [String]
    let estimatedTime: TimeInterval
}

struct CodeGeneration {
    let code: String
    let explanation: String
    let confidence: Double
}

struct CodeReview {
    let overallScore: Int
    let comments: [String]
    let approved: Bool
    let suggestions: [String]
}

struct CodeOptimization {
    let optimizedCode: String
    let improvements: [String]
    let performanceGain: Double
    let explanation: String
}

struct TestGeneration {
    let testCode: String
    let coverage: Double
    let testCases: [String]
}

enum OptimizationTarget {
    case performance
    case memory
    case readability
    case maintainability
}

// MARK: - AI Integration Test Helpers

extension SharedViewModelTestCase {
    /// Test AI-powered view model functionality
    func testAIIntegration<T: BaseViewModel>(
        viewModel: T,
        aiAction: T.Action,
        mockService: AIServiceTestUtilities.MockAIService,
        expectedCalls: [String],
        timeout: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let initialCallCount = mockService.callHistory.count

        await viewModel.handle(aiAction)

        // Wait for AI operations to complete
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        let finalCallCount = mockService.callHistory.count
        XCTAssertGreaterThan(
            finalCallCount, initialCallCount, "AI service was not called", file: file, line: line)

        for expectedCall in expectedCalls {
            XCTAssertTrue(
                mockService.callHistory.contains(where: { $0.contains(expectedCall) }),
                "Expected AI call '\(expectedCall)' was not made", file: file, line: line)
        }
    }

    /// Test AI error handling in view models
    func testAIErrorHandling<T: BaseViewModel>(
        viewModel: T,
        aiAction: T.Action,
        mockService: AIServiceTestUtilities.MockAIService,
        errorMethod: String,
        expectedError: Error,
        timeout: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        mockService.setError(expectedError, for: errorMethod)

        XCTAssertNil(
            viewModel.errorMessage, "View model should not have error initially", file: file,
            line: line)

        await viewModel.handle(aiAction)

        // Wait for error handling
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        XCTAssertNotNil(
            viewModel.errorMessage, "Error message should be set after AI error", file: file,
            line: line)
        XCTAssertTrue(
            mockService.callHistory.contains(where: { $0.contains(errorMethod) }),
            "AI method '\(errorMethod)' was not called", file: file, line: line)
    }
}
