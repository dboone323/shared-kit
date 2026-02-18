//
//  ServiceProtocols.swift
//  Shared Service Layer
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation

#if canImport(SwiftData)
    @_exported import SwiftData
#endif

// MARK: - Forward Declarations and Imports

// Import enhanced models and protocols from our data layer
// These would typically be imported from separate modules in a production environment

// Re-export core protocols from EnhancedDataModels
public protocol Validatable {
    func validate() throws
    var isValid: Bool { get }
}

public protocol Trackable {
    var trackingId: String { get }
    var analyticsMetadata: [String: Any] { get }
    func trackEvent(_ event: String, parameters: [String: Any]?)
}

public protocol CrossProjectRelatable {
    var globalId: String { get }
    var projectContext: ProjectType { get }
    var externalReferences: [ExternalReference] { get set }
}

// Re-export key enums from enhanced/// Mood rating enum
public enum MoodRating: Int, CaseIterable, Codable, Sendable {
    case none = 0
    case terrible, bad, neutral, good, great
}

public enum HabitFrequency: String, CaseIterable, Codable, Sendable {
    case daily, weekly, monthly
}

public enum HabitCategory: String, CaseIterable, Codable, Sendable {
    case health, fitness, learning, productivity, social, creative, spiritual, financial, other
}

public enum HabitDifficulty: String, CaseIterable, Codable, Sendable {
    case easy, medium, hard, expert

    public var xpMultiplier: Double {
        switch self {
        case .easy: 1.0
        case .medium: 1.5
        case .hard: 2.0
        case .expert: 3.0
        }
    }
}

public enum BudgetCategory: String, CaseIterable, Sendable {
    case housing, food, transportation, healthcare, entertainment, savings, other
}

public enum ServiceTaskPriority: String, CaseIterable, Sendable {
    case low, medium, high, urgent
}

public enum TransactionCategory: String, CaseIterable, Sendable {
    case income, expense, transfer, investment
}

public struct ServiceValidationError: Sendable {
    public let field: String
    public let message: String
    public let code: String

    public init(field: String, message: String, code: String) {
        self.field = field
        self.message = message
        self.code = code
    }
}

// Forward declarations for enhanced model types
// These would be properly imported in production
public protocol EnhancedHabitProtocol: Validatable, Trackable, CrossProjectRelatable, Sendable {
    var id: UUID { get }
    var name: String { get set }
}

public protocol EnhancedHabitLogProtocol: Validatable, Trackable {
    var id: UUID { get }
    var habitId: UUID { get set }
    var timestamp: Date { get set }
    var value: Double? { get set }
    var mood: SharedKitCore.MoodRating? { get set }
    var notes: String? { get set }
}

public protocol HabitAchievementProtocol: Validatable, Trackable, Sendable {
    var id: UUID { get }
    var habitId: UUID { get set }
}

public protocol EnhancedFinancialTransactionProtocol: Validatable, Trackable, CrossProjectRelatable
{
    var id: UUID { get }
    var amount: Double { get set }
    var date: Date { get set }
    var category: TransactionCategory { get set }
}

public protocol EnhancedTaskProtocol: Validatable, Trackable, CrossProjectRelatable, Sendable {
    var id: UUID { get }
    var title: String { get set }
}

// MARK: - Core Service Protocols

/// Base protocol for all service layer components
@MainActor
public protocol ServiceProtocol: Sendable {
    /// Service identifier
    var serviceId: String { get }

    /// Service version for compatibility tracking
    var version: String { get }

    /// Initialize service with dependencies
    func initialize() async throws

    /// Cleanup resources when service is deallocated
    func cleanup() async

    /// Health check for service monitoring
    func healthCheck() async -> ServiceHealthStatus
}

/// Service health status enumeration
public enum ServiceHealthStatus: Sendable {
    case healthy
    case degraded(reason: String)
    case unhealthy(error: any Error & Sendable)

    public var isHealthy: Bool {
        switch self {
        case .healthy: true
        case .degraded, .unhealthy: false
        }
    }
}

// MARK: - Data Service Protocols

/// Protocol for data persistence services
@MainActor
public protocol DataServiceProtocol: ServiceProtocol, Sendable {
    associatedtype ModelType: Validatable & Trackable

    /// Create a new model instance
    func create(_ model: ModelType) async throws -> ModelType

    /// Retrieve model by ID
    func get(by id: UUID) async throws -> ModelType?

    /// Retrieve all models with optional filtering
    func getAll(predicate: NSPredicate?) async throws -> [ModelType]

