import Foundation

/// Enhanced context window management for AggregatorAgent
@available(macOS 11.0, iOS 14.0, *)
public class ContextWindowManager {
    private let maxTokens: Int
    private let tokensPerMessage: Int = 100 // Rough estimate

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
        max(text.count / 4, 1)
    }
}

/// Tool result cache for AggregatorAgent
@available(macOS 11.0, iOS 14.0, *)
public actor ToolResultCache {
    private var cache: [String: (result: String, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes

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
            return results.sorted(by: { $0.0 < $1.0 }).map(\.1)
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
            return 0.5 // Default for unknown tools
        }
        return Double(stats.success) / Double(stats.total)
    }

    /// Recommend best tool for task
    public func recommendTool(from options: [String]) -> String? {
        options.max { successRate(for: $0) < successRate(for: $1) }
    }
}

// MARK: - Step 35: Smart Batch Processing

public struct BatchTask<T: Sendable>: Sendable {
    public let id: String
    public let priority: Int // 0-10, 10 is highest
    public let operation: @Sendable () async throws -> T
    public let created: Date = .init()
}

@available(macOS 12.0, iOS 15.0, *)
public actor SmartBatchProcessor<T: Sendable> {
    private var queue: [BatchTask<T>] = []
    private var isProcessing = false
    private let maxBatchSize: Int
    private let batchWindow: TimeInterval // Max wait time (N ms)

    public init(maxBatchSize: Int = 5, batchWindow: TimeInterval = 0.05) {
        self.maxBatchSize = maxBatchSize
        self.batchWindow = batchWindow
    }

    /// Submit task for processing
    public func submit(_ task: BatchTask<T>) {
        queue.append(task)
        // Sort by priority descending, then creation time
        queue.sort {
            if $0.priority == $1.priority {
                return $0.created < $1.created
            }
            return $0.priority > $1.priority
        }

        processQueueIfNeeded()
    }

    private func processQueueIfNeeded() {
        guard !isProcessing, !queue.isEmpty else { return }

        Task {
            isProcessing = true

            // Dynamic Batching: Wait small window to gather more tasks if queue is small
            if queue.count < maxBatchSize {
                try? await Task.sleep(nanoseconds: UInt64(batchWindow * 1_000_000_000))
            }

            await processBatch()
            isProcessing = false

            // Continue if more items
            if !queue.isEmpty {
                processQueueIfNeeded()
            }
        }
    }

    private func processBatch() async {
        // Take up to maxBatchSize
        let count = min(queue.count, maxBatchSize)
        let batch = Array(queue.prefix(count))
        queue.removeFirst(count)

        // Execute in parallel
        await withTaskGroup(of: Void.self) { group in
            for task in batch {
                group.addTask {
                    // Execute operation
                    // In a real implementation, we'd need a way to return results to the caller
                    // e.g., via continuations or callbacks stored in the BatchTask
                    _ = try? await task.operation()
                }
            }
        }
    }
}

struct TimeoutError: Error {}
