import Foundation
import SharedKitCore

#if canImport(SwiftData) && canImport(Combine)
import SwiftData
import SwiftUI
import Combine

// MARK: - Integration Types

// Note: StateValue, StateChangeType, ProjectType and MockInjected are now
// centrally defined in SharedKitCore/CommonTypes.swift to ensure consistency.

// MARK: - Type Definitions
// Note: Shared models and protocols are now centrally defined in ServiceProtocols.swift
// to avoid redeclaration errors and ensure consistency across the framework.

// Mock service implementations for compilation
@MainActor
public class MockAnalyticsService: AnalyticsServiceProtocol {
    public let serviceId = "mock_analytics_service"
    public let version = "1.0.0"

    public init() {}

    public func initialize() async throws {}
    public func cleanup() async {}
    public func healthCheck() async -> ServiceHealthStatus { .healthy }

    public func track(event: String, properties: [String: AnyCodable]?, userId: String?) async {
        print("📊 Mock Analytics: \(event)")
    }

    public func trackUserAction(_ action: UserAction) async {}
    public func trackPerformance(_ metric: PerformanceMetric) async {}
    public func trackError(_ error: any Error & Sendable, context: [String: AnyCodable]?) async {}

    public func getAnalyticsSummary(timeRange: DateInterval) async throws -> AnalyticsSummary {
        AnalyticsSummary(
            timeRange: timeRange,
            totalEvents: 0,
            uniqueUsers: 0,
            topActions: [:],
            averageSessionDuration: 0,
            errorRate: 0,
            performanceMetrics: [:]
        )
    }

    public func exportData(format: SharedKitCore.ExportFormat, timeRange: DateInterval) async throws
        -> Data
    {
        Data()
    }
}

@MainActor
public class MockHabitService: HabitServiceProtocol {
    public let serviceId = "mock_habit"
    public let version = "1.0.0"

    public init() {}

    public func initialize() async throws {}
    public func cleanup() async {}
    public func healthCheck() async -> ServiceHealthStatus { .healthy }

    public func createHabit(_ habit: EnhancedHabit) async throws -> EnhancedHabit {
        return habit
    }

    public func logHabitCompletion(
        _ habitId: UUID,
        value: Double? = nil,
        mood: MoodRating? = nil,
        notes: String? = nil
    ) async throws -> EnhancedHabitLog {
        return EnhancedHabitLog(
            habit: EnhancedHabit(name: "Mock"),
            completionDate: Date(),
            isCompleted: true,
            actualDurationMinutes: value.map { Int($0) },
            notes: notes,
            mood: mood
        )
    }

    public func calculateStreak(for habitId: UUID) async throws -> Int {
        return 0
    }

    public func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws
        -> HabitInsights
    {
        return HabitInsights(
            habitId: habitId,
            timeRange: timeRange,
            completionRate: 0.0,
            currentStreak: 0,
            longestStreak: 0,
            averageValue: 0.0,
            moodCorrelation: 0.0,
            recommendations: []
        )
    }

    public func checkAchievements(for habitId: UUID) async throws -> [HabitAchievement] {
        return []
    }

    public func generateRecommendations(for userId: String) async throws -> [HabitRecommendation] {
        return []
    }
}

@MainActor
public class MockFinancialService: SharedKitCore.FinancialServiceProtocol {
    public let serviceId = "mock_financial_service"
    public let version = "1.0.0"

    public init() {}

    public func initialize() async throws {}
    public func cleanup() async {}
    public func healthCheck() async -> SharedKitCore.ServiceHealthStatus { .healthy }

    public func createTransaction(
        _ transaction: EnhancedFinancialTransaction
    ) async throws -> EnhancedFinancialTransaction {
        transaction
    }

    public func calculateAccountBalance(_ accountId: UUID, asOf: Date?) async throws -> Double { 0 }

    public func getBudgetInsights(for budgetId: UUID, timeRange: DateInterval) async throws
        -> SharedKitCore.BudgetInsights
    {
        SharedKitCore.BudgetInsights(
            budgetId: budgetId,
            timeRange: timeRange,
            utilizationRate: 0.5,
            categoryBreakdown: [:],
            trendAnalysis: .stable,
            recommendations: [],
            alerts: []
        )
    }

