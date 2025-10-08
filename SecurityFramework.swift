//
//  SecurityFramework.swift
//  Quantum-workspace Shared Security Framework
//
//  Comprehensive security utilities for input validation, secure data handling,
//  cryptographic operations, and vulnerability protection.
//

import CryptoKit
import Foundation
import Security

// MARK: - Security Framework

/// Comprehensive security framework for the Quantum workspace
public enum SecurityFramework {
    // MARK: - Input Validation

    /// Input validation utilities
    public enum Validation {
        /// Validates string input against common security threats
        /// - Parameters:
        ///   - input: The string to validate
        ///   - maxLength: Maximum allowed length (default: 1000)
        ///   - allowedCharacters: Character set to allow (default: alphanumeric + common symbols)
        /// - Returns: ValidationResult indicating success or failure with details
        public static func validateStringInput(
            _ input: String,
            maxLength: Int = 1000,
            allowedCharacters: CharacterSet = .alphanumerics.union(.whitespacesAndNewlines).union(
                CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?"))
        ) -> ValidationResult {
            // Check for nil or empty
            guard !input.isEmpty else {
                return .failure(.emptyInput)
            }

            // Check length
            guard input.count <= maxLength else {
                return .failure(.inputTooLong(maxLength: maxLength))
            }

            // Check for malicious patterns
            if containsMaliciousPatterns(input) {
                return .failure(.maliciousContent)
            }

            // Check character set
            let inputCharacterSet = CharacterSet(charactersIn: input)
            guard allowedCharacters.isSuperset(of: inputCharacterSet) else {
                return .failure(.invalidCharacters)
            }

            return .success
        }

        /// Validates numeric input within safe bounds
        public static func validateNumericInput<T: Numeric & Comparable>(
            _ input: T,
            minValue: T? = nil,
            maxValue: T? = nil
        ) -> ValidationResult {
            if let min = minValue, input < min {
                return .failure(.valueTooLow(minimum: String(describing: min)))
            }

            if let max = maxValue, input > max {
                return .failure(.valueTooHigh(maximum: String(describing: max)))
            }

            return .success
        }

        /// Validates URL input for security
        public static func validateURL(_ urlString: String) -> ValidationResult {
            guard let url = URL(string: urlString) else {
                return .failure(.invalidURL)
            }

            // Check scheme
            guard let scheme = url.scheme?.lowercased(),
                ["http", "https"].contains(scheme)
            else {
                return .failure(.invalidURLScheme)
            }

            // Check for localhost/internal addresses in production
            #if !DEBUG
                if url.host?.lowercased() == "localhost" || url.host?.hasPrefix("127.") == true
                    || url.host?.hasPrefix("192.168.") == true || url.host?.hasPrefix("10.") == true
                {
                    return .failure(.internalURLNotAllowed)
                }
            #endif

            return .success
        }

        /// Checks for common malicious patterns
        private static func containsMaliciousPatterns(_ input: String) -> Bool {
            let maliciousPatterns = [
                "<script", "</script>", "javascript:", "data:",
                "vbscript:", "onload=", "onerror=", "onclick=",
                "<iframe", "<object", "<embed", "eval(",
                "document.cookie", "document.location", "window.location",
            ]

            let lowercased = input.lowercased()
            return maliciousPatterns.contains { lowercased.contains($0) }
        }
    }

    // MARK: - Secure Data Handling

    /// Secure data handling utilities
    public enum DataSecurity {
        /// Securely stores sensitive data in Keychain
        public static func storeInKeychain(key: String, data: Data) throws {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            ]

            // Delete existing item
            SecItemDelete(query as CFDictionary)

            // Add new item
            let status = SecItemAdd(query as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw SecurityError.keychainError(status: status)
            }
        }

        /// Retrieves sensitive data from Keychain
        public static func retrieveFromKeychain(key: String) throws -> Data {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess,
                let data = result as? Data
            else {
                throw SecurityError.keychainError(status: status)
            }

            return data
        }

        /// Securely wipes data from memory
        public static func secureWipe(_ data: inout Data) {
            data.withUnsafeMutableBytes { buffer in
                if let baseAddress = buffer.baseAddress {
                    memset_s(baseAddress, buffer.count, 0, buffer.count)
                }
            }
            data.removeAll()
        }

        /// Generates cryptographically secure random data
        public static func generateSecureRandomData(length: Int) throws -> Data {
            var bytes = [UInt8](repeating: 0, count: length)
            let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

            guard status == errSecSuccess else {
                throw SecurityError.randomGenerationFailed
            }

            return Data(bytes)
        }
    }

    // MARK: - Cryptographic Operations

    /// Cryptographic utilities
    public enum Crypto {
        /// Hashes data using SHA-256
        public static func sha256(_ data: Data) -> Data {
            SHA256.hash(data: data).data
        }

