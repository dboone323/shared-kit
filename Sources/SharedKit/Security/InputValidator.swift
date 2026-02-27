import Foundation
import SharedKitCore

/// Comprehensive input validation and sanitization utilities
/// Provides secure validation for user inputs across all Quantum Workspace projects

/// Input validation rules and sanitization
public enum InputValidator {
    // MARK: - Basic Validation Rules

    /// Validate that input is not empty or whitespace-only
    public static func validateNotEmpty(_ input: String) throws {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyInput
        }
    }

    /// Validate input length
    public static func validateLength(_ input: String, min: Int? = nil, max: Int? = nil) throws {
        if let min, input.count < min {
            throw ValidationError.belowMinimumLength(min: min)
        }
        if let max, input.count > max {
            throw ValidationError.exceedsMaximumLength(max: max)
        }
        if let min, let max, input.count < min || input.count > max {
            throw ValidationError.invalidLength(min: min, max: max)
        }
    }

    /// Validate email format
    public static func validateEmail(_ email: String) throws {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        try validateNotEmpty(email)
        guard let regex = try? NSRegularExpression(pattern: emailRegex, options: []),
              regex.firstMatch(in: email, options: [], range: NSRange(location: 0, length: email.utf16.count)) != nil else {
            throw ValidationError.invalidEmail
        }
    }

    /// Validate URL format
    public static func validateURL(_ urlString: String) throws {
        try self.validateNotEmpty(urlString)

        guard let url = URL(string: urlString),
            url.scheme != nil,
            url.host != nil
        else {
            throw ValidationError.invalidURL
        }

        // Additional security check - prevent javascript: URLs
        if url.scheme?.lowercased() == "javascript" {
            throw ValidationError.containsXSS
        }
    }

    /// Validate phone number (basic international format)
    public static func validatePhoneNumber(_ phone: String) throws {
        let phoneRegex = #"^\+?[1-9]\d{1,14}$"#
        try validateNotEmpty(phone)

        // Remove common separators for validation
        let cleanPhone = phone.replacingOccurrences(
            of: "[\\s\\-\\(\\)]", with: "", options: .regularExpression)

        guard let regex = try? NSRegularExpression(pattern: phoneRegex, options: []),
              regex.firstMatch(in: cleanPhone, options: [], range: NSRange(location: 0, length: cleanPhone.utf16.count)) != nil else {
            throw ValidationError.invalidPhoneNumber
        }
    }

    /// Validate numeric input
    public static func validateNumeric(_ input: String, min: Double? = nil, max: Double? = nil)
        throws
    {
        try self.validateNotEmpty(input)

        guard let number = Double(input) else {
            throw ValidationError.invalidNumericValue
        }

        if let min, number < min {
            throw ValidationError.custom(message: "Value must be at least \(min)")
        }
        if let max, number > max {
            throw ValidationError.custom(message: "Value must be at most \(max)")
        }
    }

    // MARK: - Security Validation

    /// Check for SQL injection patterns
    public static func validateNoSQLInjection(_ input: String) throws {
        let sqlPatterns = [
            "SELECT.*FROM",
            "INSERT.*INTO",
            "UPDATE.*SET",
            "DELETE.*FROM",
            "DROP.*TABLE",
            "UNION.*SELECT",
            "--",
            ";",
            "/*",
            "*/",
        ]

        for pattern in sqlPatterns
        where input.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
            throw ValidationError.containsSQLInjection
        }
    }

    /// Check for XSS patterns
    public static func validateNoXSS(_ input: String) throws {
        let xssPatterns = [
            "<script",
            "javascript:",
            "onload=",
            "onerror=",
            "onclick=",
            "<iframe",
            "<object",
            "<embed",
        ]

        let lowerInput = input.lowercased()
        for pattern in xssPatterns where lowerInput.contains(pattern) {
            throw ValidationError.containsXSS
        }
    }

    /// Check for path traversal attempts
    public static func validateNoPathTraversal(_ input: String) throws {
        let traversalPatterns = [
            "../",
            "..\\",
            "/../",
            "\\..\\",
            "/etc/",
            "/bin/",
            "C:\\\\",
            "/home/",
        ]

        for pattern in traversalPatterns where input.contains(pattern) {
            throw ValidationError.containsPathTraversal
        }
    }

    /// Validate filename (prevent directory traversal and dangerous extensions)
    public static func validateFilename(_ filename: String) throws {
        try self.validateNotEmpty(filename)
        try self.validateLength(filename, max: 255)
        try self.validateNoPathTraversal(filename)

        // Check for dangerous file extensions
        let dangerousExtensions = [
            "exe", "bat", "cmd", "com", "pif", "scr", "vbs", "js", "jar", "sh",
        ]

        let fileExtension = (filename as NSString).pathExtension.lowercased()
        if dangerousExtensions.contains(fileExtension) {
            throw ValidationError.custom(message: "File type not allowed")
        }

        // Check for invalid characters in filename
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        if filename.rangeOfCharacter(from: invalidChars) != nil {
            throw ValidationError.containsInvalidCharacters(characters: "/\\:*?\"<>|")
        }
    }

    // MARK: - Sanitization

    /// Sanitize HTML content (basic)
    public static func sanitizeHTML(_ input: String) -> String {
        var sanitized = input
        let htmlEntities = [
            "<": "&lt;",
            ">": "&gt;",
            "&": "&amp;",
            "\"": "&quot;",
            "'": "&#x27;",
            "/": "&#x2F;",
        ]

        for (char, entity) in htmlEntities {
            sanitized = sanitized.replacingOccurrences(of: char, with: entity)
        }

        return sanitized
    }

    /// Sanitize SQL input (basic escaping)
    public static func sanitizeSQL(_ input: String) -> String {
        input.replacingOccurrences(of: "'", with: "''")
    }

    /// Remove potentially dangerous characters
    public static func sanitizeInput(_ input: String) -> String {
        // Remove null bytes and other control characters
        let controlChars = CharacterSet.controlCharacters
        return input.components(separatedBy: controlChars).joined()
    }

    // MARK: - Combined Validation

    /// Comprehensive validation for user names
    public static func validateUsername(_ username: String) throws {
        try self.validateNotEmpty(username)
        try self.validateLength(username, min: 3, max: 50)
        try self.validateNoSQLInjection(username)
        try self.validateNoXSS(username)

        // Check for valid username characters (alphanumeric, underscore, dash)
        let usernameRegex = #"^[a-zA-Z0-9_-]+$"#
        guard let regex = try? NSRegularExpression(pattern: usernameRegex, options: []),
              regex.firstMatch(in: username, options: [], range: NSRange(location: 0, length: username.utf16.count)) != nil else {
            throw
                ValidationError
                .invalidFormat(
                    description:
                        "Username can only contain letters, numbers, underscores, and dashes")
        }
    }

    /// Comprehensive validation for passwords
    public static func validatePassword(_ password: String) throws {
        try self.validateNotEmpty(password)
        try self.validateLength(password, min: 8, max: 128)

        // Check for at least one uppercase, one lowercase, one digit
        let uppercaseRegex = ".*[A-Z].*"
        let lowercaseRegex = ".*[a-z].*"
        let digitRegex = ".*[0-9].*"

        guard password.range(of: uppercaseRegex, options: .regularExpression) != nil else {
            throw ValidationError.custom(
                message: "Password must contain at least one uppercase letter")
        }

        guard password.range(of: lowercaseRegex, options: .regularExpression) != nil else {
            throw ValidationError.custom(
                message: "Password must contain at least one lowercase letter")
        }

        guard password.range(of: digitRegex, options: .regularExpression) != nil else {
            throw ValidationError.custom(message: "Password must contain at least one digit")
        }
    }

    /// Comprehensive validation for general text input
    public static func validateTextInput(_ input: String, maxLength: Int = 1000) throws {
        try self.validateNotEmpty(input)
        try self.validateLength(input, max: maxLength)
        try self.validateNoSQLInjection(input)
        try self.validateNoXSS(input)
        try self.validateNoPathTraversal(input)
    }

    /// Validate and sanitize user input (returns sanitized version)
    public static func validateAndSanitize(_ input: String, maxLength: Int = 1000) throws -> String
    {
        try self.validateTextInput(input, maxLength: maxLength)
        return self.sanitizeInput(input)
    }
}

