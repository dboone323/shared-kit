//
//  EnhancedDataModels.swift
//  Quantum-workspace
//
//  Advanced data models with comprehensive relationships, validation, and computed properties
//

import Foundation

#if canImport(SwiftData)
import SwiftData

// MARK: - Enhanced Habit Model

// MARK: - Enhanced Habit Model

/// Enhanced version of the Habit model with advanced features
@Model
public final class EnhancedHabit: Validatable, Trackable, CrossProjectRelatable,
    EnhancedHabitProtocol, @unchecked Sendable
{
    // Core Properties
    public var id: UUID
    public var name: String
    public var habitDescription: String
    public var frequency: HabitFrequency
    public var creationDate: Date
    public var xpValue: Int
    public var streak: Int
    public var isActive: Bool
    public var category: HabitCategory
    public var difficulty: HabitDifficulty

    // Enhanced Properties
    public var tags: [String]
    public var reminderTimes: [Date]
    public var estimatedDurationMinutes: Int
    public var color: String
    public var iconName: String
    public var notes: String
    public var isArchived: Bool
    public var priority: Int  // 1-5 scale
    public var streakGoal: Int
    public var completionReward: String?

    // Analytics Properties
    public var totalCompletions: Int
    public var totalMissedDays: Int
    public var averageCompletionTime: Double  // in minutes
    public var lastCompletionDate: Date?
    public var bestStreak: Int
    public var monthlyGoal: Int

    // Cross-project Properties
    public var globalId: String
    public var projectContext: ProjectType
    public var externalReferences: [ExternalReference]

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \EnhancedHabitLog.habit)
    public var logs: [EnhancedHabitLog] = []

    @Relationship(deleteRule: .cascade)
    public var achievements: [HabitAchievement] = []

    @Relationship(deleteRule: .cascade)
    public var milestones: [HabitMilestone] = []

    // Computed Properties
    public var isCompletedToday: Bool {
        guard
            let todaysLog = logs.first(where: { Calendar.current.isDateInToday($0.completionDate) })
        else {
            return false
        }
        return todaysLog.isCompleted
    }

    public var completionRate: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = self.logs.filter { $0.completionDate >= thirtyDaysAgo }
        guard !recentLogs.isEmpty else { return 0.0 }
        let completedCount = recentLogs.count(where: { $0.isCompleted })
        return Double(completedCount) / Double(recentLogs.count)
    }

    public var weeklyCompletionRate: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekLogs = self.logs.filter { $0.completionDate >= weekAgo }
        guard !weekLogs.isEmpty else { return 0.0 }
        let completedCount = weekLogs.count(where: { $0.isCompleted })
        return Double(completedCount) / Double(weekLogs.count)
    }

    public var averageDailyCompletions: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = self.logs.filter { $0.completionDate >= thirtyDaysAgo }
        let completedLogs = recentLogs.filter(\.isCompleted)
        return Double(completedLogs.count) / 30.0
    }

    public var streakPercentage: Double {
        guard self.streakGoal > 0 else { return 0.0 }
        return min(Double(self.streak) / Double(self.streakGoal), 1.0) * 100.0
    }

    public var nextMilestone: HabitMilestone? {
        self.milestones.filter { !$0.isAchieved }.sorted { $0.targetValue < $1.targetValue }.first
    }

    // Initialization
    public init(
        name: String,
        description: String = "",
        frequency: HabitFrequency = .daily,
        xpValue: Int = 10,
        streak: Int = 0,
        category: HabitCategory = .health,
        difficulty: HabitDifficulty = .easy,
        estimatedDuration: Int = 15
    ) {
        let id = UUID()
        self.id = id
        self.name = name
        self.habitDescription = description
        self.frequency = frequency
        self.creationDate = Date()
        self.xpValue = xpValue
        self.streak = streak
        self.isActive = true
        self.category = category
        self.difficulty = difficulty

        self.tags = []
        self.reminderTimes = []
        self.estimatedDurationMinutes = estimatedDuration
        self.color = "blue"
        self.iconName = "circle"
        self.notes = ""
        self.isArchived = false
        self.priority = 3
        self.streakGoal = 30
        self.totalCompletions = 0
        self.totalMissedDays = 0
        self.averageCompletionTime = 0.0
        self.bestStreak = 0
        self.monthlyGoal = 20

        self.globalId = "habit_\(id.uuidString)"
        self.projectContext = .habitQuest
        self.externalReferences = []
    }

    // MARK: - Validatable Implementation

    public func validate() throws {
        let errors = self.validationErrors
        if !errors.isEmpty {
            throw errors.first!
        }
    }

    public var isValid: Bool {
        self.validationErrors.isEmpty
    }

    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []

        if self.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "name"))
        }

        if self.name.count > 100 {
            errors.append(.invalid(field: "name", reason: "must be 100 characters or less"))
        }

        if self.habitDescription.count > 500 {
            errors.append(
                .invalid(field: "habitDescription", reason: "must be 500 characters or less"))
        }

        if self.xpValue < 1 || self.xpValue > 100 {
            errors.append(.outOfRange(field: "xpValue", min: 1, max: 100))
        }

        if self.priority < 1 || self.priority > 5 {
            errors.append(.outOfRange(field: "priority", min: 1, max: 5))
        }

        if self.estimatedDurationMinutes < 1 || self.estimatedDurationMinutes > 480 {
            errors.append(.outOfRange(field: "estimatedDurationMinutes", min: 1, max: 480))
        }

        if self.streakGoal < 1 || self.streakGoal > 365 {
            errors.append(.outOfRange(field: "streakGoal", min: 1, max: 365))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "habit_\(self.id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "category": self.category.rawValue,
            "difficulty": self.difficulty.rawValue,
            "frequency": self.frequency.rawValue,
            "xpValue": self.xpValue,
            "priority": self.priority,
            "streak": self.streak,
            "completionRate": self.completionRate,
            "isActive": self.isActive,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = self.analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        // Implementation would integrate with analytics service
        print(
            "Tracking event: \(event) for habit: \(self.name) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func completeToday(
        duration: TimeInterval? = nil, notes: String? = nil, mood: MoodRating? = nil
    ) {
        let today = Date()

        // Check if already completed today
        if let existingLog = logs.first(where: { Calendar.current.isDateInToday($0.completionDate) }
        ) {
            existingLog.isCompleted = true
            existingLog.actualDurationMinutes = duration.map { Int($0 / 60) }
            existingLog.notes = notes
            existingLog.mood = mood
        } else {
            let log = EnhancedHabitLog(
                habit: self,
                completionDate: today,
                isCompleted: true,
                actualDurationMinutes: duration.map { Int($0 / 60) },
                notes: notes,
                mood: mood
            )
            self.logs.append(log)
        }

        // Update analytics
        self.totalCompletions += 1
        self.updateStreak()
        self.updateAverageCompletionTime(duration)
        self.lastCompletionDate = today

        // Track event
        self.trackEvent(
            "habit_completed",
            parameters: [
                "duration": duration ?? 0,
                "streak": self.streak,
                "consecutive_days": self.streak,
            ]
        )

        // Check for achievements
        self.checkAchievements()
    }

    @MainActor
    public func missDay() {
        self.totalMissedDays += 1
        self.streak = 0
        self.trackEvent("habit_missed")
    }

    private func updateStreak() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let wasCompletedYesterday = self.logs.contains {
            Calendar.current.isDate($0.completionDate, inSameDayAs: yesterday) && $0.isCompleted
        }

        if wasCompletedYesterday || self.streak == 0 {
            self.streak += 1
            if self.streak > self.bestStreak {
                self.bestStreak = self.streak
            }
        }
    }

    private func updateAverageCompletionTime(_ duration: TimeInterval?) {
        guard let duration else { return }
        let durationMinutes = duration / 60
        self.averageCompletionTime =
            (self.averageCompletionTime * Double(self.totalCompletions - 1) + durationMinutes)
            / Double(self.totalCompletions)
    }

    @MainActor
    private func checkAchievements() {
        // Check milestone achievements
        for milestone in self.milestones where !milestone.isAchieved {
            switch milestone.type {
            case .streak:
                if streak >= milestone.targetValue {
                    milestone.achieve()
                }
            case .totalCompletions:
                if totalCompletions >= milestone.targetValue {
                    milestone.achieve()
                }
            case .completionRate:
                if Int(completionRate * 100) >= milestone.targetValue {
                    milestone.achieve()
                }
            }
        }
    }

    @MainActor
    public func addReminder(at time: Date) {
        self.reminderTimes.append(time)
        self.trackEvent("reminder_added")
    }

    @MainActor
    public func removeReminder(at index: Int) {
        guard index < self.reminderTimes.count else { return }
        self.reminderTimes.remove(at: index)
        self.trackEvent("reminder_removed")
    }

    @MainActor
    public func addExternalReference(_ reference: ExternalReference) {
        self.externalReferences.append(reference)
        self.trackEvent(
            "external_reference_added",
            parameters: [
                "project": reference.projectContext.rawValue,
                "model_type": reference.modelType,
            ]
        )
    }
}

