import Foundation
import Combine

/// AI-powered task prioritization service for PlannerApp
/// Provides intelligent task suggestions and productivity insights
/// Integrates with the shared AI framework for consistent behavior

@available(iOS 13.0, macOS 10.15, *)
public class AITaskPrioritizationService {
    public static let shared = AITaskPrioritizationService()

    private let predictiveEngine = PredictiveAnalyticsEngine.shared
    private let ollamaManager = OllamaIntegrationManager()
    private let aiCoordinator = AICoordinator.shared

    @Published public var isProcessing = false
    @Published public var lastUpdate: Date?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.setupSubscriptions()
    }

    private func setupSubscriptions() {
        self.aiCoordinator.$availableFeatures
            .sink { [weak self] features in
                // Update capabilities based on available AI features
                self?.updateCapabilities(features)
            }
            .store(in: &self.cancellables)
    }

    private func updateCapabilities(_ features: Set<AIFeature>) {
        // Update service capabilities based on available AI features
        // This allows graceful degradation if some AI features are unavailable
    }

    // MARK: - Task Prioritization

    /// Generate AI-powered task suggestions based on current tasks and user patterns
    public func generateTaskSuggestions(
        currentTasks: [TaskItem],
        userGoals: [GoalItem],
        recentActivity: [ActivityRecord]
    ) async -> [TaskSuggestion] {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.isProcessing = true
            }

            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    defer {
                        Task { @MainActor in
                            self.isProcessing = false
                            self.lastUpdate = Date()
                        }
                    }

                    var suggestions: [TaskSuggestion] = []

                    // Generate suggestions using multiple AI approaches
                    let patternBasedSuggestions = await self.generatePatternBasedSuggestions(
                        currentTasks: currentTasks,
                        recentActivity: recentActivity
                    )

                    let goalBasedSuggestions = await self.generateGoalBasedSuggestions(
                        tasks: currentTasks,
                        goals: userGoals
                    )

                    let timeBasedSuggestions = await self.generateTimeBasedSuggestions(
                        tasks: currentTasks
                    )

                    suggestions.append(contentsOf: patternBasedSuggestions)
                    suggestions.append(contentsOf: goalBasedSuggestions)
                    suggestions.append(contentsOf: timeBasedSuggestions)

                    // Remove duplicates and sort by priority
                    let uniqueSuggestions = self.deduplicateSuggestions(suggestions)
                    let prioritizedSuggestions = self.prioritizeSuggestions(uniqueSuggestions)

                    continuation.resume(returning: prioritizedSuggestions)
                }
            }
        }
    }

    private func generatePatternBasedSuggestions(
        currentTasks: [TaskItem],
        recentActivity: [ActivityRecord]
    ) async -> [TaskSuggestion] {
        var suggestions: [TaskSuggestion] = []

        // Analyze completion patterns
        let completedTasks = recentActivity.filter { $0.type == .taskCompleted }
        let completionTimes = completedTasks.compactMap { $0.timestamp }

        if !completionTimes.isEmpty {
            // Suggest tasks during peak productivity times
            let peakHour = self.calculatePeakProductivityHour(completionTimes)

            let peakTimeSuggestion = TaskSuggestion(
                id: UUID().uuidString,
                title: "Schedule Important Tasks",
                subtitle: "Peak Productivity Window",
                reasoning: "Based on your activity patterns, you're most productive around \(self.formatHour(peakHour))",
                priority: .high,
                urgency: .medium,
                suggestedTime: self.createTimeSlot(hour: peakHour),
                category: .productivity,
                confidence: 0.8
            )
            suggestions.append(peakTimeSuggestion)
        }

        // Analyze task categories and suggest balance
        let categoryCounts = Dictionary(grouping: currentTasks, by: { $0.category })
        let dominantCategory = categoryCounts.max { $0.value.count < $1.value.count }

        if let dominant = dominantCategory?.key, categoryCounts[dominant]?.count ?? 0 > currentTasks.count / 2 {
            let balanceSuggestion = TaskSuggestion(
                id: UUID().uuidString,
                title: "Diversify Your Tasks",
                subtitle: "Work-Life Balance",
                reasoning: "You've been focusing heavily on \(dominant.rawValue) tasks. Consider balancing with other categories.",
                priority: .medium,
                urgency: .low,
                suggestedTime: nil,
                category: .balance,
                confidence: 0.7
            )
            suggestions.append(balanceSuggestion)
        }

        return suggestions
    }

    private func generateGoalBasedSuggestions(
        tasks: [TaskItem],
        goals: [GoalItem]
    ) async -> [TaskSuggestion] {
        var suggestions: [TaskSuggestion] = []

        // Find goals that need attention
        let activeGoals = goals.filter { !$0.isCompleted }
        let tasksByGoal = Dictionary(grouping: tasks, by: { $0.goalId })

        for goal in activeGoals {
            let relatedTasks = tasksByGoal[goal.id] ?? []
            let completedTasks = relatedTasks.filter { $0.isCompleted }.count
            let progress = Double(completedTasks) / Double(max(relatedTasks.count, 1))

            if progress < 0.3 && relatedTasks.count > 2 {
                let goalSuggestion = TaskSuggestion(
                    id: UUID().uuidString,
                    title: "Focus on '\(goal.title)'",
                    subtitle: "Goal Progress: \(Int(progress * 100))%",
                    reasoning: "This goal needs more attention. Breaking it into smaller tasks might help.",
                    priority: .high,
                    urgency: .high,
                    suggestedTime: self.suggestTimeForGoal(goal),
                    category: .goals,
                    confidence: 0.9
                )
                suggestions.append(goalSuggestion)
            }
        }

        return suggestions
    }

    private func generateTimeBasedSuggestions(tasks: [TaskItem]) async -> [TaskSuggestion] {
        var suggestions: [TaskSuggestion] = []

        // Find overdue tasks
        let overdueTasks = tasks.filter { $0.dueDate != nil && $0.dueDate! < Date() && !$0.isCompleted }

        if !overdueTasks.isEmpty {
            let overdueSuggestion = TaskSuggestion(
                id: UUID().uuidString,
                title: "Address Overdue Tasks",
                subtitle: "\(overdueTasks.count) tasks need attention",
                reasoning: "Overdue tasks can create stress. Consider rescheduling or breaking them down.",
                priority: .high,
                urgency: .high,
                suggestedTime: Date().addingTimeInterval(3600), // 1 hour from now
                category: .urgent,
                confidence: 0.95
            )
            suggestions.append(overdueSuggestion)
        }

        // Suggest task batching for similar activities
        let tasksByCategory = Dictionary(grouping: tasks.filter { !$0.isCompleted }, by: { $0.category })
        for (category, categoryTasks) in tasksByCategory where categoryTasks.count >= 3 {
            let batchSuggestion = TaskSuggestion(
                id: UUID().uuidString,
                title: "Batch \(category.rawValue) Tasks",
                subtitle: "\(categoryTasks.count) similar tasks",
                reasoning: "Grouping similar tasks can improve efficiency and reduce context switching.",
                priority: .medium,
                urgency: .low,
                suggestedTime: self.suggestBatchTime(category),
                category: .efficiency,
                confidence: 0.75
            )
            suggestions.append(batchSuggestion)
        }

        return suggestions
    }

    // MARK: - Productivity Insights

    /// Generate AI-powered productivity insights based on user activity
    public func generateProductivityInsights(
        activityData: [ActivityRecord],
        taskData: [TaskItem],
        goalData: [GoalItem]
    ) async -> [ProductivityInsight] {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.isProcessing = true
            }

            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    defer {
                        Task { @MainActor in
                            self.isProcessing = false
                            self.lastUpdate = Date()
                        }
                    }

                    var insights: [ProductivityInsight] = []

                    // Analyze productivity patterns
                    let productivityInsights = await self.analyzeProductivityPatterns(activityData)
                    let taskInsights = await self.analyzeTaskPatterns(taskData)
                    let goalInsights = await self.analyzeGoalProgress(goalData, taskData)

                    insights.append(contentsOf: productivityInsights)
                    insights.append(contentsOf: taskInsights)
                    insights.append(contentsOf: goalInsights)

                    // Sort by relevance and limit to top insights
                    let sortedInsights = insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
                    let topInsights = Array(sortedInsights.prefix(5))

                    continuation.resume(returning: topInsights)
                }
            }
        }
    }

    private func analyzeProductivityPatterns(_ activities: [ActivityRecord]) async -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        // Calculate productivity metrics
        let todayActivities = activities.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }

        let weekActivities = activities.filter {
            Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
        }

        let completionRate = self.calculateCompletionRate(todayActivities)
        let focusTime = self.calculateFocusTime(todayActivities)

        // Productivity score insight
        let productivityScore = (completionRate * 0.6) + (min(focusTime / 480, 1.0) * 0.4) // 8 hours max

        let scoreInsight = ProductivityInsight(
            id: UUID().uuidString,
            title: "Today's Productivity Score",
            description: String(format: "%.1f/10 - Based on task completion (%.0f%%) and focus time (%.1f hours)",
                              productivityScore * 10,
                              completionRate * 100,
                              focusTime / 60),
            icon: productivityScore > 0.7 ? "star.fill" : productivityScore > 0.4 ? "star.leadinghalf.filled" : "star",
            priority: .high,
            category: .performance,
            actionable: productivityScore < 0.6
        )
        insights.append(scoreInsight)

        // Weekly comparison
        if !weekActivities.isEmpty {
            let weekCompletionRate = self.calculateCompletionRate(weekActivities)
            let trend = weekCompletionRate > completionRate ? "improving" : "declining"

            let trendInsight = ProductivityInsight(
                id: UUID().uuidString,
                title: "Weekly Trend",
                description: "Your completion rate this week is \(trend) compared to today",
                icon: weekCompletionRate > completionRate ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                priority: .medium,
                category: .trends,
                actionable: false
            )
            insights.append(trendInsight)
        }

        // Peak productivity time
        let peakHour = self.calculatePeakProductivityHour(activities.map { $0.timestamp })

        let peakInsight = ProductivityInsight(
            id: UUID().uuidString,
            title: "Peak Productivity Time",
            description: "You're most productive around \(self.formatHour(peakHour)). Consider scheduling important tasks then.",
            icon: "clock.fill",
            priority: .medium,
            category: .optimization,
            actionable: true
        )
        insights.append(peakInsight)

        return insights
    }

    private func analyzeTaskPatterns(_ tasks: [TaskItem]) async -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        let completedTasks = tasks.filter { $0.isCompleted }
        let pendingTasks = tasks.filter { !$0.isCompleted }

        // Task completion patterns
        if !completedTasks.isEmpty {
            let averageCompletionTime = self.calculateAverageCompletionTime(completedTasks)

            let completionInsight = ProductivityInsight(
                id: UUID().uuidString,
                title: "Task Completion Speed",
                description: String(format: "Average time to complete tasks: %.1f hours", averageCompletionTime),
                icon: "speedometer",
                priority: .medium,
                category: .efficiency,
                actionable: averageCompletionTime > 4.0 // More than 4 hours
            )
            insights.append(completionInsight)
        }

        // Overdue tasks analysis
        let overdueTasks = pendingTasks.filter { $0.dueDate != nil && $0.dueDate! < Date() }
        if !overdueTasks.isEmpty {
            let overdueInsight = ProductivityInsight(
                id: UUID().uuidString,
                title: "Overdue Tasks",
                description: "You have \(overdueTasks.count) overdue tasks. Consider rescheduling or breaking them down.",
                icon: "exclamationmark.triangle.fill",
                priority: .high,
                category: .issues,
                actionable: true
            )
            insights.append(overdueInsight)
        }

        // Task distribution
        let tasksByPriority = Dictionary(grouping: pendingTasks, by: { $0.priority })
        if let highPriorityCount = tasksByPriority[.high]?.count, highPriorityCount > pendingTasks.count / 2 {
            let balanceInsight = ProductivityInsight(
                id: UUID().uuidString,
                title: "Priority Balance",
                description: "Most of your tasks are high priority. Consider adding some lower-priority tasks for balance.",
                icon: "scale.3d",
                priority: .medium,
                category: .balance,
                actionable: true
            )
            insights.append(balanceInsight)
        }

        return insights
    }

    private func analyzeGoalProgress(_ goals: [GoalItem], _ tasks: [TaskItem]) async -> [ProductivityInsight] {
        var insights: [ProductivityInsight] = []

        let activeGoals = goals.filter { !$0.isCompleted }
        let tasksByGoal = Dictionary(grouping: tasks, by: { $0.goalId })

        // Goal progress analysis
        for goal in activeGoals {
            let relatedTasks = tasksByGoal[goal.id] ?? []
            let completedTasks = relatedTasks.filter { $0.isCompleted }.count
            let totalTasks = relatedTasks.count

            if totalTasks > 0 {
                let progress = Double(completedTasks) / Double(totalTasks)

                if progress < 0.25 {
                    let goalInsight = ProductivityInsight(
                        id: UUID().uuidString,
                        title: "Goal Progress: \(goal.title)",
                        description: String(format: "Only %.0f%% complete. Consider breaking this goal into smaller, actionable steps.", progress * 100),
                        icon: "target",
                        priority: .high,
                        category: .goals,
                        actionable: true
                    )
                    insights.append(goalInsight)
                } else if progress > 0.75 {
                    let momentumInsight = ProductivityInsight(
                        id: UUID().uuidString,
                        title: "Goal Momentum",
                        description: "\(goal.title) is \(Int(progress * 100))% complete. Keep up the great work!",
                        icon: "flame.fill",
                        priority: .medium,
                        category: .motivation,
                        actionable: false
                    )
                    insights.append(momentumInsight)
                }
            }
        }

        return insights
    }

    // MARK: - Helper Methods

    private func calculateCompletionRate(_ activities: [ActivityRecord]) -> Double {
        let taskActivities = activities.filter { $0.type == .taskCompleted || $0.type == .taskCreated }
        guard !taskActivities.isEmpty else { return 0.0 }

        let completedCount = taskActivities.filter { $0.type == .taskCompleted }.count
        return Double(completedCount) / Double(taskActivities.count)
    }

    private func calculateFocusTime(_ activities: [ActivityRecord]) -> Double {
        // Estimate focus time based on activity density
        let timeIntervals = activities.map { $0.timestamp }.sorted()
        guard timeIntervals.count >= 2 else { return 0.0 }

        var totalFocusTime: Double = 0
        var currentSessionStart: Date?

        for (index, timestamp) in timeIntervals.enumerated() {
            if index == 0 {
                currentSessionStart = timestamp
                continue
            }

            let timeGap = timestamp.timeIntervalSince(timeIntervals[index - 1])
            if timeGap > 1800 { // 30 minutes gap ends session
                if let start = currentSessionStart {
                    totalFocusTime += timeIntervals[index - 1].timeIntervalSince(start)
                }
                currentSessionStart = timestamp
            }
        }

        // Add final session
        if let start = currentSessionStart, let end = timeIntervals.last {
            totalFocusTime += end.timeIntervalSince(start)
        }

        return totalFocusTime / 3600 // Convert to hours
    }

    private func calculatePeakProductivityHour(_ timestamps: [Date]) -> Int {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]

        for timestamp in timestamps {
            let hour = calendar.component(.hour, from: timestamp)
            hourCounts[hour, default: 0] += 1
        }

        return hourCounts.max { $0.value < $1.value }?.key ?? 9 // Default to 9 AM
    }

    private func calculateAverageCompletionTime(_ tasks: [TaskItem]) -> Double {
        let tasksWithTimes = tasks.compactMap { task -> Double? in
            guard let created = task.createdDate, let completed = task.completedDate else { return nil }
            return completed.timeIntervalSince(created) / 3600 // Hours
        }

        guard !tasksWithTimes.isEmpty else { return 0.0 }
        return tasksWithTimes.reduce(0, +) / Double(tasksWithTimes.count)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }

    private func createTimeSlot(hour: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = 0
        components.second = 0

        // If the time has passed today, schedule for tomorrow
        if let suggestedTime = calendar.date(from: components),
           suggestedTime < now {
            return calendar.date(byAdding: .day, value: 1, to: suggestedTime) ?? now
        }

        return calendar.date(from: components) ?? now
    }

    private func suggestTimeForGoal(_ goal: GoalItem) -> Date {
        // Suggest time based on goal priority and user's typical schedule
        let calendar = Calendar.current
        let now = Date()

        switch goal.priority {
        case .high:
            // High priority goals: schedule soon
            return now.addingTimeInterval(3600) // 1 hour
        case .medium:
            // Medium priority: next day
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .low:
            // Low priority: weekend or next week
            let weekday = calendar.component(.weekday, from: now)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                return calendar.date(byAdding: .day, value: 3, to: now) ?? now
            } else {
                return calendar.date(byAdding: .day, value: 7, to: now) ?? now
            }
        }
    }

    private func suggestBatchTime(_ category: TaskCategory) -> Date {
        let calendar = Calendar.current
        let now = Date()

        // Suggest batch times based on category
        switch category {
        case .work:
            return createTimeSlot(hour: 9) // 9 AM
        case .personal:
            return createTimeSlot(hour: 18) // 6 PM
        case .health:
            return createTimeSlot(hour: 7) // 7 AM
        case .learning:
            return createTimeSlot(hour: 14) // 2 PM
        default:
            return now.addingTimeInterval(7200) // 2 hours from now
        }
    }

    private func deduplicateSuggestions(_ suggestions: [TaskSuggestion]) -> [TaskSuggestion] {
        var seen = Set<String>()
        return suggestions.filter { suggestion in
            let key = "\(suggestion.title)-\(suggestion.category.rawValue)"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }

    private func prioritizeSuggestions(_ suggestions: [TaskSuggestion]) -> [TaskSuggestion] {
        return suggestions.sorted { lhs, rhs in
            // Sort by priority first, then by urgency, then by confidence
            if lhs.priority != rhs.priority {
                return lhs.priority.rawValue > rhs.priority.rawValue
            }
            if lhs.urgency != rhs.urgency {
                return lhs.urgency.rawValue > rhs.urgency.rawValue
            }
            return lhs.confidence > rhs.confidence
        }
    }
}

