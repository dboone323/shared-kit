//
//  OllamaWorkflowDemo.swift
//  Quantum-workspace
//
//  Created: Phase 9B - Ollama Workflow Integration Demo
//  Purpose: Demonstrate the complete Ollama-powered local AI workflow system
//

import Combine
import Foundation

/// Demonstration of the complete Ollama Workflow Integration System
/// Shows how to use all components together for autonomous AI workflows
@MainActor
public final class OllamaWorkflowDemo {
    private let workflowOrchestrator: OllamaWorkflowOrchestrator
    private let integrationManager: OllamaIntegrationManager
    private let client: OllamaClient

    public init() {
        self.workflowOrchestrator = OllamaWorkflowOrchestrator()
        self.integrationManager = OllamaIntegrationManager()
        self.client = OllamaClient()
    }

    /// Run the complete workflow demonstration
    public func runCompleteDemo() async throws {
        print("🚀 Starting Phase 9B Ollama Workflow Integration Demo")
        print("=" * 60)

        // 1. Health Check
        await runHealthCheckDemo()

        // 2. Basic Generation Demo
        await runBasicGenerationDemo()

        // 3. Workflow Orchestration Demo
        try await runWorkflowOrchestrationDemo()

        // 4. Code Generation Pipeline Demo
        try await runCodeGenerationPipelineDemo()

        // 5. Multi-Agent Coordination Demo
        try await runMultiAgentCoordinationDemo()

        print("\n✅ Phase 9B Demo Complete!")
        print("🎯 Ollama Workflow Integration successfully demonstrated")
    }

    // MARK: - Demo Components

    private func runHealthCheckDemo() async {
        print("\n🏥 Health Check Demo")
        print("-" * 30)

        let health = await integrationManager.getHealthStatus()
        print("Ollama Server: \(health.isRunning ? "✅ Running" : "❌ Not Running")")
        print("Models Available: \(health.modelsAvailable ? "✅ Yes" : "❌ No")")
        print("Model Count: \(health.modelCount)")
        print("Response Time: \(String(format: "%.2f", health.responseTime))s")

        if !health.recommendedActions.isEmpty {
            print("Recommended Actions:")
            health.recommendedActions.forEach { print("  • \($0)") }
        }
    }

    private func runBasicGenerationDemo() async {
        print("\n🤖 Basic Generation Demo")
        print("-" * 30)

        do {
            let prompt = "Explain quantum computing in simple terms"
            let response = try await integrationManager.generateText(
                prompt: prompt,
                maxTokens: 200,
                temperature: 0.7
            )

            print("Prompt: \(prompt)")
            print("Response: \(response.prefix(150))...")
            print("✅ Generation successful")

        } catch {
            print("❌ Generation failed: \(error.localizedDescription)")
        }
    }

    private func runWorkflowOrchestrationDemo() async throws {
        print("\n⚙️ Workflow Orchestration Demo")
        print("-" * 35)

        // Create a simple workflow
        let workflow = workflowOrchestrator.createWorkflow(
            name: "Code Review Workflow",
            steps: [
                WorkflowStep(
                    name: "analyze_code",
                    type: .textGeneration,
                    model: "llama2",
                    prompt: "Analyze this Swift code for potential issues: {{code}}",
                    outputKey: "analysis"
                ),
                WorkflowStep(
                    name: "generate_fixes",
                    type: .textGeneration,
                    model: "codellama",
                    prompt: "Based on this analysis, suggest fixes: {{analysis}}",
                    dependencies: [UUID(uuidString: "00000000-0000-0000-0000-000000000001")!],
                    outputKey: "fixes"
                ),
            ]
        )

        // Sample code to analyze
        let sampleCode = """
        func calculateTotal(items: [Double]) -> Double {
            var total = 0.0
            for item in items {
                total += item
            }
            return total
        }
        """

        // Execute workflow
        let inputs = ["code": sampleCode]
        let result = try await workflowOrchestrator.executeWorkflow(workflow)

        print("Workflow: \(workflow.name)")
        print("Steps: \(workflow.steps.count)")
        print("Success: \(result.success)")
        print("Execution Time: \(String(format: "%.2f", result.executionTime))s")

        if let analysis = result.outputs["analysis"] as? String {
            print("Analysis: \(analysis.prefix(100))...")
        }

        if let fixes = result.outputs["fixes"] as? String {
            print("Fixes: \(fixes.prefix(100))...")
        }
    }

    private func runCodeGenerationPipelineDemo() async throws {
        print("\n💻 Code Generation Pipeline Demo")
        print("-" * 40)

        let description = "Create a Swift function that validates email addresses using regex"
        let language = "Swift"

        let result = try await integrationManager.generateCode(
            description: description,
            language: language
        )

        print("Description: \(description)")
        print("Language: \(language)")
        print("Generated Code:")
        print(result.code)
        print("✅ Code generation successful")
    }

    private func runMultiAgentCoordinationDemo() async throws {
        print("\n🤝 Multi-Agent Coordination Demo")
        print("-" * 40)

        // This would integrate with the MultiAgentCoordinationSystem
        // For now, demonstrate parallel workflow execution

        let workflow1 = workflowOrchestrator.createWorkflow(
            name: "Documentation Workflow",
            steps: [
                WorkflowStep(
                    name: "generate_docs",
                    type: .textGeneration,
                    model: "llama2",
                    prompt: "Generate documentation for: {{code}}",
                    outputKey: "documentation"
                ),
            ]
        )

        let workflow2 = workflowOrchestrator.createWorkflow(
            name: "Testing Workflow",
            steps: [
                WorkflowStep(
                    name: "generate_tests",
                    type: .textGeneration,
                    model: "codellama",
                    prompt: "Generate unit tests for: {{code}}",
                    outputKey: "tests"
                ),
            ]
        )

        let sampleCode = """
        struct User {
            let id: Int
            let name: String
            let email: String
        }
        """

        // Execute both workflows in parallel
        async let result1 = workflowOrchestrator.executeWorkflow(workflow1)
        async let result2 = workflowOrchestrator.executeWorkflow(workflow2)

        let (r1, r2) = try await (result1, result2)

        print("Workflow 1 (\(workflow1.name)): \(r1.success ? "✅" : "❌")")
        print("Workflow 2 (\(workflow2.name)): \(r2.success ? "✅" : "❌")")
        print("✅ Parallel execution demonstrated")
    }