    public func calculateNetWorth(for userId: String, asOf date: Date?) async throws
        -> SharedKitCore.NetWorthSummary
    {
        SharedKitCore.NetWorthSummary(
            userId: userId,
            asOfDate: date ?? Date(),
            totalAssets: 0,
            totalLiabilities: 0,
            monthOverMonthChange: 0,
            yearOverYearChange: 0,
            breakdown: SharedKitCore.NetWorthBreakdown(
                cashAndEquivalents: 0,
                investments: 0,
                realEstate: 0,
                personalProperty: 0,
                creditCardDebt: 0,
                loans: 0,
                mortgages: 0
            )
        )
    }

    public func generateFinancialRecommendations(for userId: String) async throws -> [SharedKitCore
        .FinancialRecommendation]
    { [] }

    public func categorizeTransaction(
        _ transaction: EnhancedFinancialTransaction
    ) async throws -> SharedKitCore.TransactionCategory {
        .expense
    }

    public func getTransaction(by id: UUID) async throws -> EnhancedFinancialTransaction? {
        nil
    }

    public func getAllTransactions(predicate: NSPredicate?) async throws
        -> [EnhancedFinancialTransaction]
    {
        []
    }

    public func updateTransaction(
        _ transaction: EnhancedFinancialTransaction
    )
        async throws -> EnhancedFinancialTransaction
    {
        transaction
    }

    public func deleteTransaction(by id: UUID) async throws {}

    public func batchCreateTransactions(
        _ transactions: [EnhancedFinancialTransaction]
    )
        async throws -> [EnhancedFinancialTransaction]
    {
        transactions
    }

    public func batchUpdateTransactions(
        _ transactions: [EnhancedFinancialTransaction]
    )
        async throws -> [EnhancedFinancialTransaction]
    {
        transactions
    }

    public func batchDeleteTransactions(ids: [UUID]) async throws {}

    public func searchTransactions(query: String, fields: [String]) async throws
        -> [EnhancedFinancialTransaction]
    {
        []
    }

    public func countTransactions(predicate: NSPredicate?) async throws -> Int {
        0
    }

    public func validateTransaction(
        _ transaction: EnhancedFinancialTransaction
    )
        async throws
    {}

    public func exportFinancialData(for userId: String, format: SharedKitCore.ExportFormat)
        async throws -> Data
    {
        Data()
    }
}

@MainActor
public class MockPlannerService: PlannerServiceProtocol {
    public let serviceId = "mock_planner"
    public let version = "1.0.0"

    public init() {}

    public func initialize() async throws {}
    public func cleanup() async {}
    public func healthCheck() async -> ServiceHealthStatus { .healthy }

    public func createTask(_ task: EnhancedTask) async throws -> EnhancedTask {
        return task
    }

    public func updateTaskProgress(_ taskId: UUID, progress: Double) async throws -> EnhancedTask {
        return EnhancedTask(title: "Mock Task")
    }

    public func calculateGoalProgress(_ goalId: UUID) async throws -> SharedKitCore.GoalProgress {
        SharedKitCore.GoalProgress(
            goalId: goalId,
            currentProgress: 0,
            targetValue: 100,
            estimatedCompletion: nil,
            milestones: []
        )
    }

    public func generateTaskRecommendations(
        for userId: String, context: SharedKitCore.PlanningContext
    ) async throws -> [SharedKitCore.TaskRecommendation] {
        []
    }

    public func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws
        -> SharedKitCore.ScheduleOptimization
    {
        SharedKitCore.ScheduleOptimization(
            userId: userId,
            timeRange: timeRange,
            optimizedTasks: [],
            efficiency: 0,
            recommendations: []
        )
    }

    public func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws
        -> SharedKitCore.ProductivityInsights
    {
        SharedKitCore.ProductivityInsights(
            userId: userId,
            timeRange: timeRange,
            completionRate: 0,
            averageTaskDuration: 0,
            peakProductivityHours: [],
            productivityTrend: .stable,
            topCategories: [:],
            recommendations: []
        )
    }
}

@MainActor
public class MockCrossProjectService: SharedKitCore.CrossProjectServiceProtocol {
    public let serviceId = "mock_cross_project_service"
    public let version = "1.0.0"

    public init() {}

    public func initialize() async throws {}
    public func cleanup() async {}
    public func healthCheck() async -> SharedKitCore.ServiceHealthStatus { .healthy }

    public func syncData(
        from sourceProject: SharedKitCore.ProjectType, to targetProject: SharedKitCore.ProjectType
    ) async throws {
        print("Mock sync from \(sourceProject.rawValue) to \(targetProject.rawValue)")
    }

    public func getCrossProjectReferences(for entityId: UUID, entityType: String) async throws
        -> [SharedKitCore.CrossProjectReference]
    {
        []
    }

