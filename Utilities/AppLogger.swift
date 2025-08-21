// Compatibility wrapper to match CodingReviewer AppLogger API.
import Foundation
import OSLog

/// Lightweight wrapper providing a shared instance to delegate to the static `Logger` API.
final class AppLogger {
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
        case .ui: return Logger.ui
        case .data: return Logger.data
        case .business: return Logger.business
        case .network: return Logger.network
        case .performance: return Logger.performance
        default: return Logger.business
        }
    }

    func log(_ message: String, level: LogLevel = .info, category: LogCategory = .general) {
        let oslog = osLog(for: category)
        switch level {
        case .debug:
            Logger.logDebug(message, category: oslog)
        case .info:
            Logger.logInfo(message, category: oslog)
        case .warning:
            Logger.logWarning(message, category: oslog)
        case .error:
            Logger.logError(
                NSError(
                    domain: "AppLogger", code: 1, userInfo: [NSLocalizedDescriptionKey: message]),
                context: "")
        case .critical:
            Logger.logWarning(message, category: oslog)
        }
    }

    func debug(_ message: String) {
        Logger.logDebug(message, category: Logger.ui)
    }

    func logWarning(_ message: String) {
        Logger.logWarning(message, category: Logger.business)
    }

    func logError(_ error: Error, context: String = "") {
        Logger.logError(error, context: context)
    }
}
