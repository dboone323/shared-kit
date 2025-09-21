//
//  StateManagement.swift
//  Shared State Management System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Import Required Types from Service Layer

// These types are imported from our service protocols

public enum ProjectType: String, CaseIterable {
    case habitQuest = "habit_quest"
    case momentumFinance = "momentum_finance"
    case plannerApp = "planner_app"
    case codingReviewer = "coding_reviewer"
    case avoidObstaclesGame = "avoid_obstacles_game"
    
    public var displayName: String {
        switch self {
        case .habitQuest: "HabitQuest"
        case .momentumFinance: "MomentumFinance"
        case .plannerApp: "PlannerApp"
        case .codingReviewer: "CodingReviewer"
        case .avoidObstaclesGame: "AvoidObstaclesGame"
        }
    }
}

// Re-export types from service protocols for state management
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
    func logHabitCompletion(_ habitId: UUID, value: Double?, mood: MoodRating?, notes: String?) async throws -> any EnhancedHabitLogProtocol
    func calculateStreak(for habitId: UUID) async throws -> Int
    func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws -> HabitInsights
    func checkAchievements(for habitId: UUID) async throws -> [any HabitAchievementProtocol]
}

public protocol FinancialServiceProtocol {
    func createTransaction(_ transaction: any EnhancedFinancialTransactionProtocol) async throws -> any EnhancedFinancialTransactionProtocol
    func calculateNetWorth(for userId: String, asOf: Date?) async throws -> NetWorthSummary
    func generateFinancialRecommendations(for userId: String) async throws -> [FinancialRecommendation]
}

public protocol PlannerServiceProtocol {
    func createTask(_ task: any EnhancedTaskProtocol) async throws -> any EnhancedTaskProtocol
    func updateTaskProgress(_ taskId: UUID, progress: Double) async throws -> any EnhancedTaskProtocol
    func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws -> ScheduleOptimization
    func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws -> ProductivityInsights
}

public protocol CrossProjectServiceProtocol {
    func syncData(from sourceProject: ProjectType, to targetProject: ProjectType) async throws
}

// Supporting types
public enum MoodRating: Int, CaseIterable {
    case veryPoor = 1, poor, fair, good, excellent
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
    
