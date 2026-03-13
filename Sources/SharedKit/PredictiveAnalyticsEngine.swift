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

    private init() {}

    /// Analyze time-series data to predict future success probability.
    /// This implementation uses a weighted moving average and trend analysis.
    public func analyze(_ points: [TimeSeriesPoint]) -> PredictionResult {
        guard points.count >= 3 else {
            return PredictionResult(
                probability: 0.5,
                trend: .stable,
                confidence: 0.3,
                message: "Insufficient data for accurate prediction."
            )
        }

        let sortedPoints = points.sorted { $0.timestamp < $1.timestamp }
        let values = sortedPoints.map(\.value)

        // Calculate weighted moving average (more weight to recent points)
        var weightedSum: Double = 0
        var totalWeight: Double = 0
        for (index, value) in values.enumerated() {
            let weight = Double(index + 1)
            weightedSum += value * weight
            totalWeight += weight
        }
        let average = weightedSum / totalWeight

        // Simple trend analysis
        let firstHalf = values.prefix(values.count / 2)
        let secondHalf = values.suffix(values.count / 2)
        let firstAvg = firstHalf.reduce(0, +) / Double(max(1, firstHalf.count))
        let secondAvg = secondHalf.reduce(0, +) / Double(max(1, secondHalf.count))

        let trend: PredictionResult.Trend
        if secondAvg > firstAvg + 0.1 {
            trend = .improving
        } else if secondAvg < firstAvg - 0.1 {
            trend = .declining
        } else {
            trend = .stable
        }

        // Adjust probability based on trend
        var probability = average
        if trend == .improving {
            probability += 0.1
        } else if trend == .declining {
            probability -= 0.1
        }
        probability = min(max(probability, 0.0), 1.0)

        // Confidence increases with more data points
        let confidence = min(Double(points.count) / 10.0, 0.95)

        let message = "Based on \(points.count) data points, the trend is \(trend.rawValue)."

        return PredictionResult(
            probability: probability,
            trend: trend,
            confidence: confidence,
            message: message
        )
    }
}
