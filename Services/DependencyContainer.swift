//
//  DependencyContainer.swift
//  Shared Service Layer
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Dependency Injection Container

/// Main dependency injection container for the service layer
public final class DependencyContainer: @unchecked Sendable {
    // MARK: - Singleton Instance

    public static let shared = DependencyContainer()
    
    // MARK: - Private Properties

    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private let lock = NSLock()
    
    // MARK: - Initialization

    private init() {
        self.setupDefaultServices()
    }
    
    // MARK: - Registration Methods
    
    /// Register a service instance
    public func register<T>(_ service: T, for type: T.Type) {
        self.lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        self.services[key] = service
    }
    
    /// Register a factory for creating service instances
    public func register<T>(factory: @escaping () -> T, for type: T.Type) {
        self.lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        self.factories[key] = factory
    }
    
    /// Register a singleton factory
    public func registerSingleton<T>(factory: @escaping () -> T, for type: T.Type) {
        self.lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        self.factories[key] = {
            if let existing = self.singletons[key] {
                return existing
            }
            let instance = factory()
            self.singletons[key] = instance
            return instance
        }
    }
    
    // MARK: - Resolution Methods
    
    /// Resolve a service instance
    public func resolve<T>(_ type: T.Type) -> T? {
        self.lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        // Check for registered instance
        if let service = services[key] as? T {
            return service
        }
        
        // Check for factory
        if let factory = factories[key] {
            return factory() as? T
        }
        
        return nil
    }
    
    /// Resolve a service instance with error handling
    public func resolve<T>(_ type: T.Type) throws -> T {
        guard let service = resolve(type) else {
            throw DependencyError.serviceNotFound(String(describing: type))
        }
        return service
    }
    
    /// Check if a service is registered
    public func isRegistered(_ type: (some Any).Type) -> Bool {
        self.lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        return self.services[key] != nil || self.factories[key] != nil
    }
    
    // MARK: - Lifecycle Methods
    
    /// Clear all registrations
    public func clear() {
        self.lock.lock()
        defer { lock.unlock() }
        
        self.services.removeAll()
        self.factories.removeAll()
        self.singletons.removeAll()
    }
    
    /// Reset to default configuration
    public func reset() {
        self.clear()
        self.setupDefaultServices()
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultServices() {
        // Register default service implementations
        self.registerSingleton(factory: { DefaultAnalyticsService() }, for: AnalyticsServiceProtocol.self)
        self.registerSingleton(factory: { DefaultCrossProjectService() }, for: CrossProjectServiceProtocol.self)
        
        // Register data services
        self.registerSingleton(factory: { DefaultHabitService() }, for: HabitServiceProtocol.self)
        self.registerSingleton(factory: { DefaultFinancialService() }, for: FinancialServiceProtocol.self)
        self.registerSingleton(factory: { DefaultPlannerService() }, for: PlannerServiceProtocol.self)
    }
}

// MARK: - Dependency Injection Property Wrapper

/// Property wrapper for automatic dependency injection
@propertyWrapper
public struct Injected<T> {
    private var service: T?
    
    public var wrappedValue: T {
        mutating get {
            if let service {
                return service
            }
            
            guard let resolvedService = DependencyContainer.shared.resolve(T.self) else {
                fatalError("Service of type \(T.self) not registered in DependencyContainer")
            }
            
            service = resolvedService
            return resolvedService
        }
        set {
            self.service = newValue
        }
    }
    
    public init() {}
    
    public init(wrappedValue: T) {
        self.service = wrappedValue
    }
}

// MARK: - Service Locator Pattern

/// Service locator for accessing services
public enum ServiceLocator {
    public static func get<T>(_ type: T.Type) -> T? {
        DependencyContainer.shared.resolve(type)
    }
    
    public static func get<T>(_ type: T.Type) throws -> T {
        try DependencyContainer.shared.resolve(type)
    }
    
