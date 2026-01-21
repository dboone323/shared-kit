import Foundation

/// Feedback tracking for agent responses to enable learning
@available(macOS 12.0, *)
public actor FeedbackLearningSystem {
    public static let shared = FeedbackLearningSystem()

    private var feedbackHistory: [ResponseFeedback] = []
    private let maxHistorySize = 100

    public struct ResponseFeedback: Sendable, Codable {
        public let responseId: UUID
        public let query: String
        public let response: String
        public let rating: Rating
        public let timestamp: Date
        public let toolUsed: String?

        public enum Rating: String, Codable, Sendable {
            case helpful // Thumbs up
            case unhelpful // Thumbs down
            case neutral
        }

        public init(
            responseId: UUID, query: String, response: String, rating: Rating,
            toolUsed: String? = nil
        ) {
            self.responseId = responseId
            self.query = query
            self.response = response
            self.rating = rating
            self.timestamp = Date()
            self.toolUsed = toolUsed
        }
    }

    private init() {
        Task {
            await loadFeedback()
        }
    }

    /// Record user feedback for a response
    public func recordFeedback(
        responseId: UUID,
        query: String,
        response: String,
        rating: ResponseFeedback.Rating,
        toolUsed: String? = nil
    ) {
        let feedback = ResponseFeedback(
            responseId: responseId,
            query: query,
            response: response,
            rating: rating,
            toolUsed: toolUsed
        )

        feedbackHistory.append(feedback)

        if feedbackHistory.count > maxHistorySize {
            feedbackHistory.removeFirst()
        }

        saveFeedback()

        print("📊 Feedback: \(rating.rawValue) for query: '\(query.prefix(50))'")
    }

    /// Get statistics on feedback
    public func getStatistics() -> FeedbackStats {
        let helpful = feedbackHistory.filter { $0.rating == .helpful }.count
        let unhelpful = feedbackHistory.filter { $0.rating == .unhelpful }.count
        let total = feedbackHistory.count

        let successRate = total > 0 ? Double(helpful) / Double(total) : 0.0

        // Analyze tool performance
        var toolStats: [String: (helpful: Int, total: Int)] = [:]
        for feedback in feedbackHistory where feedback.toolUsed != nil {
            let tool = feedback.toolUsed!
            let current = toolStats[tool] ?? (helpful: 0, total: 0)
            toolStats[tool] = (
                helpful: current.helpful + (feedback.rating == .helpful ? 1 : 0),
                total: current.total + 1
            )
        }

        return FeedbackStats(
            totalFeedback: total,
            helpfulCount: helpful,
            unhelpfulCount: unhelpful,
            successRate: successRate,
            toolPerformance: toolStats
        )
    }

    /// Get problematic patterns (queries that often get negative feedback)
    public func getProblematicPatterns() -> [String] {
        var queryFeedback: [String: [ResponseFeedback.Rating]] = [:]

        for feedback in feedbackHistory {
            let key = feedback.query.lowercased()
            if queryFeedback[key] == nil {
                queryFeedback[key] = []
            }
            queryFeedback[key]?.append(feedback.rating)
        }

        return queryFeedback.compactMap { query, ratings in
            let unhelpfulCount = ratings.filter { $0 == .unhelpful }.count
            let total = ratings.count
            if total >= 2 && Double(unhelpfulCount) / Double(total) > 0.5 {
                return query
            }
            return nil
        }
    }

    /// Get improvement suggestions based on feedback
    public func getImprovementSuggestions() -> [String] {
        var suggestions: [String] = []

        let stats = getStatistics()

        if stats.successRate < 0.7 && stats.totalFeedback > 10 {
            suggestions.append(
                "Overall success rate is low (\(Int(stats.successRate * 100))%). Consider improving planning logic or adding more context."
            )
        }

        for (tool, perf) in stats.toolPerformance {
            let toolSuccess = Double(perf.helpful) / Double(perf.total)
            if toolSuccess < 0.5 && perf.total >= 3 {
                suggestions.append(
                    "Tool '\(tool)' has low success rate (\(Int(toolSuccess * 100))%). Review its implementation."
                )
            }
        }

        let problematic = getProblematicPatterns()
        if !problematic.isEmpty {
            let joined = problematic.prefix(3).joined(separator: ", ")
            suggestions.append("These query patterns often fail: \(joined)")
        }

        return suggestions
    }

    // MARK: - Persistence

    private func saveFeedback() {
        let fileURL = getFeedbackFileURL()
        do {
            let data = try JSONEncoder().encode(feedbackHistory)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("⚠️ Failed to save feedback: \(error)")
        }
    }

    private func loadFeedback() {
        let fileURL = getFeedbackFileURL()
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            feedbackHistory = try JSONDecoder().decode([ResponseFeedback].self, from: data)
            print("📖 Loaded \(feedbackHistory.count) feedback entries")
        } catch {
            print("⚠️ Failed to load feedback: \(error)")
        }
    }

    private func getFeedbackFileURL() -> URL {
        guard
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            // Fallback to temp directory if app support not available
            SecureLogger.error(
                "Application Support directory not found, using temp directory",
                category: .system
            )
            let tempDir = FileManager.default.temporaryDirectory
            return tempDir.appendingPathComponent("AgentIntelligence/feedback.json")
        }

        let appDir = appSupport.appendingPathComponent("AgentIntelligence")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("feedback.json")
    }
}

public struct FeedbackStats {
    public let totalFeedback: Int
    public let helpfulCount: Int
    public let unhelpfulCount: Int
    public let successRate: Double
    public let toolPerformance: [String: (helpful: Int, total: Int)]
}
