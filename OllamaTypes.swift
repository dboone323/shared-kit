import Foundation

// MARK: - Core Ollama Configuration & Types

public struct OllamaConfig {
    public let baseURL: String
    public let defaultModel: String
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let temperature: Double
    public let maxTokens: Int
    public let enableCaching: Bool
    public let cacheExpiryTime: TimeInterval
    public let enableMetrics: Bool
    public let enableAutoModelDownload: Bool
    public let fallbackModels: [String]
    public let requestThrottleDelay: TimeInterval
    public let enableCloudModels: Bool
    public let cloudEndpoint: String
    public let preferCloudModels: Bool

    public init(
        baseURL: String = "http://localhost:11434",
        defaultModel: String = "llama2",
        timeout: TimeInterval = 60.0,
        maxRetries: Int = 3,
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        enableCaching: Bool = true,
        cacheExpiryTime: TimeInterval = 3600,
        enableMetrics: Bool = true,
        enableAutoModelDownload: Bool = true,
        fallbackModels: [String] = ["llama2", "phi3"],
        requestThrottleDelay: TimeInterval = 0.1,
        enableCloudModels: Bool = true,
        cloudEndpoint: String = "https://ollama.com",
        preferCloudModels: Bool = false
    ) {
        self.baseURL = baseURL
        self.defaultModel = defaultModel
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.enableCaching = enableCaching
        self.cacheExpiryTime = cacheExpiryTime
        self.enableMetrics = enableMetrics
        self.enableAutoModelDownload = enableAutoModelDownload
        self.fallbackModels = fallbackModels
        self.requestThrottleDelay = requestThrottleDelay
        self.enableCloudModels = enableCloudModels
        self.cloudEndpoint = cloudEndpoint
        self.preferCloudModels = preferCloudModels
    }

    public static let `default` = OllamaConfig()
    public static let codeGeneration = OllamaConfig(
        defaultModel: "codellama",
        temperature: 0.2,
        maxTokens: 4096,
        fallbackModels: ["codellama", "llama2"]
    )
    public static let analysis = OllamaConfig(
        defaultModel: "llama2",
        temperature: 0.3,
        maxTokens: 2048,
        fallbackModels: ["llama2", "phi3"]
    )
    public static let creative = OllamaConfig(
        defaultModel: "llama2",
        temperature: 0.8,
        maxTokens: 1024
    )
    public static let quantumPerformance = OllamaConfig(
        defaultModel: "phi3",
        temperature: 0.1,
        maxTokens: 8192,
        cacheExpiryTime: 7200,
        fallbackModels: ["phi3", "llama2", "codellama"],
        requestThrottleDelay: 0.05
    )

    // Cloud presets
    public static let cloudCoder = OllamaConfig(
        defaultModel: "qwen3-coder:480b-cloud",
        temperature: 0.2,
        maxTokens: 8192,
        fallbackModels: ["qwen3-coder:480b-cloud", "gpt-oss:120b-cloud", "codellama"],
        enableCloudModels: true,
        preferCloudModels: true
    )

    public static let cloudAdvanced = OllamaConfig(
        defaultModel: "deepseek-v3.1:671b-cloud",
        temperature: 0.3,
        maxTokens: 16384,
        fallbackModels: ["deepseek-v3.1:671b-cloud", "gpt-oss:120b-cloud", "qwen3-coder:480b-cloud"],
        enableCloudModels: true,
        preferCloudModels: true
    )

    public static let cloudGeneral = OllamaConfig(
        defaultModel: "gpt-oss:120b-cloud",
        temperature: 0.7,
        maxTokens: 4096,
        fallbackModels: ["gpt-oss:120b-cloud", "gpt-oss:20b-cloud", "llama2"],
        enableCloudModels: true,
        preferCloudModels: true
    )
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
    case networkTimeout
    case rateLimitExceeded
    case cacheError
    case modelLoadFailed(String)
    case contextWindowExceeded
    case authenticationFailed
    case serverOverloaded

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
        case .networkTimeout:
            "Network request timed out"
        case .rateLimitExceeded:
            "Rate limit exceeded"
        case .cacheError:
            "Cache operation failed"
        case let .modelLoadFailed(model):
            "Failed to load model: \(model)"
        case .contextWindowExceeded:
            "Input exceeds model's context window"
        case .authenticationFailed:
            "Authentication failed"
        case .serverOverloaded:
            "Server is overloaded"
        }
    }

    public var recoveryStrategy: String {
        switch self {
        case .serverNotRunning:
            "Start the Ollama server using 'ollama serve'"
        case .modelNotAvailable:
            "Install the model using 'ollama pull [model-name]'"
        case .networkTimeout:
            "Check the network connection and consider increasing timeout"
        case .rateLimitExceeded:
            "Wait before retrying to respect rate limits"
        case .contextWindowExceeded:
            "Reduce input length or split into smaller chunks"
        default:
            "Check Ollama server status and configuration"
        }
    }
}

// MARK: - Integration Result Models

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

    public var temperature: Double {
        switch self {
        case .simple: 0.1
        case .standard: 0.3
        case .advanced: 0.5
        }
    }

    public var maxTokens: Int {
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

    public init(
        id: String,
        type: TaskType,
        description: String,
        language: String? = nil,
        code: String? = nil
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.language = language
        self.code = code
    }

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

// MARK: - Health Monitoring Models

public struct HealthStats {
    public let ollamaUptime: Double
    public let huggingFaceUptime: Double
    public let lastOllamaCheck: Date?
    public let lastHuggingFaceCheck: Date?
}

public struct CurrentHealth {
    public let ollamaHealthy: Bool
    public let huggingFaceHealthy: Bool
    public let anyServiceAvailable: Bool
}
