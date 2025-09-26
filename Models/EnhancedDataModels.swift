//
//  EnhancedDataModels.swift
//  Quantum-workspace
//
//  Advanced data models with comprehensive relationships, validation, and computed properties
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Enhanced Core Data Protocols

/// Protocol for models that support validation
@MainActor
public protocol Validatable {
    /// Validates the model and returns any validation errors
    func validate() throws

    /// Returns true if the model is in a valid state
    var isValid: Bool { get }

    /// Returns validation errors without throwing
    var validationErrors: [ValidationError] { get }
}

/// Protocol for models that support analytics tracking
public protocol Trackable {
    /// Unique identifier for analytics
    var trackingId: String { get }

    /// Metadata for analytics
    var analyticsMetadata: [String: Any] { get }

    /// Records an analytics event
    func trackEvent(_ event: String, parameters: [String: Any]?)
}

/// Protocol for models that support cross-project relationships
public protocol CrossProjectRelatable {
    /// Unique identifier that can be referenced across projects
    var globalId: String { get }

    /// Project context this model belongs to
    var projectContext: ProjectContext { get }

    /// External references to other models
    var externalReferences: [ExternalReference] { get set }
}

// MARK: - Supporting Types

public enum ValidationError: Error, LocalizedError {
    case required(field: String)
    case invalid(field: String, reason: String)
    case outOfRange(field: String, min: Any?, max: Any?)
    case custom(message: String)

    public var errorDescription: String? {
        switch self {
        case let .required(field):
            "\(field) is required"
        case let .invalid(field, reason):
            "\(field) is invalid: \(reason)"
        case let .outOfRange(field, min, max):
            "\(field) is out of range (\(min ?? "nil") - \(max ?? "nil"))"
        case let .custom(message):
            message
        }
    }
}

public enum ProjectContext: String, CaseIterable, Codable {
    case habitQuest
    case momentumFinance
    case plannerApp
    case codingReviewer
    case avoidObstaclesGame
}

public struct ExternalReference: Codable, Identifiable {
    public let id: UUID
    public let projectContext: ProjectContext
    public let modelType: String
    public let modelId: String
    public let relationshipType: String
    public let createdAt: Date

    public init(projectContext: ProjectContext, modelType: String, modelId: String, relationshipType: String) {
        id = UUID()
        self.projectContext = projectContext
        self.modelType = modelType
        self.modelId = modelId
        self.relationshipType = relationshipType
        createdAt = Date()
    }
}

// MARK: - Enhanced Habit Model

/// Enhanced version of the Habit model with advanced features
@Model
public final class EnhancedHabit: Validatable, Trackable, CrossProjectRelatable {
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
    public var priority: Int // 1-5 scale
    public var streakGoal: Int
    public var completionReward: String?

    // Analytics Properties
    public var totalCompletions: Int
    public var totalMissedDays: Int
    public var averageCompletionTime: Double // in minutes
    public var lastCompletionDate: Date?
    public var bestStreak: Int
    public var monthlyGoal: Int