    public func createCrossProjectRelationship(
        _ relationship: SharedKitCore.CrossProjectRelationship
    ) async throws {}

    public func getUnifiedUserInsights(for userId: String) async throws
        -> SharedKitCore.UnifiedUserInsights
    {
        SharedKitCore.UnifiedUserInsights(
            userId: userId,
            timeRange: DateInterval(start: Date(), duration: 3600),
            habitInsights: [],
            financialInsights: nil,
            productivityInsights: SharedKitCore.ProductivityInsights(
                userId: userId,
                timeRange: DateInterval(start: Date(), duration: 3600),
                completionRate: 0,
                averageTaskDuration: 0,
                peakProductivityHours: [],
                productivityTrend: .stable,
                topCategories: [:],
                recommendations: []
            ),
            crossProjectCorrelations: [],
            overallScore: 0,
            recommendations: []
        )
    }

    public func exportUnifiedData(for userId: String, format: SharedKitCore.ExportFormat)
        async throws -> Data
    {
        Data()
    }
}

// Mock model implementations removed as we now use concrete types locally or in tests
// Mock implementations removed

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
public enum StateHealthStatus: Sendable {
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

// MARK: - State Management Core

public struct StateChange: Sendable {
    public let id: UUID
    public let timestamp: Date = .init()
    public let sourceProject: SharedKitCore.ProjectType
    public let stateManager: String
    public let changeType: SharedKitCore.StateChangeType
    public let payload: [String: SharedKitCore.StateValue]
    public let userId: String?

    public init(
        sourceProject: SharedKitCore.ProjectType,
        stateManager: String,
        changeType: SharedKitCore.StateChangeType,
        payload: [String: SharedKitCore.StateValue],
        userId: String? = nil
    ) {
        self.id = UUID()
        self.sourceProject = sourceProject
        self.stateManager = stateManager
        self.changeType = changeType
        self.payload = payload
        self.userId = userId
    }
}

// MARK: - Generic State Manager

/// Generic state manager for handling collections of data
@MainActor
public class GenericStateManager<T: Identifiable>: ObservableObject, StateManagerProtocol
where T.ID == UUID {
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
        _analyticsService = MockInjected(wrappedValue: MockAnalyticsService())
        self.setupObservation()
    }

    // MARK: - StateManagerProtocol Implementation

    public func initialize() async throws {
        await self.analyticsService.track(
            event: "state_manager_initialized",
            properties: ["state_id": AnyCodable(self.stateId)],
            userId: nil as String?
        )
    }

    public func reset() async {
        self.items = []
        self.error = nil
        self.lastUpdated = nil
        await self.analyticsService.track(
            event: "state_manager_reset",
            properties: ["state_id": AnyCodable(self.stateId)],
            userId: nil as String?
        )
    }

    public func cleanup() async {
        self.cancellables.removeAll()
        await self.analyticsService.track(
            event: "state_manager_cleaned_up",
            properties: ["state_id": AnyCodable(self.stateId)],
            userId: nil as String?
        )
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
                await self.analyticsService.trackError(
                    error!,
                    context: [
                        "state_id": .string(self.stateId),
                        "error": .string(error!.localizedDescription),
                    ])
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
                        properties: [
                            "state_id": .string(self.stateId), "item_count": .int(self.items.count),
                        ],
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
public final class HabitStateManager: ObservableObject, StateManagerProtocol, StatePersistable,
    StateSynchronizable
{
    public let stateId = "habit_state_manager"

    // MARK: - Published Properties

    @Published public private(set) var habits: [UUID: EnhancedHabit] = [:]
    @Published public private(set) var habitLogs: [UUID: [EnhancedHabitLog]] = [:]
    @Published public private(set) var achievements: [UUID: [HabitAchievement]] = [:]
    @Published public private(set) var streaks: [UUID: Int] = [:]
    @Published public private(set) var insights: [UUID: HabitInsights] = [:]

    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    @Published public private(set) var lastSyncDate: Date?

    // MARK: - Services

    @SharedKitCore.MockInjected public var habitService: any SharedKitCore.HabitServiceProtocol
    @SharedKitCore.MockInjected public var analyticsService:
        any SharedKitCore.AnalyticsServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var pendingChanges: [StateChange] = []

    // MARK: - Initialization

    public init() {
        self.setupObservation()
    }

    // MARK: - StateManagerProtocol Implementation

    public func initialize() async throws {
        try await self.loadState()
        await self.analyticsService.track(
            event: "habit_state_manager_initialized", properties: nil, userId: nil)
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
        await self.analyticsService.track(
            event: "habit_state_cleaned_up", properties: nil, userId: nil)
    }

    public func getStateHealth() async -> StateHealthStatus {
        if let error {
            return .error(error)
        }

        if let lastSync = lastSyncDate, Date().timeIntervalSince(lastSync) > 1800 {  // 30 minutes
            return .warning("State not synced recently")
        }

        return .healthy
    }

    // MARK: - Habit Management

    public func createHabit(_ habit: EnhancedHabit) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let createdHabit = try await habitService.createHabit(habit)
            self.habits[createdHabit.id] = createdHabit

            self.addPendingChange(
                StateChange(
                    sourceProject: ProjectType.habitQuest,
                    stateManager: self.stateId,
                    changeType: .create,
                    payload: [
                        "habitId": SharedKitCore.StateValue.string(createdHabit.id.uuidString),
                        "name": SharedKitCore.StateValue.string(createdHabit.name),
                    ]
                ))

            await self.analyticsService.track(
                event: "habit_created",
                properties: ["habitId": .string(createdHabit.id.uuidString)],
                userId: nil
            )
        } catch {
            self.error = error
            throw error
        }
    }

