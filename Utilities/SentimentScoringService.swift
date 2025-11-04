import Foundation

public protocol SentimentScoring: Sendable {
    func score(text: String) async -> SentimentResult
}

public struct SentimentResult: Sendable {
    public let label: String
    public let score: Double // -1.0..1.0
}

public final class OllamaSentimentScoringService: SentimentScoring {
    private let llm: LLMClient?
    private let model: String

    public init(llm: LLMClient? = nil, model: String = "llama3.1:8b") {
        self.llm = llm
        self.model = model
    }

    public func score(text: String) async -> SentimentResult {
        // Use simple fallback if no client is provided
        guard let llm else { return KeywordSentimentScoringService().scoreSync(text: text) }

        let prompt = """
        Analyze the sentiment of the following text. Respond in JSON only as {"label":"positive|neutral|negative","score":X} where score is in [-1,1].
        Text: \n\n\(text)
        """
        do {
            let out = try await llm.generate(model: model, prompt: prompt, temperature: 0.0)
            if let parsed = Self.parse(jsonLike: out) { return parsed }
        } catch {
            // Fall back to keyword method
        }
        return KeywordSentimentScoringService().scoreSync(text: text)
    }

    private static func parse(jsonLike: String) -> SentimentResult? {
        // Minimal parsing without introducing a JSON dependency on potentially non-strict output
        guard let start = jsonLike.firstIndex(of: "{"), let end = jsonLike.lastIndex(of: "}") else { return nil }
        let slice = jsonLike[start ... end]
        if let data = String(slice).data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let label = obj["label"] as? String,
           let score = obj["score"] as? Double
        {
            return SentimentResult(label: label, score: max(-1.0, min(1.0, score)))
        }
        return nil
    }
}

public final class KeywordSentimentScoringService: Sendable {
    public init() {}

    public func scoreSync(text: String) -> SentimentResult {
        let lower = text.lowercased()
        let positives = ["love", "great", "excellent", "happy", "good", "amazing", "wonderful", "fast", "clean"]
        let negatives = ["hate", "bad", "terrible", "slow", "bug", "broken", "awful", "poor", "crash"]
        let pos = positives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let neg = negatives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let raw = Double(pos - neg)
        let score = max(-1.0, min(1.0, raw / 5.0))
        let label: String = score > 0.2 ? "positive" : (score < -0.2 ? "negative" : "neutral")
        return SentimentResult(label: label, score: score)
    }
}
