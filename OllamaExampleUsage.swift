#!/usr/bin/env swift

import Foundation

// MARK: - Ollama Integration Framework Types (Embedded for Example)

// Note: In a real project, you would import these from OllamaIntegrationFramework
// For this example, we'll define the essential types here

enum CodeComplexity {
    case simple, standard, complex
}

enum AnalysisType {
    case basic, comprehensive
}

enum AutomationTaskType {
    case codeGeneration, codeAnalysis, documentation
}

struct AutomationTask {
    let id: String
    let type: AutomationTaskType
    let description: String
    let language: String
}

struct CodeGenerationResult {
    let code: String
    let analysis: String
    let language: String
}

struct CodeAnalysisResult {
    let analysis: String
    let issues: [CodeIssue]
    let suggestions: [String]
}

struct CodeIssue {
    let description: String
    let severity: String
}

struct DocumentationResult {
    let documentation: String
}

struct BatchTaskResult {
    let task: AutomationTask
    let success: Bool
    let codeGenerationResult: CodeGenerationResult?
    let error: Error?
}

struct ServiceHealth {
    let ollamaRunning: Bool
    let modelsAvailable: [String]
}

// MARK: - Ollama Integration Manager (Simplified for Example)

class OllamaIntegrationManager {
    private let baseURL = "http://localhost:11434"

    func checkServiceHealth() async -> ServiceHealth {
        // Simplified health check
        ServiceHealth(ollamaRunning: true, modelsAvailable: ["llama2", "codellama"])
    }

    func generateCode(description: String, language: String, complexity: CodeComplexity) async throws -> CodeGenerationResult {
        // Simplified code generation - using the description for generation
        let code = "// Generated \(language) code for: \(description)\n// This is a placeholder implementation\n\nfunc example() {\n    print(\"Hello, World!\")\n}"

        return CodeGenerationResult(
            code: code,
            analysis: "Generated basic \(language) code structure for: \(description)",
            language: language
        )
    }

    func analyzeCodebase(code: String, language: String, analysisType: AnalysisType) async throws -> CodeAnalysisResult {
        // Simplified analysis
        CodeAnalysisResult(
            analysis: "Code analysis for \(language): \(code.count) characters",
            issues: [],
            suggestions: ["Consider adding error handling", "Add documentation"]
        )
    }

    func generateDocumentation(code: String, language: String, includeExamples: Bool) async throws -> DocumentationResult {
        // Simplified documentation
        let docs = """
        /// Documentation for the provided \(language) code
        ///
        /// This code contains \(code.count) characters and appears to be a \(language) implementation.
        /// Key features: Basic functionality with room for enhancement.
        """

        return DocumentationResult(documentation: docs)
    }

    func processBatchTasks(_ tasks: [AutomationTask]) async throws -> [BatchTaskResult] {
        // Simplified batch processing
        tasks.map { task in
            BatchTaskResult(
                task: task,
                success: true,
                codeGenerationResult: CodeGenerationResult(
                    code: "// Generated code for task: \(task.description)",
                    analysis: "Task completed successfully",
                    language: task.language
                ),
                error: nil
            )
        }
    }

    func quickCodeGeneration(description: String, language: String) async throws -> String {
        let result = try await generateCode(description: description, language: language, complexity: .simple)
        return result.code
    }

    func quickAnalysis(code: String, language: String) async throws -> String {
        let result = try await analyzeCodebase(code: code, language: language, analysisType: .basic)
        return result.analysis
    }
}

// MARK: - Example Usage Functions

