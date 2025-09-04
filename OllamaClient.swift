import Foundation

/// Free AI Client for Ollama
/// Completely free alternative to OpenAI/Gemini APIs
/// Runs locally on your machine with no API costs

// MARK: - Configuration

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

// MARK: - Response Types

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
            return "Invalid Ollama server URL"
        case .invalidResponse:
            return "Invalid response from Ollama server"
        case let .httpError(code):
            return "HTTP error: \(code)"
        case .invalidResponseFormat:
            return "Invalid response format from Ollama"
        case .modelPullFailed:
            return "Failed to pull model from Ollama"
        case .serverNotRunning:
            return "Ollama server is not running"
        case let .modelNotAvailable(model):
            return "Model '\(model)' is not available"
        }
    }
}

// MARK: - Enhanced Ollama Client

public class OllamaClient {
    private let config: OllamaConfig
    private let session: URLSession
    private let logger = OllamaLogger()

    public init(config: OllamaConfig = .default) {
        self.config = config
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Core Generation Methods

    public func generate(
        model: String? = nil,
        prompt: String,
        temperature: Double? = nil,
        maxTokens: Int? = nil
    ) async throws -> String {
        let requestModel = model ?? config.defaultModel
        let requestTemp = temperature ?? config.temperature
        let requestMaxTokens = maxTokens ?? config.maxTokens

        let requestBody: [String: Any] = [
            "model": requestModel,
            "prompt": prompt,
            "temperature": requestTemp,
            "num_predict": requestMaxTokens,
            "stream": false,
        ]

        logger.log("Generating with model: \(requestModel), prompt length: \(prompt.count)")

        let response = try await performRequest(endpoint: "api/generate", body: requestBody)
        return response["response"] as? String ?? ""
    }

    public func generateAdvanced(
        model: String,
        prompt: String,
        system: String? = nil,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        topK: Int = 40,
        maxTokens: Int = 500,
        context: [Int]? = nil
    ) async throws -> OllamaGenerateResponse {

        var requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "temperature": temperature,
            "top_p": topP,
            "top_k": topK,
            "num_predict": maxTokens,
            "stream": false,
        ]

        if let system {
            requestBody["system"] = system
        }

        if let context {
            requestBody["context"] = context
        }

        let response = try await performRequest(endpoint: "api/generate", body: requestBody)
        let data = try JSONSerialization.data(withJSONObject: response)
        return try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
    }

    public func chat(
        model: String,
        messages: [OllamaMessage],
        temperature: Double = 0.7
    ) async throws -> String {

        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "temperature": temperature,
            "stream": false,
        ]

        let response = try await performRequest(endpoint: "api/chat", body: requestBody)

        guard let message = response["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            throw OllamaError.invalidResponseFormat
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Model Management

    public func listModels() async throws -> [String] {
        let response = try await performRequest(endpoint: "api/tags", body: [:])
        let models = response["models"] as? [[String: Any]] ?? []
        return models.compactMap { $0["name"] as? String }
    }

    public func pullModel(_ modelName: String) async throws {
        let requestBody: [String: Any] = [
            "name": modelName,
            "stream": false,
        ]

        _ = try await performRequest(endpoint: "api/pull", body: requestBody)
    }

    public func checkModelAvailability(_ model: String) async -> Bool {
        do {
            let models = try await listModels()
            return models.contains(model)
        } catch {
            return false
        }
    }

    // MARK: - Health & Status

    public func isServerRunning() async -> Bool {
        do {
            let _ = try await performRequest(endpoint: "api/tags", body: [:])
            return true
        } catch {
            return false
        }
    }

    public func getServerStatus() async -> OllamaServerStatus {
        do {
            let response = try await performRequest(endpoint: "api/tags", body: [:])
            let models = response["models"] as? [[String: Any]] ?? []
            return OllamaServerStatus(running: true, modelCount: models.count, models: models.compactMap { $0["name"] as? String })
        } catch {
            return OllamaServerStatus(running: false, modelCount: 0, models: [])
        }
    }

    // MARK: - Private Methods

    private func performRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        let url = URL(string: "\(config.baseURL)/\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OllamaError.invalidResponseFormat
        }

        return json
    }
}

// MARK: - Logger

private class OllamaLogger {
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] OllamaClient: \(message)")
    }
}

// MARK: - Convenience Extensions

public extension OllamaClient {
    func generateCode(
        language: String,
        task: String,
        context: String? = nil
    ) async throws -> String {
        let userPrompt = """
        Language: \(language)
        Task: \(task)
        \(context != nil ? "Context: \(context!)" : "")
        """

        return try await generate(
            model: "codellama",
            prompt: userPrompt,
            temperature: 0.2,
            maxTokens: 2048
        )
    }

    func analyzeCode(
        code: String,
        language: String
    ) async throws -> String {
        let prompt = """
        Analyze this \(language) code for:
        1. Potential bugs or issues
        2. Performance improvements
        3. Best practices compliance
        4. Security concerns

        Code:
        \(code)
        """

        return try await generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.3,
            maxTokens: 1024
        )
    }

    func generateDocumentation(
        code: String,
        language: String
    ) async throws -> String {
        let prompt = """
        Generate comprehensive documentation for this \(language) code including:
        - Function/class purpose
        - Parameters and return values
        - Usage examples
        - Important notes

        Code:
        \(code)
        """

        return try await generate(
            model: "llama2",
            prompt: prompt,
            temperature: 0.4,
            maxTokens: 1024
        )
    }
}
