import Foundation

/// Enhanced context window management for AggregatorAgent
@available(macOS 11.0, iOS 14.0, *)
public class ContextWindowManager {
    private let maxTokens: Int
    private let tokensPerMessage: Int = 100  // Rough estimate

    public init(maxTokens: Int = 4096) {
        self.maxTokens = maxTokens
    }

    /// Optimize messages to fit within context window
    public func optimizeMessages(_ messages: [ConversationMessage]) -> [ConversationMessage] {
        var optimized: [ConversationMessage] = []
        var tokenCount = 0

        // Always keep the most recent messages
        for message in messages.reversed() {
            let messageTokens = estimateTokens(message.content)
            if tokenCount + messageTokens <= maxTokens {
                optimized.insert(message, at: 0)
                tokenCount += messageTokens
            } else {
                break
            }
        }

        return optimized
    }

    /// Summarize old messages to save context
    public func summarize(_ messages: [ConversationMessage]) async throws -> String {
        let combined = messages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        return "Summary of \(messages.count) earlier messages: " + combined.prefix(200) + "..."
    }

    private func estimateTokens(_ text: String) -> Int {
        // Rough estimate: 4 characters per token
        return max(text.count / 4, 1)
    }
}

/// Tool result cache for AggregatorAgent
@available(macOS 11.0, iOS 14.0, *)
public actor ToolResultCache {
    private var cache: [String: (result: String, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 300  // 5 minutes

    public init() {}

    /// Get cached result if valid
    public func get(for key: String) -> String? {
        guard let entry = cache[key] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.result
    }

    /// Cache a result
    public func set(_ result: String, for key: String) {
        cache[key] = (result, Date())

        // Cleanup old entries
        if cache.count > 100 {
            cleanup()
        }
    }

    private func cleanup() {
        let now = Date()
        cache = cache.filter { now.timeIntervalSince($0.value.timestamp) <= ttl }
    }
}

/// Tool execution parallelizer
@available(macOS 11.0, iOS 14.0, *)
public class ToolExecutionCoordinator {
    /// Execute multiple tools in parallel
    public func executeParallel(
        tools: [@Sendable () async throws -> String]
    ) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, tool) in tools.enumerated() {
                group.addTask {
                    let result = try await tool()
                    return (index, result)
                }
            }

            var results: [(Int, String)] = []
            for try await (index, result) in group {
                results.append((index, result))
            }

            // Return in original order
            return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
        }
    }
    /// Execute with timeout
    public func executeWithTimeout(
        seconds: TimeInterval,
        block: @escaping @Sendable () async throws -> String
    ) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await block()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

/// Learning system for tool selection
@available(macOS 11.0, iOS 14.0, *)
public actor ToolLearningSystem {
    private var successRates: [String: (success: Int, total: Int)] = [:]

    public init() {}

    /// Record tool execution outcome
    public func recordOutcome(tool: String, success: Bool) {
        var stats = successRates[tool] ?? (0, 0)
        stats.total += 1
        if success {
            stats.success += 1
        }
        successRates[tool] = stats
    }

    /// Get success rate for tool
    public func successRate(for tool: String) -> Double {
        guard let stats = successRates[tool], stats.total > 0 else {
            return 0.5  // Default for unknown tools
        }
        return Double(stats.success) / Double(stats.total)
    }

    /// Recommend best tool for task
    public func recommendTool(from options: [String]) -> String? {
        options.max { successRate(for: $0) < successRate(for: $1) }
    }
}

struct TimeoutError: Error {}