    public init(taskId: UUID, title: String, scheduledStart: Date, scheduledEnd: Date, optimalTimeSlot: Bool, reasoning: String) {
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
    
    public init(budgetId: UUID, timeRange: DateInterval, utilizationRate: Double, recommendations: [String]) {
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
    
    public init(goalId: UUID, currentProgress: Double, targetValue: Double, estimatedCompletion: Date?) {
        self.goalId = goalId
        self.currentProgress = currentProgress
        self.targetValue = targetValue
        self.progressPercentage = targetValue > 0 ? (currentProgress / targetValue) * 100 : 0
        self.estimatedCompletion = estimatedCompletion
        self.onTrack = self
            .progressPercentage >= 95 || (estimatedCompletion != nil && estimatedCompletion! <= Date().addingTimeInterval(86400 * 7))
    }
}

// Mock Injected property wrapper for compilation
@propertyWrapper
public struct MockInjected<T> {
    public var wrappedValue: T
    
    public init() {
        // This is a mock implementation - in production, this would resolve from DependencyContainer
        fatalError("Mock injection not implemented for type \(T.self)")
    }
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
}

// Mock service implementations for compilation
public class MockAnalyticsService: AnalyticsServiceProtocol {
    public func track(event: String, properties: [String: Any]?, userId: String?) async {
        print("📊 Mock Analytics: \(event)")
    }
}

public class MockHabitService: HabitServiceProtocol {
    public func createHabit(_ habit: any EnhancedHabitProtocol) async throws -> any EnhancedHabitProtocol {
        habit
    }
    
    public func logHabitCompletion(
        _ habitId: UUID,
        value: Double?,
        mood: MoodRating?,
        notes: String?
    ) async throws -> any EnhancedHabitLogProtocol {
        MockHabitLog(id: UUID(), habitId: habitId)
    }
    
    public func calculateStreak(for habitId: UUID) async throws -> Int {
        0
    }
    
    public func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws -> HabitInsights {
        HabitInsights(
            habitId: habitId,
            timeRange: timeRange,
            completionRate: 0,
            currentStreak: 0,
            longestStreak: 0,
            averageValue: nil,
            moodCorrelation: nil,
            recommendations: []
        )
    }
    
    public func checkAchievements(for habitId: UUID) async throws -> [any HabitAchievementProtocol] {
        []
    }
}

public class MockFinancialService: FinancialServiceProtocol {
    public func createTransaction(_ transaction: any EnhancedFinancialTransactionProtocol) async throws
        -> any EnhancedFinancialTransactionProtocol {
        transaction
    }
    
    public func calculateNetWorth(for userId: String, asOf: Date?) async throws -> NetWorthSummary {
        NetWorthSummary(
            userId: userId,
            asOfDate: asOf ?? Date(),
            totalAssets: 0,
            totalLiabilities: 0,
            netWorth: 0,
            monthOverMonthChange: 0,
            yearOverYearChange: 0
        )
    }
    
    public func generateFinancialRecommendations(for userId: String) async throws -> [FinancialRecommendation] {
        []
    }
}

public class MockPlannerService: PlannerServiceProtocol {
    public func createTask(_ task: any EnhancedTaskProtocol) async throws -> any EnhancedTaskProtocol {
        task
    }
    
    public func updateTaskProgress(_ taskId: UUID, progress: Double) async throws -> any EnhancedTaskProtocol {
        MockTask(id: taskId, title: "Mock Task")
    }
    
    public func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws -> ScheduleOptimization {
        ScheduleOptimization(userId: userId, timeRange: timeRange, optimizedTasks: [], efficiency: 0, recommendations: [])
    }
    
    public func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws -> ProductivityInsights {
        ProductivityInsights(
            userId: userId,
            timeRange: timeRange,
            completionRate: 0,
            averageTaskDuration: 0,
            peakProductivityHours: [],
            recommendations: []
        )
    }
}

public class MockCrossProjectService: CrossProjectServiceProtocol {
    public func syncData(from sourceProject: ProjectType, to targetProject: ProjectType) async throws {
        print("Mock sync from \(sourceProject.displayName) to \(targetProject.displayName)")
    }
}

// Mock model implementations
public struct MockHabitLog: EnhancedHabitLogProtocol {
    public let id: UUID
    public var habitId: UUID
}

public struct MockTask: EnhancedTaskProtocol {
    public let id: UUID
    public var title: String
}

public struct MockHabit: EnhancedHabitProtocol {
    public let id: UUID
    public var name: String
}

public struct MockTransaction: EnhancedFinancialTransactionProtocol {
    public let id: UUID
    public var amount: Double
}

public struct MockAchievement: HabitAchievementProtocol {
    public let id: UUID
    public var habitId: UUID
}

// MARK: - Core State Management Protocols

/// Base protocol for all state managers
public protocol StateManagerProtocol: ObservableObject {
    /// Unique identifier for the state manager
    var stateId: String { get }
    
    /// Initialize the state manager
    func initialize() async throws
    
    /// Reset state to initial values
    func reset() async
    
    /// Cleanup resources
    func cleanup() async
    
    /// Get current state health
    func getStateHealth() async -> StateHealthStatus
}

/// State health status enumeration
public enum StateHealthStatus {
    case healthy
    case warning(String)
    case error(Error)
    
    public var isHealthy: Bool {
        switch self {
        case .healthy: true
        case .warning, .error: false
        }
    }
}

/// Protocol for state persistence
public protocol StatePersistable {
    /// Save state to persistent storage
    func saveState() async throws
    
    /// Load state from persistent storage
    func loadState() async throws
    
    /// Clear persisted state
    func clearPersistedState() async throws
}

/// Protocol for state synchronization across projects
public protocol StateSynchronizable {
    /// Sync state with other projects
    func syncState(with projects: [ProjectType]) async throws
    
    /// Handle incoming state changes from other projects
    func handleExternalStateChange(_ change: StateChange) async
    
    /// Get state changes to broadcast to other projects
    func getPendingStateChanges() async -> [StateChange]
}

// MARK: - State Change Models

/// Represents a state change event
public struct StateChange {
    public let id: UUID = .init()
    public let timestamp: Date = .init()
    public let sourceProject: ProjectType
    public let stateManager: String
    public let changeType: StateChangeType
    public let payload: [String: Any]
    public let userId: String?
    
    public init(
        sourceProject: ProjectType,
        stateManager: String,
        changeType: StateChangeType,
        payload: [String: Any],
        userId: String? = nil
    ) {
        self.sourceProject = sourceProject
        self.stateManager = stateManager
        self.changeType = changeType
        self.payload = payload
        self.userId = userId
    }
}

/// State change type enumeration
public enum StateChangeType {
    case create
    case update
    case delete
    case sync
    case reset
    
    public var description: String {
        switch self {
        case .create: "Create"
        case .update: "Update"
        case .delete: "Delete"
        case .sync: "Sync"
        case .reset: "Reset"
        }
    }
}

// MARK: - Generic State Manager

/// Generic state manager for handling collections of data
@MainActor
public class GenericStateManager<T: Identifiable>: ObservableObject, StateManagerProtocol where T.ID == UUID {
    public let stateId: String
    
    @Published public private(set) var items: [T] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    @Published public private(set) var lastUpdated: Date?
    
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "StateManager", qos: .userInitiated)
    
    @MockInjected private var analyticsService: AnalyticsServiceProtocol
    
    public init(stateId: String) {
        self.stateId = stateId
        // Initialize with mock service
        self._analyticsService = MockInjected(wrappedValue: MockAnalyticsService())
        self.setupObservation()
    }
    
    // MARK: - StateManagerProtocol Implementation
    
    public func initialize() async throws {
        await self.analyticsService.track(
            event: "state_manager_initialized",
            properties: ["state_id": self.stateId],
            userId: nil as String?
        )
    }
    
    public func reset() async {
        self.items = []
        self.error = nil
        self.lastUpdated = nil
        await self.analyticsService.track(event: "state_manager_reset", properties: ["state_id": self.stateId], userId: nil as String?)
    }
    
    public func cleanup() async {
        self.cancellables.removeAll()
        await self.analyticsService.track(event: "state_manager_cleaned_up", properties: ["state_id": self.stateId], userId: nil as String?)
    }
    
    public func getStateHealth() async -> StateHealthStatus {
        if self.error != nil {
            return .error(self.error!)
        }
        
        if let lastUpdated, Date().timeIntervalSince(lastUpdated) > 300 {
            return .warning("State not updated recently")
        }
        
        return .healthy
    }
    
    // MARK: - State Management Operations
    
    public func setItems(_ newItems: [T]) {
        self.items = newItems
        self.lastUpdated = Date()
        self.error = nil
    }
    
    public func addItem(_ item: T) {
        self.items.append(item)
        self.lastUpdated = Date()
        self.error = nil
    }
    
    public func updateItem(_ item: T) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            self.items[index] = item
            self.lastUpdated = Date()
            self.error = nil
        }
    }
    
    public func removeItem(withId id: UUID) {
        self.items.removeAll { $0.id == id }
        self.lastUpdated = Date()
        self.error = nil
    }
    
    public func findItem(withId id: UUID) -> T? {
        self.items.first { $0.id == id }
    }
    
    public func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }
    
    public func setError(_ error: Error?) {
        self.error = error
        if error != nil {
            Task {
                await self.analyticsService.trackError(error!, context: ["state_id": self.stateId])
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservation() {
        self.$items
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.analyticsService.track(
                        event: "state_items_changed",
                        properties: ["state_id": self.stateId, "item_count": self.items.count],
                        userId: nil as String?
                    )
                }
            }
            .store(in: &self.cancellables)
    }
}

