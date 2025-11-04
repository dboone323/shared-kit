import Foundation

public protocol LLMClient: Sendable {
    func generate(model: String, prompt: String, temperature: Double) async throws -> String
}

public struct OllamaConfig: Sendable {
    public let baseURL: URL
    public let defaultTimeout: TimeInterval

    public init(baseURL: URL = URL(string: "http://127.0.0.1:11434")!, defaultTimeout: TimeInterval = 120) {
        self.baseURL = baseURL
        self.defaultTimeout = defaultTimeout
    }
}

public final class OllamaClient: LLMClient {
    private let session: URLSession
    private let config: OllamaConfig

    public init(config: OllamaConfig = OllamaConfig()) {
        self.config = config
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.defaultTimeout
        sessionConfig.timeoutIntervalForResource = config.defaultTimeout
        self.session = URLSession(configuration: sessionConfig)
    }

    public func generate(model: String, prompt: String, temperature: Double) async throws -> String {
        // POST /api/generate { model, prompt, options, stream:false }
        struct Payload: Encodable {
            let model: String
            let prompt: String
            let stream: Bool
            let options: Options
        }
        struct Options: Encodable { let temperature: Double }
        struct Response: Decodable { let response: String? }

        let url = config.baseURL.appendingPathComponent("/api/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = Payload(model: model, prompt: prompt, stream: false, options: .init(temperature: temperature))
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            throw OllamaClientError.httpError(code)
        }
        if let text = try? JSONDecoder().decode(Response.self, from: data).response { return text }
        // Some models stream or return lines; fallback to raw text
        if let text = String(data: data, encoding: .utf8) { return text }
        throw OllamaClientError.emptyResponse
    }
}

public enum OllamaClientError: Error {
    case httpError(Int)
    case emptyResponse
}