    // MARK: - Advanced Features Demo

    public func demonstrateAdvancedFeatures() async throws {
        print("\n🔬 Advanced Features Demo")
        print("-" * 30)

        // 1. Caching demonstration
        await demonstrateCaching()

        // 2. Fallback mechanisms
        await demonstrateFallback()

        // 3. Performance monitoring
        await demonstratePerformanceMonitoring()

        // 4. Batch processing
        try await demonstrateBatchProcessing()
    }

    private func demonstrateCaching() async {
        print("📦 Caching Demo:")

        let prompt = "What is the capital of France?"
        let startTime = Date()

        // First request (should cache)
        _ = try? await integrationManager.generateText(prompt: prompt, maxTokens: 50)
        let firstDuration = Date().timeIntervalSince(startTime)

        // Second request (should use cache)
        _ = try? await integrationManager.generateText(prompt: prompt, maxTokens: 50)
        let secondDuration = Date().timeIntervalSince(startTime) - firstDuration

        print("  First request: \(String(format: "%.2f", firstDuration))s")
        print("  Second request: \(String(format: "%.2f", secondDuration))s")
        print("  Cache speedup: \(String(format: "%.1fx", firstDuration / secondDuration))x")
    }

    private func demonstrateFallback() async {
        print("🔄 Fallback Demo:")

        // Force a failure scenario to test fallback
        let status = await integrationManager.getServiceStatus()
        print("  Ollama: \(status.ollama ? "✅" : "❌")")
        print("  Hugging Face: \(status.huggingFace ? "✅" : "❌")")
        print("  Any Available: \(status.anyAvailable ? "✅" : "❌")")
    }

    private func demonstratePerformanceMonitoring() async {
        print("📊 Performance Monitoring Demo:")

        let metrics = await integrationManager.getPerformanceMetrics()
        print("  Total Operations: \(metrics.totalOperations)")
        print("  Success Rate: \(String(format: "%.1f%%", metrics.successRate * 100))")
        print("  Average Response Time: \(String(format: "%.2f", metrics.averageResponseTime))s")
    }

    private func demonstrateBatchProcessing() async throws {
        print("📋 Batch Processing Demo:")

        let tasks = [
            AutomationTask(
                id: "task1",
                type: .codeGeneration,
                description: "Create a Swift struct for User data",
                language: "Swift"
            ),
            AutomationTask(
                id: "task2",
                type: .documentation,
                description: "Document a simple function",
                language: "Swift",
                code: "func hello() { print(\"Hello\") }"
            ),
        ]

        let results = try await integrationManager.processBatchTasks(tasks)
        print("  Processed \(results.count) tasks")
        let successCount = results.filter(\.success).count
        print("  Success Rate: \(successCount)/\(results.count)")
    }
}

// MARK: - Helper Extensions

extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}

// MARK: - Demo Runner

/// Main demo runner for easy execution
public func runOllamaWorkflowDemo() async {
    let demo = OllamaWorkflowDemo()

    do {
        try await demo.runCompleteDemo()
        try await demo.demonstrateAdvancedFeatures()
    } catch {
        print("❌ Demo failed: \(error.localizedDescription)")
    }
}

// MARK: - Usage Examples

/// Example usage patterns for the Ollama Workflow Integration
public enum OllamaWorkflowExamples {

    /// Basic text generation example
    public static func basicGenerationExample() async throws -> String {
        let manager = OllamaIntegrationManager()
        return try await manager.generateText(
            prompt: "Explain machine learning in 100 words",
            maxTokens: 150,
            temperature: 0.7
        )
    }

    /// Code analysis workflow example
    public static func codeAnalysisWorkflowExample() async throws -> CodeAnalysisResult {
        let manager = OllamaIntegrationManager()

        let sampleCode = """
        func fetchUser(id: Int) async throws -> User {
            let url = URL(string: "https://api.example.com/users/\(id)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(User.self, from: data)
        }
        """

        return try await manager.analyzeCode(
            code: sampleCode,
            language: "Swift",
            analysisType: .comprehensive
        )
    }

    /// Complete development workflow example
    public static func completeDevelopmentWorkflow() async throws {
        let manager = OllamaIntegrationManager()

        // 1. Generate code
        let codeResult = try await manager.generateCode(
            description: "Create a Swift protocol for data validation",
            language: "Swift"
        )

        print("Generated Code:")
        print(codeResult.code)

        // 2. Analyze the generated code
        let analysis = try await manager.analyzeCode(
            code: codeResult.code,
            language: "Swift",
            analysisType: .comprehensive
        )

        print("\nAnalysis:")
        print(analysis.analysis)

        // 3. Generate documentation
        let docs = try await manager.generateDocumentation(
            code: codeResult.code,
            language: "Swift"
        )

        print("\nDocumentation:")
        print(docs.documentation)

        // 4. Generate tests
        let tests = try await manager.generateTests(
            code: codeResult.code,
            language: "Swift"
        )

        print("\nTests:")
        print(tests.testCode)
    }
}