    /// Update existing model
    func update(_ model: ModelType) async throws -> ModelType

    /// Delete model by ID
    func delete(by id: UUID) async throws

    /// Batch operations
    func batchCreate(_ models: [ModelType]) async throws -> [ModelType]
    func batchUpdate(_ models: [ModelType]) async throws -> [ModelType]
    func batchDelete(ids: [UUID]) async throws

    /// Search functionality
    func search(query: String, fields: [String]) async throws -> [ModelType]

    /// Count operations
    func count(predicate: NSPredicate?) async throws -> Int

    /// Data validation
    func validate(_ model: ModelType) async throws
}

/// Protocol for analytics and tracking services
@MainActor
public protocol AnalyticsServiceProtocol: ServiceProtocol, Sendable {
    /// Track an event with metadata
    func track(event: String, properties: [String: AnyCodable]?, userId: String?) async

    /// Track user behavior
    func trackUserAction(_ action: UserAction) async

    /// Track performance metrics
    func trackPerformance(_ metric: PerformanceMetric) async

    /// Track errors and exceptions
    func trackError(_ error: any Error & Sendable, context: [String: AnyCodable]?) async

    /// Get analytics summary
    func getAnalyticsSummary(timeRange: DateInterval) async throws -> AnalyticsSummary

    /// Export analytics data
    func exportData(format: ExportFormat, timeRange: DateInterval) async throws -> Data
}

/// User action tracking model
public struct UserAction: Sendable {
    public let id: UUID = .init()
    public let timestamp: Date = .init()
    public let action: String
    public let context: String?
    public let userId: String?
    public let metadata: [String: AnyCodable]?

    public init(
        action: String, context: String? = nil, userId: String? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.action = action
        self.context = context
        self.userId = userId
        self.metadata = metadata
    }
}

/// Performance metric tracking model
public struct PerformanceMetric: Sendable {
    public let id: UUID = .init()
    public let timestamp: Date = .init()
    public let name: String
    public let value: Double
    public let unit: String
    public let metadata: [String: AnyCodable]?

    public init(name: String, value: Double, unit: String, metadata: [String: AnyCodable]? = nil) {
        self.name = name
        self.value = value
        self.unit = unit
        self.metadata = metadata
    }
}

/// Analytics summary model
public struct AnalyticsSummary: Sendable {
    public let timeRange: DateInterval
    public let totalEvents: Int
    public let uniqueUsers: Int
    public let topActions: [String: Int]
    public let averageSessionDuration: TimeInterval
    public let errorRate: Double
    public let performanceMetrics: [String: Double]

    public init(
        timeRange: DateInterval,
        totalEvents: Int,
        uniqueUsers: Int,
        topActions: [String: Int],
        averageSessionDuration: TimeInterval,
        errorRate: Double,
        performanceMetrics: [String: Double]
    ) {
        self.timeRange = timeRange
        self.totalEvents = totalEvents
        self.uniqueUsers = uniqueUsers
        self.topActions = topActions
        self.averageSessionDuration = averageSessionDuration
        self.errorRate = errorRate
        self.performanceMetrics = performanceMetrics
    }
}

/// Export format enumeration
public enum ExportFormat: Sendable {
    case json
    case csv
    case xml
    case sqlite

    public var fileExtension: String {
        switch self {
        case .json: "json"
        case .csv: "csv"
        case .xml: "xml"
        case .sqlite: "db"
        }
    }

    public var mimeType: String {
        switch self {
        case .json: "application/json"
        case .csv: "text/csv"
        case .xml: "application/xml"
        case .sqlite: "application/x-sqlite3"
        }
    }
}

// MARK: - Business Logic Service Protocols

/// Protocol for habit-related business logic
@MainActor
public protocol HabitServiceProtocol: ServiceProtocol, Sendable {
    /// Create a new habit with validation
    func createHabit(_ habit: EnhancedHabit) async throws -> EnhancedHabit

    /// Log habit completion
    func logHabitCompletion(_ habitId: UUID, value: Double?, mood: MoodRating?, notes: String?)
        async throws
        -> EnhancedHabitLog

    /// Calculate habit streak
    func calculateStreak(for habitId: UUID) async throws -> Int

    /// Get habit insights
    func getHabitInsights(for habitId: UUID, timeRange: DateInterval) async throws -> HabitInsights

    /// Check for achievements
    func checkAchievements(for habitId: UUID) async throws -> [HabitAchievement]

