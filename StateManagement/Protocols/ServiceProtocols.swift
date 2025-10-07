//
//  ServiceProtocols.swift
//  Shared State Management System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation

// Forward declarations for types defined in StateTypes.swift
// In a real implementation, these would be imported from separate modules

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
}

public struct NetWorthSummary {
    public let userId: String
    public let asOfDate: Date
    public let totalAssets: Double
    public let totalLiabilities: Double
    public let netWorth: Double
    public let monthOverMonthChange: Double
    public let yearOverYearChange: Double
}

public struct FinancialRecommendation {
    public let title: String
    public let description: String
    public let estimatedImpact: Double
}

public struct ScheduleOptimization {
    public let userId: String
    public let timeRange: DateInterval
    public let optimizedTasks: [OptimizedTaskSchedule]
    public let efficiency: Double
    public let recommendations: [String]
}

public struct OptimizedTaskSchedule {
    public let taskId: UUID
    public let title: String
    public let scheduledStart: Date
    public let scheduledEnd: Date
    public let optimalTimeSlot: Bool
    public let reasoning: String
}

public struct ProductivityInsights {
    public let userId: String
    public let timeRange: DateInterval
    public let completionRate: Double
    public let averageTaskDuration: TimeInterval
    public let peakProductivityHours: [Int]
    public let recommendations: [String]
}

public enum ProjectType: String, CaseIterable {
    case habitQuest = "habit_quest"
    case momentumFinance = "momentum_finance"
    case plannerApp = "planner_app"
    case codingReviewer = "coding_reviewer"
    case avoidObstaclesGame = "avoid_obstacles_game"
}

// Protocol forward declarations
public protocol EnhancedHabitProtocol {
    var id: UUID { get }
    var name: String { get set }
}

public protocol EnhancedHabitLogProtocol {
    var id: UUID { get }
    var habitId: UUID { get set }
}

public protocol HabitAchievementProtocol {
    var id: UUID { get }
    var habitId: UUID { get set }
}

public protocol EnhancedFinancialTransactionProtocol {
    var id: UUID { get }
    var amount: Double { get set }
}

public protocol EnhancedTaskProtocol {
    var id: UUID { get }
    var title: String { get set }
}

// Service protocols (simplified versions for state management)
public protocol AnalyticsServiceProtocol {
    func track(event: String, properties: [String: Any]?, userId: String?) async
}

public protocol HabitServiceProtocol {
    func createHabit(_ habit: any EnhancedHabitProtocol) async throws -> any EnhancedHabitProtocol
    func logHabitCompletion(_ habitId: UUID, value: Double?, mood: MoodRating?, notes: String?)
        async throws -> any EnhancedHabitLogProtocol
    func calculateStreak(for habitId: UUID) async throws -> Int
    func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws -> HabitInsights
    func checkAchievements(for habitId: UUID) async throws -> [any HabitAchievementProtocol]
}

public protocol FinancialServiceProtocol {
    func createTransaction(_ transaction: any EnhancedFinancialTransactionProtocol) async throws
        -> any EnhancedFinancialTransactionProtocol
    func calculateNetWorth(for userId: String, asOf: Date?) async throws -> NetWorthSummary
    func generateFinancialRecommendations(for userId: String) async throws
        -> [FinancialRecommendation]
}

public protocol PlannerServiceProtocol {
    func createTask(_ task: any EnhancedTaskProtocol) async throws -> any EnhancedTaskProtocol
    func updateTaskProgress(_ taskId: UUID, progress: Double) async throws
        -> any EnhancedTaskProtocol
    func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws
        -> ScheduleOptimization
    func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws
        -> ProductivityInsights
}

public protocol CrossProjectServiceProtocol {
    func syncData(from sourceProject: ProjectType, to targetProject: ProjectType) async throws
}
