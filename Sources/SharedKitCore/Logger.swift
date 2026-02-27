// Shared Logger for Quantum Workspace
// Copyright © 2025 Quantum Workspace. All rights reserved.

//
//  SharedLogger.swift
//  SharedKit
//
//  Created by Daniel Stevens
//

import Foundation

#if canImport(OSLog)
    import OSLog
#else
    // Shim for Linux
    public struct OSLog: Sendable {
        let subsystem: String
        let category: String
        public init(subsystem: String, category: String) {
            self.subsystem = subsystem
            self.category = category
        }
    }

    public enum OSLogType {
        case `default`, info, debug, error, fault
    }

    public struct Logger: Sendable {
        let subsystem: String
        let category: String
        public init(subsystem: String, category: String) {
            self.subsystem = subsystem
            self.category = category
        }
        public func info(_ message: String) {
            print("[INFO] [\(category)] \(message)")
        }
        public func debug(_ message: String) {
            print("[DEBUG] [\(category)] \(message)")
        }
        public func error(_ message: String) {
            print("[ERROR] [\(category)] \(message)")
        }
        public func fault(_ message: String) {
            print("[FAULT] [\(category)] \(message)")
        }
    }

    func os_log(_ message: String, log: OSLog, type: OSLogType, _ args: CVarArg...) {
        print("[\(log.category)] \(message)")
    }

    func os_log(_ message: StaticString, log: OSLog, type: OSLogType, _ args: CVarArg...) {
        print("[\(log.category)] \(message)")
    }
#endif

/// Centralized logging system for Quantum Workspace applications
/// Provides structured logging across different categories and severity levels
public enum SharedLogger {
    // MARK: - Core Logger Categories

    static let ui = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "QuantumWorkspace",
        category: "UI"
    )
    static let data = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "QuantumWorkspace",
        category: "Data"
    )
    static let business = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "QuantumWorkspace",
        category: "Business"
    )
    static let network = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "QuantumWorkspace",
        category: "Network"
    )
    static let performance = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "QuantumWorkspace",
        category: "Performance"
    )

    public static let defaultLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "QuantumWorkspace",
        category: "General"
    )
}

// MARK: - Core Logging Methods

extension SharedLogger {
    /// Log error messages with context
    public static func logError(
        _ error: Error,
        context: String = "",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        let message =
            "\(context.isEmpty ? "" : "\(context) - ")\(error.localizedDescription) [\(source)]"
        os_log("%@", log: self.defaultLog, type: .error, message)
    }

    /// Log debug information
    public static func logDebug(
        _ message: String,
        category: OSLog = defaultLog,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
            let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
            os_log("[DEBUG] %@ [%@]", log: category, type: .debug, message, source)
        #endif
    }

    /// Log informational messages
    public static func logInfo(_ message: String, category: OSLog = defaultLog) {
        os_log("%@", log: category, type: .info, message)
    }

    /// Log warning messages
    public static func logWarning(_ message: String, category: OSLog = defaultLog) {
        os_log("%@", log: category, type: .default, message)
    }
}

// MARK: - Business Logic Logging

extension SharedLogger {
    /// Log business-related events and decisions
    public static func logBusiness(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[BUSINESS] %@ [%@]", log: self.business, type: .info, message, source)
    }

    /// Log UI-related events
    public static func logUI(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[UI] %@ [%@]", log: self.ui, type: .info, message, source)
    }

    /// Log data operations
    public static func logData(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[DATA] %@ [%@]", log: self.data, type: .info, message, source)
    }

    /// Log network operations
    public static func logNetwork(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[NETWORK] %@ [%@]", log: self.network, type: .info, message, source)
    }
}

// MARK: - Performance Measurement

extension SharedLogger {
    /// Measure and log execution time of a code block
    public static func measurePerformance<T>(_ operation: String, block: () throws -> T) rethrows
        -> T
    {
        let startTime = Date().timeIntervalSinceReferenceDate
        let result = try block()
        let timeElapsed = Date().timeIntervalSinceReferenceDate - startTime

        os_log(
            "[PERFORMANCE] %@ completed in %.4f seconds", log: self.performance, type: .info,
            operation,
            timeElapsed
        )
        return result
    }

    /// Start a performance measurement session
    public static func startPerformanceMeasurement(_ operation: String) -> PerformanceMeasurement {
        PerformanceMeasurement(operation: operation, startTime: Date().timeIntervalSinceReferenceDate)
    }
}

// MARK: - Context-Aware Logging

extension SharedLogger {
    /// Log with additional context information
    public static func logWithContext(
        _ message: String, context: [String: AnyCodable], category: OSLog = defaultLog,
        type: OSLogType = .info
    ) {
        let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let fullMessage = "\(message) | Context: [\(contextString)]"
        os_log("%@", log: category, type: type, fullMessage)
    }

    /// Log analytics events
    public static func logAnalytics(_ event: String, parameters: [String: AnyCodable] = [:]) {
        let paramString = parameters.isEmpty ? "" : " | Parameters: \(parameters)"
        os_log("[ANALYTICS] %@%@", log: self.defaultLog, type: .info, event, paramString)
    }
}

// MARK: - File Logging Support

extension SharedLogger {
    /// Write log to file for debugging purposes
    public static func writeToFile(_ message: String, fileName: String = "quantum_workspace.log") {
        #if DEBUG
            guard
                let documentsPath = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                ).first
            else { return }
            let logURL = documentsPath.appendingPathComponent(fileName)

            let timestamp = DateFormatter.logFormatter.string(from: Date())
            let logEntry = "[\(timestamp)] \(message)\n"

            if FileManager.default.fileExists(atPath: logURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                    fileHandle.closeFile()
                }
            } else {
                try? logEntry.write(to: logURL, atomically: true, encoding: .utf8)
            }
        #endif
    }
}

// MARK: - Supporting Types

public struct PerformanceMeasurement {
    let operation: String
    let startTime: TimeInterval

    /// <#Description#>
    /// - Returns: <#description#>
    func end() {
        let timeElapsed = Date().timeIntervalSinceReferenceDate - self.startTime
        SharedLogger.logInfo(
            "[PERFORMANCE] \(self.operation) completed in \(String(format: "%.4f", timeElapsed)) seconds",
            category: SharedLogger.performance
        )
    }
}

// MARK: - Extensions

extension DateFormatter {
    fileprivate static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