// Example 1: Basic Code Generation
func exampleCodeGeneration() async {
    print("=== Code Generation Example ===")

    let manager = OllamaIntegrationManager()

    do {
        // Check if Ollama is running and models are available
        let health = await manager.checkServiceHealth()
        print("Ollama Status: Running=\(health.ollamaRunning), Models=\(health.modelsAvailable)")

        if !health.ollamaRunning {
            print("Please start Ollama server: ollama serve")
            return
        }

        // Generate Swift code for a simple calculator
        let result = try await manager.generateCode(
            description: "Create a Swift class for a basic calculator with add, subtract, multiply, and divide operations",
            language: "Swift",
            complexity: .standard
        )

        print("Generated Code:")
        print(result.code)
        print("\nAnalysis:")
        print(result.analysis)

    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Example 2: Code Analysis
func exampleCodeAnalysis() async {
    print("\n=== Code Analysis Example ===")

    let manager = OllamaIntegrationManager()

    let sampleCode = """
    func calculateTotal(items: [Double]) -> Double {
        var total = 0.0
        for item in items {
            total = total + item
        }
        return total
    }
    """

    do {
        let result = try await manager.analyzeCodebase(
            code: sampleCode,
            language: "Swift",
            analysisType: .comprehensive
        )

        print("Analysis Result:")
        print(result.analysis)

        print("\nIssues Found:")
        for issue in result.issues {
            print("- \(issue.description) (Severity: \(issue.severity))")
        }

        print("\nSuggestions:")
        for suggestion in result.suggestions {
            print("- \(suggestion)")
        }

    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Example 3: Documentation Generation
func exampleDocumentation() async {
    print("\n=== Documentation Generation Example ===")

    let manager = OllamaIntegrationManager()

    let sampleCode = """
    struct User {
        let id: Int
        let name: String
        let email: String

        init(id: Int, name: String, email: String) {
            self.id = id
            self.name = name
            self.email = email
        }

        func displayName() -> String {
            return name.capitalized
        }
    }
    """

    do {
        let result = try await manager.generateDocumentation(
            code: sampleCode,
            language: "Swift",
            includeExamples: true
        )

        print("Generated Documentation:")
        print(result.documentation)

    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Example 4: Batch Processing
func exampleBatchProcessing() async {
    print("\n=== Batch Processing Example ===")

    let manager = OllamaIntegrationManager()

    let tasks = [
        AutomationTask(
            id: "task1",
            type: .codeGeneration,
            description: "Create a Swift function to validate email addresses",
            language: "Swift"
        ),
        AutomationTask(
            id: "task2",
            type: .codeGeneration,
            description: "Generate a Python script to read CSV files",
            language: "Python"
        ),
    ]

    do {
        let results = try await manager.processBatchTasks(tasks)

        for result in results {
            print("Task \(result.task.id): \(result.success ? "SUCCESS" : "FAILED")")
            if let codeResult = result.codeGenerationResult {
                print("Generated code length: \(codeResult.code.count) characters")
            }
            if let error = result.error {
                print("Error: \(error.localizedDescription)")
            }
        }

    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// Example 5: Quick Operations
func exampleQuickOperations() async {
    print("\n=== Quick Operations Example ===")

    let manager = OllamaIntegrationManager()

    do {
        // Quick code generation
        let code = try await manager.quickCodeGeneration(
            description: "Swift function to check if a string is palindrome",
            language: "Swift"
        )
        print("Quick Generated Code:")
        print(code)

        // Quick analysis
        let analysis = try await manager.quickAnalysis(
            code: "func test() { print('hello') }",
            language: "Swift"
        )
        print("\nQuick Analysis:")
        print(analysis.prefix(200) + "...")

    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// MARK: - Main Execution

func runExamples() async {
    print("🚀 Ollama Integration Framework Examples")
    print("=======================================")

    // Run examples
    await exampleCodeGeneration()
    await exampleCodeAnalysis()
    await exampleDocumentation()
    await exampleBatchProcessing()
    await exampleQuickOperations()

    print("\n✅ Examples completed!")
    print("\nTo use this framework in your projects:")
    print("1. Import OllamaIntegrationFramework")
    print("2. Create OllamaIntegrationManager() instance")
    print("3. Use async methods for AI-powered operations")
    print("4. Handle errors appropriately")
}

// Run the examples
await runExamples()
