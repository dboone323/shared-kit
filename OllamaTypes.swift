import Foundation

// MARK: - Ollama Types

public struct OllamaConfig {
    public let baseURL: String
    public let defaultModel: String
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let temperature: Double
    public let maxTokens: Int

    public init(
        baseURL: String = "http://localhost:11434",
        defaultModel: String = "llama2",
        timeout: TimeInterval = 60.0,
        maxRetries: Int = 3,
        temperature: Double = 0.7,
        maxTokens: Int = 2048
    ) {
        self.baseURL = baseURL
        self.defaultModel = defaultModel
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    public static let `default` = OllamaConfig()
    public static let codeGeneration = OllamaConfig(defaultModel: "codellama", temperature: 0.2, maxTokens: 4096)
    public static let analysis = OllamaConfig(defaultModel: "llama2", temperature: 0.3, maxTokens: 2048)
    public static let creative = OllamaConfig(defaultModel: "llama2", temperature: 0.8, maxTokens: 1024)
}

public struct OllamaMessage: Codable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct OllamaGenerateResponse: Codable {
    public let model: String
    public let created_at: String
    public let response: String
    public let done: Bool
    public let context: [Int]?
    public let total_duration: Int?
    public let load_duration: Int?
    public let prompt_eval_count: Int?
    public let prompt_eval_duration: Int?
    public let eval_count: Int?
    public let eval_duration: Int?
}

public struct OllamaServerStatus {
    public let running: Bool
    public let modelCount: Int
    public let models: [String]
}

public enum OllamaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case httpError(Int)
    case modelPullFailed
    case serverNotRunning
    case modelNotAvailable(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid Ollama server URL"
        case .invalidResponse:
            "Invalid response from Ollama server"
        case let .httpError(code):
            "HTTP error: \(code)"
        case .invalidResponseFormat:
            "Invalid response format from Ollama"
        case .modelPullFailed:
            "Failed to pull model from Ollama"
        case .serverNotRunning:
            "Ollama server is not running"
        case let .modelNotAvailable(model):
            "Model '\(model)' is not available"
        }
    }
}

// MARK: - Integration Types

public struct ServiceHealth {
    public let ollamaRunning: Bool
    public let modelsAvailable: Bool
    public let modelCount: Int
    public let recommendedActions: [String]
}

public enum CodeComplexity {
    case simple
    case standard
    case advanced

    var temperature: Double {
        switch self {
        case .simple: 0.1
        case .standard: 0.3
        case .advanced: 0.5
        }
    }

    var maxTokens: Int {
        switch self {
        case .simple: 1000
        case .standard: 2000
        case .advanced: 4000
        }
    }
}

public enum AnalysisType {
    case bugs
    case performance
    case security
    case comprehensive
}

public struct CodeGenerationResult {
    public let code: String
    public let analysis: String
    public let language: String
    public let complexity: CodeComplexity
}

public struct CodeAnalysisResult {
    public let analysis: String
    public let issues: [CodeIssue]
    public let suggestions: [String]
    public let language: String
    public let analysisType: AnalysisType
}

public struct CodeIssue {
    public let description: String
    public let severity: IssueSeverity
}

public enum IssueSeverity {
    case low
    case medium
    case high
    case critical
}

public struct DocumentationResult {
    public let documentation: String
    public let language: String
    public let includesExamples: Bool
}

public struct TestGenerationResult {
    public let testCode: String
    public let language: String
    public let testFramework: String
    public let coverage: Double
}

public struct AutomationTask {
    public let id: String
    public let type: TaskType
    public let description: String
    public let language: String?
    public let code: String?

    public enum TaskType {
        case codeGeneration
        case codeAnalysis
        case documentation
        case testing
    }
}

public struct TaskResult {
    public let task: AutomationTask
    public let success: Bool
    public let error: Error?
    public let codeGenerationResult: CodeGenerationResult?
    public let analysisResult: CodeAnalysisResult?
    public let documentationResult: DocumentationResult?
    public let testResult: TestGenerationResult?

    public init(
        task: AutomationTask,
        success: Bool,
        error: Error? = nil,
        codeGenerationResult: CodeGenerationResult? = nil,
        analysisResult: CodeAnalysisResult? = nil,
        documentationResult: DocumentationResult? = nil,
        testResult: TestGenerationResult? = nil
    ) {
        self.task = task
        self.success = success
        self.error = error
        self.codeGenerationResult = codeGenerationResult
        self.analysisResult = analysisResult
        self.documentationResult = documentationResult
        self.testResult = testResult
    }
}

public enum IntegrationError: Error {
    case missingRequiredData(String)
    case serviceUnavailable
    case invalidConfiguration
}