    public static func register<T>(_ service: T, for type: T.Type) {
        DependencyContainer.shared.register(service, for: type)
    }
}

// MARK: - Error Types

public enum DependencyError: Error, LocalizedError {
    case serviceNotFound(String)
    case circularDependency(String)
    case initializationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case let .serviceNotFound(service):
            "Service not found: \(service)"
        case let .circularDependency(service):
            "Circular dependency detected for service: \(service)"
        case let .initializationFailed(service):
            "Failed to initialize service: \(service)"
        }
    }
}

// MARK: - Service Manager

/// Manager for service lifecycle and configuration
public final class ServiceManager: @unchecked Sendable {
    public static let shared = ServiceManager()
    
    private var initializedServices: Set<String> = []
    private let lock = NSLock()
    
    private init() {}
    
    /// Initialize all registered services
    public func initializeServices() async throws {
        let container = DependencyContainer.shared
        
        // Initialize analytics service
        if let analyticsService = container.resolve(AnalyticsServiceProtocol.self) {
            try await self.initializeService(analyticsService)
        }
        
        // Initialize cross-project service
        if let crossProjectService = container.resolve(CrossProjectServiceProtocol.self) {
            try await self.initializeService(crossProjectService)
        }
        
        // Initialize business logic services
        if let habitService = container.resolve(HabitServiceProtocol.self) {
            try await self.initializeService(habitService)
        }
        
        if let financialService = container.resolve(FinancialServiceProtocol.self) {
            try await self.initializeService(financialService)
        }
        
        if let plannerService = container.resolve(PlannerServiceProtocol.self) {
            try await self.initializeService(plannerService)
        }
    }
    
    /// Initialize a specific service
    private func initializeService(_ service: ServiceProtocol) async throws {
        self.lock.lock()
        let serviceId = service.serviceId
        let alreadyInitialized = self.initializedServices.contains(serviceId)
        self.lock.unlock()
        
        if !alreadyInitialized {
            try await service.initialize()
            
            self.lock.lock()
            self.initializedServices.insert(serviceId)
            self.lock.unlock()
        }
    }
    
    /// Cleanup all services
    public func cleanupServices() async {
        let container = DependencyContainer.shared
        
        for serviceId in self.initializedServices {
            // Cleanup services in reverse order
            if let analyticsService = container.resolve(AnalyticsServiceProtocol.self) {
                await analyticsService.cleanup()
            }
            
            if let crossProjectService = container.resolve(CrossProjectServiceProtocol.self) {
                await crossProjectService.cleanup()
            }
            
            if let habitService = container.resolve(HabitServiceProtocol.self) {
                await habitService.cleanup()
            }
            
            if let financialService = container.resolve(FinancialServiceProtocol.self) {
                await financialService.cleanup()
            }
            
            if let plannerService = container.resolve(PlannerServiceProtocol.self) {
                await plannerService.cleanup()
            }
        }
        
        self.lock.lock()
        self.initializedServices.removeAll()
        self.lock.unlock()
    }
    
    /// Get health status of all services
    public func getServicesHealthStatus() async -> [String: ServiceHealthStatus] {
        let container = DependencyContainer.shared
        var healthStatuses: [String: ServiceHealthStatus] = [:]
        
        if let analyticsService = container.resolve(AnalyticsServiceProtocol.self) {
            healthStatuses[analyticsService.serviceId] = await analyticsService.healthCheck()
        }
        
        if let crossProjectService = container.resolve(CrossProjectServiceProtocol.self) {
            healthStatuses[crossProjectService.serviceId] = await crossProjectService.healthCheck()
        }
        
        if let habitService = container.resolve(HabitServiceProtocol.self) {
            healthStatuses[habitService.serviceId] = await habitService.healthCheck()
        }
        
        if let financialService = container.resolve(FinancialServiceProtocol.self) {
            healthStatuses[financialService.serviceId] = await financialService.healthCheck()
        }
        
        if let plannerService = container.resolve(PlannerServiceProtocol.self) {
            healthStatuses[plannerService.serviceId] = await plannerService.healthCheck()
        }
        
        return healthStatuses
    }
}

