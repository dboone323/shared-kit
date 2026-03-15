//
//  CrossProjectIntegration.swift
//  Unified Cross-Project Integration System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation
import SharedKitCore

#if canImport(SwiftData) && canImport(Combine)
    import Combine
    #if canImport(SwiftUI)
        import SwiftUI
    #endif

    // MARK: - Cross-Project Integration Core

    /// Main coordinator for cross-project integration and data sharing
    @MainActor
    public final class CrossProjectIntegrator: ObservableObject {
        public static let shared = CrossProjectIntegrator()

        // MARK: - Published Properties

        @Published public private(set) var isIntegrationActive = false
        @Published public private(set) var connectedProjects: Set<ProjectType> = []
        @Published public private(set) var unifiedInsights: UnifiedUserInsights?
        @Published public private(set) var crossProjectCorrelations: [CrossProjectCorrelation] = []
        @Published public private(set) var integrationHealth: IntegrationHealthStatus = .disconnected

        // MARK: - Private Properties

        let globalCoordinator = GlobalStateCoordinator.shared
        private var cancellables = Set<AnyCancellable>()
        private var integrationTimer: Timer?
        private let syncQueue = DispatchQueue(label: "CrossProjectSync", qos: .utility)

        // MARK: - Service Dependencies

        @Injected private var analyticsService: AnalyticsServiceProtocol
        @Injected private var crossProjectService: CrossProjectServiceProtocol

        // MARK: - Initialization

        private init() {
            self.setupIntegrationObservation()
        }

        // MARK: - Public Interface

        /// Initialize cross-project integration
        public func initializeIntegration() async throws {
            guard !self.isIntegrationActive else { return }

            do {
                // Initialize global state coordinator first
                try await self.globalCoordinator.initialize()

                // Discover and connect to available projects
                await self.discoverProjects()

                // Start integration workflows
                await self.startIntegrationWorkflows()

                self.isIntegrationActive = true
                self.integrationHealth =
                    self.connectedProjects.isEmpty ? .warning("No projects connected") : .healthy

                await self.analyticsService.track(
                    event: "cross_project_integration_initialized",
                    properties: ["connected_projects": AnyCodable(self.connectedProjects.count)],
                    userId: nil
                )
            } catch {
                self.integrationHealth = .error(error)
                throw error
            }
        }

        /// Connect specific project to the integration system
        public func connectProject(_ project: ProjectType) async throws {
            self.connectedProjects.insert(project)

            // Sync data from the newly connected project
            try await self.syncProjectData(project)

            await self.analyticsService.track(
                event: "project_connected",
                properties: ["project": AnyCodable(project.rawValue)],
                userId: nil
            )
        }

        /// Disconnect project from integration system
        public func disconnectProject(_ project: ProjectType) async {
            self.connectedProjects.remove(project)

            await self.analyticsService.track(
                event: "project_disconnected",
                properties: ["project": AnyCodable(project.rawValue)],
                userId: nil
            )
        }

        /// Generate unified insights across all connected projects
        public func generateUnifiedInsights(for userId: String) async throws {
            guard self.isIntegrationActive else {
                throw CrossProjectError.integrationNotActive
            }

            // Removed do
            // Gather insights from all connected projects
            var habitInsights: [HabitInsights] = []
            var financialInsights: BudgetInsights?
            var productivityInsights: ProductivityInsights?

            if self.connectedProjects.contains(.habitQuest) {
                habitInsights = await self.gatherHabitInsights(for: userId)
            }

            if self.connectedProjects.contains(.momentumFinance) {
                financialInsights = await self.gatherFinancialInsights(for: userId)
            }

            if self.connectedProjects.contains(.plannerApp) {
                productivityInsights = await self.gatherProductivityInsights(for: userId)
            }

            // Calculate cross-project correlations
            let correlations = await calculateCrossProjectCorrelations(userId: userId)
            self.crossProjectCorrelations = correlations

            // Generate unified recommendations
            let recommendations = await generateUnifiedRecommendations(
                habitInsights: habitInsights,
                financialInsights: financialInsights,
                productivityInsights: productivityInsights,
                correlations: correlations
            )

            // Calculate overall score
            let overallScore = self.calculateOverallScore(
                habitInsights: habitInsights,
                financialInsights: financialInsights,
                productivityInsights: productivityInsights
            )

            // Create unified insights
            let timeRange = DateInterval(start: Date().addingTimeInterval(-2_592_000), end: Date()) // Last 30 days

            self.unifiedInsights = UnifiedUserInsights(
                userId: userId,
                timeRange: timeRange,
                habitInsights: habitInsights,
                financialInsights: financialInsights,
                productivityInsights: productivityInsights
                    ?? ProductivityInsights(
                        userId: userId,
                        timeRange: timeRange,
                        completionRate: 0,
                        averageTaskDuration: 0,
                        peakProductivityHours: [],
                        productivityTrend: .unknown,
                        topCategories: [:],
                        recommendations: []
                    ),
                crossProjectCorrelations: correlations,
                overallScore: overallScore,
                recommendations: recommendations
            )

            await self.analyticsService.track(
                event: "unified_insights_generated",
                properties: [
                    "user_id": AnyCodable(userId),
                    "overall_score": AnyCodable(overallScore),
                    "correlation_count": AnyCodable(correlations.count),
                    "recommendation_count": AnyCodable(recommendations.count),
                ],
                userId: userId
            )
            // Error handling was removed because methods inside do not throw.
        }

        /// Export unified data across all projects
        public func exportUnifiedData(for userId: String, format: ExportFormat) async throws -> Data {
            if unifiedInsights == nil {
                try await self.generateUnifiedInsights(for: userId)
            }

            guard let insights = unifiedInsights else {
                throw CrossProjectError.exportFailure("Failed to generate insights")
            }

            let exportData = await UnifiedExportData(
                userId: userId,
                exportDate: Date(),
                insights: insights,
                rawData: gatherRawData(for: userId)
            )

            let data = try await serializeExportData(exportData, format: format)

            await analyticsService.track(
                event: "unified_data_exported",
                properties: [
                    "user_id": AnyCodable(userId),
                    "format": AnyCodable(format.fileExtension),
                    "data_size": AnyCodable(data.count),
                ],
                userId: userId
            )

            return data
        }

        /// Sync data between specific projects
        public func syncBetweenProjects(from sourceProject: ProjectType, to targetProject: ProjectType)
            async throws
        {
            guard self.connectedProjects.contains(sourceProject),
                  self.connectedProjects.contains(targetProject)
            else {
                throw CrossProjectError.projectNotConnected
            }

            try await self.crossProjectService.syncData(from: sourceProject, to: targetProject)

            await self.analyticsService.track(
                event: "cross_project_sync",
                properties: [
                    "source_project": AnyCodable(sourceProject.rawValue),
                    "target_project": AnyCodable(targetProject.rawValue),
                ],
                userId: nil
            )
        }

        // MARK: - Private Methods

        private func setupIntegrationObservation() {
            // Observe global state changes
            self.globalCoordinator.$isInitialized
                .sink { [weak self] isInitialized in
                    if !isInitialized {
                        self?.isIntegrationActive = false
                        self?.integrationHealth = .disconnected
                    }
                }
                .store(in: &self.cancellables)

            self.globalCoordinator.$globalError
                .sink { [weak self] error in
                    if let error {
                        self?.integrationHealth = .error(error)
                    }
                }
                .store(in: &self.cancellables)
        }

        private func discoverProjects() async {
            // In a real implementation, this would discover available projects
            // For now, we'll simulate project discovery

            let availableProjects: [ProjectType] = [
                .habitQuest,
                .momentumFinance,
                .plannerApp,
                .codingReviewer,
                .avoidObstacles,
            ]

            for project in availableProjects {
                let isAvailable = await self.isProjectAvailable(project)
                if isAvailable {
                    self.connectedProjects.insert(project)
                }
            }
        }

        private func isProjectAvailable(_: ProjectType) async -> Bool {
            // Simulate project availability check
            // In production, this would check if the project is installed and accessible
            true
        }

        private func startIntegrationWorkflows() async {
            // Start periodic sync timer
            let timerBlock: @Sendable (Timer) -> Void = { [weak self] _ in
                Task { [weak self] in
                    await self?.performPeriodicSync()
                }
            }
            self.integrationTimer = Timer.scheduledTimer(
                withTimeInterval: 600, repeats: true, block: timerBlock
            )

            // Start real-time integration workflows
            await self.startRealTimeIntegration()
        }

        private func performPeriodicSync() async {
            guard self.isIntegrationActive else { return }

            for project in self.connectedProjects {
                do {
                    try await self.syncProjectData(project)
                } catch {
                    await self.analyticsService.track(
                        event: "periodic_sync_error",
                        properties: [
                            "project": AnyCodable(project.rawValue),
                            "error": AnyCodable(error.localizedDescription),
                        ],
                        userId: nil
                    )
                }
            }
        }

        private func startRealTimeIntegration() async {
            // Set up real-time state change propagation
            self.globalCoordinator.habitState.$habits
                .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    Task { [weak self] in
                        await self?.propagateHabitChanges()
                    }
                }
                .store(in: &self.cancellables)

            self.globalCoordinator.financialState.$transactions
                .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    Task { [weak self] in
                        await self?.propagateFinancialChanges()
                    }
                }
                .store(in: &self.cancellables)

            self.globalCoordinator.plannerState.$tasks
                .debounce(for: .milliseconds(1000), scheduler: RunLoop.main)
                .sink { [weak self] _ in
                    Task { [weak self] in
                        await self?.propagateTaskChanges()
                    }
                }
                .store(in: &self.cancellables)
        }

        private func syncProjectData(_ project: ProjectType) async throws {
            switch project {
            case .habitQuest:
                // Sync habit data with other projects
                await self.syncHabitData()
            case .momentumFinance:
                // Sync financial data
                await self.syncFinancialData()
            case .plannerApp:
                // Sync task and goal data
                await self.syncPlannerData()
            case .codingReviewer:
                // Sync coding review data
                await self.syncCodingData()
            case .avoidObstacles:
                // Sync game data
                await self.syncGameData()
            case .sharedKit, .toolsAutomation:
                // operational projects, no user data to sync
                break
            }
        }

        private func syncHabitData() async {
            // Correlate habits with financial goals
            if self.connectedProjects.contains(.momentumFinance) {
                await self.correlateHabitsWithFinancialGoals()
            }

            // Correlate habits with productivity tasks
            if self.connectedProjects.contains(.plannerApp) {
                await self.correlateHabitsWithTasks()
            }
        }

        private func syncFinancialData() async {
            // Create financial habit suggestions
            if self.connectedProjects.contains(.habitQuest) {
                await self.suggestFinancialHabits()
            }

            // Create budget-based task suggestions
            if self.connectedProjects.contains(.plannerApp) {
                await self.suggestBudgetTasks()
            }
        }

        private func syncPlannerData() async {
            // Create productivity habits
            if self.connectedProjects.contains(.habitQuest) {
                await self.suggestProductivityHabits()
            }

            // Create financial planning tasks
            if self.connectedProjects.contains(.momentumFinance) {
                await self.suggestFinancialTasks()
            }
        }

        private func syncCodingData() async {
            // Create coding practice habits
            if self.connectedProjects.contains(.habitQuest) {
                await self.suggestCodingHabits()
            }

            // Create coding tasks
            if self.connectedProjects.contains(.plannerApp) {
                await self.suggestCodingTasks()
            }
        }

        private func syncGameData() async {
            // Gamify other project activities
            await self.gamifyHabits()
            await self.gamifyFinancialGoals()
            await self.gamifyTasks()
        }

        // MARK: - Cross-Project Correlation Methods

        private func correlateHabitsWithFinancialGoals() async {
            let habitState = self.globalCoordinator.habitState
            let financialState = self.globalCoordinator.financialState

            // Find habits that correlate with financial performance
            for (habitId, habit) in habitState.habits {
                if let insights = habitState.insights[habitId] {
                    // Check if habit completion correlates with financial improvement
                    await self.analyzeHabitFinancialCorrelation(
                        habit, insights: insights, financialState: financialState
                    )
                }
            }
        }

        private func correlateHabitsWithTasks() async {
            let habitState = self.globalCoordinator.habitState
            let plannerState = self.globalCoordinator.plannerState

            // Find habits that affect task completion
            for (habitId, habit) in habitState.habits {
                if let insights = habitState.insights[habitId] {
                    await self.analyzeHabitProductivityCorrelation(
                        habit, insights: insights, plannerState: plannerState
                    )
                }
            }
        }

        private func suggestFinancialHabits() async {
            let financialState = self.globalCoordinator.financialState
            let habitState = self.globalCoordinator.habitState

            // Analyze financial patterns and suggest habits
            if let netWorth = financialState.netWorth {
                await self.createHabitsFromFinancialPatterns(netWorth: netWorth, habitState: habitState)
            }
        }

        private func suggestBudgetTasks() async {
            let financialState = self.globalCoordinator.financialState
            let plannerState = self.globalCoordinator.plannerState

            // Create tasks based on budget insights
            for (budgetId, insights) in financialState.budgets {
                await self.createTasksFromBudgetInsights(
                    budgetId: budgetId, insights: insights, plannerState: plannerState
                )
            }
        }

        private func suggestProductivityHabits() async {
            let plannerState = self.globalCoordinator.plannerState
            let habitState = self.globalCoordinator.habitState

            // Analyze productivity patterns and suggest habits
            if let insights = plannerState.productivityInsights {
                await self.createHabitsFromProductivityInsights(
                    insights: insights, habitState: habitState
                )
            }
        }

        private func suggestFinancialTasks() async {
            let plannerState = self.globalCoordinator.plannerState
            let financialState = self.globalCoordinator.financialState

            // Create financial planning tasks
            for recommendation in financialState.recommendations {
                await self.createTaskFromFinancialRecommendation(
                    recommendation, plannerState: plannerState
                )
            }
        }

        private func suggestCodingHabits() async {
            // Create coding practice habits based on review patterns
            await self.analyticsService.track(
                event: "coding_habits_suggested", properties: nil, userId: nil
            )
        }

        private func suggestCodingTasks() async {
            // Create tasks for code improvements
            await self.analyticsService.track(
                event: "coding_tasks_suggested", properties: nil, userId: nil
            )
        }

        private func gamifyHabits() async {
            // Add game elements to habit tracking
            await self.analyticsService.track(event: "habits_gamified", properties: nil, userId: nil)
        }

        private func gamifyFinancialGoals() async {
            // Add game elements to financial goals
            await self.analyticsService.track(
                event: "financial_goals_gamified", properties: nil, userId: nil
            )
        }

        private func gamifyTasks() async {
            // Add game elements to task completion
            await self.analyticsService.track(event: "tasks_gamified", properties: nil, userId: nil)
        }

        // MARK: - State Change Propagation

        private func propagateHabitChanges() async {
            // Propagate habit changes to other projects
            if self.connectedProjects.contains(.momentumFinance) {
                await self.updateFinancialBasedOnHabits()
            }

            if self.connectedProjects.contains(.plannerApp) {
                await self.updateTasksBasedOnHabits()
            }

            if self.connectedProjects.contains(.avoidObstacles) {
                await self.updateGameProgressBasedOnHabits()
            }
        }

        private func propagateFinancialChanges() async {
            // Propagate financial changes to other projects
            if self.connectedProjects.contains(.habitQuest) {
                await self.updateHabitsBasedOnFinancial()
            }

            if self.connectedProjects.contains(.plannerApp) {
                await self.updateTasksBasedOnFinancial()
            }
        }

        private func propagateTaskChanges() async {
            // Propagate task changes to other projects
            if self.connectedProjects.contains(.habitQuest) {
                await self.updateHabitsBasedOnTasks()
            }

            if self.connectedProjects.contains(.momentumFinance) {
                await self.updateFinancialBasedOnTasks()
            }
        }

        // MARK: - Data Gathering Methods

        private func gatherHabitInsights(for _: String) async -> [HabitInsights] {
            let habitState = self.globalCoordinator.habitState
            return Array(habitState.insights.values)
        }

        private func gatherFinancialInsights(for _: String) async -> BudgetInsights? {
            let financialState = self.globalCoordinator.financialState
            return financialState.budgets.values.first // Simplified - would aggregate all budgets
        }

        private func gatherProductivityInsights(for _: String) async -> ProductivityInsights? {
            let plannerState = self.globalCoordinator.plannerState
            return plannerState.productivityInsights
        }

        private func calculateCrossProjectCorrelations(userId: String) async
            -> [CrossProjectCorrelation]
        {
            var correlations: [CrossProjectCorrelation] = []

            // Habit-Finance correlation
            if self.connectedProjects.contains(.habitQuest),
               self.connectedProjects.contains(.momentumFinance)
            {
                let correlation = await calculateHabitFinanceCorrelation(userId: userId)
                if abs(correlation) > 0.3 { // Significant correlation threshold
                    correlations.append(
                        CrossProjectCorrelation(
                            project1: .habitQuest,
                            project2: .momentumFinance,
                            correlation: correlation,
                            significance: abs(correlation),
                            description: correlation > 0
                                ? "Good habits correlate with better financial outcomes"
                                : "Poor habits correlate with financial struggles"
                        )
                    )
                }
            }

            // Habit-Productivity correlation
            if self.connectedProjects.contains(.habitQuest),
               self.connectedProjects.contains(.plannerApp)
            {
                let correlation = await calculateHabitProductivityCorrelation(userId: userId)
                if abs(correlation) > 0.3 {
                    correlations.append(
                        CrossProjectCorrelation(
                            project1: .habitQuest,
                            project2: .plannerApp,
                            correlation: correlation,
                            significance: abs(correlation),
                            description: correlation > 0
                                ? "Good habits improve productivity"
                                : "Poor habits reduce productivity"
                        )
                    )
                }
            }

            // Finance-Productivity correlation
            if self.connectedProjects.contains(.momentumFinance),
               self.connectedProjects.contains(.plannerApp)
            {
                let correlation = await calculateFinanceProductivityCorrelation(userId: userId)
                if abs(correlation) > 0.3 {
                    correlations.append(
                        CrossProjectCorrelation(
                            project1: .momentumFinance,
                            project2: .plannerApp,
                            correlation: correlation,
                            significance: abs(correlation),
                            description: correlation > 0
                                ? "Financial stability improves productivity"
                                : "Financial stress reduces productivity"
                        )
                    )
                }
            }

            return correlations
        }

        private func generateUnifiedRecommendations(
            habitInsights: [HabitInsights],
            financialInsights: BudgetInsights?,
            productivityInsights: ProductivityInsights?,
            correlations: [CrossProjectCorrelation]
        ) async -> [UnifiedRecommendation] {
            var recommendations: [UnifiedRecommendation] = []

            // Cross-project synergy recommendations
            for correlation in correlations where correlation.correlation > 0.5 {
                await recommendations.append(
                    UnifiedRecommendation(
                        type: .crossProjectSynergy,
                        title:
                        "Leverage \(correlation.project1.displayName) for \(correlation.project2.displayName)",
                        description: correlation.description,
                        affectedProjects: [correlation.project1, correlation.project2],
                        priority: .high,
                        estimatedImpact: correlation.significance * 100,
                        actionItems: generateSynergyActionItems(for: correlation)
                    )
                )
            }

            // Habit-finance integration recommendations
            if !habitInsights.isEmpty, financialInsights != nil {
                recommendations.append(
                    UnifiedRecommendation(
                        type: .habitFinanceIntegration,
                        title: "Align Habits with Financial Goals",
                        description:
                        "Create financial habits that support your budget and savings goals",
                        affectedProjects: [.habitQuest, .momentumFinance],
                        priority: .medium,
                        estimatedImpact: 75.0,
                        actionItems: [
                            "Track spending habits",
                            "Create saving challenges",
                            "Monitor financial habit correlation",
                        ]
                    )
                )
            }

            // Productivity-habit alignment recommendations
            if !habitInsights.isEmpty, productivityInsights != nil {
                recommendations.append(
                    UnifiedRecommendation(
                        type: .productivityHabitAlignment,
                        title: "Optimize Daily Routines for Productivity",
                        description: "Align your habits with peak productivity hours and energy levels",
                        affectedProjects: [.habitQuest, .plannerApp],
                        priority: .medium,
                        estimatedImpact: 65.0,
                        actionItems: [
                            "Schedule habits during peak hours",
                            "Create productivity-supporting habits",
                            "Track energy-habit correlation",
                        ]
                    )
                )
            }

            // Wellness-productivity recommendations
            if let productivityRate = productivityInsights?.completionRate, productivityRate < 0.7 {
                recommendations.append(
                    UnifiedRecommendation(
                        type: .wellnessProductivity,
                        title: "Improve Productivity Through Wellness",
                        description: "Focus on wellness habits to boost overall productivity",
                        affectedProjects: [.habitQuest, .plannerApp],
                        priority: .high,
                        estimatedImpact: 80.0,
                        actionItems: [
                            "Add exercise habits", "Improve sleep tracking", "Schedule regular breaks",
                        ]
                    )
                )
            }

            return recommendations
        }

        private func calculateOverallScore(
            habitInsights: [HabitInsights],
            financialInsights: BudgetInsights?,
            productivityInsights: ProductivityInsights?
        ) -> Double {
            var totalScore: Double = 0
            var componentCount = 0

            // Habit score (0-100)
            if !habitInsights.isEmpty {
                let avgCompletionRate =
                    habitInsights.map(\.completionRate).reduce(0, +) / Double(habitInsights.count)
                totalScore += avgCompletionRate * 100
                componentCount += 1
            }

            // Financial score (0-100)
            if let financialInsights {
                let budgetScore = min(100, max(0, 100 - (financialInsights.utilizationRate * 100)))
                totalScore += budgetScore
                componentCount += 1
            }

            // Productivity score (0-100)
            if let productivityInsights {
                totalScore += productivityInsights.completionRate * 100
                componentCount += 1
            }

            return componentCount > 0 ? totalScore / Double(componentCount) : 0
        }

        private func gatherRawData(for userId: String) async -> [String: AnyCodable] {
            var rawData: [String: AnyCodable] = [:]

            if self.connectedProjects.contains(.habitQuest) {
                rawData["habits"] = await AnyCodable(self.exportHabitData(for: userId))
            }

            if self.connectedProjects.contains(.momentumFinance) {
                rawData["financial"] = await AnyCodable(self.exportFinancialData(for: userId))
            }

            if self.connectedProjects.contains(.plannerApp) {
                rawData["tasks"] = await AnyCodable(self.exportPlannerData(for: userId))
            }

            return rawData
        }

        private func serializeExportData(_ exportData: UnifiedExportData, format: ExportFormat)
            async throws -> Data
        {
            switch format {
            case .json:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                return try encoder.encode(exportData)

            case .csv:
                // Convert to CSV format
                return try await self.convertToCSV(exportData)

            case .xml:
                // Convert to XML format
                return try await self.convertToXML(exportData)

            case .sqlite:
                // Convert to SQLite format
                return try await self.convertToSQLite(exportData)
            }
        }

        // MARK: - Integration Implementation

        private func analyzeHabitFinancialCorrelation(
            _ habit: any EnhancedHabitProtocol,
            insights: HabitInsights,
            financialState: FinancialStateManager
        ) async {
            let budgetUtilization = financialState.budgets.values.first?.utilizationRate ?? 0.0
            if insights.completionRate > 0.8 && budgetUtilization < 0.8 {
                await self.analyticsService.track(
                    event: "positive_habit_financial_correlation",
                    properties: ["habit": .string(habit.name)],
                    userId: nil
                )
            }
        }

        private func analyzeHabitProductivityCorrelation(
            _ habit: any EnhancedHabitProtocol,
            insights: HabitInsights,
            plannerState: PlannerStateManager
        ) async {
            let completionRate = plannerState.productivityInsights?.completionRate ?? 0.0
            if insights.completionRate > 0.8 && completionRate > 0.8 {
                await self.analyticsService.track(
                    event: "positive_habit_productivity_correlation",
                    properties: ["habit": .string(habit.name)],
                    userId: nil
                )
            }
        }

        private func createHabitsFromFinancialPatterns(
            netWorth: NetWorthSummary, habitState: HabitStateManager
        ) async {
            if netWorth.totalAssets < 1000 {
                // Suggest saving habit
                print("Suggestion: Create a Daily Saving Habit due to low assets.")
            }
        }

        private func createTasksFromBudgetInsights(
            budgetId: UUID,
            insights: BudgetInsights,
            plannerState: PlannerStateManager
        ) async {
            if insights.utilizationRate > 1.0 {
                print("Task: Review budget \(budgetId) - Overspent!")
            }
        }

        private func createHabitsFromProductivityInsights(
            insights: ProductivityInsights,
            habitState: HabitStateManager
        ) async {
            if insights.completionRate < 0.5 {
                print("Habit Suggestion: Focus Meditation to improve productivity.")
            }
        }

        private func createTaskFromFinancialRecommendation(
            _ recommendation: FinancialRecommendation,
            plannerState: PlannerStateManager
        ) async {
            print("Task created from recommendation: \(recommendation.title)")
        }

        private func updateFinancialBasedOnHabits() async {
            await self.analyticsService.track(event: "financial_updated_from_habits", properties: nil, userId: nil)
        }

        private func updateTasksBasedOnHabits() async {
            await self.analyticsService.track(event: "tasks_updated_from_habits", properties: nil, userId: nil)
        }

        private func updateGameProgressBasedOnHabits() async {
            await self.analyticsService.track(event: "game_updated_from_habits", properties: nil, userId: nil)
        }

        private func updateHabitsBasedOnFinancial() async {
            await self.analyticsService.track(event: "habits_updated_from_financial", properties: nil, userId: nil)
        }

        private func updateTasksBasedOnFinancial() async {
            await self.analyticsService.track(event: "tasks_updated_from_financial", properties: nil, userId: nil)
        }

        private func updateHabitsBasedOnTasks() async {
            await self.analyticsService.track(event: "habits_updated_from_tasks", properties: nil, userId: nil)
        }

        private func updateFinancialBasedOnTasks() async {
            await self.analyticsService.track(event: "financial_updated_from_tasks", properties: nil, userId: nil)
        }

        private func calculateHabitFinanceCorrelation(userId: String) async -> Double {
            let habitInsights = await self.gatherHabitInsights(for: userId)
            let financialInsights = await self.gatherFinancialInsights(for: userId)

            guard !habitInsights.isEmpty, let financialInsights else {
                return 0.0
            }

            let avgCompletion =
                habitInsights.map(\.completionRate).reduce(0, +) / Double(habitInsights.count)
            let budgetUtilization = financialInsights.utilizationRate

            return (avgCompletion + (1.0 - budgetUtilization)) / 2.0
        }

        private func calculateHabitProductivityCorrelation(userId: String) async -> Double {
            let habitInsights = await self.gatherHabitInsights(for: userId)
            let productivityInsights = await self.gatherProductivityInsights(for: userId)

            guard !habitInsights.isEmpty, let productivityInsights else {
                return 0.0
            }

            let avgCompletion =
                habitInsights.map(\.completionRate).reduce(0, +) / Double(habitInsights.count)
            let productivityScore = productivityInsights.completionRate

            return (avgCompletion + productivityScore) / 2.0
        }

        private func calculateFinanceProductivityCorrelation(userId: String) async -> Double {
            let financialInsights = await self.gatherFinancialInsights(for: userId)
            let productivityInsights = await self.gatherProductivityInsights(for: userId)

            guard let financialInsights,
                  let productivityInsights
            else {
                return 0.0
            }

            let budgetUtilization = financialInsights.utilizationRate
            let productivityScore = productivityInsights.completionRate

            return ((1.0 - budgetUtilization) + productivityScore) / 2.0
        }

        private func generateSynergyActionItems(for correlation: CrossProjectCorrelation) async -> [String] {
            return [
                "Monitor \(correlation.project1.displayName) vs \(correlation.project2.displayName) correlation",
                "Create integrated workflows for \(correlation.project1.displayName)",
                "Set up automated triggers in \(correlation.project2.displayName)"
            ]
        }

        private func exportHabitData(for userId: String) async -> [String: AnyCodable] {
            let state = self.globalCoordinator.habitState
            return [
                "habit_count": AnyCodable(state.habits.count),
                "last_sync": AnyCodable(state.lastSyncDate?.timeIntervalSince1970 ?? 0)
            ]
        }

        private func exportFinancialData(for userId: String) async -> [String: AnyCodable] {
            let state = self.globalCoordinator.financialState
            return [
                "transaction_count": AnyCodable(state.transactions.count),
                "account_count": AnyCodable(state.accounts.count)
            ]
        }

        private func exportPlannerData(for userId: String) async -> [String: AnyCodable] {
            let state = self.globalCoordinator.plannerState
            return [
                "task_count": AnyCodable(state.tasks.count),
                "completed_tasks": AnyCodable(state.tasks.filter { $0.value.isCompleted }.count)
            ]
        }

        private func convertToCSV(_ data: UnifiedExportData) async throws -> Data {
            var csv = "UserId,ExportDate,OverallScore\n"
            csv += "\(data.userId),\(data.exportDate),\(data.insights.overallScore)\n"
            return Data(csv.utf8)
        }

        private func convertToXML(_ data: UnifiedExportData) async throws -> Data {
            var xml = "<UnifiedExport>\n"
            xml += "  <UserId>\(data.userId)</UserId>\n"
            xml += "  <OverallScore>\(data.insights.overallScore)</OverallScore>\n"
            xml += "</UnifiedExport>"
            return Data(xml.utf8)
        }

        private func convertToSQLite(_ data: UnifiedExportData) async throws -> Data {
            // Simplified SQLite simulation
            return Data("SQLite Binary Simulation".utf8)
        }
    }

    // MARK: - Supporting Types

    /// Integration health status
    public enum IntegrationHealthStatus {
        case healthy
        case warning(String)
        case error(Error)
        case disconnected

        public var isHealthy: Bool {
            switch self {
            case .healthy: true
            case .warning, .error, .disconnected: false
            }
        }
    }

    /// Cross-project integration errors
    public enum CrossProjectError: Error, LocalizedError {
        case integrationNotActive
        case projectNotConnected
        case syncFailure(String)
        case dataCorruption
        case exportFailure(String)

        public var errorDescription: String? {
            switch self {
            case .integrationNotActive:
                "Cross-project integration is not active"
            case .projectNotConnected:
                "Project is not connected to integration system"
            case let .syncFailure(reason):
                "Sync failed: \(reason)"
            case .dataCorruption:
                "Data corruption detected in cross-project integration"
            case let .exportFailure(reason):
                "Export failed: \(reason)"
            }
        }
    }

    /// Unified export data structure
    public struct UnifiedExportData: Codable {
        public let userId: String
        public let exportDate: Date
        public let insights: UnifiedUserInsights
        public let rawData: [String: AnyCodable]

        public init(
            userId: String, exportDate: Date, insights: UnifiedUserInsights,
            rawData: [String: AnyCodable]
        ) {
            self.userId = userId
            self.exportDate = exportDate
            self.insights = insights
            self.rawData = rawData
        }
    }

#endif
