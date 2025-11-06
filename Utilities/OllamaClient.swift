import Foundation

// MARK: - Cloud Fallback Policy (Shared-Kit Utilities)

fileprivate struct CloudFallbackPolicy {
    let configPath: String
    let quotaTrackerPath: String
    let escalationLogPath: String

    private(set) var enabled: Bool = false
    private var config: [String: Any] = [:]

    init(
        configPath: String = "config/cloud_fallback_config.json",
        quotaTrackerPath: String = "metrics/quota_tracker.json",
        escalationLogPath: String = "logs/cloud_escalation_log.jsonl"
    ) {
        self.configPath = configPath
        self.quotaTrackerPath = quotaTrackerPath
        self.escalationLogPath = escalationLogPath
        self.reload()
    }

    mutating func reload() {
        guard let cfg = Self.readJSON(path: configPath) else { return }
        self.config = cfg
        self.enabled = true
    }

    mutating func recordFailure(priority: String) {
        guard enabled else { return }
        var tracker = Self.readJSON(path: quotaTrackerPath) ?? [:]
        var cb = (tracker["circuit_breaker"] as? [String: Any]) ?? [:]
        var pcb = (cb[priority] as? [String: Any]) ?? [
            "state": "closed", "failure_count": 0, "last_failure": NSNull(), "opened_at": NSNull(),
        ]
        let now = Self.iso8601Now()
        let failures = ((pcb["failure_count"] as? Int) ?? 0) + 1
        pcb["failure_count"] = failures
        pcb["last_failure"] = now
        let threshold = ((config["circuit_breaker"] as? [String: Any])?["failure_threshold"] as? Int) ?? 3
        if failures >= threshold {
            pcb["state"] = "open"
            pcb["opened_at"] = now
        }
        cb[priority] = pcb
        tracker["circuit_breaker"] = cb
        Self.writeJSON(path: quotaTrackerPath, object: tracker)
    }

    func logEscalation(task: String, priority: String, reason: String, modelAttempted: String, provider: String) {
        guard enabled else { return }
        let now = Self.iso8601Now()
        let line: [String: Any] = [
            "timestamp": now,
            "task": task,
            "priority": priority,
            "reason": reason,
            "model_attempted": modelAttempted,
            "cloud_provider": provider,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: line),
           let s = String(data: data, encoding: .utf8) {
            if FileManager.default.fileExists(atPath: escalationLogPath) == false {
                FileManager.default.createFile(atPath: escalationLogPath, contents: nil)
            }
            if let h = try? FileHandle(forWritingTo: URL(fileURLWithPath: escalationLogPath)) {
                h.seekToEndOfFile()
                h.write(Data((s + "\n").utf8))
                try? h.close()
            }
        }
    }

    // Helpers
    private static func readJSON(path: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
    private static func writeJSON(path: String, object: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
    private static func iso8601Now() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: Date())
    }
}

public protocol LLMClient: Sendable {
    func generate(model: String, prompt: String, temperature: Double) async throws -> String
}

public struct OllamaConfig: Sendable {
    public let baseURL: URL
    public let defaultTimeout: TimeInterval

    public init(
        baseURL: URL = URL(string: "http://127.0.0.1:11434")!, defaultTimeout: TimeInterval = 120
    ) {
        self.baseURL = baseURL
        self.defaultTimeout = defaultTimeout
    }
}

public final class OllamaClient: LLMClient {
    private let session: URLSession
    private let config: OllamaConfig
    private var policy = CloudFallbackPolicy()

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

        let payload = Payload(
            model: model, prompt: prompt, stream: false, options: .init(temperature: temperature)
        )
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            // Record failure for circuit breaker (default medium priority)
            policy.recordFailure(priority: "medium")
            throw OllamaClientError.httpError(code)
        }
        if let text = try? JSONDecoder().decode(Response.self, from: data).response { return text }
        // Some models stream or return lines; fallback to raw text
        if let text = String(data: data, encoding: .utf8) { return text }
        // Record failure for circuit breaker if empty
        policy.recordFailure(priority: "medium")
        throw OllamaClientError.emptyResponse
    }

    // Multimodal image support for vision-capable models (e.g., llava, llama3.2-vision)
    public func generate(
        model: String,
        prompt: String,
        temperature: Double = 0.2,
        images: [Data]
    ) async throws -> String {
        struct Payload: Encodable {
            let model: String
            let prompt: String
            let stream: Bool
            let images: [String]
            let options: Options
        }
        struct Options: Encodable { let temperature: Double }
        struct Response: Decodable { let response: String? }

        let url = config.baseURL.appendingPathComponent("/api/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Images = images.map { $0.base64EncodedString() }
        let payload = Payload(
            model: model,
            prompt: prompt,
            stream: false,
            images: base64Images,
            options: .init(temperature: temperature)
        )
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            policy.recordFailure(priority: "medium")
            throw OllamaClientError.httpError(code)
        }
        if let text = try? JSONDecoder().decode(Response.self, from: data).response { return text }
        if let text = String(data: data, encoding: .utf8) { return text }
        policy.recordFailure(priority: "medium")
        throw OllamaClientError.emptyResponse
    }
}

public enum OllamaClientError: Error {
    case httpError(Int)
    case emptyResponse
}