    public func updateHabit(_ habit: EnhancedHabit) async throws {
        self.isLoading = true
        defer { isLoading = false }

        self.habits[habit.id] = habit

        self.addPendingChange(
            StateChange(
                sourceProject: .habitQuest,
                stateManager: self.stateId,
                changeType: .update,
                payload: [
                    "habitId": SharedKitCore.StateValue.string(habit.id.uuidString),
                    "name": SharedKitCore.StateValue.string(habit.name),
                ]
            ))

        await self.analyticsService.track(
            event: "habit_updated",
            properties: ["habit_id": .string(habit.id.uuidString)],
            userId: nil
        )
    }

    public func deleteHabit(withId habitId: UUID) async throws {
        self.habits.removeValue(forKey: habitId)
        self.habitLogs.removeValue(forKey: habitId)
        self.achievements.removeValue(forKey: habitId)
        self.streaks.removeValue(forKey: habitId)
        self.insights.removeValue(forKey: habitId)

        self.addPendingChange(
            StateChange(
                sourceProject: .habitQuest,
                stateManager: self.stateId,
                changeType: SharedKitCore.StateChangeType.delete,
                payload: ["habitId": SharedKitCore.StateValue.string(habitId.uuidString)]
            ))

        await self.analyticsService.track(
            event: "habit_deleted",
            properties: ["habit_id": .string(habitId.uuidString)],
            userId: nil
        )
    }

    public func logHabitCompletion(
        _ habitId: UUID, value: Double?, mood: MoodRating?, notes: String?
    ) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let habitLog = try await habitService.logHabitCompletion(
                habitId, value: value, mood: mood, notes: notes)

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

            await self.analyticsService.track(
                event: "habit_completed",
                properties: [
                    "habitId": .string(habitId.uuidString),
                    "value": .double(value ?? 0),
                    "mood": .int(mood?.rawValue ?? 0),
                    "streak": .int(currentStreak),
                ], userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }

