import Foundation

/// Structured result from tool execution
public struct ToolExecutionResult: Sendable {
    public let toolName: String
    public let success: Bool
    public let output: String
    public let metrics: [String: String]
    public let warnings: [String]
    public let suggestions: [String]

    public init(toolName: String, success: Bool, output: String, metrics: [String: String] = [:], warnings: [String] = [], suggestions: [String] = []) {
        self.toolName = toolName
        self.success = success
        self.output = output
        self.metrics = metrics
        self.warnings = warnings
        self.suggestions = suggestions
    }

    /// Parse structured output from docker-manager and extract key information
    public static func parse(toolName: String, rawOutput: String) -> ToolExecutionResult {
        var success = !rawOutput.lowercased().contains("error")
        var metrics: [String: String] = [:]
        var warnings: [String] = []
        var suggestions: [String] = []

        // Parse container counts for status command
        if toolName.contains("status") {
            let lines = rawOutput.split(separator: "\n")
            for line in lines {
                if line.contains("running") || line.contains("healthy") {
                    if let count = line.split(separator: " ").first(where: { Int($0) != nil }) {
                        metrics["containers_running"] = String(count)
                    }
                }
            }
        }

        // Extract warnings
        let warningLines = rawOutput.split(separator: "\n").filter {
            $0.lowercased().contains("warn") || $0.lowercased().contains("deprecated")
        }
        warnings = warningLines.map { String($0) }

        // Extract error messages for failed operations
        if rawOutput.lowercased().contains("error") || rawOutput.lowercased().contains("failed") {
            success = false
            let errorLines = rawOutput.split(separator: "\n").filter {
                $0.lowercased().contains("error") || $0.lowercased().contains("failed")
            }
            if !errorLines.isEmpty {
                suggestions.append("Check logs for: \(errorLines.first ?? "")")
            }
        }

        return ToolExecutionResult(
            toolName: toolName,
            success: success,
            output: rawOutput,
            metrics: metrics,
            warnings: warnings,
            suggestions: suggestions
        )
    }
}

/// Enhanced memory with entity tracking
public struct EntityMemory: Sendable {
    public var services: Set<String> = []
    public var recentErrors: [String] = []
    public var mentionedFiles: Set<String> = []

    public mutating func extractEntities(from text: String) {
        // Extract service names (common Docker services)
        let servicePatterns = ["postgres", "redis", "ollama", "grafana", "sonarqube", "prometheus", "db"]
        for pattern in servicePatterns {
            if text.lowercased().contains(pattern) {
                services.insert(pattern)
            }
        }

        // Extract file paths using basic string matching
        let words = text.split(separator: " ")
        for word in words {
            let wordStr = String(word)
            if wordStr.hasPrefix("/") && wordStr.count > 1 {
                mentionedFiles.insert(wordStr)
            }
        }

        // Track errors
        if text.lowercased().contains("error") {
            let errorLine = text.split(separator: "\n").first(where: { $0.lowercased().contains("error") })
            if let error = errorLine {
                recentErrors.append(String(error))
                if recentErrors.count > 5 {
                    recentErrors.removeFirst()
                }
            }
        }
    }
}
