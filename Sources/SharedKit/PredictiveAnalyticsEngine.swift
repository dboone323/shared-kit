import Foundation

@available(iOS 13.0, macOS 10.15, *)
public final class PredictiveAnalyticsEngine: Sendable {
    public static let shared = PredictiveAnalyticsEngine()

    public struct TimeSeriesPoint: Codable, Sendable {
        public let timestamp: Date
        public let value: Double
        public let metadata: [String: String]?

        public init(timestamp: Date, value: Double, metadata: [String: String]? = nil) {
            self.timestamp = timestamp
            self.value = value
            self.metadata = metadata
        }
    }

    public struct PredictionResult: Codable, Sendable {
        public let probability: Double
        public let trend: Trend
        public let confidence: Double
        public let message: String

        public enum Trend: String, Codable, Sendable {
            case improving, declining, stable
        }
    }

    private let ollamaClient: OllamaClient?

    public init(ollamaClient: OllamaClient? = nil) {
        self.ollamaClient = ollamaClient
    }

    /// Analyze time-series data to predict future success probability using LLM-derived insights.
    public func analyze(_ points: [TimeSeriesPoint]) async -> PredictionResult {
        guard points.count >= 3 else {
            return PredictionResult(
                probability: 0.5,
                trend: .stable,
                confidence: 0.1,
                message: "Awaiting sufficient data baseline (min 3 points)."
            )
        }

        let dataset = points.sorted { $0.timestamp < $1.timestamp }
            .map { "Date: \($0.timestamp), Value: \($0.value)" }
            .joined(separator: "\n")

        let prompt = """
        Predictive Analytics Request:
        Analyze the following time-series data points and determine the success probability and trend.
        
        Data:
        \(dataset)
        
        Provide:
        1. Success Probability (0.0 to 1.0)
        2. Trend (improving, declining, stable)
        3. Confidence score (0.0 to 1.0)
        4. A concise strategic message.
        
        Return EXCLUSIVELY a JSON object with keys: "probability", "trend", "confidence", "message".
        """

        if let client = ollamaClient {
            do {
                let response = try await client.generate(model: nil, prompt: prompt)
                
                // Robust JSON extraction
                let cleanedResponse = if let range = response.range(of: "\\{.*\\}", options: .regularExpression) {
                    String(response[range])
                } else {
                    response
                }
                
                guard let data = cleanedResponse.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let prob = json["probability"] as? Double,
                      let trendStr = json["trend"] as? String,
                      let conf = json["confidence"] as? Double,
                      let msg = json["message"] as? String
                else {
                    return performHeuristicFallback(points)
                }

                let trend: PredictionResult.Trend = switch trendStr.lowercased() {
                    case "improving": .improving
                    case "declining": .declining
                    default: .stable
                }

                return PredictionResult(
                    probability: prob,
                    trend: trend,
                    confidence: conf,
                    message: msg
                )
            } catch {
                return performHeuristicFallback(points)
            }
        } else {
            return performHeuristicFallback(points)
        }
    }

    private func performHeuristicFallback(_ points: [TimeSeriesPoint]) -> PredictionResult {
        let values = points.map(\.value)
        let average = values.reduce(0, +) / Double(values.count)
        
        return PredictionResult(
            probability: average,
            trend: .stable,
            confidence: 0.4,
            message: "Standard diagnostic baseline applied."
        )
    }
}
