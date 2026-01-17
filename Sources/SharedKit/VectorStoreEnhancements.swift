import Foundation

// Note: PostgresConnectionPool already exists in PostgresConnectionPool.swift
// This file contains additional vector store utilities only

/// Batch operation support for vector store
public struct VectorBatchOperation {
    public let contents: [String]
    public let vectors: [[Double]]
    public let metadata: [[String: String]]

    public init(contents: [String], vectors: [[Double]], metadata: [[String: String]] = []) {
        self.contents = contents
        self.vectors = vectors
        self.metadata = metadata.isEmpty ? Array(repeating: [:], count: contents.count) : metadata
    }

    /// Execute batch insert
    public func execute(on store: PostgresVectorStore) async throws {
        // Batch in chunks of 100
        let chunkSize = 100
        for i in stride(from: 0, to: contents.count, by: chunkSize) {
            let end = min(i + chunkSize, contents.count)
            let chunk = Array(i..<end)

            for idx in chunk {
                try await store.save(
                    content: contents[idx],
                    vector: vectors[idx],
                    metadata: metadata[idx]
                )
            }
        }
    }
}

/// Query optimization hints
public struct QueryOptimization {
    public let useIndex: Bool
    public let limit: Int
    public let offset: Int
    public let minScore: Float

    public init(useIndex: Bool = true, limit: Int = 10, offset: Int = 0, minScore: Float = 0.0) {
        self.useIndex = useIndex
        self.limit = limit
        self.offset = offset
        self.minScore = minScore
    }
}

/// Vector store performance metrics
@available(macOS 11.0, iOS 14.0, *)
public actor VectorStoreMetrics {
    private var queryTimes: [TimeInterval] = []
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var errors: Int = 0

    public init() {}

    public func recordQuery(duration: TimeInterval) {
        queryTimes.append(duration)
        if queryTimes.count > 1000 {
            queryTimes.removeFirst()
        }
    }

    public func recordCacheHit() {
        cacheHits += 1
    }

    public func recordCacheMiss() {
        cacheMisses += 1
    }

    public func recordError() {
        errors += 1
    }

    public func getMetrics() -> (
        avgQueryTime: TimeInterval, cacheHitRate: Double, errorRate: Double
    ) {
        let avgTime = queryTimes.isEmpty ? 0 : queryTimes.reduce(0, +) / Double(queryTimes.count)
        let total = cacheHits + cacheMisses
        let hitRate = total == 0 ? 0 : Double(cacheHits) / Double(total)
        let totalQueries = queryTimes.count
        let errorRate = totalQueries == 0 ? 0 : Double(errors) / Double(totalQueries)

        return (avgTime, hitRate, errorRate)
    }
}

// MARK: - Step 34: Query Optimization

public struct HybridSearchResult {
    public let content: String
    public let score: Float
    public let source: String  // "vector" or "keyword"
}

@available(macOS 12.0, iOS 15.0, *)
public actor HybridSearchEngine {
    private let vectorStore: PostgresVectorStore  // Assumption: Accessible

    public init(vectorStore: PostgresVectorStore) {
        self.vectorStore = vectorStore
    }

    /// Combine vector search with keyword matching (BM25 simulation)
    public func search(query: String, vector: [Double], limit: Int = 10) async throws
        -> [HybridSearchResult]
    {
        // 1. Vector Search
        // PostgresVectorStore.search now returns [SearchResult]
        let vectorResults = try await vectorStore.search(queryVector: vector, limit: limit)

        // 2. Keyword Search (Simulated for this context)
        // In production, this would use Postgres Full Text Search (tsvector)
        // Here we simulate by re-scoring vector results with keyword overlap

        var hybridResults: [HybridSearchResult] = []

        for result in vectorResults {
            // Calculate pseudo-BM25 score
            let keywordScore = calculateKeywordScore(query, content: result.content)

            // Normalize scores (0-1) - assuming vector score is cosine similarity (0-1)
            let vectorScore = Float(result.similarity)

            // Weighted combination: 70% vector, 30% keyword
            let combined = (vectorScore * 0.7) + (Float(keywordScore) * 0.3)

            hybridResults.append(
                HybridSearchResult(
                    content: result.content,
                    score: combined,
                    source: "hybrid"
                ))
        }

        // Re-sort
        return hybridResults.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    private func calculateKeywordScore(_ query: String, content: String) -> Double {
        let queryTerms = Set(query.lowercased().split(separator: " "))
        let contentTerms = Set(content.lowercased().split(separator: " "))
        let intersection = queryTerms.intersection(contentTerms).count
        return Double(intersection) / Double(queryTerms.count)  // Simple recall score
    }
}

@available(macOS 12.0, iOS 15.0, *)
public struct QueryExpander {
    /// Expand query with synonyms to improve recall
    /// In a real system, this would call an LLM
    public static func expand(_ query: String) async -> [String] {
        // Simulation: Just splitting significant words for now
        // Production: Call Ollama to get synonyms

        var expanded = [query]
        let terms = query.split(separator: " ")
        if terms.count > 3 {
            // If long query, add simplified version
            expanded.append(terms.prefix(3).joined(separator: " "))
        }
        return expanded
    }
}