    // Cross-project Properties
    public var globalId: String
    public var projectContext: String
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
        guard let todaysLog = logs.first(where: { Calendar.current.isDateInToday($0.completionDate) }) else {
            return false
        }
        return todaysLog.isCompleted
    }

    public var completionRate: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = logs.filter { $0.completionDate >= thirtyDaysAgo }
        guard !recentLogs.isEmpty else { return 0.0 }
        let completedCount = recentLogs.count(where: { $0.isCompleted })
        return Double(completedCount) / Double(recentLogs.count)
    }

    public var weeklyCompletionRate: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekLogs = logs.filter { $0.completionDate >= weekAgo }
        guard !weekLogs.isEmpty else { return 0.0 }
        let completedCount = weekLogs.count(where: { $0.isCompleted })
        return Double(completedCount) / Double(weekLogs.count)
    }

    public var averageDailyCompletions: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = logs.filter { $0.completionDate >= thirtyDaysAgo }
        let completedLogs = recentLogs.filter(\.isCompleted)
        return Double(completedLogs.count) / 30.0
    }

    public var streakPercentage: Double {
        guard streakGoal > 0 else { return 0.0 }
        return min(Double(streak) / Double(streakGoal), 1.0) * 100.0
    }

    public var nextMilestone: HabitMilestone? {
        milestones.filter { !$0.isAchieved }.sorted { $0.targetValue < $1.targetValue }.first
    }

    // Initialization
    public init(
        name: String,
        habitDescription: String,
        frequency: HabitFrequency,
        xpValue: Int = 10,
        category: HabitCategory = .health,
        difficulty: HabitDifficulty = .easy,
        tags: [String] = [],
        estimatedDurationMinutes: Int = 15,
        color: String = "blue",
        iconName: String = "star",
        priority: Int = 3,
        streakGoal: Int = 30
    ) {
        id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.frequency = frequency
        creationDate = Date()
        self.xpValue = xpValue
        streak = 0
        isActive = true
        self.category = category
        self.difficulty = difficulty

        self.tags = tags
        reminderTimes = []
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.color = color
        self.iconName = iconName
        notes = ""
        isArchived = false
        self.priority = priority
        self.streakGoal = streakGoal

        totalCompletions = 0
        totalMissedDays = 0
        averageCompletionTime = 0.0
        bestStreak = 0
        monthlyGoal = 20

        globalId = "habit_\(id.uuidString)"
        projectContext = ProjectContext.habitQuest.rawValue
        externalReferences = []
    }

    // MARK: - Validatable Implementation

    @MainActor
    public func validate() throws {
        let errors = validationErrors
        if !errors.isEmpty {
            throw errors.first!
        }
    }

    public var isValid: Bool {
        validationErrors.isEmpty
    }

    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "name"))
        }

        if name.count > 100 {
            errors.append(.invalid(field: "name", reason: "must be 100 characters or less"))
        }

        if habitDescription.count > 500 {
            errors.append(.invalid(field: "habitDescription", reason: "must be 500 characters or less"))
        }

        if xpValue < 1 || xpValue > 100 {
            errors.append(.outOfRange(field: "xpValue", min: 1, max: 100))
        }

        if priority < 1 || priority > 5 {
            errors.append(.outOfRange(field: "priority", min: 1, max: 5))
        }

        if estimatedDurationMinutes < 1 || estimatedDurationMinutes > 480 {
            errors.append(.outOfRange(field: "estimatedDurationMinutes", min: 1, max: 480))
        }

        if streakGoal < 1 || streakGoal > 365 {
            errors.append(.outOfRange(field: "streakGoal", min: 1, max: 365))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "habit_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "category": category.rawValue,
            "difficulty": difficulty.rawValue,
            "frequency": frequency.rawValue,
            "xpValue": xpValue,
            "priority": priority,
            "streak": streak,
            "completionRate": completionRate,
            "isActive": isActive,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        // Implementation would integrate with analytics service
        print("Tracking event: \(event) for habit: \(name) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func completeToday(duration: TimeInterval? = nil, notes: String? = nil, mood: MoodRating? = nil) {
        let today = Date()

        // Check if already completed today
        if let existingLog = logs.first(where: { Calendar.current.isDateInToday($0.completionDate) }) {
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
            logs.append(log)
        }

        // Update analytics
        totalCompletions += 1
        updateStreak()
        updateAverageCompletionTime(duration)
        lastCompletionDate = today

        // Track event
        trackEvent("habit_completed", parameters: [
            "duration": duration ?? 0,
            "streak": streak,
            "consecutive_days": streak,
        ])

        // Check for achievements
        checkAchievements()
    }

    @MainActor
    public func missDay() {
        totalMissedDays += 1
        streak = 0
        trackEvent("habit_missed")
    }

    private func updateStreak() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let wasCompletedYesterday = logs.contains {
            Calendar.current.isDate($0.completionDate, inSameDayAs: yesterday) && $0.isCompleted
        }

        if wasCompletedYesterday || streak == 0 {
            streak += 1
            if streak > bestStreak {
                bestStreak = streak
            }
        }
    }

    private func updateAverageCompletionTime(_ duration: TimeInterval?) {
        guard let duration else { return }
        let durationMinutes = duration / 60
        averageCompletionTime = (averageCompletionTime * Double(totalCompletions - 1) + durationMinutes) /
            Double(totalCompletions)
    }

    private func checkAchievements() {
        // Check milestone achievements
        for milestone in milestones where !milestone.isAchieved {
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
        reminderTimes.append(time)
        trackEvent("reminder_added")
    }

    @MainActor
    public func removeReminder(at index: Int) {
        guard index < reminderTimes.count else { return }
        reminderTimes.remove(at: index)
        trackEvent("reminder_removed")
    }

    @MainActor
    public func addExternalReference(_ reference: ExternalReference) {
        externalReferences.append(reference)
        trackEvent("external_reference_added", parameters: [
            "project": reference.projectContext.rawValue,
            "model_type": reference.modelType,
        ])
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
    public var energyLevel: Int? // 1-10 scale

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
        id = UUID()
        self.habit = habit
        self.completionDate = completionDate
        self.isCompleted = isCompleted
        self.notes = notes
        xpEarned = 0 // Will be calculated after initialization
        self.mood = mood
        completionTime = isCompleted ? Date() : nil
        self.actualDurationMinutes = actualDurationMinutes
    }

    @MainActor
    public func calculateXpEarned() {
        guard let habit else { return }
        xpEarned = isCompleted ? habit.xpValue * habit.difficulty.xpMultiplier : 0
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
        id = UUID()
        self.title = title
        achievementDescription = description
        self.iconName = iconName
        self.xpReward = xpReward
        isAchieved = false
    }

    @MainActor
    public func achieve() {
        isAchieved = true
        achievedDate = Date()
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
        id = UUID()
        self.title = title
        self.type = type
        self.targetValue = targetValue
        isAchieved = false
    }

    @MainActor
    public func achieve() {
        isAchieved = true
        achievedDate = Date()
    }
}

