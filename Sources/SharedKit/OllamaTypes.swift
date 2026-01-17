import Foundation

// MARK: - Core Ollama Configuration & Types

public struct OllamaConfig: Sendable {
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
        baseURL: String = "http://127.0.0.1:11434",
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
        fallbackModels: [
            "deepseek-v3.1:671b-cloud", "gpt-oss:120b-cloud", "qwen3-coder:480b-cloud",
        ],
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

public struct OllamaMessage: Codable, Sendable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct OllamaGenerateResponse: Codable, Sendable {
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

public struct OllamaServerStatus: Sendable {
    public let running: Bool
    public let modelCount: Int
    public let models: [String]
}

public enum OllamaError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case invalidResponseFormat
    case httpError(Int)
    case apiError(String)
    case connectionFailed
    case modelNotFound(String)
    case serverError(String)
    case unknownError(String)
    case modelNotAvailable(String)

    // Legacy/Migration aliases if needed, or re-add them if they differ semantically
    case modelPullFailed
    case serverNotRunning
    case networkTimeout
    case rateLimitExceeded
    case cacheError
    case modelLoadFailed(String)
    case contextWindowExceeded
    case authenticationFailed
    case serverOverloaded

    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let details):
            return "Invalid configuration: \(details)"
        case .invalidURL:
            return "Invalid Ollama server URL"
        case .invalidResponse:
            return "Invalid response from Ollama server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidResponseFormat:
            return "Invalid response format from Ollama"
        case .modelPullFailed:
            return "Failed to pull model from Ollama"
        case .serverNotRunning:
            return "Ollama server is not running"
        case .modelNotAvailable(let model):
            return "Model '\(model)' is not available"
        case .networkTimeout:
            return "Network request timed out"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .cacheError:
            return "Cache operation failed"
        case .modelLoadFailed(let model):
            return "Failed to load model: \(model)"
        case .contextWindowExceeded:
            return "Input exceeds model's context window"
        case .authenticationFailed:
            return "Authentication failed"
        case .serverOverloaded:
            return "Server is overloaded"
        case .apiError(let msg):
            return "API Error: \(msg)"
        case .connectionFailed:
            return "Failed to connect to Ollama server"
        case .modelNotFound(let model):
            return "Model not found: \(model)"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .unknownError(let msg):
            return "Unknown error: \(msg)"
        }
    }

    public var recoveryStrategy: String {
        switch self {
        case .serverNotRunning:
            return "Start the Ollama server using 'ollama serve'"
        case .modelNotAvailable:
            return "Install the model using 'ollama pull [model-name]'"
        case .networkTimeout:
            return "Check the network connection and consider increasing timeout"
        case .rateLimitExceeded:
            return "Wait before retrying to respect rate limits"
        case .contextWindowExceeded:
            return "Reduce input length or split into smaller chunks"
        default:
            return "Check Ollama server status and configuration"
        }
    }
}

// MARK: - Integration Result Models
// Other integration models like ServiceHealth, CodeComplexity, etc. are defined in AIServiceProtocols.swift
