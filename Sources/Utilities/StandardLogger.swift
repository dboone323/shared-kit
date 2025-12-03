//
// StandardLogger.swift
// SharedKit
//
// Unified logging wrapper for the entire suite
//

import Foundation
import os

public enum LogLevel: String {
    case debug = "💜 DEBUG"
    case info = "💚 INFO"
    case warning = "💛 WARNING"
    case error = "❤️ ERROR"
}

public struct StandardLogger {
    public static let shared = StandardLogger()
    private let logger = Logger(subsystem: "com.tools-automation", category: "General")

    public func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.rawValue) [\(fileName):\(line)] \(function) -> \(message)"

        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }

        #if DEBUG
            print(logMessage)
        #endif
    }
}
