import Foundation

/// Protocol defining the interface for an autonomous agent in 2026.
public protocol BaseAgent: Sendable {
    /// Unique identifier for the agent
    var id: String { get }

    /// Readable name for the agent
    var name: String { get }

    /// Perform a specific task based on input context
    func execute(context: [String: Sendable]) async throws -> AgentResult
}

/// Standardized result structure for agent execution
public struct AgentResult: Codable, Sendable {
    public let agentId: String
    public let success: Bool
    public let summary: String
    public let detail: [String: String]
    public let timestamp: Date
    public let requiresApproval: Bool

    public init(
        agentId: String, success: Bool, summary: String, detail: [String: String] = [:],
        requiresApproval: Bool = false
    ) {
        self.agentId = agentId
        self.success = success
        self.summary = summary
        self.detail = detail
        self.timestamp = Date()
        self.requiresApproval = requiresApproval
    }
}