// MARK: - Habit State Management

/// State manager for habit-related data
@MainActor
public final class HabitStateManager: ObservableObject, StateManagerProtocol, StatePersistable, StateSynchronizable {
    public let stateId = "habit_state_manager"
    
    // MARK: - Published Properties

    @Published public private(set) var habits: [UUID: EnhancedHabitProtocol] = [:]
    @Published public private(set) var habitLogs: [UUID: [EnhancedHabitLogProtocol]] = [:]
    @Published public private(set) var achievements: [UUID: [HabitAchievementProtocol]] = [:]
    @Published public private(set) var streaks: [UUID: Int] = [:]
    @Published public private(set) var insights: [UUID: HabitInsights] = [:]
    
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    @Published public private(set) var lastSyncDate: Date?
    
    // MARK: - Services

    @MockInjected private var habitService: HabitServiceProtocol
    @MockInjected private var analyticsService: AnalyticsServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingChanges: [StateChange] = []
    
    // MARK: - Initialization
    
    public init() {
        self.setupObservation()
    }
    
    // MARK: - StateManagerProtocol Implementation
    
    public func initialize() async throws {
        try await self.loadState()
        await self.analyticsService.track(event: "habit_state_manager_initialized", properties: nil, userId: nil)
    }
    
    public func reset() async {
        self.habits.removeAll()
        self.habitLogs.removeAll()
        self.achievements.removeAll()
        self.streaks.removeAll()
        self.insights.removeAll()
        self.error = nil
        self.lastSyncDate = nil
        
        await self.analyticsService.track(event: "habit_state_reset", properties: nil, userId: nil)
    }
    
