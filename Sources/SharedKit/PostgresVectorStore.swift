import Foundation
import Logging
import NIOCore
import NIOPosix
import PostgresNIO

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
            CREATE TABLE IF NOT EXISTS embeddings (
                id SERIAL PRIMARY KEY,
                content TEXT,
                vector vector(512), 
                metadata JSONB,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """, logger: Logging.Logger(label: "init-table"))

        // Create IVFFlat index for fast cosine similarity search
        // IVFFlat is recommended for datasets with >1000 vectors
        try await conn.query(
            """
            CREATE INDEX IF NOT EXISTS embeddings_vector_idx 
            ON embeddings 
            USING ivfflat (vector vector_cosine_ops) 
            WITH (lists = 100);
            """, logger: Logging.Logger(label: "init-index"))

        SecureLogger.info("VectorStore: Table and index initialized", category: .database)
    }

    /// Saves a text and its embedding to the database.
    public func save(content: String, vector: [Double], metadata: [String: String] = [:])
        async throws
    {
        guard let conn = connection else { throw VectorStoreError.notConnected }

        // Convert [Double] to pgvector string format: "[1.0,2.0,3.0]"
        let vectorString = "[" + vector.map { String($0) }.joined(separator: ",") + "]"

        try await conn.query(
            "INSERT INTO embeddings (content, vector) VALUES (\(content), \(vectorString)::vector)",
            logger: Logging.Logger(label: "save-embedding")
        )
        SecureLogger.debug(
            "VectorStore: Saved content length \(content.count)", category: .database)
    }

    /// Searches for similar content using cosine similarity (<=> operator is cosine distance).
    public func search(queryVector: [Double], limit: Int = 3) async throws -> [String] {
        guard let conn = connection else { throw VectorStoreError.notConnected }

        let vectorString = "[" + queryVector.map { String($0) }.joined(separator: ",") + "]"

        let rows = try await conn.query(
            "SELECT content FROM embeddings ORDER BY vector <=> \(vectorString)::vector LIMIT \(limit)",
            logger: Logging.Logger(label: "search-embedding")
        )

        var results: [String] = []
        for try await row in rows {
            let randomAccess = row.makeRandomAccess()
            if let content = randomAccess[data: "content"].string {
                results.append(content)
            }
        }
        return results
    }

    public func close() async {
        try? await connection?.close()
        try? await eventLoopGroup.shutdownGracefully()
    }
}

public enum VectorStoreError: Error {
    case notConnected
}