    /// Generate habit recommendations
    func generateRecommendations(for userId: String) async throws -> [HabitRecommendation]
}

/// Protocol for financial services
@MainActor
public protocol FinancialServiceProtocol: ServiceProtocol, Sendable {
    /// Create financial transaction with validation
    func createTransaction(_ transaction: EnhancedFinancialTransaction) async throws
        -> EnhancedFinancialTransaction

    /// Calculate account balances
    func calculateAccountBalance(_ accountId: UUID, asOf: Date?) async throws -> Double

    /// Generate budget insights
    func getBudgetInsights(for budgetId: UUID, timeRange: DateInterval) async throws
        -> BudgetInsights

    /// Calculate net worth
    func calculateNetWorth(for userId: String, asOf: Date?) async throws -> NetWorthSummary

    /// Generate financial recommendations
    func generateFinancialRecommendations(for userId: String) async throws
        -> [FinancialRecommendation]

    /// Categorize transactions automatically
    func categorizeTransaction(_ transaction: EnhancedFinancialTransaction) async throws
        -> TransactionCategory
}

/// Protocol for task and goal management services
@MainActor
public protocol PlannerServiceProtocol: ServiceProtocol, Sendable {
    /// Create task with intelligent scheduling
    func createTask(_ task: EnhancedTask) async throws -> EnhancedTask

    /// Update task progress
    func updateTaskProgress(_ taskId: UUID, progress: Double) async throws -> EnhancedTask

    /// Calculate goal progress
    func calculateGoalProgress(_ goalId: UUID) async throws -> GoalProgress

    /// Generate task recommendations based on context
    func generateTaskRecommendations(for userId: String, context: PlanningContext) async throws
        -> [TaskRecommendation]

    /// Optimize task scheduling
    func optimizeSchedule(for userId: String, timeRange: DateInterval) async throws
        -> ScheduleOptimization

    /// Generate productivity insights
    func getProductivityInsights(for userId: String, timeRange: DateInterval) async throws
        -> ProductivityInsights
}

// MARK: - Cross-Project Integration Protocols

/// Protocol for cross-project data synchronization
@MainActor
public protocol CrossProjectServiceProtocol: ServiceProtocol, Sendable {
    /// Sync data between projects
    func syncData(from sourceProject: ProjectType, to targetProject: ProjectType) async throws

    /// Get cross-project references
    func getCrossProjectReferences(for entityId: UUID, entityType: String) async throws
        -> [CrossProjectReference]

    /// Create cross-project relationship
    func createCrossProjectRelationship(_ relationship: CrossProjectRelationship) async throws

    /// Get unified user insights across all projects
    func getUnifiedUserInsights(for userId: String) async throws -> UnifiedUserInsights

    /// Export unified data for analysis
    func exportUnifiedData(for userId: String, format: ExportFormat) async throws -> Data
}

/// Cross-project reference model
public struct CrossProjectReference: Sendable {
    public let id: UUID
    public let sourceProject: ProjectType
    public let sourceEntityId: UUID
    public let sourceEntityType: String
    public let targetProject: ProjectType
    public let targetEntityId: UUID
    public let targetEntityType: String
    public let relationship: String
    public let metadata: [String: AnyCodable]?
    public let createdAt: Date

    public init(
        sourceProject: ProjectType,
        sourceEntityId: UUID,
        sourceEntityType: String,
        targetProject: ProjectType,
        targetEntityId: UUID,
        targetEntityType: String,
        relationship: String,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = UUID()
        self.sourceProject = sourceProject
        self.sourceEntityId = sourceEntityId
        self.sourceEntityType = sourceEntityType
        self.targetProject = targetProject
        self.targetEntityId = targetEntityId
        self.targetEntityType = targetEntityType
        self.relationship = relationship
        self.metadata = metadata
        self.createdAt = Date()
    }
}

/// Cross-project relationship model
public struct CrossProjectRelationship: Sendable {
    public let id: UUID
    public let type: RelationshipType
    public let entities: [ProjectEntity]
    public let metadata: [String: AnyCodable]?
    public let createdAt: Date

    public init(
        type: RelationshipType, entities: [ProjectEntity], metadata: [String: AnyCodable]? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.entities = entities
        self.metadata = metadata
        self.createdAt = Date()
    }
}

/// Relationship type enumeration
public enum RelationshipType: String, Sendable {
    case oneToOne = "one_to_one"
    case oneToMany = "one_to_many"
    case manyToMany = "many_to_many"
    case dependency
    case aggregation
    case composition
}

