import Foundation

/// PostgreSQL connection pool for vector store
@available(macOS 11.0, iOS 14.0, *)
public actor PostgresConnectionPool {
    private var availableConnections: [PostgresConnection] = []
    private var activeConnections: Set<PostgresConnection> = []
    private let maxConnections: Int
    private let minConnections: Int

    public init(minConnections: Int = 2, maxConnections: Int = 10) {
        self.minConnections = minConnections
        self.maxConnections = maxConnections
    }

    /// Get connection from pool
    public func acquire() async throws -> PostgresConnection {
        // Return available connection if exists
        if let connection = availableConnections.first {
            availableConnections.removeFirst()
            activeConnections.insert(connection)
            return connection
        }

        // Create new if under limit
        if activeConnections.count < maxConnections {
            let connection = try await PostgresConnection.create()
            activeConnections.insert(connection)
            return connection
        }

        // Wait for connection to become available
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
        return try await acquire()
    }

    /// Release connection back to pool
    public func release(_ connection: PostgresConnection) {
        activeConnections.remove(connection)

        if availableConnections.count < minConnections {
            availableConnections.append(connection)
        } else {
            Task { await connection.close() }
        }
    }

    /// Execute query with automatic connection management
    public func withConnection<T>(_ block: (PostgresConnection) async throws -> T) async throws -> T
    {
        let conn = try await acquire()
        defer { Task { await self.release(conn) } }
        return try await block(conn)
    }
}

/// Batch operation support for vector store
public struct VectorBatchOperation {
    public let contents: [String]
    public let vectors: [[Float]]
    public let metadata: [[String: String]]

    public init(contents: [String], vectors: [[Float]], metadata: [[String: String]] = []) {
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
