// Compatibility wrapper to match CodingReviewer AppLogger API.
import Foundation
#if canImport(OSLog)
import OSLog
#endif

/// Lightweight wrapper providing a shared instance to delegate to the static `Logger` API.
final class AppLogger: @unchecked Sendable {
    static let shared = AppLogger()
    private init() {}

    // Local LogLevel used by callers (keeps compatibility with CodingReviewer usage)
    enum LogLevel {
        case debug, info, warning, error, critical
    }

    // Local LogCategory maps to MomentumFinance Logger OSLog categories
    enum LogCategory {
        case general, analysis, performance, security, ui, ai, network, data, business
    }

    private func osLog(for category: LogCategory) -> OSLog {
        switch category {
        case .ui: SharedLogger.ui
        case .data: SharedLogger.data
        case .business: SharedLogger.business
        case .network: SharedLogger.network
        case .performance: SharedLogger.performance
        default: SharedLogger.business
        }
    }

    func log(_ message: String, level: LogLevel = .info, category: LogCategory = .general) {
        let oslog = self.osLog(for: category)
        switch level {
        case .debug:
            SharedLogger.logDebug(message, category: oslog)
        case .info:
            SharedLogger.logInfo(message, category: oslog)
        case .warning:
            SharedLogger.logWarning(message, category: oslog)
        case .error:
            SharedLogger.logError(
                NSError(
                    domain: "AppLogger", code: 1, userInfo: [NSLocalizedDescriptionKey: message]
                ),
                context: ""
            )
        case .critical:
            SharedLogger.logWarning(message, category: oslog)
        }
    }

    func debug(_ message: String) {
        SharedLogger.logDebug(message, category: SharedLogger.ui)
    }

    func logWarning(_ message: String) {
        SharedLogger.logWarning(message, category: SharedLogger.business)
    }

    func logError(_ error: Error, context: String = "") {
        SharedLogger.logError(error, context: context)
    }
}
