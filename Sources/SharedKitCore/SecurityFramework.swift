import Foundation

#if canImport(CryptoKit)
    import CryptoKit
#else
    import Crypto
#endif

/// Security Hardening Framework for Shared-Kit
/// Covers Steps 42-47: Headers, Input Validation, Auth/RBAC, Encryption

@available(macOS 12.0, iOS 15.0, *)
public actor SecurityFramework {
    public static let shared = SecurityFramework()

    private let inputValidator = InputValidator()
    private let accessControl = AccessControl()
    private let cryptoManager = CryptoManager()

    public init() {}

    /// Step 42: Get secure headers
    public nonisolated func getSecureHeaders() -> [String: String] {
        [
            "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
            "Content-Security-Policy": "default-src 'self'",
            "X-Content-Type-Options": "nosniff",
            "X-Frame-Options": "DENY",
            "X-XSS-Protection": "1; mode=block",
        ]
    }

    /// Step 43: Validate input
    public func validate(input: String, type: InputType) async throws {
        // Validation is stateless/pure function logic, can be done non-isolated if actor state not needed
        // But InputValidator is an actor.
        try await inputValidator.validate(input, type: type)
    }

    /// Step 43: Sanitize input (SQL/Context aware)
    public func sanitize(_ input: String) async -> String {
        await inputValidator.sanitize(input)
    }

    /// Step 44-45: Check permission
    public func checkPermission(user: UserContext, action: Action) async throws {
        try await accessControl.authorize(user: user, action: action)
    }

    /// Step 46: Encrypt data (At Rest)
    public func encrypt(_ data: Data) async throws -> Data {
        try await cryptoManager.encrypt(data)
    }

    /// Step 46: Decrypt data
    public func decrypt(_ data: Data) async throws -> Data {
        try await cryptoManager.decrypt(data)
    }
}

// MARK: - Step 43: Input Validation

public enum InputType: Sendable {
    case email
    case url
    case identifier
    case text
    case habitName
    case habitDescription
}

actor InputValidator {
    func validate(_ input: String, type: InputType) throws {
        // Length check
        if input.count > 10000 { throw ValidationError.inputTooLong(maxLength: 10000) }

        switch type {
        case .email:
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !predicate.evaluate(with: input) {
                throw ValidationError.invalidEmail
            }
        case .url:
            guard let url = URL(string: input), url.scheme != nil, url.host != nil else {
                throw ValidationError.invalidURL
            }
        case .identifier:
            if input.range(of: "^[a-zA-Z0-9_]+$", options: .regularExpression) == nil {
                throw ValidationError.invalidFormat(
                    description: "Invalid identifier (alphanumeric only)")
            }
        case .text:
            // Check for obvious XSS tags
            if input.contains("<script") || input.contains("javascript:") {
                throw ValidationError.unsafeContent
            }
        case .habitName:
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw ValidationError.emptyInput }
            if trimmed.count > 50 { throw ValidationError.inputTooLong(maxLength: 50) }
        case .habitDescription:
            if input.count > 200 { throw ValidationError.inputTooLong(maxLength: 200) }
        }
    }

    func sanitize(_ input: String) -> String {
        // Basic SQL escape (use prepared statements effectively instead)
        input.replacingOccurrences(of: "\0", with: "")
            .replacingOccurrences(of: "'", with: "''")
    }
}

// MARK: - Step 44-45: Authentication & RBAC

public enum Role: String, Sendable {
    case admin
    case user
    case viewer
}

public struct UserContext: Sendable {
    public let id: String
    public let role: Role

    public init(id: String, role: Role) {
        self.id = id
        self.role = role
    }
}

public enum Action: Sendable {
    case read
    case write
    case delete
    case admin
}

enum AuthError: Error {
    case unauthorized
    case forbidden
}

actor AccessControl {
    func authorize(user: UserContext, action: Action) throws {
        // RBAC Matrix
        switch user.role {
        case .admin:
            return  // Allowed everything

        case .user:
            switch action {
            case .read, .write: return
            case .delete, .admin: throw AuthError.forbidden
            }

        case .viewer:
            switch action {
            case .read: return
            default: throw AuthError.forbidden
            }
        }
    }
}

// MARK: - Step 46-47: Encryption

public actor CryptoManager {
    public static let shared = CryptoManager()

    private let keychain = KeychainManager.shared
    private let serviceName = "com.habitquest.encryption"
    private let accountName = "primaryKey"

    private func getKey() async throws -> SymmetricKey {
        do {
            let keyData = try await keychain.retrieveData(
                service: serviceName, account: accountName
            )
            return SymmetricKey(data: keyData)
        } catch {
            // Generate new key if not found
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            try await keychain.save(keyData, service: serviceName, account: accountName)
            return newKey
        }
    }

    public func encrypt(_ data: Data) async throws -> Data {
        let key = try await getKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    public func decrypt(_ data: Data) async throws -> Data {
        let key = try await getKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