    public func cleanup() async {
        self.cancellables.removeAll()
        try? await self.saveState()
        await self.analyticsService.track(event: "habit_state_cleaned_up", properties: nil, userId: nil)
    }
    
    public func getStateHealth() async -> StateHealthStatus {
        if let error {
            return .error(error)
        }
        
        if let lastSync = lastSyncDate, Date().timeIntervalSince(lastSync) > 1800 { // 30 minutes
            return .warning("State not synced recently")
        }
        
        return .healthy
    }
    
    // MARK: - Habit Management
    
    public func createHabit(_ habit: EnhancedHabitProtocol) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let createdHabit = try await habitService.createHabit(habit)
            self.habits[createdHabit.id] = createdHabit
            
            self.addPendingChange(StateChange(
                sourceProject: .habitQuest,
                stateManager: self.stateId,
                changeType: .create,
                payload: ["habit_id": createdHabit.id.uuidString, "name": createdHabit.name]
            ))
            
            await self.analyticsService.track(event: "habit_created", properties: ["habit_id": createdHabit.id.uuidString], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func updateHabit(_ habit: EnhancedHabitProtocol) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        self.habits[habit.id] = habit
        
        self.addPendingChange(StateChange(
            sourceProject: .habitQuest,
            stateManager: self.stateId,
            changeType: .update,
            payload: ["habit_id": habit.id.uuidString, "name": habit.name]
        ))
        
        await self.analyticsService.track(event: "habit_updated", properties: ["habit_id": habit.id.uuidString], userId: nil)
    }
    
    public func deleteHabit(withId habitId: UUID) async throws {
        self.habits.removeValue(forKey: habitId)
        self.habitLogs.removeValue(forKey: habitId)
        self.achievements.removeValue(forKey: habitId)
        self.streaks.removeValue(forKey: habitId)
        self.insights.removeValue(forKey: habitId)
        
        self.addPendingChange(StateChange(
            sourceProject: .habitQuest,
            stateManager: self.stateId,
            changeType: .delete,
            payload: ["habit_id": habitId.uuidString]
        ))
        
        await self.analyticsService.track(event: "habit_deleted", properties: ["habit_id": habitId.uuidString], userId: nil)
    }
    
    public func logHabitCompletion(_ habitId: UUID, value: Double?, mood: MoodRating?, notes: String?) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let habitLog = try await habitService.logHabitCompletion(habitId, value: value, mood: mood, notes: notes)
            
            if self.habitLogs[habitId] == nil {
                self.habitLogs[habitId] = []
            }
            self.habitLogs[habitId]?.append(habitLog)
            
            // Update streak
            let currentStreak = try await habitService.calculateStreak(for: habitId)
            self.streaks[habitId] = currentStreak
            
            // Check for achievements
            let newAchievements = try await habitService.checkAchievements(for: habitId)
            self.achievements[habitId] = newAchievements
            
