import Foundation

/// Represents a specialized capability that can be called by agents
public struct Skill: Codable, Sendable {
    public let name: String
    public let description: String
    public let parameters: [String: SkillParameter]
    public let version: String

    public init(name: String, description: String, parameters: [String: SkillParameter], version: String = "1.0.0") {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.version = version
    }
}

/// Description of a skill parameter
public struct SkillParameter: Codable, Sendable {
    public let type: String
    public let description: String
    public let required: Bool

    public init(type: String, description: String, required: Bool = true) {
        self.type = type
        self.description = description
        self.required = required
    }
}

/// Protocol for executing a Swift skill
public protocol SkillExecutor: Sendable {
    func execute(arguments: [String: Sendable]) async throws -> [String: Sendable]
}

/// Registry for Swift-based skills exposed to the Python agent fleet
public actor SkillRegistry {
    public static let shared = SkillRegistry()

    private var skills: [String: Skill] = [:]
    private var executors: [String: SkillExecutor] = [:]
    private let registryPath: URL

    private init() {
        // Use a standard location for skill metadata discovery
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.registryPath = home.appendingPathComponent("github-projects/tools-automation/config/swift_skills.json")
        try? FileManager.default.createDirectory(at: registryPath.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    /// Register a new skill and its executor
    public func registerSkill(_ skill: Skill, executor: SkillExecutor) async throws {
        skills[skill.name] = skill
        executors[skill.name] = executor
        try await exportRegistry()
    }

    /// Call a registered skill by name
    public func callSkill(name: String, arguments: [String: Sendable]) async throws -> [String: Sendable] {
        guard let executor = executors[name] else {
            throw NSError(domain: "SkillRegistry", code: 404, userInfo: [NSLocalizedDescriptionKey: "Skill '\(name)' not found"])
        }
        return try await executor.execute(arguments: arguments)
    }

    /// Export all registered skills to a JSON file for the Python MCP server to discover
    private func exportRegistry() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(Array(skills.values))
        try data.write(to: registryPath, options: .atomic)
    }

    public func getSkill(name: String) -> Skill? {
        return skills[name]
    }

    public func listSkills() -> [Skill] {
        return Array(skills.values)
    }
}
