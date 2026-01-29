import Foundation

// MARK: - Example Usage Functions

// Example 1: Basic Code Generation
func exampleCodeGeneration() async {
    print("=== Code Generation Example ===")

    let manager = OllamaIntegrationManager()

    do {
        // Check if Ollama is running and models are available
        let health = await manager.checkServiceHealth()
        print(
            "Ollama Status: running=\(health.ollamaRunning), modelsAvailable=\(health.modelsAvailable), modelCount=\(health.modelCount)"
        )

        if !health.recommendedActions.isEmpty {
            print("Recommended actions: \(health.recommendedActions.joined(separator: ", "))")
        }

        guard health.ollamaRunning else {
            print("Please start Ollama server: ollama serve")
            return
        }

        // Generate Swift code for a simple calculator
        let result = try await manager.generateCode(
            description:
            "Create a Swift class for a basic calculator with add, subtract, multiply, and divide operations",
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
            print("- \(issue.description) (Severity: \(String(describing: issue.severity)))")
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
        let preview = String(analysis.prefix(200))
        let suffix = analysis.count > 200 ? "..." : ""
        print(preview + suffix)

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

// Note: This file provides example functions only. Intentionally no top-level execution
// to keep Shared building as a library. Call `runExamples()` from an app target or test.
