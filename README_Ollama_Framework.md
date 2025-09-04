# Ollama Integration Framework

A comprehensive Swift framework for integrating free Ollama AI models into your development workflows, providing AI-powered code generation, analysis, documentation, and automation capabilities.

## 🚀 Features

- **Free AI Integration**: Uses local Ollama models instead of paid APIs
- **Code Generation**: Generate code in multiple languages with context-aware prompts
- **Code Analysis**: Intelligent analysis of codebases with issue detection
- **Documentation Generation**: Automated documentation creation
- **Batch Processing**: Process multiple tasks efficiently
- **Health Monitoring**: Service health checks and status monitoring
- **Error Handling**: Comprehensive error handling and recovery
- **Swift Concurrency**: Built with async/await for modern Swift development

## 📦 Installation

1. **Install Ollama**: Download and install Ollama from [ollama.ai](https://ollama.ai)
2. **Start Ollama Service**: Run `ollama serve` in your terminal
3. **Pull Models**: Download the models you want to use:
   ```bash
   ollama pull llama2
   ollama pull codellama
   ```
4. **Add Framework**: Copy `OllamaIntegrationFramework.swift` to your project

## 🛠️ Usage

### Basic Setup

```swift
import Foundation

// Create integration manager
let manager = OllamaIntegrationManager()

// Check if Ollama is running
let health = await manager.checkServiceHealth()
if health.ollamaRunning {
    print("Ollama is ready with models: \(health.modelsAvailable)")
}
```

### Code Generation

```swift
// Generate Swift code
let result = try await manager.generateCode(
    description: "Create a Swift struct for user authentication",
    language: "Swift",
    complexity: .standard
)

print("Generated Code:")
print(result.code)
print("\nAnalysis:")
print(result.analysis)
```

### Code Analysis

```swift
// Analyze existing code
let analysis = try await manager.analyzeCodebase(
    code: yourCodeString,
    language: "Swift",
    analysisType: .comprehensive
)

print("Issues found: \(analysis.issues.count)")
for suggestion in analysis.suggestions {
    print("- \(suggestion)")
}
```

### Documentation Generation

```swift
// Generate documentation
let docs = try await manager.generateDocumentation(
    code: yourCodeString,
    language: "Swift",
    includeExamples: true
)

print(docs.documentation)
```

### Batch Processing

```swift
// Process multiple tasks
let tasks = [
    AutomationTask(
        id: "task1",
        type: .codeGeneration,
        description: "Create email validation function",
        language: "Swift"
    ),
    AutomationTask(
        id: "task2",
        type: .documentation,
        description: "Document user management API",
        language: "Swift"
    )
]

let results = try await manager.processBatchTasks(tasks)
for result in results {
    print("Task \(result.task.id): \(result.success ? "✅" : "❌")")
}
```

### Quick Operations

```swift
// Quick code generation
let code = try await manager.quickCodeGeneration(
    description: "Swift function to reverse a string",
    language: "Swift"
)

// Quick analysis
let analysis = try await manager.quickAnalysis(
    code: yourCode,
    language: "Swift"
)
```

## 🔧 Integration with Automation Scripts

The framework is designed to work seamlessly with bash automation scripts:

```bash
#!/bin/bash
# Example integration with agent_codegen.sh

swift run OllamaIntegrationFramework generate \
    --description "Create unit tests for user authentication" \
    --language Swift \
    --output generated_tests.swift
```

## 📋 Supported Models

- **llama2**: General purpose conversations and code understanding
- **codellama**: Specialized for code generation and analysis
- **mistral**: Fast inference with good code capabilities
- **phi**: Lightweight model for basic code tasks

## ⚡ Performance Tips

1. **Model Selection**: Choose appropriate models for your use case
2. **Batch Processing**: Use batch operations for multiple similar tasks
3. **Caching**: Cache results for frequently requested operations
4. **Health Checks**: Monitor service health before operations
5. **Error Handling**: Implement proper error handling and retries

## 🐛 Troubleshooting

### Common Issues

1. **"Ollama not running"**: Make sure to start Ollama with `ollama serve`
2. **"Model not found"**: Pull the required model with `ollama pull <model-name>`
3. **Network timeouts**: Increase timeout values for complex operations
4. **Memory issues**: Use smaller models or reduce batch sizes

### Health Check

```swift
let health = await manager.checkServiceHealth()
if !health.ollamaRunning {
    print("Start Ollama: ollama serve")
}
if health.modelsAvailable.isEmpty {
    print("Pull models: ollama pull llama2")
}
```

## 📚 Examples

See `OllamaExampleUsage.swift` for comprehensive examples of all framework features.

## 🤝 Contributing

1. Test with different Ollama models
2. Add support for new languages
3. Improve error handling
4. Add performance optimizations
5. Create integration examples

## 📄 License

This framework is provided as-is for educational and development purposes. Ensure compliance with Ollama's licensing terms when using their models.

---

**Note**: This framework provides a free alternative to paid AI services by leveraging local Ollama models. All AI processing happens locally on your machine, ensuring privacy and cost-effectiveness.