// MARK: - Data Models

public struct TaskSuggestion: Identifiable, Codable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let reasoning: String
    public let priority: TaskPriority
    public let urgency: TaskUrgency
    public let suggestedTime: Date?
    public let category: SuggestionCategory
    public let confidence: Double

    public enum TaskPriority: String, Codable, CaseIterable {
        case low, medium, high
    }

    public enum TaskUrgency: String, Codable, CaseIterable {
        case low, medium, high
    }

    public enum SuggestionCategory: String, Codable, CaseIterable {
        case productivity, balance, goals, urgent, efficiency
    }
}

public struct ProductivityInsight: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let priority: InsightPriority
    public let category: InsightCategory
    public let actionable: Bool

    public enum InsightPriority: String, Codable, CaseIterable {
        case low, medium, high
    }

    public enum InsightCategory: String, Codable, CaseIterable {
        case performance, trends, optimization, efficiency, issues, balance, goals, motivation
    }
}

// MARK: - Supporting Types

public enum TaskCategory: String, Codable, CaseIterable {
    case work, personal, health, learning, other
}

public enum TaskPriority: String, Codable, CaseIterable {
    case low, medium, high
}

public struct TaskItem: Codable {
    public let id: String
    public let title: String
    public let category: TaskCategory
    public let priority: TaskPriority
    public let isCompleted: Bool
    public let createdDate: Date?
    public let completedDate: Date?
    public let dueDate: Date?
    public let goalId: String?
}

public struct GoalItem: Codable {
    public let id: String
    public let title: String
    public let priority: TaskPriority
    public let isCompleted: Bool
}

public enum ActivityType: String, Codable {
    case taskCreated, taskCompleted, goalCreated, goalCompleted
}

public struct ActivityRecord: Codable {
    public let id: String
    public let type: ActivityType
    public let timestamp: Date
}</content>
<parameter name="filePath">/Users/danielstevens/Desktop/Quantum-workspace/Shared/AITaskPrioritizationService.swift