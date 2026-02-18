import Foundation

/// Connection pool for PostgreSQL with automatic failover and retry.
/// > [!IMPORTANT]
/// > This component requires PostgresNIO which is omitted from the core build target.
@available(macOS 12.0, *)
public actor PostgresConnectionPool {
    public static let shared = PostgresConnectionPool()

    private init() {}

    /// Get a connection from the pool, creating one if needed
    public func getConnection() async throws -> PostgresConnection {
        NSLog(
            "[PostgresConnectionPool] ERROR: Attempted to get connection without PostgresNIO dependency."
        )
        throw NSError(
            domain: "PostgresConnectionPool",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Postgres dependency unavailable in this build target."
            ]
        )
    }

    /// Return a connection to the pool
    public func releaseConnection(_ conn: PostgresConnection) {
        // No-op for stub
    }

    /// Execute a query using pooled connection
    public func withConnection<T>(_ body: (PostgresConnection) async throws -> T) async throws -> T
    {
        NSLog(
            "[PostgresConnectionPool] ERROR: Attempted to execute query without PostgresNIO dependency."
        )
        throw NSError(
            domain: "PostgresConnectionPool",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Postgres dependency unavailable in this build target."
            ]
        )
    }

    /// Close all connections
    public func closeAll() async {
        // No-op for stub
    }
}

/// Stub types for build stability when external dependencies are not linked.
public struct PostgresConnection {
    public static func connect(on eventLoop: Any, configuration: Any, id: Int, logger: Any)
        async throws -> PostgresConnection
    {
        throw NSError(
            domain: "PostgresConnection",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Postgres connection requires PostgresNIO library."
            ]
        )
    }

    public func close() async throws {
        // No-op
    }
}

public struct PostgresConnectionConfiguration {
    public init() {}
}

extension PostgresConnection {
    public struct Configuration {
        public init() {}
    }
}