    public func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws {
        do {
            let habitInsights = try await habitService.getHabitInsights(
                for: habitId, timeRange: timeRange)
            self.insights[habitId] = habitInsights

            await self.analyticsService.track(
                event: "habit_insights_loaded",
                properties: [
                    "habit_id": .string(habitId.uuidString),
                    "completion_rate": .double(habitInsights.completionRate),
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

        await self.analyticsService.track(
            event: "habit_state_saved",
            properties: ["habit_count": .int(self.habits.count)],
            userId: nil
        )
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

        await self.analyticsService.track(
            event: "habit_state_cleared", properties: nil, userId: nil)
    }

    // MARK: - StateSynchronizable Implementation

    public func syncState(with projects: [ProjectType]) async throws {
        for project in projects {
            await self.analyticsService.track(
                event: "habit_state_sync_requested",
                properties: ["target_project": .string(project.rawValue)],
                userId: nil
            )
        }

        self.lastSyncDate = Date()
    }

    public func handleExternalStateChange(_ change: StateChange) async {
        switch change.changeType {
        case .create, .update:
            // Handle external habit changes
            await self.analyticsService.track(
                event: "external_habit_change_received",
                properties: [
                    "source_project": .string(change.sourceProject.rawValue),
                    "change_type": .string(change.changeType.description),
                ], userId: change.userId)

        case .delete:
            // Handle external deletions
            guard let habitIdString = change.payload["habitId"]?.stringValue,
                let habitId = UUID(uuidString: habitIdString)
            else { return }
            self.habits.removeValue(forKey: habitId)

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
public final class FinancialStateManager: ObservableObject, StateManagerProtocol, StatePersistable,
    StateSynchronizable
{
    public let stateId = "financial_state_manager"

    // MARK: - Published Properties

    @Published public private(set) var accounts: [UUID: EnhancedFinancialAccount] = [:]
    @Published public private(set) var transactions: [EnhancedFinancialTransaction] = []
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
        await self.analyticsService.track(
            event: "financial_state_manager_initialized", properties: nil, userId: nil)
    }

    public func reset() async {
        self.accounts.removeAll()
        self.transactions.removeAll()
        self.budgets.removeAll()
        self.netWorth = nil
        self.recommendations.removeAll()
        self.error = nil
        self.lastSyncDate = nil

        await self.analyticsService.track(
            event: "financial_state_reset", properties: nil, userId: nil)
    }

    public func cleanup() async {
        self.cancellables.removeAll()
        try? await self.saveState()
        await self.analyticsService.track(
            event: "financial_state_cleaned_up", properties: nil, userId: nil)
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

    public func createTransaction(_ transaction: EnhancedFinancialTransaction) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let createdTransaction = try await financialService.createTransaction(transaction)
            self.transactions.append(createdTransaction)

            self.addPendingChange(
                StateChange(
                    sourceProject: .momentumFinance,
                    stateManager: self.stateId,
                    changeType: .create,
                    payload: [
                        "transaction_id": .string(createdTransaction.id.uuidString),
                        "amount": .double(createdTransaction.amount),
                    ]
                ))

            await self.analyticsService.track(
                event: "transaction_created",
                properties: [
                    "transactionId": .string(transaction.id.uuidString),
                    "amount": .double(transaction.amount),
                    "category": .string(transaction.category ?? "Uncategorized"),
                    "timestamp": .int(Int(transaction.date.timeIntervalSince1970)),
                ],
                userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }

    public func calculateNetWorth(for userId: String) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let netWorthSummary = try await financialService.calculateNetWorth(
                for: userId, asOf: Date())
            self.netWorth = netWorthSummary

            await self.analyticsService.track(
                event: "net_worth_calculated",
                properties: [
                    "user_id": .string(userId),
                    "net_worth": .double(netWorthSummary.netWorth),
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
            let newRecommendations = try await financialService.generateFinancialRecommendations(
                for: userId)
            self.recommendations = newRecommendations

            await self.analyticsService.track(
                event: "financial_recommendations_generated",
                properties: [
                    "user_id": .string(userId),
                    "recommendation_count": .int(newRecommendations.count),
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
            properties: ["transaction_count": AnyCodable(self.transactions.count)],
            userId: nil
        )
    }

    public func loadState() async throws {
        if let savedDate = UserDefaults.standard.object(forKey: "financial_last_save_date") as? Date
        {
            self.lastSyncDate = savedDate
        }
        await self.analyticsService.track(
            event: "financial_state_loaded", properties: nil, userId: nil)
    }

    public func clearPersistedState() async throws {
        UserDefaults.standard.removeObject(forKey: "financial_last_save_date")
        await self.analyticsService.track(
            event: "financial_state_cleared", properties: nil, userId: nil)
    }

    // MARK: - StateSynchronizable Implementation

    public func syncState(with projects: [ProjectType]) async throws {
        self.lastSyncDate = Date()
        await self.analyticsService.track(
            event: "financial_state_synced",
            properties: ["project_count": AnyCodable(projects.count)],
            userId: nil
        )
    }

    public func handleExternalStateChange(_ change: StateChange) async {
        await self.analyticsService.track(
            event: "external_financial_change_received",
            properties: [
                "source_project": AnyCodable(change.sourceProject.rawValue),
                "change_type": AnyCodable(change.changeType.description),
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
public final class PlannerStateManager: ObservableObject, StateManagerProtocol, StatePersistable,
    StateSynchronizable
{
    public let stateId = "planner_state_manager"

    // MARK: - Published Properties

    @Published public private(set) var tasks: [UUID: EnhancedTask] = [:]
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
        await self.analyticsService.track(
            event: "planner_state_manager_initialized", properties: nil, userId: nil)
    }

    public func reset() async {
        self.tasks.removeAll()
        self.goals.removeAll()
        self.scheduleOptimization = nil
        self.productivityInsights = nil
        self.recommendations.removeAll()
        self.error = nil
        self.lastSyncDate = nil

        await self.analyticsService.track(
            event: "planner_state_reset", properties: nil, userId: nil)
    }

    public func cleanup() async {
        self.cancellables.removeAll()
        try? await self.saveState()
        await self.analyticsService.track(
            event: "planner_state_cleaned_up", properties: nil, userId: nil)
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

    public func createTask(_ task: EnhancedTask) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let createdTask = try await plannerService.createTask(task)
            self.tasks[createdTask.id] = createdTask

            self.addPendingChange(
                StateChange(
                    sourceProject: .plannerApp,
                    stateManager: self.stateId,
                    changeType: .create,
                    payload: [
                        "task_id": .string(createdTask.id.uuidString),
                        "title": .string(createdTask.title),
                    ]
                ))

            await self.analyticsService.track(
                event: "task_created",
                properties: [
                    "taskId": .string(createdTask.id.uuidString),
                    "title": .string(createdTask.title),
                ],
                userId: nil)
        } catch {
            self.error = error
            throw error
        }
    }

    public func updateTaskProgress(_ taskId: UUID, progress: Double) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let updatedTask = try await plannerService.updateTaskProgress(
                taskId, progress: progress)
            self.tasks[taskId] = updatedTask

            await self.analyticsService.track(
                event: "task_progress_updated",
                properties: [
                    "task_id": .string(taskId.uuidString),
                    "progress": .double(progress),
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
            let optimization = try await plannerService.optimizeSchedule(
                for: userId, timeRange: timeRange)
            self.scheduleOptimization = optimization

            await self.analyticsService.track(
                event: "schedule_optimized",
                properties: [
                    "user_id": .string(userId),
                    "efficiency": .double(optimization.efficiency),
                    "task_count": .int(optimization.optimizedTasks.count),
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
            let insights = try await plannerService.getProductivityInsights(
                for: userId, timeRange: timeRange)
            self.productivityInsights = insights

            await self.analyticsService.track(
                event: "productivity_insights_loaded",
                properties: [
                    "user_id": .string(userId),
                    "completion_rate": .double(insights.completionRate),
                ], userId: userId)
        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - StatePersistable Implementation

    public func saveState() async throws {
        UserDefaults.standard.set(Date(), forKey: "planner_last_save_date")
        await self.analyticsService.track(
            event: "planner_state_saved",
            properties: ["task_count": .int(self.tasks.count)],
            userId: nil
        )
    }

    public func loadState() async throws {
        if let savedDate = UserDefaults.standard.object(forKey: "planner_last_save_date") as? Date {
            self.lastSyncDate = savedDate
        }
        await self.analyticsService.track(
            event: "planner_state_loaded", properties: nil, userId: nil)
    }

    public func clearPersistedState() async throws {
        UserDefaults.standard.removeObject(forKey: "planner_last_save_date")
        await self.analyticsService.track(
            event: "planner_state_cleared", properties: nil, userId: nil)
    }

    // MARK: - StateSynchronizable Implementation

    public func syncState(with projects: [ProjectType]) async throws {
        self.lastSyncDate = Date()
        await self.analyticsService.track(
            event: "planner_state_synced",
            properties: ["project_count": .int(projects.count)],
            userId: nil
        )
    }

    public func handleExternalStateChange(_ change: StateChange) async {
        await self.analyticsService.track(
            event: "external_planner_change_received",
            properties: [
                "source_project": .string(change.sourceProject.rawValue),
                "change_type": .string(change.changeType.description),
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

            await self.analyticsService.track(
                event: "global_state_initialized", properties: nil, userId: nil)
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

        await self.analyticsService.track(
            event: "global_state_cleaned_up", properties: nil, userId: nil)
    }

    // MARK: - Cross-Project Synchronization

    public func syncAllProjects() async throws {
        self.isLoading = true
        defer { isLoading = false }

        let allProjects: [ProjectType] = [
            .habitQuest,
            .momentumFinance,
            .plannerApp,
            .codingReviewer,
            .avoidObstacles,
        ]

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

            await self.analyticsService.track(
                event: "global_state_synced",
                properties: [
                    "change_count": .int(allChanges.count),
                    "projects_synced": .int(allProjects.count),
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
        Timer.publish(every: 300, on: .main, in: .common)  // 5 minutes
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

#endif
