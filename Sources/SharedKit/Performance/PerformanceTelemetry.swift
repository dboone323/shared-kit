import Foundation

public struct PerformanceSample: Sendable, Codable, Equatable {
    public let timestamp: Date
    public let metric: String
    public let value: Double
    public let unit: String

    public init(timestamp: Date = Date(), metric: String, value: Double, unit: String) {
        self.timestamp = timestamp
        self.metric = metric
        self.value = value
        self.unit = unit
    }
}

public actor PerformanceTelemetry {
    public static let shared = PerformanceTelemetry()

    private var samples: [PerformanceSample] = []

    public init() {}

    public func record(metric: String, value: Double, unit: String) {
        samples.append(PerformanceSample(metric: metric, value: value, unit: unit))

        if samples.count > 1000 {
            samples.removeFirst(samples.count - 1000)
        }
    }

    public func recentSamples(limit: Int = 100) -> [PerformanceSample] {
        guard limit > 0 else { return [] }
        return Array(samples.suffix(limit))
    }

    public func clear() {
        samples.removeAll()
    }
}
