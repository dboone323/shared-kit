import Foundation
import Logging
import NIOCore
import NIOPosix
import PostgresNIO
import Swift

/// A storage engine for vector embeddings using Postgres + pgvector.
@available(macOS 12.0, *)
public actor PostgresVectorStore {
    public static let shared = PostgresVectorStore()

    private var connection: PostgresConnection?
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    private init() {}

    /// Connects to the Postgres database.
    public func connect() async throws {
        if connection != nil { return }

        let config = PostgresConnection.Configuration(
            host: "127.0.0.1",
            port: 5432,
            username: "sonar",
            password: ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"] ?? "",
            database: "sonar",
            tls: .disable
        )

        let logger = Logging.Logger(label: "PostgresVectorStore")

        // Establish connection
        self.connection = try await PostgresConnection.connect(
            on: eventLoopGroup.next(),
            configuration: config,
            id: 1,
            logger: logger
        )

        try await ensureTableExists()
    }

    /// Ensures the 'embeddings' table exists with the vector extension and optimized indexes.
    private func ensureTableExists() async throws {
        guard let conn = connection else { throw VectorStoreError.notConnected }

        // Use PostgresQuery interpolation
        try await conn.query(
            """
            CREATE EXTENSION IF NOT EXISTS vector;
            CREATE TABLE IF NOT EXISTS embeddings (
                id SERIAL PRIMARY KEY,
                content TEXT,
                embedding vector(384),
                metadata JSONB
            );
            CREATE INDEX IF NOT EXISTS embeddings_embedding_idx ON embeddings USING hnsw (embedding vector_cosine_ops);
            """,
            logger: Logging.Logger(label: "PostgresVectorStore")
        )
    }

    public struct SearchResult: Sendable {
        public let content: String
        public let similarity: Double
    }

    /// Searches for similar vectors.
    public func search(queryVector: [Double], limit: Int = 10) async throws -> [SearchResult] {
        guard let conn = connection else { throw VectorStoreError.notConnected }

        let vectorString = "[" + queryVector.map { String($0) }.joined(separator: ",") + "]"

        // Use manual string construction for vector since PostgresNIO might not support vector binding natively yet in
        // this version
        // 1 - (embedding <=> $1) as similarity
        // Note: <=> is cosine distance. Similarity = 1 - distance.
        let rows = try await conn.query(
            """
            SELECT content, 1 - (embedding <=> \(vectorString)::vector) as similarity
            FROM embeddings
            ORDER BY embedding <=> \(vectorString)::vector
            LIMIT \(limit);
            """,
            logger: Logging.Logger(label: "PostgresVectorStore")
        )

        var results: [SearchResult] = []
        for try await row in rows {
            let randomAccess = row.makeRandomAccess()
            if let content = randomAccess[data: "content"].string,
               let similarity = randomAccess[data: "similarity"].double
            {
                results.append(SearchResult(content: content, similarity: similarity))
            }
        }
        return results
    }

    /// Save content and vector
    public func save(content: String, vector: [Double], metadata: [String: String] = [:])
        async throws
    {
        guard let conn = connection else { throw VectorStoreError.notConnected }

        let vectorString = "[" + vector.map { String($0) }.joined(separator: ",") + "]"

        // This is simplified. In prod use proper bindings if available or thorough escaping.
        // Assuming content is safe-ish or we use bindings for content.
        // Serialize metadata to JSON
        let metadataData = try JSONSerialization.data(withJSONObject: metadata, options: [])
        let metadataString = String(data: metadataData, encoding: .utf8) ?? "{}"

        // Use manual string construction for vector since PostgresNIO might not support vector binding natively yet in
        // this version
        // We use string interpolation carefully here. In a real app, use bind parameters if the driver supports `Wait`
        // for vector.
        try await conn.query(
            """
            INSERT INTO embeddings (content, embedding, metadata)
            VALUES ('\(content)', '\(vectorString)'::vector, '\(metadataString)'::jsonb);
            """,
            logger: Logging.Logger(label: "PostgresVectorStore")
        )
    }

    public func close() async {
        try? await connection?.close()
        try? await eventLoopGroup.shutdownGracefully()
    }
}

public enum VectorStoreError: Error {
    case notConnected
}