public enum MoodRating: String, CaseIterable, Codable {
    case terrible = "😞"
    case poor = "😕"
    case okay = "😐"
    case good = "😊"
    case excellent = "😄"

    public var displayName: String {
        switch self {
        case .terrible: "Terrible"
        case .poor: "Poor"
        case .okay: "Okay"
        case .good: "Good"
        case .excellent: "Excellent"
        }
    }

    public var numericValue: Int {
        switch self {
        case .terrible: 1
        case .poor: 2
        case .okay: 3
        case .good: 4
        case .excellent: 5
        }
    }
}

// Re-export existing enums with enhancements
public enum HabitFrequency: String, CaseIterable, Codable {
    case daily
    case weekly
    case biweekly
    case monthly
    case custom

    public var displayName: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .biweekly: "Bi-weekly"
        case .monthly: "Monthly"
        case .custom: "Custom"
        }
    }

    public var expectedCompletionsPerMonth: Int {
        switch self {
        case .daily: 30
        case .weekly: 4
        case .biweekly: 2
        case .monthly: 1
        case .custom: 15 // default estimate
        }
    }
}

public enum HabitCategory: String, CaseIterable, Codable {
    case health
    case fitness
    case learning
    case productivity
    case social
    case creativity
    case mindfulness
    case finance
    case career
    case relationship
    case other

    public var emoji: String {
        switch self {
        case .health: "🏥"
        case .fitness: "🏋️‍♀️"
        case .learning: "📚"
        case .productivity: "💼"
        case .social: "👥"
        case .creativity: "🎨"
        case .mindfulness: "🧘‍♀️"
        case .finance: "💰"
        case .career: "📈"
        case .relationship: "❤️"
        case .other: "📋"
        }
    }

    public var color: String {
        switch self {
        case .health: "red"
        case .fitness: "orange"
        case .learning: "blue"
        case .productivity: "green"
        case .social: "purple"
        case .creativity: "yellow"
        case .mindfulness: "indigo"
        case .finance: "mint"
        case .career: "brown"
        case .relationship: "pink"
        case .other: "gray"
        }
    }
}

public enum HabitDifficulty: String, CaseIterable, Codable {
    case trivial
    case easy
    case medium
    case hard
    case extreme

    public var displayName: String {
        switch self {
        case .trivial: "Trivial"
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        case .extreme: "Extreme"
        }
    }

    public nonisolated var xpMultiplier: Int {
        switch self {
        case .trivial: 1
        case .easy: 2
        case .medium: 3
        case .hard: 5
        case .extreme: 8
        }
    }

    public var color: Color {
        switch self {
        case .trivial: .gray
        case .easy: .green
        case .medium: .blue
        case .hard: .orange
        case .extreme: .red
        }
    }
}
