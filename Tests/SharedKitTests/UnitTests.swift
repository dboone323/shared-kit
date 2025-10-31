#if canImport(XCTest)
    import Foundation
    @testable import SharedKit
    import XCTest

    // MARK: - Unit Tests for Core Components

    class WorkflowIntelligenceAmplificationSystemTests: XCTestCase {
        var intelligenceSystem: WorkflowIntelligenceAmplificationSystem!
        var testWorkflow: MCPWorkflow!
        var testContext: WorkflowIntelligenceContext!

        override func setUp() async throws {
            intelligenceSystem = await MainActor.run { WorkflowIntelligenceAmplificationSystem() }
            testWorkflow = TestDataBuilder.createTestMCPWorkflow()
            testContext = WorkflowIntelligenceContext(
                expectedExecutionTime: 300.0,
                businessPriority: .high
            )
        }

        override func tearDown() async throws {
            intelligenceSystem = nil
            testWorkflow = nil
            testContext = nil
        }

        func testBasicWorkflowAmplification() async throws {
            // Given
            let workflow = testWorkflow!

            // When
            let result = try await intelligenceSystem!.amplifyWorkflowIntelligence(
                workflow,
                amplificationLevel: .basic,
                context: testContext!
            )

            // Then
            XCTAssertGreaterThan(result.decisionQuality, 0.0)
            XCTAssertGreaterThan(result.optimizationScore, 0.0)
            XCTAssertEqual(result.amplificationLevel, .basic)
            XCTAssertFalse(result.intelligenceInsights.isEmpty)
        }

        func testAdvancedWorkflowAmplification() async throws {
            // Given
            let workflow = testWorkflow!

            // When
            let result = try await intelligenceSystem!.amplifyWorkflowIntelligence(
                workflow,
                amplificationLevel: .advanced,
                context: testContext!
            )

            // Then
            XCTAssertGreaterThan(result.decisionQuality, 0.0)
            XCTAssertGreaterThan(result.optimizationScore, 0.0)
            XCTAssertEqual(result.amplificationLevel, .advanced)
            XCTAssertFalse(result.intelligenceInsights.isEmpty)
        }

        func testSystemMetricsTracking() async throws {
            // Given
            let initialMetrics = await intelligenceSystem!.getIntelligenceMetrics()

            // When
            _ = try await intelligenceSystem!.amplifyWorkflowIntelligence(
                testWorkflow!,
                amplificationLevel: .advanced,
                context: testContext!
            )

            let updatedMetrics = await intelligenceSystem!.getIntelligenceMetrics()

            // Then
            XCTAssertGreaterThanOrEqual(
                updatedMetrics.totalAmplifications, initialMetrics.totalAmplifications)
        }
    }

    // MARK: - Autonomous Workflow Evolution Tests

    class AutonomousWorkflowEvolutionSystemTests: XCTestCase {
        var evolutionSystem: AutonomousWorkflowEvolutionSystem!
        var testWorkflow: MCPWorkflow!

        override func setUp() async throws {
            evolutionSystem = await MainActor.run { AutonomousWorkflowEvolutionSystem() }
            testWorkflow = TestDataBuilder.createTestMCPWorkflow()
        }

        override func tearDown() async throws {
            evolutionSystem = nil
            testWorkflow = nil
        }

        func testWorkflowEvolution() async throws {
            // Given
            let workflow = testWorkflow!

            // When
            let evolvedWorkflow = try await evolutionSystem!.evolveWorkflow(
                workflow,
                evolutionType: "parallel_optimization",
                parameters: [:],
                priority: .high
            )

            // Then
            XCTAssertEqual(evolvedWorkflow.id, workflow.id)
            XCTAssertFalse(evolvedWorkflow.steps.isEmpty)
        }

        func testEvolutionRecommendations() async throws {
            // Given - create a workflow that should trigger recommendations
            let complexWorkflow = TestDataBuilder.createComplexTestWorkflow()

            // When
            let recommendations = await evolutionSystem!.getEvolutionRecommendations(
                for: complexWorkflow)

            // Then
            XCTAssertFalse(
                recommendations.isEmpty, "Complex workflow should generate recommendations")
        }

        func testQuantumSuperposition() async throws {
            // Given
            let workflow = testWorkflow!

            // When
            let superposition = await evolutionSystem!.implementQuantumSuperposition(for: workflow)

            // Then
            XCTAssertEqual(superposition.workflowId, workflow.id)
            XCTAssertFalse(superposition.possibleConfigurations.isEmpty)
            XCTAssertFalse(superposition.probabilityAmplitudes.isEmpty)
        }
    }

#endif

// MARK: - Test Data Builders

enum TestDataBuilder {
    static func createTestMCPWorkflow(name: String = "Test Workflow") -> MCPWorkflow {
        let step1 = MCPWorkflowStep(
            id: UUID(),
            toolId: "test-tool-1",
            parameters: ["action": AnyCodable("test")],
            dependencies: [],
            executionMode: .sequential,
            retryPolicy: MCPRetryPolicy(maxAttempts: 3, backoffStrategy: .exponential),
            timeout: 30.0,
            metadata: nil
        )

        let step2 = MCPWorkflowStep(
            id: UUID(),
            toolId: "test-tool-2",
            parameters: ["condition": AnyCodable("test")],
            dependencies: [step1.id],
            executionMode: .sequential,
            retryPolicy: MCPRetryPolicy(maxAttempts: 2, backoffStrategy: .exponential),
            timeout: 15.0,
            metadata: nil
        )

        return MCPWorkflow(
            id: UUID(),
            name: name,
            description: "Test workflow for quantum intelligence",
            steps: [step1, step2],
            metadata: [
                "created": AnyCodable(Date().ISO8601Format()),
                "version": AnyCodable("1.0"),
                "priority": AnyCodable("high"),
            ]
        )
    }

    static func createComplexTestWorkflow() -> MCPWorkflow {
        var steps: [MCPWorkflowStep] = []

        // Create 5 steps with complex dependencies to trigger recommendations
        for i in 0..<5 {
            let step = MCPWorkflowStep(
                id: UUID(),
                toolId: "test-tool-\(i)",
                parameters: ["action": AnyCodable("step\(i)")],
                dependencies: i > 0 ? [steps[i - 1].id] : [],  // Chain dependencies
                executionMode: .sequential,  // No parallel execution
                retryPolicy: MCPRetryPolicy(maxAttempts: 3, backoffStrategy: .exponential),
                timeout: 30.0,
                metadata: nil
            )
            steps.append(step)
        }

        return MCPWorkflow(
            id: UUID(),
            name: "Complex Test Workflow",
            description: "Complex workflow with chained dependencies",
            steps: steps,
            metadata: [
                "created": AnyCodable(Date().ISO8601Format()),
                "version": AnyCodable("1.0"),
                "priority": AnyCodable("high"),
            ]
        )
    }
}
