import Foundation

/// Machine Learning and Intelligence enhancements for Shared-Kit
/// Covers Steps 31-33: Tool Selection, Predictive Health, Advanced Caching

@available(macOS 12.0, iOS 15.0, *)
public actor Intelligence {
    public static let shared = Intelligence()

    private let toolRecommender = ToolRecommender()
    private let healthPredictor = HealthPredictor()
    private let semanticCache = SemanticCache()

    public init() {}

    /// Get tool recommendations based on task description
    public func recommendTools(for task: String, availableTools: [ToolDescription]) async
        -> [String]
    {
        return await toolRecommender.rank(tools: availableTools, for: task)
    }

    /// Check if a model is predicted to likely fail soon
    public func predictHealth(for modelId: String) async -> HealthPrediction {
        return await healthPredictor.predict(modelId)
    }

    /// Cache semantic result
    public func cacheResult(_ result: String, for query: String, embeddings: [Float]) async {
        await semanticCache.set(result, for: query, vector: embeddings)
    }

    /// Retrieve semantic result
    public func retrieveCachedResult(for query: String, embeddings: [Float]) async -> String? {
        return await semanticCache.get(for: query, vector: embeddings)
    }
}

// MARK: - Step 31: ML-Based Tool Selection

public struct ToolDescription: Sendable, Hashable {
    public let name: String
    public let description: String
    public let vector: [Float]?  // Pre-computed embedding

    public init(name: String, description: String, vector: [Float]? = nil) {
        self.name = name
        self.description = description
        self.vector = vector
    }
}

@available(macOS 12.0, iOS 15.0, *)
actor ToolRecommender {
    private var historicalSuccess: [String: Double] = [:]  // Simple exponential moving average of success

    /// Rank tools by hybrid score (Vector Similarity + Success Rate)
    func rank(tools: [ToolDescription], for task: String) -> [String] {
        // In a real system, we'd generate an embedding for 'task' here.
        // For this implementation, we assume we rely more on basic text matching overlap
        // plus historical success rates if actual vectors aren't provided.

        return tools.sorted { t1, t2 in
            score(t1, task: task) > score(t2, task: task)
        }.map { $0.name }
    }

    private func score(_ tool: ToolDescription, task: String) -> Double {
        // 1. Text Similarity (Simplified Jaccard/Overlap for simulation)
        let similarity = textSimilarity(tool.description, task)

        // 2. Historical Success Boost
        let successBoost = historicalSuccess[tool.name] ?? 1.0

        return (similarity * 0.7) + (successBoost * 0.3)
    }

    private func textSimilarity(_ s1: String, _ s2: String) -> Double {
        let set1 = Set(s1.lowercased().split(separator: " "))
        let set2 = Set(s2.lowercased().split(separator: " "))
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        return union == 0 ? 0 : Double(intersection) / Double(union)
    }

    func recordOutcome(tool: String, success: Bool) {
        let current = historicalSuccess[tool] ?? 1.0
        // Exponential moving average update
        let alpha = 0.2
        let newValue = success ? 1.0 : 0.0
        historicalSuccess[tool] = (current * (1 - alpha)) + (newValue * alpha)
    }
}

// MARK: - Step 32: Predictive Health Monitoring

public enum HealthStatus: String, Sendable {
    case healthy
    case degraded
    case critical
}

public struct HealthPrediction: Sendable {
    public let status: HealthStatus
    public let probabilityOfFailure: Double
    public let estimatedLatency: TimeInterval
}

@available(macOS 12.0, iOS 15.0, *)
actor HealthPredictor {
    struct LatencySample {
        let timestamp: Date
        let duration: TimeInterval
    }

    private var latencyHistory: [String: [LatencySample]] = [:]
    private let windowSize: TimeInterval = 300  // 5 minutes

    func recordLatency(model: String, duration: TimeInterval) {
        let sample = LatencySample(timestamp: Date(), duration: duration)
        if latencyHistory[model] == nil {
            latencyHistory[model] = []
        }
        latencyHistory[model]?.append(sample)
        prune(model: model)
    }

    func predict(_ model: String) -> HealthPrediction {
        guard let history = latencyHistory[model], !history.isEmpty else {
            return HealthPrediction(
                status: .healthy, probabilityOfFailure: 0.0, estimatedLatency: 0.5)
        }

        // Calculate P95 Latency
        let sortedDurations = history.map { $0.duration }.sorted()
        let index = Int(Double(sortedDurations.count) * 0.95)
        let p95 = sortedDurations[index]

        // Trend Analysis: Is latency increasing?
        let recent = history.suffix(10)
        let avgRecent = recent.map { $0.duration }.reduce(0, +) / Double(recent.count)
        let avgTotal = sortedDurations.reduce(0, +) / Double(sortedDurations.count)

        var status: HealthStatus = .healthy
        var prob: Double = 0.1

        if p95 > 5.0 || avgRecent > avgTotal * 1.5 {
            status = .degraded
            prob = 0.6
        }

        if p95 > 10.0 {
            status = .critical
            prob = 0.9
        }

        return HealthPrediction(
            status: status,
            probabilityOfFailure: prob,
            estimatedLatency: p95
        )
    }

    private func prune(model: String) {
        let cutoff = Date().addingTimeInterval(-windowSize)
        latencyHistory[model] = latencyHistory[model]?.filter { $0.timestamp > cutoff }
    }
}

// MARK: - Step 33: Advanced Semantic Caching (LRU + Vector)

@available(macOS 12.0, iOS 15.0, *)
actor SemanticCache {
    private struct CacheEntry {
        let result: String
        let vector: [Float]
        let lastAccessed: Date
        let expiry: Date
    }

    private var cache: [String: CacheEntry] = [:]
    private let maxEntries = 1000
    private let similarityThreshold: Float = 0.9  // For semantic match

    func set(_ result: String, for query: String, vector: [Float], ttl: TimeInterval = 300) {
        if cache.count >= maxEntries {
            evictLRU()
        }

        let entry = CacheEntry(
            result: result,
            vector: vector,
            lastAccessed: Date(),
            expiry: Date().addingTimeInterval(ttl)
        )
        cache[query] = entry
    }

    func get(for query: String, vector: [Float]) -> String? {
        // 1. Exact Match
        if let entry = cache[query], entry.expiry > Date() {
            cache[query] = CacheEntry(
                result: entry.result,
                vector: entry.vector,
                lastAccessed: Date(),  // Update access time for LRU
                expiry: entry.expiry
            )
            return entry.result
        }

        // 2. Semantic Match (Simulated)
        // Find most similar providing it's above threshold
        // Requires vector math import (simplified here)
        for (_, entry) in cache {
            if entry.expiry > Date() {
                let sim = cosineSimilarity(v1: vector, v2: entry.vector)
                if sim > similarityThreshold {
                    return entry.result
                }
            }
        }

        return nil
    }

    private func evictLRU() {
        // Remove oldest accessed
        let sorted = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        if let first = sorted.first {
            cache.removeValue(forKey: first.key)
        }
    }

    private func cosineSimilarity(v1: [Float], v2: [Float]) -> Float {
        guard v1.count == v2.count, !v1.isEmpty else { return 0 }
        var dot: Float = 0
        var mag1: Float = 0
        var mag2: Float = 0
        for i in 0..<v1.count {
            dot += v1[i] * v2[i]
            mag1 += v1[i] * v1[i]
            mag2 += v2[i] * v2[i]
        }
        return dot / (sqrt(mag1) * sqrt(mag2))
    }
}