/// Project entity reference
public struct ProjectEntity: Sendable {
    public let project: ProjectType
    public let entityId: UUID
    public let entityType: String
    public let metadata: [String: AnyCodable]?

    public init(
        project: ProjectType, entityId: UUID, entityType: String,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.project = project
        self.entityId = entityId
        self.entityType = entityType
        self.metadata = metadata
    }
}

// MARK: - Supporting Models

/// Habit insights model
public struct HabitInsights: Sendable {
    public let habitId: UUID
    public let timeRange: DateInterval
    public let completionRate: Double
    public let currentStreak: Int
    public let longestStreak: Int
    public let averageValue: Double?
    public let moodCorrelation: Double?
    public let recommendations: [String]

    public init(
        habitId: UUID, timeRange: DateInterval, completionRate: Double, currentStreak: Int,
        longestStreak: Int, averageValue: Double? = nil, moodCorrelation: Double? = nil,
        recommendations: [String] = []
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

/// Habit recommendation model
public struct HabitRecommendation: Sendable {
    public let id: UUID = .init()
    public let title: String
    public let description: String
    public let category: HabitCategory
    public let difficulty: HabitDifficulty
    public let estimatedTime: Int
    public let confidence: Double
    public let reasoning: String

    public init(
        title: String,
        description: String,
        category: HabitCategory,
        difficulty: HabitDifficulty,
        estimatedTime: Int,
        confidence: Double,
        reasoning: String
    ) {
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.confidence = confidence
        self.reasoning = reasoning
    }
}

/// Budget insights model
public struct BudgetInsights: Sendable {
    public let budgetId: UUID
    public let timeRange: DateInterval
    public let utilizationRate: Double
    public let categoryBreakdown: [String: Double]
    public let trendAnalysis: TrendDirection
    public let recommendations: [String]
    public let alerts: [String]

    public init(
        budgetId: UUID,
        timeRange: DateInterval,
        utilizationRate: Double,
        categoryBreakdown: [String: Double],
        trendAnalysis: TrendDirection,
        recommendations: [String],
        alerts: [String]
    ) {
        self.budgetId = budgetId
        self.timeRange = timeRange
        self.utilizationRate = utilizationRate
        self.categoryBreakdown = categoryBreakdown
        self.trendAnalysis = trendAnalysis
        self.recommendations = recommendations
        self.alerts = alerts
    }
}

/// Net worth summary model
public struct NetWorthSummary: Sendable {
    public let userId: String
    public let asOfDate: Date
    public let totalAssets: Double
    public let totalLiabilities: Double
    public let monthOverMonthChange: Double
    public let yearOverYearChange: Double
    public let breakdown: NetWorthBreakdown

    public var netWorth: Double {
        return totalAssets - totalLiabilities
    }

    public init(
        userId: String,
        asOfDate: Date,
        totalAssets: Double,
        totalLiabilities: Double,
        monthOverMonthChange: Double,
        yearOverYearChange: Double,
        breakdown: NetWorthBreakdown
    ) {
        self.userId = userId
        self.asOfDate = asOfDate
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.monthOverMonthChange = monthOverMonthChange
        self.yearOverYearChange = yearOverYearChange
        self.breakdown = breakdown
    }
}

/// Net worth breakdown model
public struct NetWorthBreakdown: Sendable {
    public let cashAndEquivalents: Double
    public let investments: Double
    public let realEstate: Double
    public let personalProperty: Double
    public let creditCardDebt: Double
    public let loans: Double
    public let mortgages: Double

    public init(
        cashAndEquivalents: Double,
        investments: Double,
        realEstate: Double,
        personalProperty: Double,
        creditCardDebt: Double,
        loans: Double,
        mortgages: Double
    ) {
        self.cashAndEquivalents = cashAndEquivalents
        self.investments = investments
        self.realEstate = realEstate
        self.personalProperty = personalProperty
        self.creditCardDebt = creditCardDebt
        self.loans = loans
        self.mortgages = mortgages
    }
}

/// Financial recommendation model
public struct FinancialRecommendation: Sendable {
    public let id: UUID = .init()
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let priority: RecommendationPriority
    public let estimatedImpact: Double
    public let confidence: Double
    public let actionItems: [String]
    public let timeframe: String

    public init(
        type: RecommendationType,
        title: String,
        description: String,
        priority: RecommendationPriority,
        estimatedImpact: Double,
        confidence: Double,
        actionItems: [String],
        timeframe: String
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.priority = priority
        self.estimatedImpact = estimatedImpact
        self.confidence = confidence
        self.actionItems = actionItems
        self.timeframe = timeframe
    }
}

/// Recommendation type enumeration
public enum RecommendationType: Sendable {
    case budgetOptimization
    case debtReduction
    case investmentStrategy
    case savingsGoal
    case expenseReduction
    case incomeIncrease
}

/// Recommendation priority enumeration
public enum RecommendationPriority: Int, CaseIterable, Sendable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4

    public var description: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .urgent: "Urgent"
        }
    }
}