            await self.analyticsService.track(event: "habit_completed", properties: [
                "habit_id": habitId.uuidString,
                "value": value ?? 0,
                "mood": mood?.rawValue ?? 0,
                "streak": currentStreak
            ], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws {
        do {
            let habitInsights = try await habitService.getHabitInsights(for: habitId, timeRange: timeRange)
            self.insights[habitId] = habitInsights
            
            await self.analyticsService.track(event: "habit_insights_loaded", properties: [
                "habit_id": habitId.uuidString,
                "completion_rate": habitInsights.completionRate
            ], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - StatePersistable Implementation
    
    public func saveState() async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // This would save to persistent storage in a real implementation
        // For now, we'll use UserDefaults as an example
        let habitIds = self.habits.keys.map(\.uuidString)
        UserDefaults.standard.set(habitIds, forKey: "saved_habit_ids")
        UserDefaults.standard.set(Date(), forKey: "last_state_save_date")
        
        await self.analyticsService.track(event: "habit_state_saved", properties: ["habit_count": self.habits.count], userId: nil)
    }
    
    public func loadState() async throws {
        // This would load from persistent storage in a real implementation
        if let savedDate = UserDefaults.standard.object(forKey: "last_state_save_date") as? Date {
            self.lastSyncDate = savedDate
        }
        
        await self.analyticsService.track(event: "habit_state_loaded", properties: nil, userId: nil)
    }
    
    public func clearPersistedState() async throws {
        UserDefaults.standard.removeObject(forKey: "saved_habit_ids")
        UserDefaults.standard.removeObject(forKey: "last_state_save_date")
        
        await self.analyticsService.track(event: "habit_state_cleared", properties: nil, userId: nil)
    }
    
    // MARK: - StateSynchronizable Implementation
    
    public func syncState(with projects: [ProjectType]) async throws {
        for project in projects {
            await self.analyticsService.track(
                event: "habit_state_sync_requested",
                properties: ["target_project": project.rawValue],
                userId: nil
            )
        }
        
        self.lastSyncDate = Date()
    }
    
    public func handleExternalStateChange(_ change: StateChange) async {
        switch change.changeType {
        case .create, .update:
            // Handle external habit changes
            await self.analyticsService.track(event: "external_habit_change_received", properties: [
                "source_project": change.sourceProject.rawValue,
                "change_type": change.changeType.description
            ], userId: change.userId)
            
        case .delete:
            // Handle external deletions
            if let habitIdString = change.payload["habit_id"] as? String,
               let habitId = UUID(uuidString: habitIdString) {
                self.habits.removeValue(forKey: habitId)
            }
            
        case .sync, .reset:
            // Handle sync and reset operations
            break
        }
    }
    
    public func getPendingStateChanges() async -> [StateChange] {
        let changes = self.pendingChanges
        self.pendingChanges.removeAll()
        return changes
    }
    
    // MARK: - Private Methods
    
    private func setupObservation() {
        self.$habits
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    try? await self.saveState()
                }
            }
            .store(in: &self.cancellables)
    }
    
    private func addPendingChange(_ change: StateChange) {
        self.pendingChanges.append(change)
    }
}

// MARK: - Financial State Management

/// State manager for financial data
@MainActor
public final class FinancialStateManager: ObservableObject, StateManagerProtocol, StatePersistable, StateSynchronizable {
    public let stateId = "financial_state_manager"
    
    // MARK: - Published Properties

    @Published public private(set) var accounts: [UUID: EnhancedFinancialTransactionProtocol] = [:]
    @Published public private(set) var transactions: [EnhancedFinancialTransactionProtocol] = []
    @Published public private(set) var budgets: [UUID: BudgetInsights] = [:]
    @Published public private(set) var netWorth: NetWorthSummary?
    @Published public private(set) var recommendations: [FinancialRecommendation] = []
    
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    @Published public private(set) var lastSyncDate: Date?
    
    // MARK: - Services

    @Injected private var financialService: FinancialServiceProtocol
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingChanges: [StateChange] = []
    
    // MARK: - Initialization
    
    public init() {
        self.setupObservation()
    }
    
    // MARK: - StateManagerProtocol Implementation
    
    public func initialize() async throws {
        try await self.loadState()
        await self.analyticsService.track(event: "financial_state_manager_initialized", properties: nil, userId: nil)
    }
    
    public func reset() async {
        self.accounts.removeAll()
        self.transactions.removeAll()
        self.budgets.removeAll()
        self.netWorth = nil
        self.recommendations.removeAll()
        self.error = nil
        self.lastSyncDate = nil
        
        await self.analyticsService.track(event: "financial_state_reset", properties: nil, userId: nil)
    }
    
    public func cleanup() async {
        self.cancellables.removeAll()
        try? await self.saveState()
        await self.analyticsService.track(event: "financial_state_cleaned_up", properties: nil, userId: nil)
    }
    
    public func getStateHealth() async -> StateHealthStatus {
        if let error {
            return .error(error)
        }
        
        if self.transactions.isEmpty, self.accounts.isEmpty {
            return .warning("No financial data loaded")
        }
        
        return .healthy
    }
    
    // MARK: - Financial Operations
    
    public func createTransaction(_ transaction: EnhancedFinancialTransactionProtocol) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let createdTransaction = try await financialService.createTransaction(transaction)
            self.transactions.append(createdTransaction)
            
