import Foundation
import Logging
import NIOCore
import NIOPosix
import PostgresNIO

/// Connection pool for PostgreSQL with automatic failover and retry
@available(macOS 12.0, *)
public actor PostgresConnectionPool {
    public static let shared = PostgresConnectionPool()

    private var connections: [PostgresConnection] = []
    private let maxConnections = 5
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private var availableConnections: [PostgresConnection] = []
    private var config: PostgresConnection.Configuration

    private init() {
        self.config = PostgresConnection.Configuration(
            host: "127.0.0.1",
            port: 5432,
            username: "sonar",
            password: ProcessInfo.processInfo.environment["POSTGRES_PASSWORD"] ?? "",
            database: "sonar",
            tls: .disable
        )
    }

    /// Get a connection from the pool, creating one if needed
    public func getConnection() async throws -> PostgresConnection {
        // Return available connection if one exists
        if let conn = availableConnections.first {
            availableConnections.removeFirst()
            return conn
        }

        // Create new connection if under limit
        if connections.count < maxConnections {
            let logger = Logging.Logger(label: "PostgresPool")
            let conn = try await PostgresConnection.connect(
                on: eventLoopGroup.next(),
                configuration: config,
                id: connections.count + 1,
                logger: logger
            )
            connections.append(conn)
            return conn
        }

        // Wait for a connection to become available (simple implementation)
        // In production, use a semaphore or condition variable
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
        return try await getConnection()
    }

    /// Return a connection to the pool
    public func releaseConnection(_ conn: PostgresConnection) {
        if !availableConnections.contains(where: { $0 === conn }) {
            availableConnections.append(conn)
        }
    }

    /// Execute a query using pooled connection
    public func withConnection<T: Sendable>(
        _ body: @Sendable (PostgresConnection) async throws -> T
    ) async throws -> T {
        let conn = try await getConnection()
        defer {
            Task {
                await releaseConnection(conn)
            }
        }
        return try await body(conn)
    }

    /// Close all connections
    public func closeAll() async {
        for conn in connections {
            try? await conn.close()
        }
        connections.removeAll()
        availableConnections.removeAll()
        try? await eventLoopGroup.shutdownGracefully()
    }
}