// MARK: - Extensions

extension String {
    /// Validate this string with comprehensive security checks
    public func validated(as type: ValidationType, options: ValidationOptions = .default) throws
        -> String
    {
        switch type {
        case .username:
            try InputValidator.validateUsername(self)
        case .password:
            try InputValidator.validatePassword(self)
        case .email:
            try InputValidator.validateEmail(self)
        case .url:
            try InputValidator.validateURL(self)
        case .phone:
            try InputValidator.validatePhoneNumber(self)
        case .filename:
            try InputValidator.validateFilename(self)
        case .text:
            try InputValidator.validateTextInput(self, maxLength: options.maxLength)
        case .numeric:
            try InputValidator.validateNumeric(self, min: options.minValue, max: options.maxValue)
        }

        return options.sanitize ? InputValidator.sanitizeInput(self) : self
    }
}

public enum ValidationType {
    case username
    case password
    case email
    case url
    case phone
    case filename
    case text
    case numeric
}

public struct ValidationOptions: Sendable {
    public let maxLength: Int
    public let minValue: Double?
    public let maxValue: Double?
    public let sanitize: Bool

    public static let `default` = ValidationOptions(
        maxLength: 1000, minValue: nil, maxValue: nil, sanitize: true)

    public init(
        maxLength: Int = 1000, minValue: Double? = nil, maxValue: Double? = nil,
        sanitize: Bool = true
    ) {
        self.maxLength = maxLength
        self.minValue = minValue
        self.maxValue = maxValue
        self.sanitize = sanitize
    }
}