            self.addPendingChange(StateChange(
                sourceProject: .momentumFinance,
                stateManager: self.stateId,
                changeType: .create,
                payload: ["transaction_id": createdTransaction.id.uuidString, "amount": createdTransaction.amount]
            ))
            
            await self.analyticsService.track(event: "transaction_created", properties: [
                "transaction_id": createdTransaction.id.uuidString,
                "amount": createdTransaction.amount
            ], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func calculateNetWorth(for userId: String) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let netWorthSummary = try await financialService.calculateNetWorth(for: userId, asOf: Date())
            self.netWorth = netWorthSummary
            
            await self.analyticsService.track(event: "net_worth_calculated", properties: [
                "user_id": userId,
                "net_worth": netWorthSummary.netWorth
            ], userId: userId)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func generateRecommendations(for userId: String) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let newRecommendations = try await financialService.generateFinancialRecommendations(for: userId)
            self.recommendations = newRecommendations
            
            await self.analyticsService.track(event: "financial_recommendations_generated", properties: [
                "user_id": userId,
                "recommendation_count": newRecommendations.count
            ], userId: userId)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - StatePersistable Implementation
    
    public func saveState() async throws {
        UserDefaults.standard.set(Date(), forKey: "financial_last_save_date")
        await self.analyticsService.track(
            event: "financial_state_saved",
            properties: ["transaction_count": self.transactions.count],
            userId: nil
        )
    }
    
    public func loadState() async throws {
        if let savedDate = UserDefaults.standard.object(forKey: "financial_last_save_date") as? Date {
            self.lastSyncDate = savedDate
        }
        await self.analyticsService.track(event: "financial_state_loaded", properties: nil, userId: nil)
    }
    
    public func clearPersistedState() async throws {
        UserDefaults.standard.removeObject(forKey: "financial_last_save_date")
        await self.analyticsService.track(event: "financial_state_cleared", properties: nil, userId: nil)
    }
    
    // MARK: - StateSynchronizable Implementation
    
    public func syncState(with projects: [ProjectType]) async throws {
        self.lastSyncDate = Date()
        await self.analyticsService.track(event: "financial_state_synced", properties: ["project_count": projects.count], userId: nil)
    }
    
    public func handleExternalStateChange(_ change: StateChange) async {
        await self.analyticsService.track(event: "external_financial_change_received", properties: [
            "source_project": change.sourceProject.rawValue,
            "change_type": change.changeType.description
        ], userId: change.userId)
    }
    
    public func getPendingStateChanges() async -> [StateChange] {
        let changes = self.pendingChanges
        self.pendingChanges.removeAll()
        return changes
    }
    
    // MARK: - Private Methods
    
    private func setupObservation() {
        self.$transactions
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    try? await self.saveState()
                }
            }
            .store(in: &self.cancellables)
    }
    
    private func addPendingChange(_ change: StateChange) {
        self.pendingChanges.append(change)
    }
}

// MARK: - Task and Goal State Management

/// State manager for planning and productivity data
@MainActor
public final class PlannerStateManager: ObservableObject, StateManagerProtocol, StatePersistable, StateSynchronizable {
    public let stateId = "planner_state_manager"
    
    // MARK: - Published Properties

    @Published public private(set) var tasks: [UUID: EnhancedTaskProtocol] = [:]
    @Published public private(set) var goals: [UUID: GoalProgress] = [:]
    @Published public private(set) var scheduleOptimization: ScheduleOptimization?
    @Published public private(set) var productivityInsights: ProductivityInsights?
    @Published public private(set) var recommendations: [TaskRecommendation] = []
    
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    @Published public private(set) var lastSyncDate: Date?
    
    // MARK: - Services

    @Injected private var plannerService: PlannerServiceProtocol
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var pendingChanges: [StateChange] = []
    
    // MARK: - Initialization
    
    public init() {
        self.setupObservation()
    }
    
    // MARK: - StateManagerProtocol Implementation
    
    public func initialize() async throws {
        try await self.loadState()
        await self.analyticsService.track(event: "planner_state_manager_initialized", properties: nil, userId: nil)
    }
    
    public func reset() async {
        self.tasks.removeAll()
        self.goals.removeAll()
        self.scheduleOptimization = nil
        self.productivityInsights = nil
        self.recommendations.removeAll()
        self.error = nil
        self.lastSyncDate = nil
        
        await self.analyticsService.track(event: "planner_state_reset", properties: nil, userId: nil)
    }
    