/// Trend direction enumeration
public enum TrendDirection: String, Codable, Sendable {
    case increasing
    case decreasing
    case stable
    case volatile
    case unknown

    public var description: String {
        switch self {
        case .increasing: "Increasing"
        case .decreasing: "Decreasing"
        case .stable: "Stable"
        case .volatile: "Volatile"
        case .unknown: "Unknown"
        }
    }
}

/// Budget alert model
public struct BudgetAlert: Sendable {
    public let id: UUID = .init()
    public let type: AlertType
    public let severity: AlertSeverity
    public let message: String
    public let threshold: Double
    public let currentValue: Double
    public let createdAt: Date = .init()

    public init(
        type: AlertType, severity: AlertSeverity, message: String, threshold: Double,
        currentValue: Double
    ) {
        self.type = type
        self.severity = severity
        self.message = message
        self.threshold = threshold
        self.currentValue = currentValue
    }
}

/// Alert type enumeration
public enum AlertType: Sendable {
    case budgetExceeded
    case budgetWarning
    case unusualSpending
    case goalDeadlineApproaching
    case incomeDecrease
    case debtIncrease
}

/// Alert severity enumeration
public enum AlertSeverity: Int, CaseIterable, Sendable {
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    public var description: String {
        switch self {
        case .info: "Info"
        case .warning: "Warning"
        case .error: "Error"
        case .critical: "Critical"
        }
    }
}

/// Goal progress model
public struct GoalProgress: Sendable {
    public let goalId: UUID
    public let currentProgress: Double
    public let targetValue: Double
    public let estimatedCompletion: Date?
    public let milestones: [String]

    public init(
        goalId: UUID, currentProgress: Double, targetValue: Double,
        estimatedCompletion: Date? = nil, milestones: [String] = []
    ) {
        self.goalId = goalId
        self.currentProgress = currentProgress
        self.targetValue = targetValue
        self.estimatedCompletion = estimatedCompletion
        self.milestones = milestones
    }
}

/// Goal milestone model
public struct GoalMilestone: Sendable {
    public let id: UUID = .init()
    public let title: String
    public let targetValue: Double
    public let achieved: Bool
    public let achievedAt: Date?
    public let description: String?

    public init(
        title: String,
        targetValue: Double,
        achieved: Bool,
        achievedAt: Date? = nil,
        description: String? = nil
    ) {
        self.title = title
        self.targetValue = targetValue
        self.achieved = achieved
        self.achievedAt = achievedAt
        self.description = description
    }
}

/// Task recommendation model
public struct TaskRecommendation: Sendable {
    public let taskId: UUID?
    public let type: String
    public let message: String
    public let priority: RecommendationPriority
    public let suggestedTime: Date?

    public init(
        taskId: UUID? = nil, type: String, message: String, priority: RecommendationPriority,
        suggestedTime: Date? = nil
    ) {
        self.taskId = taskId
        self.type = type
        self.message = message
        self.priority = priority
        self.suggestedTime = suggestedTime
    }
}

/// Planning context model
public struct PlanningContext: Sendable {
    public let userId: String
    public let currentTime: Date
    public let availableTime: Int
    public let energyLevel: EnergyLevel
    public let location: String?
    public let mood: MoodRating?
    public let priorities: [String]

    public init(
        userId: String,
        currentTime: Date = Date(),
        availableTime: Int,
        energyLevel: EnergyLevel,
        location: String? = nil,
        mood: MoodRating? = nil,
        priorities: [String] = []
    ) {
        self.userId = userId
        self.currentTime = currentTime
        self.availableTime = availableTime
        self.energyLevel = energyLevel
        self.location = location
        self.mood = mood
        self.priorities = priorities
    }
}

/// Schedule optimization model
public struct ScheduleOptimization: Sendable {
    public let userId: String
    public let timeRange: DateInterval
    public let optimizedTasks: [String]
    public let efficiency: Double
    public let recommendations: [String]