// MARK: - Default Service Implementations

/// Default analytics service implementation
final class DefaultAnalyticsService: AnalyticsServiceProtocol {
    let serviceId = "default_analytics_service"
    let version = "1.0.0"
    
    func initialize() async throws {
        // Initialize analytics tracking
        print("Analytics service initialized")
    }
    
    func cleanup() async {
        // Cleanup analytics resources
        print("Analytics service cleaned up")
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        .healthy
    }
    
    func track(event: String, properties: [String: Any]?, userId: String?) async {
        // Default implementation - log to console in debug mode
        #if DEBUG
        print("📊 Analytics: \(event) | User: \(userId ?? "anonymous") | Properties: \(properties ?? [:])")
        #endif
    }
    
    func trackUserAction(_ action: UserAction) async {
        await self.track(event: action.action, properties: action.metadata, userId: action.userId)
    }
    
    func trackPerformance(_ metric: PerformanceMetric) async {
        await self.track(event: "performance_metric", properties: [
            "name": metric.name,
            "value": metric.value,
            "unit": metric.unit
        ], userId: nil)
    }
    
    func trackError(_ error: Error, context: [String: Any]?) async {
        await self.track(event: "error", properties: [
            "error": error.localizedDescription,
            "context": context ?? [:]
        ], userId: nil)
    }
    
    func getAnalyticsSummary(timeRange: DateInterval) async throws -> AnalyticsSummary {
        // Default implementation returns empty summary
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
    
    func exportData(format: ExportFormat, timeRange: DateInterval) async throws -> Data {
        // Default implementation returns empty data
        Data()
    }
}

/// Default cross-project service implementation
final class DefaultCrossProjectService: CrossProjectServiceProtocol {
    let serviceId = "default_cross_project_service"
    let version = "1.0.0"
    
    func initialize() async throws {
        print("Cross-project service initialized")
    }
    
    func cleanup() async {
        print("Cross-project service cleaned up")
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        .healthy
    }
    
    func syncData(from sourceProject: ProjectType, to targetProject: ProjectType) async throws {
        // Default implementation - placeholder
        print("Syncing data from \(sourceProject.displayName) to \(targetProject.displayName)")
    }
    
    func getCrossProjectReferences(for entityId: UUID, entityType: String) async throws -> [CrossProjectReference] {
        // Default implementation returns empty array
        []
    }
    
    func createCrossProjectRelationship(_ relationship: CrossProjectRelationship) async throws {
        // Default implementation - placeholder
        print("Created cross-project relationship: \(relationship.type.rawValue)")
    }
    
