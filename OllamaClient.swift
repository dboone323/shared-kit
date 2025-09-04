import Foundation

/// Free AI Client for Ollama
/// Completely free alternative to OpenAI/Gemini APIs
/// Runs locally on your machine with no API costs

public class OllamaClient {
    private let baseURL: String
    private let session: URLSession

    public init(baseURL: String = "http://localhost:11434") {
        self.baseURL = baseURL
        self.session = URLSession(configuration: .default)
    }

    /// Generate text using Ollama models
    /// - Parameters:
    ///   - model: Model name (e.g., "llama2", "codellama")
    ///   - prompt: Text prompt to generate from
    ///   - temperature: Creativity level (0.0-1.0, default 0.7)
    ///   - maxTokens: Maximum tokens to generate
    /// - Returns: Generated text response
    public func generate(
        model: String,
        prompt: String,
        temperature: Double = 0.7,
        maxTokens: Int = 500
    ) async throws -> String {

        let endpoint = "\(baseURL)/api/generate"

        let requestBody: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "temperature": temperature,
            "max_tokens": maxTokens,
            "stream": false
        ]

        guard let url = URL(string: endpoint) else {
            throw OllamaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = json["response"] as? String else {
            throw OllamaError.invalidResponseFormat
        }

        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// List available models
    public func listModels() async throws -> [String] {
        let endpoint = "\(baseURL)/api/tags"

        guard let url = URL(string: endpoint) else {
            throw OllamaError.invalidURL
        }

        let (data, _) = try await session.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else {
            throw OllamaError.invalidResponseFormat
        }

        return models.compactMap { $0["name"] as? String }
    }

    /// Check if Ollama server is running
    public func isServerRunning() async -> Bool {
        let endpoint = "\(baseURL)/api/tags"

        guard let url = URL(string: endpoint) else {
            return false
        }

        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Pull a model (download if not available locally)
    public func pullModel(_ modelName: String) async throws {
        let endpoint = "\(baseURL)/api/pull"

        let requestBody: [String: Any] = [
            "name": modelName,
            "stream": false
        ]

        guard let url = URL(string: endpoint) else {
            throw OllamaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.modelPullFailed
        }
    }
}

/// Errors that can occur when using OllamaClient
public enum OllamaError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidResponseFormat
    case modelPullFailed
    case serverNotRunning

    public var errorDescription: String? {
        switch self {
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
        }
    }
}

/// Convenience extension for code analysis
extension OllamaClient {

    /// Analyze code for issues and suggestions
    public func analyzeCode(_ code: String, language: String) async throws -> String {
        let prompt = """
        Analyze this \(language) code for:
        1. Potential bugs or issues
        2. Code quality improvements
        3. Best practices suggestions
        4. Security concerns

        Code:
        \(code)

        Provide a concise analysis with specific recommendations:
        """

        return try await generate(model: "codellama", prompt: prompt, temperature: 0.1)
    }

    /// Generate code suggestions
    public func suggestImprovements(for code: String, language: String) async throws -> [String] {
        let prompt = """
        Suggest specific improvements for this \(language) code.
        Focus on:
        - Performance optimizations
        - Code readability
        - Error handling
        - Modern language features

        Code:
        \(code)

        Return suggestions as a numbered list:
        """

        let response = try await generate(model: "codellama", prompt: prompt, temperature: 0.2)
        return response.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

/// Free AI Service Manager
/// Manages multiple free AI services with automatic fallback
public class FreeAIServiceManager {
    private let ollamaClient: OllamaClient
    private let huggingFaceToken: String?

    public init(ollamaBaseURL: String = "http://localhost:11434", huggingFaceToken: String? = nil) {
        self.ollamaClient = OllamaClient(baseURL: ollamaBaseURL)
        self.huggingFaceToken = huggingFaceToken
    }

    /// Generate text with automatic fallback
    public func generateText(prompt: String, model: String = "llama2") async throws -> String {
        // Try Ollama first (free, local)
        if await ollamaClient.isServerRunning() {
            do {
                return try await ollamaClient.generate(model: model, prompt: prompt)
            } catch {
                print("Ollama failed, trying fallback...")
            }
        }

        // Fallback to Hugging Face (free tier)
        return try await generateWithHuggingFace(prompt: prompt)
    }

    private func generateWithHuggingFace(prompt: String) async throws -> String {
        let endpoint = "https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium"

        guard let url = URL(string: endpoint) else {
            throw OllamaError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = huggingFaceToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "max_length": 500,
                "temperature": 0.7
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = json.first,
              let generatedText = firstResult["generated_text"] as? String else {
            throw OllamaError.invalidResponseFormat
        }

        return generatedText
    }

    /// Check service availability
    public func checkAvailability() async -> [String: Bool] {
        var status: [String: Bool] = [:]

        // Check Ollama
        status["ollama"] = await ollamaClient.isServerRunning()

        // Check Hugging Face (simple connectivity test)
        do {
            let testURL = URL(string: "https://huggingface.co/api/models")!
            let (_, response) = try await URLSession.shared.data(from: testURL)
            status["huggingface"] = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            status["huggingface"] = false
        }

        return status
    }
}