    public init(
        userId: String, timeRange: DateInterval, optimizedTasks: [String] = [],
        efficiency: Double = 0.0, recommendations: [String] = []
    ) {
        self.userId = userId
        self.timeRange = timeRange
        self.optimizedTasks = optimizedTasks
        self.efficiency = efficiency
        self.recommendations = recommendations
    }
}

/// Optimized task schedule model
public struct OptimizedTaskSchedule: Sendable {
    public let taskId: UUID
    public let title: String
    public let scheduledStart: Date
    public let scheduledEnd: Date
    public let optimalTimeSlot: Bool
    public let reasoning: String

    public init(
        taskId: UUID,
        title: String,
        scheduledStart: Date,
        scheduledEnd: Date,
        optimalTimeSlot: Bool,
        reasoning: String
    ) {
        self.taskId = taskId
        self.title = title
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.optimalTimeSlot = optimalTimeSlot
        self.reasoning = reasoning
    }
}

/// Productivity insights model
public struct ProductivityInsights: Sendable {
    public let userId: String
    public let timeRange: DateInterval
    public let completionRate: Double
    public let averageTaskDuration: TimeInterval
    public let peakProductivityHours: [Int]
    public let productivityTrend: TrendDirection
    public let topCategories: [String: Double]
    public let recommendations: [String]

    public init(
        userId: String, timeRange: DateInterval, completionRate: Double,
        averageTaskDuration: TimeInterval, peakProductivityHours: [Int],
        productivityTrend: TrendDirection, topCategories: [String: Double],
        recommendations: [String] = []
    ) {
        self.userId = userId
        self.timeRange = timeRange
        self.completionRate = completionRate
        self.averageTaskDuration = averageTaskDuration
        self.peakProductivityHours = peakProductivityHours
        self.productivityTrend = productivityTrend
        self.topCategories = topCategories
        self.recommendations = recommendations
    }
}

/// Unified user insights model
public struct UnifiedUserInsights: Sendable {
    public let userId: String
    public let timeRange: DateInterval
    public let habitInsights: [HabitInsights]
    public let financialInsights: BudgetInsights?
    public let productivityInsights: ProductivityInsights
    public let crossProjectCorrelations: [CrossProjectCorrelation]
    public let overallScore: Double
    public let recommendations: [UnifiedRecommendation]

    public init(
        userId: String,
        timeRange: DateInterval,
        habitInsights: [HabitInsights],
        financialInsights: BudgetInsights?,
        productivityInsights: ProductivityInsights,
        crossProjectCorrelations: [CrossProjectCorrelation],
        overallScore: Double,
        recommendations: [UnifiedRecommendation]
    ) {
        self.userId = userId
        self.timeRange = timeRange
        self.habitInsights = habitInsights
        self.financialInsights = financialInsights
        self.productivityInsights = productivityInsights
        self.crossProjectCorrelations = crossProjectCorrelations
        self.overallScore = overallScore
        self.recommendations = recommendations
    }
}

/// Cross-project correlation model
public struct CrossProjectCorrelation: Sendable {
    public let project1: ProjectType
    public let project2: ProjectType
    public let correlation: Double
    public let significance: Double
    public let description: String

    public init(
        project1: ProjectType,
        project2: ProjectType,
        correlation: Double,
        significance: Double,
        description: String
    ) {
        self.project1 = project1
        self.project2 = project2
        self.correlation = correlation
        self.significance = significance
        self.description = description
    }
}

/// Unified recommendation model
public struct UnifiedRecommendation: Sendable {
    public let id: UUID = .init()
    public let type: UnifiedRecommendationType
    public let title: String
    public let description: String
    public let affectedProjects: [ProjectType]
    public let priority: RecommendationPriority
    public let estimatedImpact: Double
    public let actionItems: [String]

    public init(
        type: UnifiedRecommendationType,
        title: String,
        description: String,
        affectedProjects: [ProjectType],
        priority: RecommendationPriority,
        estimatedImpact: Double,
        actionItems: [String]
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.affectedProjects = affectedProjects
        self.priority = priority
        self.estimatedImpact = estimatedImpact
        self.actionItems = actionItems
    }
}

/// Unified recommendation type enumeration
public enum UnifiedRecommendationType: String, Sendable {
    case habitFinanceIntegration
    case productivityHabitAlignment
    case financialGoalTask
    case wellnessProductivity
    case timeEnergyOptimization
    case crossProjectSynergy
}
