import Foundation

#if canImport(os)
    import os.log
    private typealias PlatformLogger = os.Logger
#else
    import Foundation
    private struct PlatformLogger {
        let category: String
        init(subsystem: String, category: String) { self.category = category }
        func debug(_ msg: String) { print("[\(category)] [DEBUG] \(msg)") }
        func info(_ msg: String) { print("[\(category)] [INFO] \(msg)") }
        func notice(_ msg: String) { print("[\(category)] [NOTICE] \(msg)") }
        func error(_ msg: String) { print("[\(category)] [ERROR] \(msg)") }
        func fault(_ msg: String) { print("[\(category)] [FAULT] \(msg)") }
    }
#endif

/// Secure logging utility for Shared-Kit
/// Replaces print() statements with proper logging
@available(macOS 11.0, iOS 14.0, *)
public final class SecureLogger {

    /// Subsystem identifier for logging
    private static let subsystem = "com.yourapp.shared-kit"

    /// Log categories for organization
    public enum Category: String {
        case general = "General"
        case network = "Network"
        case database = "Database"
        case haptics = "Haptics"
        case system = "System"  // Added for file system operations
        case ai = "AI"
        case performance = "Performance"
        case security = "Security"
        case ui = "UI"
        case toolExecution = "ToolExecution"  // For agent tool delegation
    }

    /// Log levels matching OSLog
    public enum Level {
        case debug
        case info
        case notice
        case error
        case fault
    }

    // MARK: - Logger Instances

    /// Get or create logger for category (creates new logger each time - no mutable state)
    private static func logger(for category: Category) -> PlatformLogger {
        return PlatformLogger(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Public Logging Methods

    /// Log debug message (only in debug builds)
    public static func debug(
        _ message: String, category: Category = .general, file: String = #file, line: Int = #line
    ) {
        #if DEBUG
            logger(for: category).debug("\(message) [\(fileBasename(file)):\(line)]")
        #endif
    }

    /// Log informational message
    public static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message)")
    }

    /// Log notice (significant but not error)
    public static func notice(_ message: String, category: Category = .general) {
        logger(for: category).notice("\(message)")
    }

    /// Log error
    public static func error(
        _ message: String, category: Category = .general, error: Error? = nil, file: String = #file,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        logger(for: category).error("\(fullMessage) [\(fileBasename(file)):\(line)]")
    }

    /// Log critical fault
    public static func fault(
        _ message: String, category: Category = .general, file: String = #file, line: Int = #line
    ) {
        logger(for: category).fault("\(message) [\(fileBasename(file)):\(line)]")
    }

    // MARK: - Specialized Logging

    /// Log performance metric
    public static func performance(
        _ operation: String, duration: TimeInterval, category: Category = .performance
    ) {
        logger(for: category).notice(
            "⏱️ \(operation) completed in \(String(format: "%.3f", duration))s")
    }

    /// Log network request
    public static func networkRequest(_ method: String, url: String) {
        logger(for: .network).info("→ \(method) \(redactURL(url))")
    }

    /// Log network response
    public static func networkResponse(_ statusCode: Int, url: String, duration: TimeInterval) {
        logger(for: .network).info(
            "← \(statusCode) \(redactURL(url)) (\(String(format: "%.2f", duration))s)")
    }

    /// Log database query (redacted)
    public static func databaseQuery(_ query: String) {
        // Redact sensitive data from queries
        let redacted = redactSensitiveData(query)
        logger(for: .database).debug("🗄️ Query: \(redacted)")
    }

    /// Log security event
    public static func securityEvent(_ event: String, severity: Level = .notice) {
        let message = "🔒 Security: \(event)"
        switch severity {
        case .debug: logger(for: .security).debug("\(message)")
        case .info: logger(for: .security).info("\(message)")
        case .notice: logger(for: .security).notice("\(message)")
        case .error: logger(for: .security).error("\(message)")
        case .fault: logger(for: .security).fault("\(message)")
        }
    }

    // MARK: - Helper Methods

    /// Extract filename from full path
    private static func fileBasename(_ filePath: String) -> String {
        return (filePath as NSString).lastPathComponent
    }

    /// Redact sensitive data from URLs
    private static func redactURL(_ url: String) -> String {
        // Remove query parameters that might contain tokens
        if let urlObj = URL(string: url),
            let components = URLComponents(url: urlObj, resolvingAgainstBaseURL: false)
        {
            var clean = components
            if clean.queryItems != nil {
                clean.queryItems = [URLQueryItem(name: "redacted", value: "***")]
            }
            return clean.url?.absoluteString ?? url
        }
        return url
    }

    /// Redact sensitive data from strings
    private static func redactSensitiveData(_ text: String) -> String {
        var redacted = text

        // Redact common sensitive patterns
        let patterns = [
            ("password\\s*=\\s*['\"]?[^'\"\\s]+", "password=***"),
            ("token\\s*=\\s*['\"]?[^'\"\\s]+", "token=***"),
            ("api[_-]?key\\s*=\\s*['\"]?[^'\"\\s]+", "api_key=***"),
            ("secret\\s*=\\s*['\"]?[^'\"\\s]+", "secret=***"),
        ]

        for (pattern, replacement) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                redacted = regex.stringByReplacingMatches(
                    in: redacted, range: range, withTemplate: replacement)
            }
        }

        return redacted
    }
}

// MARK: - Convenience Extensions

@available(macOS 11.0, iOS 14.0, *)
extension SecureLogger {
    /// Log with custom level
    public static func log(
        _ message: String, level: Level, category: Category = .general, error: Error? = nil
    ) {
        switch level {
        case .debug: debug(message, category: category)
        case .info: info(message, category: category)
        case .notice: notice(message, category: category)
        case .error: self.error(message, category: category, error: error)
        case .fault: fault(message, category: category)
        }
    }
}

// MARK: - Migration Helper

@available(macOS 11.0, iOS 14.0, *)
extension SecureLogger {
    /// Temporary compatibility method for gradual migration from print()
    /// Mark as deprecated to encourage proper usage
    @available(*, deprecated, message: "Use SecureLogger.debug/info/error instead")
    public static func legacy(_ message: String) {
        #if DEBUG
            print("[LEGACY] \(message)")
        #endif
    }
}

// MARK: - Global Convenience (Optional)

/// Global logging functions for easier migration
@available(macOS 11.0, iOS 14.0, *)
public func logDebug(_ message: String, category: SecureLogger.Category = .general) {
    SecureLogger.debug(message, category: category)
}

@available(macOS 11.0, iOS 14.0, *)
public func logInfo(_ message: String, category: SecureLogger.Category = .general) {
    SecureLogger.info(message, category: category)
}

@available(macOS 11.0, iOS 14.0, *)
public func logError(
    _ message: String, category: SecureLogger.Category = .general, error: Error? = nil
) {
    SecureLogger.error(message, category: category, error: error)
}