    public func cleanup() async {
        self.cancellables.removeAll()
        try? await self.saveState()
        await self.analyticsService.track(event: "planner_state_cleaned_up", properties: nil, userId: nil)
    }
    
    public func getStateHealth() async -> StateHealthStatus {
        if let error {
            return .error(error)
        }
        
        if self.tasks.isEmpty {
            return .warning("No tasks loaded")
        }
        
        return .healthy
    }
    
    // MARK: - Task Management
    
    public func createTask(_ task: EnhancedTaskProtocol) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let createdTask = try await plannerService.createTask(task)
            self.tasks[createdTask.id] = createdTask
            
            self.addPendingChange(StateChange(
                sourceProject: .plannerApp,
                stateManager: self.stateId,
                changeType: .create,
                payload: ["task_id": createdTask.id.uuidString, "title": createdTask.title]
            ))
            
            await self.analyticsService.track(event: "task_created", properties: [
                "task_id": createdTask.id.uuidString,
                "title": createdTask.title
            ], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func updateTaskProgress(_ taskId: UUID, progress: Double) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let updatedTask = try await plannerService.updateTaskProgress(taskId, progress: progress)
            self.tasks[taskId] = updatedTask
            
            await self.analyticsService.track(event: "task_progress_updated", properties: [
                "task_id": taskId.uuidString,
                "progress": progress
            ], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let optimization = try await plannerService.optimizeSchedule(for: userId, timeRange: timeRange)
            self.scheduleOptimization = optimization
            
            await self.analyticsService.track(event: "schedule_optimized", properties: [
                "user_id": userId,
                "efficiency": optimization.efficiency,
                "task_count": optimization.optimizedTasks.count
            ], userId: userId)
        } catch {
            self.error = error
            throw error
        }
    }
    
    public func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            let insights = try await plannerService.getProductivityInsights(for: userId, timeRange: timeRange)
            self.productivityInsights = insights
            
            await self.analyticsService.track(event: "productivity_insights_loaded", properties: [
                "user_id": userId,
                "completion_rate": insights.completionRate
            ], userId: userId)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - StatePersistable Implementation
    
    public func saveState() async throws {
        UserDefaults.standard.set(Date(), forKey: "planner_last_save_date")
        await self.analyticsService.track(event: "planner_state_saved", properties: ["task_count": self.tasks.count], userId: nil)
    }
    
    public func loadState() async throws {
        if let savedDate = UserDefaults.standard.object(forKey: "planner_last_save_date") as? Date {
            self.lastSyncDate = savedDate
        }
        await self.analyticsService.track(event: "planner_state_loaded", properties: nil, userId: nil)
    }
    
    public func clearPersistedState() async throws {
        UserDefaults.standard.removeObject(forKey: "planner_last_save_date")
        await self.analyticsService.track(event: "planner_state_cleared", properties: nil, userId: nil)
    }
    
    // MARK: - StateSynchronizable Implementation
    
    public func syncState(with projects: [ProjectType]) async throws {
        self.lastSyncDate = Date()
        await self.analyticsService.track(event: "planner_state_synced", properties: ["project_count": projects.count], userId: nil)
    }
    
    public func handleExternalStateChange(_ change: StateChange) async {
        await self.analyticsService.track(event: "external_planner_change_received", properties: [
            "source_project": change.sourceProject.rawValue,
            "change_type": change.changeType.description
        ], userId: change.userId)
    }
    
    public func getPendingStateChanges() async -> [StateChange] {
        let changes = self.pendingChanges
        self.pendingChanges.removeAll()
        return changes
    }
    
    // MARK: - Private Methods
    
    private func setupObservation() {
        self.$tasks
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    try? await self.saveState()
                }
            }
            .store(in: &self.cancellables)
    }
    
    private func addPendingChange(_ change: StateChange) {
        self.pendingChanges.append(change)
    }
}

// MARK: - Global State Coordinator

/// Coordinates state across all projects and state managers
@MainActor
public final class GlobalStateCoordinator: ObservableObject {
    public static let shared = GlobalStateCoordinator()
    
    // MARK: - State Managers

    @Published public private(set) var habitState = HabitStateManager()
    @Published public private(set) var financialState = FinancialStateManager()
    @Published public private(set) var plannerState = PlannerStateManager()
    
    // MARK: - Global State

    @Published public private(set) var isInitialized = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var globalError: Error?
    @Published public private(set) var lastGlobalSync: Date?
    
