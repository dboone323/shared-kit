import Foundation

public struct NetworkRequestSample: Sendable, Codable, Equatable {
    public let url: String
    public let method: String
    public let startedAt: Date
    public let durationMs: Double
    public let statusCode: Int?

    public init(url: String, method: String, startedAt: Date, durationMs: Double, statusCode: Int?) {
        self.url = url
        self.method = method
        self.startedAt = startedAt
        self.durationMs = durationMs
        self.statusCode = statusCode
    }
}

public actor NetworkRequestMonitor {
    public static let shared = NetworkRequestMonitor()

    private var samples: [NetworkRequestSample] = []

    public init() {}

    public func record(_ sample: NetworkRequestSample) {
        samples.append(sample)
        if samples.count > 1000 {
            samples.removeFirst(samples.count - 1000)
        }
    }

    public func recentSamples(limit: Int = 100) -> [NetworkRequestSample] {
        guard limit > 0 else { return [] }
        return Array(samples.suffix(limit))
    }

    public func clear() {
        samples.removeAll()
    }
}
