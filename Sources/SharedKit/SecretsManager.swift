import Foundation

/// Centralized manager for retrieving sensitive configuration and tokens
public actor SecretsManager {
    public static let shared = SecretsManager()

    private let keychain = KeychainManager.shared
    private let serviceName = "com.habitquest.secrets"

    private init() {}

    public enum SecretKey: String {
        case huggingFaceToken = "HF_TOKEN"
        case ollamaEndpoint = "OLLAMA_ENDPOINT"
        case encryptionKey = "APP_ENCRYPTION_KEY"
    }

    /// Retrieve a secret from environment variables or Keychain
    public func getSecret(_ key: SecretKey) async -> String? {
        // 1. Check environment variables (primarily for dev/CI)
        if let envValue = ProcessInfo.processInfo.environment[key.rawValue], !envValue.isEmpty {
            return envValue
        }

        // 2. Check Keychain
        do {
            return try await keychain.retrieveString(service: serviceName, account: key.rawValue)
        } catch {
            return nil
        }
    }

    /// Securely store a secret in the Keychain
    public func setSecret(_ value: String, for key: SecretKey) async throws {
        try await keychain.save(value, service: serviceName, account: key.rawValue)
    }

    /// Delete a secret from the Keychain
    public func deleteSecret(_ key: SecretKey) async throws {
        try await keychain.delete(service: serviceName, account: key.rawValue)
    }

    /// Specialized getter for Hugging Face token with fallback check
    public func getHuggingFaceToken() async -> String? {
        await getSecret(.huggingFaceToken)
    }

    /// Specialized getter for Ollama endpoint with default fallback
    public func getOllamaEndpoint() async -> String {
        await getSecret(.ollamaEndpoint) ?? "http://localhost:11434"
    }
}