    @Injected private var crossProjectService: CrossProjectServiceProtocol
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "GlobalStateSync", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        self.setupGlobalObservation()
    }
    
    // MARK: - Lifecycle Methods
    
    public func initialize() async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        do {
            // Initialize all state managers
            try await self.habitState.initialize()
            try await self.financialState.initialize()
            try await self.plannerState.initialize()
            
            self.isInitialized = true
            
            await self.analyticsService.track(event: "global_state_initialized", properties: nil, userId: nil)
        } catch {
            self.globalError = error
            throw error
        }
    }
    
    public func cleanup() async {
        await self.habitState.cleanup()
        await self.financialState.cleanup()
        await self.plannerState.cleanup()
        
        self.cancellables.removeAll()
        self.isInitialized = false
        
        await self.analyticsService.track(event: "global_state_cleaned_up", properties: nil, userId: nil)
    }
    
    // MARK: - Cross-Project Synchronization
    
    public func syncAllProjects() async throws {
        self.isLoading = true
        defer { isLoading = false }
        
        let allProjects: [ProjectType] = [.habitQuest, .momentumFinance, .plannerApp, .codingReviewer, .avoidObstaclesGame]
        
        do {
            // Sync each state manager with all projects
            try await self.habitState.syncState(with: allProjects)
            try await self.financialState.syncState(with: allProjects)
            try await self.plannerState.syncState(with: allProjects)
            
            // Get and process pending changes
            let habitChanges = await habitState.getPendingStateChanges()
            let financialChanges = await financialState.getPendingStateChanges()
            let plannerChanges = await plannerState.getPendingStateChanges()
            
            let allChanges = habitChanges + financialChanges + plannerChanges
            
            // Distribute changes to relevant state managers
            for change in allChanges {
                await self.distributeStateChange(change)
            }
            
            self.lastGlobalSync = Date()
            
            await self.analyticsService.track(event: "global_state_synced", properties: [
                "change_count": allChanges.count,
                "projects_synced": allProjects.count
            ], userId: nil)
            
        } catch {
            self.globalError = error
            throw error
        }
    }
    
    public func getGlobalHealthStatus() async -> [String: StateHealthStatus] {
        var healthStatuses: [String: StateHealthStatus] = [:]
        
        healthStatuses[self.habitState.stateId] = await self.habitState.getStateHealth()
        healthStatuses[self.financialState.stateId] = await self.financialState.getStateHealth()
        healthStatuses[self.plannerState.stateId] = await self.plannerState.getStateHealth()
        
        return healthStatuses
    }
    
    public func resetAllState() async {
        await self.habitState.reset()
        await self.financialState.reset()
        await self.plannerState.reset()
        
        self.globalError = nil
        self.lastGlobalSync = nil
        
        await self.analyticsService.track(event: "global_state_reset", properties: nil, userId: nil)
    }
    
    // MARK: - Private Methods
    
    private func setupGlobalObservation() {
        // Observe changes in individual state managers
        self.habitState.$error
            .sink { [weak self] error in
                if error != nil {
                    self?.globalError = error
                }
            }
            .store(in: &self.cancellables)
        
        self.financialState.$error
            .sink { [weak self] error in
                if error != nil {
                    self?.globalError = error
                }
            }
            .store(in: &self.cancellables)
        
        self.plannerState.$error
            .sink { [weak self] error in
                if error != nil {
                    self?.globalError = error
                }
            }
            .store(in: &self.cancellables)
        
        // Set up periodic sync
        Timer.publish(every: 300, on: .main, in: .common) // 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    try? await self?.syncAllProjects()
                }
            }
            .store(in: &self.cancellables)
    }
    
    private func distributeStateChange(_ change: StateChange) async {
        switch change.stateManager {
        case self.habitState.stateId:
            // Distribute habit changes to financial and planner states
            await self.financialState.handleExternalStateChange(change)
            await self.plannerState.handleExternalStateChange(change)
            
        case self.financialState.stateId:
            // Distribute financial changes to habit and planner states
            await self.habitState.handleExternalStateChange(change)
            await self.plannerState.handleExternalStateChange(change)
            
        case self.plannerState.stateId:
            // Distribute planner changes to habit and financial states
            await self.habitState.handleExternalStateChange(change)
            await self.financialState.handleExternalStateChange(change)
            
        default:
            break
        }
    }
}
