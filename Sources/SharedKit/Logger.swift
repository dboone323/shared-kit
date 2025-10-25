// Shared Logger for Quantum Workspace
// Copyright © 2025 Quantum Workspace. All rights reserved.

//
//  Logger.swift
//  SharedKit
//
//  Created by Daniel Stevens
//

import Foundation
import OSLog

/// Centralized logging system for Quantum Workspace applications
/// Provides structured logging across different categories and severity levels
public enum Logger {
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

public extension Logger {
    /// Log error messages with context
    static func logError(
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
    static func logDebug(
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
    static func logInfo(_ message: String, category: OSLog = defaultLog) {
        os_log("%@", log: category, type: .info, message)
    }

    /// Log warning messages
    static func logWarning(_ message: String, category: OSLog = defaultLog) {
        os_log("%@", log: category, type: .default, message)
    }
}

// MARK: - Business Logic Logging

public extension Logger {
    /// Log business-related events and decisions
    static func logBusiness(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[BUSINESS] %@ [%@]", log: self.business, type: .info, message, source)
    }

    /// Log UI-related events
    static func logUI(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[UI] %@ [%@]", log: self.ui, type: .info, message, source)
    }

    /// Log data operations
    static func logData(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[DATA] %@ [%@]", log: self.data, type: .info, message, source)
    }

    /// Log network operations
    static func logNetwork(
        _ message: String, file: String = #file, function: String = #function, line: Int = #line
    ) {
        let source = "\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)"
        os_log("[NETWORK] %@ [%@]", log: self.network, type: .info, message, source)
    }
}

// MARK: - Performance Measurement

public extension Logger {
    /// Measure and log execution time of a code block
    static func measurePerformance<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        os_log(
            "[PERFORMANCE] %@ completed in %.4f seconds", log: self.performance, type: .info,
            operation,
            timeElapsed
        )
        return result
    }

    /// Start a performance measurement session
    static func startPerformanceMeasurement(_ operation: String) -> PerformanceMeasurement {
        PerformanceMeasurement(operation: operation, startTime: CFAbsoluteTimeGetCurrent())
    }
}

// MARK: - Context-Aware Logging

public extension Logger {
    /// Log with additional context information
    static func logWithContext(
        _ message: String, context: [String: Any], category: OSLog = defaultLog,
        type: OSLogType = .info
    ) {
        let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let fullMessage = "\(message) | Context: [\(contextString)]"
        os_log("%@", log: category, type: type, fullMessage)
    }

    /// Log analytics events
    static func logAnalytics(_ event: String, parameters: [String: Any] = [:]) {
        let paramString = parameters.isEmpty ? "" : " | Parameters: \(parameters)"
        os_log("[ANALYTICS] %@%@", log: self.defaultLog, type: .info, event, paramString)
    }
}

// MARK: - File Logging Support

public extension Logger {
    /// Write log to file for debugging purposes
    static func writeToFile(_ message: String, fileName: String = "quantum_workspace.log") {
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
    let startTime: CFAbsoluteTime

    /// <#Description#>
    /// - Returns: <#description#>
    func end() {
        let timeElapsed = CFAbsoluteTimeGetCurrent() - self.startTime
        Logger.logInfo(
            "[PERFORMANCE] \(self.operation) completed in \(String(format: "%.4f", timeElapsed)) seconds",
            category: Logger.performance
        )
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
