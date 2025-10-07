//
//  StateTypes.swift
//  Shared State Management System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation

// Supporting types
public enum MoodRating: Int, CaseIterable {
    case veryPoor = 1
    case poor, fair, good, excellent
}

public struct HabitInsights {
    public let habitId: UUID
    public let timeRange: DateInterval
    public let completionRate: Double
    public let currentStreak: Int
    public let longestStreak: Int
    public let averageValue: Double?
    public let moodCorrelation: Double?
    public let recommendations: [String]

    public init(
        habitId: UUID,
        timeRange: DateInterval,
        completionRate: Double,
        currentStreak: Int,
        longestStreak: Int,
        averageValue: Double?,
        moodCorrelation: Double?,
        recommendations: [String]
    ) {
        self.habitId = habitId
        self.timeRange = timeRange
        self.completionRate = completionRate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.averageValue = averageValue
        self.moodCorrelation = moodCorrelation
        self.recommendations = recommendations
    }
}

public struct NetWorthSummary {
    public let userId: String
    public let asOfDate: Date
    public let totalAssets: Double
    public let totalLiabilities: Double
    public let netWorth: Double
    public let monthOverMonthChange: Double
    public let yearOverYearChange: Double

    public init(
        userId: String,
        asOfDate: Date,
        totalAssets: Double,
        totalLiabilities: Double,
        netWorth: Double,
        monthOverMonthChange: Double,
        yearOverYearChange: Double
    ) {
        self.userId = userId
        self.asOfDate = asOfDate
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.netWorth = netWorth
        self.monthOverMonthChange = monthOverMonthChange
        self.yearOverYearChange = yearOverYearChange
    }
}

public struct FinancialRecommendation {
    public let id: UUID = .init()
    public let title: String
    public let description: String
    public let estimatedImpact: Double

    public init(title: String, description: String, estimatedImpact: Double) {
        self.title = title
        self.description = description
        self.estimatedImpact = estimatedImpact
    }
}

public struct ScheduleOptimization {
    public let userId: String
    public let timeRange: DateInterval
    public let optimizedTasks: [OptimizedTaskSchedule]
    public let efficiency: Double
    public let recommendations: [String]

    public init(
        userId: String,
        timeRange: DateInterval,
        optimizedTasks: [OptimizedTaskSchedule],
        efficiency: Double,
        recommendations: [String]
    ) {
        self.userId = userId
        self.timeRange = timeRange
        self.optimizedTasks = optimizedTasks
        self.efficiency = efficiency
        self.recommendations = recommendations
    }
}

public struct OptimizedTaskSchedule {
    public let taskId: UUID
    public let title: String
    public let scheduledStart: Date
    public let scheduledEnd: Date
    public let optimalTimeSlot: Bool
    public let reasoning: String

    public init(
        taskId: UUID, title: String, scheduledStart: Date, scheduledEnd: Date,
        optimalTimeSlot: Bool, reasoning: String
    ) {
        self.taskId = taskId
        self.title = title
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.optimalTimeSlot = optimalTimeSlot
        self.reasoning = reasoning
    }
}

public struct ProductivityInsights {
    public let userId: String
    public let timeRange: DateInterval
    public let completionRate: Double
    public let averageTaskDuration: TimeInterval
    public let peakProductivityHours: [Int]
    public let recommendations: [String]

    public init(
        userId: String,
        timeRange: DateInterval,
        completionRate: Double,
        averageTaskDuration: TimeInterval,
        peakProductivityHours: [Int],
        recommendations: [String]
    ) {
        self.userId = userId
        self.timeRange = timeRange
        self.completionRate = completionRate
        self.averageTaskDuration = averageTaskDuration
        self.peakProductivityHours = peakProductivityHours
        self.recommendations = recommendations
    }
}

public struct TaskRecommendation {
    public let id: UUID = .init()
    public let title: String
    public let description: String
    public let estimatedDuration: Int
    public let reasoning: String

    public init(title: String, description: String, estimatedDuration: Int, reasoning: String) {
        self.title = title
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.reasoning = reasoning
    }
}

public struct BudgetInsights {
    public let budgetId: UUID
    public let timeRange: DateInterval
    public let utilizationRate: Double
    public let recommendations: [String]

    public init(
        budgetId: UUID, timeRange: DateInterval, utilizationRate: Double, recommendations: [String]
    ) {
        self.budgetId = budgetId
        self.timeRange = timeRange
        self.utilizationRate = utilizationRate
        self.recommendations = recommendations
    }
}

public struct GoalProgress {
    public let goalId: UUID
    public let currentProgress: Double
    public let targetValue: Double
    public let progressPercentage: Double
    public let estimatedCompletion: Date?
    public let onTrack: Bool

    public init(
        goalId: UUID, currentProgress: Double, targetValue: Double, estimatedCompletion: Date?
    ) {
        self.goalId = goalId
        self.currentProgress = currentProgress
        self.targetValue = targetValue
        self.progressPercentage = targetValue > 0 ? (currentProgress / targetValue) * 100 : 0
        self.estimatedCompletion = estimatedCompletion
        self.onTrack =
            self
            .progressPercentage >= 95
            || (estimatedCompletion != nil
                && estimatedCompletion! <= Date().addingTimeInterval(86400 * 7))
    }
}
