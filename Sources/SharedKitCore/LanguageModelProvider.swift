import Foundation

public struct ProviderMessage: Sendable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public protocol LanguageModelProvider: Sendable {
    func generate(
        model: String?,
        prompt: String,
        temperature: Double?,
        maxTokens: Int?,
        useCache: Bool
    ) async throws -> String

    func chat(
        model: String,
        messages: [ProviderMessage],
        temperature: Double
    ) async throws -> String
}