        /// Hashes string using SHA-256
        public static func sha256(_ string: String) -> Data {
            sha256(Data(string.utf8))
        }

        /// Generates HMAC-SHA256
        public static func hmacSHA256(data: Data, key: Data) -> Data {
            HMAC<SHA256>.authenticationCode(for: data, using: .init(data: key)).data
        }

        /// Encrypts data using AES-GCM
        public static func encryptAESGCM(data: Data, key: Data) throws -> (
            ciphertext: Data, nonce: Data, tag: Data
        ) {
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(data, using: .init(data: key), nonce: nonce)
            return (sealedBox.ciphertext, Data(nonce), sealedBox.tag)
        }

        /// Decrypts data using AES-GCM
        public static func decryptAESGCM(ciphertext: Data, nonce: Data, tag: Data, key: Data) throws
            -> Data
        {
            let nonce = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(sealedBox, using: .init(data: key))
        }
    }

    // MARK: - Security Monitoring

    /// Security monitoring and logging
    public enum Monitoring {
        private static let logger = Logger(
            subsystem: "com.quantum.security", category: "SecurityFramework")

        /// Logs security events
        public static func logSecurityEvent(_ event: SecurityEvent, details: [String: Any]? = nil) {
            let message = event.description
            let metadata = details?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? ""

            switch event.level {
            case .info:
                logger.info("\(message) - \(metadata)")
            case .warning:
                logger.warning("\(message) - \(metadata)")
            case .error:
                logger.error("\(message) - \(metadata)")
            case .critical:
                logger.critical("\(message) - \(metadata)")
            }
        }

        /// Reports potential security incidents
        public static func reportSecurityIncident(_ incident: SecurityIncident) {
            logSecurityEvent(
                .incidentDetected(type: incident.type),
                details: [
                    "severity": incident.severity.rawValue,
                    "description": incident.description,
                    "timestamp": incident.timestamp.ISO8601Format(),
                ])
        }
    }

    // MARK: - Vulnerability Scanning

    /// Vulnerability scanning utilities
    public enum VulnerabilityScanner {
        /// Scans code for common vulnerabilities
        public static func scanForVulnerabilities(code: String, language: String) -> [Vulnerability]
        {
            var vulnerabilities: [Vulnerability] = []

            // SQL Injection patterns
            if language.lowercased().contains("sql") || code.contains("SELECT") {
                let sqlPatterns = ["'", "\"", ";", "--", "/*", "*/", "UNION", "DROP", "DELETE"]
                for pattern in sqlPatterns {
                    if code.contains(pattern) && !isInSafeContext(code, pattern: pattern) {
                        vulnerabilities.append(
                            Vulnerability(
                                type: .sqlInjection,
                                severity: .high,
                                description: "Potential SQL injection vulnerability detected",
                                line: findLineNumber(code: code, pattern: pattern),
                                recommendation: "Use parameterized queries or prepared statements"
                            ))
                    }
                }
            }

            // XSS patterns for web languages
            if ["javascript", "html", "typescript"].contains(language.lowercased()) {
                let xssPatterns = ["innerHTML", "outerHTML", "document.write", "eval("]
                for pattern in xssPatterns {
                    if code.contains(pattern) {
                        vulnerabilities.append(
                            Vulnerability(
                                type: .xss,
                                severity: .high,
                                description: "Potential XSS vulnerability detected",
                                line: findLineNumber(code: code, pattern: pattern),
                                recommendation:
                                    "Use safe DOM manipulation methods or sanitize input"
                            ))
                    }
                }
            }

            // Hardcoded secrets
            let secretPatterns = ["password", "secret", "key", "token"]
            for pattern in secretPatterns {
                if code.lowercased().contains(pattern) && code.contains("\"")
                    && !code.contains("//")
                {  // Ignore comments
                    vulnerabilities.append(
                        Vulnerability(
                            type: .hardcodedSecret,
                            severity: .critical,
                            description: "Potential hardcoded secret detected",
                            line: findLineNumber(code: code, pattern: pattern),
                            recommendation:
                                "Move secrets to environment variables or secure storage"
                        ))
                }
            }

            return vulnerabilities
        }

        private static func isInSafeContext(_ code: String, pattern: String) -> Bool {
            // Simple heuristic - check if pattern is in a comment or safe context
            let lines = code.components(separatedBy: .newlines)
            for line in lines {
                if line.contains(pattern) {
                    return line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
                        || line.trimmingCharacters(in: .whitespaces).hasPrefix("/*")
                        || line.contains("preparedStatement") || line.contains("bindValue")
                }
            }
            return false
        }

