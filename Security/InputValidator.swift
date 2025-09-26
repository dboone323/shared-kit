import Foundation

/// Comprehensive input validation and sanitization utilities
/// Provides secure validation for user inputs across all Quantum Workspace projects

public enum ValidationError: LocalizedError {
    case emptyInput
    case invalidLength(min: Int, max: Int)
    case invalidFormat(description: String)
    case containsInvalidCharacters(characters: String)
    case exceedsMaximumLength(max: Int)
    case belowMinimumLength(min: Int)
    case invalidEmail
    case invalidURL
    case invalidPhoneNumber
    case containsSQLInjection
    case containsXSS
    case containsPathTraversal
    case invalidNumericValue
    case invalidDate
    case custom(message: String)

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input cannot be empty"
        case let .invalidLength(min, max):
            return "Input must be between \(min) and \(max) characters"
        case let .invalidFormat(description):
            return "Invalid format: \(description)"
        case let .containsInvalidCharacters(characters):
            return "Input contains invalid characters: \(characters)"
        case let .exceedsMaximumLength(max):
            return "Input exceeds maximum length of \(max) characters"
        case let .belowMinimumLength(min):
            return "Input must be at least \(min) characters"
        case .invalidEmail:
            return "Invalid email address format"
        case .invalidURL:
            return "Invalid URL format"
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .containsSQLInjection:
            return "Input contains potentially malicious SQL content"
        case .containsXSS:
            return "Input contains potentially malicious script content"
        case .containsPathTraversal:
            return "Input contains path traversal attempts"
        case .invalidNumericValue:
            return "Invalid numeric value"
        case .invalidDate:
            return "Invalid date format"
        case let .custom(message):
            return message
        }
    }
}

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
        if let min = min, input.count < min {
            throw ValidationError.belowMinimumLength(min: min)
        }
        if let max = max, input.count > max {
            throw ValidationError.exceedsMaximumLength(max: max)
        }
        if let min = min, let max = max, input.count < min || input.count > max {
            throw ValidationError.invalidLength(min: min, max: max)
        }
    }

    /// Validate email format
    public static func validateEmail(_ email: String) throws {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        try validateNotEmpty(email)

        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidEmail
        }
    }

    /// Validate URL format
    public static func validateURL(_ urlString: String) throws {
        try validateNotEmpty(urlString)

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
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)

        try validateNotEmpty(phone)

        // Remove common separators for validation
        let cleanPhone = phone.replacingOccurrences(of: "[\\s\\-\\(\\)]", with: "", options: .regularExpression)

        guard phonePredicate.evaluate(with: cleanPhone) else {
            throw ValidationError.invalidPhoneNumber
        }
    }

    /// Validate numeric input
    public static func validateNumeric(_ input: String, min: Double? = nil, max: Double? = nil) throws {
        try validateNotEmpty(input)

        guard let number = Double(input) else {
            throw ValidationError.invalidNumericValue
        }

        if let min = min, number < min {
            throw ValidationError.custom(message: "Value must be at least \(min)")
        }
        if let max = max, number > max {
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

        for pattern in sqlPatterns {
            if input.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                throw ValidationError.containsSQLInjection
            }
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
        for pattern in xssPatterns {
            if lowerInput.contains(pattern) {
                throw ValidationError.containsXSS
            }
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

        for pattern in traversalPatterns {
            if input.contains(pattern) {
                throw ValidationError.containsPathTraversal
            }
        }
    }

    /// Validate filename (prevent directory traversal and dangerous extensions)
    public static func validateFilename(_ filename: String) throws {
        try validateNotEmpty(filename)
        try validateLength(filename, max: 255)
        try validateNoPathTraversal(filename)

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
        return input.replacingOccurrences(of: "'", with: "''")
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
        try validateNotEmpty(username)
        try validateLength(username, min: 3, max: 50)
        try validateNoSQLInjection(username)
        try validateNoXSS(username)

        // Check for valid username characters (alphanumeric, underscore, dash)
        let usernameRegex = #"^[a-zA-Z0-9_-]+$"#
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)

        guard usernamePredicate.evaluate(with: username) else {
            throw ValidationError.invalidFormat(description: "Username can only contain letters, numbers, underscores, and dashes")
        }
    }

    /// Comprehensive validation for passwords
    public static func validatePassword(_ password: String) throws {
        try validateNotEmpty(password)
        try validateLength(password, min: 8, max: 128)

        // Check for at least one uppercase, one lowercase, one digit
        let uppercaseRegex = ".*[A-Z].*"
        let lowercaseRegex = ".*[a-z].*"
        let digitRegex = ".*[0-9].*"

        guard password.range(of: uppercaseRegex, options: .regularExpression) != nil else {
            throw ValidationError.custom(message: "Password must contain at least one uppercase letter")
        }

        guard password.range(of: lowercaseRegex, options: .regularExpression) != nil else {
            throw ValidationError.custom(message: "Password must contain at least one lowercase letter")
        }

        guard password.range(of: digitRegex, options: .regularExpression) != nil else {
            throw ValidationError.custom(message: "Password must contain at least one digit")
        }
    }

    /// Comprehensive validation for general text input
    public static func validateTextInput(_ input: String, maxLength: Int = 1000) throws {
        try validateNotEmpty(input)
        try validateLength(input, max: maxLength)
        try validateNoSQLInjection(input)
        try validateNoXSS(input)
        try validateNoPathTraversal(input)
    }

    /// Validate and sanitize user input (returns sanitized version)
    public static func validateAndSanitize(_ input: String, maxLength: Int = 1000) throws -> String {
        try validateTextInput(input, maxLength: maxLength)
        return sanitizeInput(input)
    }
}

// MARK: - Extensions

public extension String {
    /// Validate this string with comprehensive security checks
    func validated(as type: ValidationType, options: ValidationOptions = .default) throws -> String {
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

public struct ValidationOptions {
    public let maxLength: Int
    public let minValue: Double?
    public let maxValue: Double?
    public let sanitize: Bool

    public static let `default` = ValidationOptions(maxLength: 1000, minValue: nil, maxValue: nil, sanitize: true)

    public init(maxLength: Int = 1000, minValue: Double? = nil, maxValue: Double? = nil, sanitize: Bool = true) {
        self.maxLength = maxLength
        self.minValue = minValue
        self.maxValue = maxValue
        self.sanitize = sanitize
    }
}