    func getUnifiedUserInsights(for userId: String) async throws -> UnifiedUserInsights {
        // Default implementation returns minimal insights
        UnifiedUserInsights(
            userId: userId,
            timeRange: DateInterval(start: Date().addingTimeInterval(-86400 * 30), end: Date()),
            habitInsights: [],
            financialInsights: nil,
            productivityInsights: ProductivityInsights(
                userId: userId,
                timeRange: DateInterval(start: Date().addingTimeInterval(-86400 * 30), end: Date()),
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
    
    func exportUnifiedData(for userId: String, format: ExportFormat) async throws -> Data {
        // Default implementation returns empty data
        Data()
    }
}

/// Default habit service implementation
final class DefaultHabitService: HabitServiceProtocol {
    let serviceId = "default_habit_service"
    let version = "1.0.0"
    
    func initialize() async throws {
        print("Habit service initialized")
    }
    
    func cleanup() async {
        print("Habit service cleaned up")
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        .healthy
    }
    
    func createHabit(_ habit: EnhancedHabit) async throws -> EnhancedHabit {
        // Default implementation - placeholder
        print("Creating habit: \(habit.name)")
        return habit
    }
    
    func logHabitCompletion(_ habitId: UUID, value: Double?, mood: MoodRating?, notes: String?) async throws -> EnhancedHabitLog {
        // Default implementation - placeholder
        print("Logging habit completion for: \(habitId)")
        // This would return a proper EnhancedHabitLog instance in production
        fatalError("Default implementation not available for EnhancedHabitLog")
    }
    
    func calculateStreak(for habitId: UUID) async throws -> Int {
        // Default implementation returns 0
        0
    }
    
    func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws -> HabitInsights {
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
    
    func checkAchievements(for habitId: UUID) async throws -> [HabitAchievement] {
        []
    }
    
    func generateRecommendations(for userId: String) async throws -> [HabitRecommendation] {
        []
    }
}

/// Default financial service implementation
final class DefaultFinancialService: FinancialServiceProtocol {
    let serviceId = "default_financial_service"
    let version = "1.0.0"
    
    func initialize() async throws {
        print("Financial service initialized")
    }
    
    func cleanup() async {
        print("Financial service cleaned up")
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        .healthy
    }
    
    func createTransaction(_ transaction: EnhancedFinancialTransaction) async throws -> EnhancedFinancialTransaction {
        print("Creating transaction: \(transaction.amount)")
        return transaction
    }
    
    func calculateAccountBalance(_ accountId: UUID, asOf: Date?) async throws -> Double {
        0
    }
    
    func getBudgetInsights(for budgetId: UUID, timeRange: DateInterval) async throws -> BudgetInsights {
        BudgetInsights(
            budgetId: budgetId,
            timeRange: timeRange,
            utilizationRate: 0,
            categoryBreakdown: [:],
            trendAnalysis: .stable,
            recommendations: [],
            alerts: []
        )
    }
    
    func calculateNetWorth(for userId: String, asOf: Date?) async throws -> NetWorthSummary {
        NetWorthSummary(
            userId: userId,
            asOfDate: asOf ?? Date(),
            totalAssets: 0,
            totalLiabilities: 0,
            monthOverMonthChange: 0,
            yearOverYearChange: 0,
            breakdown: NetWorthBreakdown(
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
    
    func generateFinancialRecommendations(for userId: String) async throws -> [FinancialRecommendation] {
        []
    }
    
    func categorizeTransaction(_ transaction: EnhancedFinancialTransaction) async throws -> TransactionCategory {
        .expense
    }
}

/// Default planner service implementation
final class DefaultPlannerService: PlannerServiceProtocol {
    let serviceId = "default_planner_service"
    let version = "1.0.0"
    
    func initialize() async throws {
        print("Planner service initialized")
    }
    
    func cleanup() async {
        print("Planner service cleaned up")
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        .healthy
    }
    
    func createTask(_ task: EnhancedTask) async throws -> EnhancedTask {
        print("Creating task: \(task.title)")
        return task
    }
    
    func updateTaskProgress(_ taskId: UUID, progress: Double) async throws -> EnhancedTask {
        print("Updating task progress: \(taskId) to \(progress)")
        // This would return a proper EnhancedTask instance in production
        fatalError("Default implementation not available for EnhancedTask")
    }
    
    func calculateGoalProgress(_ goalId: UUID) async throws -> GoalProgress {
        GoalProgress(
            goalId: goalId,
            currentProgress: 0,
            targetValue: 100,
            estimatedCompletion: nil,
            milestones: []
        )
    }
    
    func generateTaskRecommendations(for userId: String, context: PlanningContext) async throws -> [TaskRecommendation] {
        []
    }
    
    func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws -> ScheduleOptimization {
        ScheduleOptimization(
            userId: userId,
            timeRange: timeRange,
            optimizedTasks: [],
            efficiency: 0,
            recommendations: []
        )
    }
    
    func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws -> ProductivityInsights {
        ProductivityInsights(
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