        private static func findLineNumber(code: String, pattern: String) -> Int? {
            let lines = code.components(separatedBy: .newlines)
            for (index, line) in lines.enumerated() {
                if line.contains(pattern) {
                    return index + 1
                }
            }
            return nil
        }
    }
}

// MARK: - Supporting Types

/// Result of validation operations
public enum ValidationResult {
    case success
    case failure(ValidationError)

    public var isValid: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    public var error: ValidationError? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

/// Validation error types
public enum ValidationError: Error, LocalizedError {
    case emptyInput
    case inputTooLong(maxLength: Int)
    case maliciousContent
    case invalidCharacters
    case valueTooLow(minimum: String)
    case valueTooHigh(maximum: String)
    case invalidURL
    case invalidURLScheme
    case internalURLNotAllowed

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input cannot be empty"
        case .inputTooLong(let maxLength):
            return "Input exceeds maximum length of \(maxLength) characters"
        case .maliciousContent:
            return "Input contains potentially malicious content"
        case .invalidCharacters:
            return "Input contains invalid characters"
        case .valueTooLow(let minimum):
            return "Value is below minimum allowed value of \(minimum)"
        case .valueTooHigh(let maximum):
            return "Value is above maximum allowed value of \(maximum)"
        case .invalidURL:
            return "Invalid URL format"
        case .invalidURLScheme:
            return "URL scheme not allowed"
        case .internalURLNotAllowed:
            return "Internal URLs are not allowed in production"
        }
    }
}

/// Security errors
public enum SecurityError: Error, LocalizedError {
    case keychainError(status: OSStatus)
    case randomGenerationFailed
    case encryptionFailed
    case decryptionFailed

    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain operation failed with status: \(status)"
        case .randomGenerationFailed:
            return "Failed to generate secure random data"
        case .encryptionFailed:
            return "Encryption operation failed"
        case .decryptionFailed:
            return "Decryption operation failed"
        }
    }
}

/// Security event types
public enum SecurityEvent {
    case inputValidationFailed(type: String)
    case keychainOperationFailed(operation: String)
    case encryptionOperationFailed
    case vulnerabilityDetected(type: VulnerabilityType)
    case incidentDetected(type: String)

    public var description: String {
        switch self {
        case .inputValidationFailed(let type):
            return "Input validation failed for type: \(type)"
        case .keychainOperationFailed(let operation):
            return "Keychain operation failed: \(operation)"
        case .encryptionOperationFailed:
            return "Encryption operation failed"
        case .vulnerabilityDetected(let type):
            return "Vulnerability detected: \(type.rawValue)"
        case .incidentDetected(let type):
            return "Security incident detected: \(type)"
        }
    }

    public var level: LogLevel {
        switch self {
        case .inputValidationFailed:
            return .warning
        case .keychainOperationFailed, .encryptionOperationFailed:
            return .error
        case .vulnerabilityDetected, .incidentDetected:
            return .critical
        }
    }
}

/// Log levels
public enum LogLevel {
    case info, warning, error, critical
}

/// Security incident types
public struct SecurityIncident {
    public let type: String
    public let severity: IncidentSeverity
    public let description: String
    public let timestamp: Date

    public init(type: String, severity: IncidentSeverity, description: String) {
        self.type = type
        self.severity = severity
        self.description = description
        self.timestamp = Date()
    }
}

/// Incident severity levels
public enum IncidentSeverity: String {
    case low, medium, high, critical
}

/// Vulnerability types
public enum VulnerabilityType: String {
    case sqlInjection = "SQL Injection"
    case xss = "Cross-Site Scripting"
    case hardcodedSecret = "Hardcoded Secret"
    case insecureRandom = "Insecure Random"
    case weakEncryption = "Weak Encryption"
}

/// Detected vulnerability
public struct Vulnerability {
    public let type: VulnerabilityType
    public let severity: IncidentSeverity
    public let description: String
    public let line: Int?
    public let recommendation: String
}

// MARK: - Extensions

extension SHA256Digest {
    var data: Data {
        Data(self)
    }
}

extension HMAC<SHA256>.MAC {
    var data: Data {
        Data(self)
    }
}

extension AES.GCM.Nonce {
    init(data: Data) throws {
        self = try .init(data: data)
    }

    var data: Data {
        withUnsafeBytes { Data($0) }
    }
}

// MARK: - Logger (Simple implementation)

private struct Logger {
    let subsystem: String
    let category: String

    func info(_ message: String) {
        print("[INFO] [\(subsystem):\(category)] \(message)")
    }

    func warning(_ message: String) {
        print("[WARNING] [\(subsystem):\(category)] \(message)")
    }

    func error(_ message: String) {
        print("[ERROR] [\(subsystem):\(category)] \(message)")
    }

    func critical(_ message: String) {
        print("[CRITICAL] [\(subsystem):\(category)] \(message)")
    }
}