// MARK: - Enhanced Habit Log Model

@Model
public final class EnhancedHabitLog {
    public var id: UUID
    public var completionDate: Date
    public var isCompleted: Bool
    public var notes: String?
    public var xpEarned: Int
    public var mood: MoodRating?
    public var completionTime: Date?
    public var actualDurationMinutes: Int?
    public var location: String?
    public var weather: String?
    public var energyLevel: Int?  // 1-10 scale

    // Relationship
    public var habit: EnhancedHabit?

    public init(
        habit: EnhancedHabit,
        completionDate: Date = Date(),
        isCompleted: Bool = false,
        actualDurationMinutes: Int? = nil,
        notes: String? = nil,
        mood: MoodRating? = nil
    ) {
        self.id = UUID()
        self.habit = habit
        self.completionDate = completionDate
        self.isCompleted = isCompleted
        self.notes = notes
        self.xpEarned = 0  // Will be calculated after initialization
        self.mood = mood
        self.completionTime = isCompleted ? Date() : nil
        self.actualDurationMinutes = actualDurationMinutes
    }

    @MainActor
    public func calculateXpEarned() {
        guard let habit else { return }
        self.xpEarned =
            self.isCompleted ? Int(Double(habit.xpValue) * habit.difficulty.xpMultiplier) : 0
    }
}

// MARK: - Supporting Models

@Model
public final class HabitAchievement {
    public var id: UUID
    public var title: String
    public var achievementDescription: String
    public var iconName: String
    public var isAchieved: Bool
    public var achievedDate: Date?
    public var xpReward: Int

    public init(title: String, description: String, iconName: String, xpReward: Int) {
        self.id = UUID()
        self.title = title
        self.achievementDescription = description
        self.iconName = iconName
        self.xpReward = xpReward
        self.isAchieved = false
    }

    @MainActor
    public func achieve() {
        self.isAchieved = true
        self.achievedDate = Date()
    }
}

@Model
public final class HabitMilestone {
    public var id: UUID
    public var title: String
    public var type: MilestoneType
    public var targetValue: Int
    public var isAchieved: Bool
    public var achievedDate: Date?

    public enum MilestoneType: String, CaseIterable, Codable {
        case streak
        case totalCompletions
        case completionRate
    }

    public init(title: String, type: MilestoneType, targetValue: Int) {
        self.id = UUID()
        self.title = title
        self.type = type
        self.targetValue = targetValue
        self.isAchieved = false
    }

    @MainActor
    public func achieve() {
        self.isAchieved = true
        self.achievedDate = Date()
    }
}

#endif
