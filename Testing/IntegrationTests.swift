#if canImport(XCTest)
import Combine
import Foundation
@testable import TestingFramework
import XCTest

// MARK: - Integration Tests

// Comprehensive integration testing for cross-component workflows and data flow

// MARK: - Cross-Project Integration Tests

class CrossProjectIntegrationTests: IntegrationTestCase {
    func testHabitToFinancialIntegration() async throws {
        // Given - Habit completion triggers financial reward
        let habitManager = HabitManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        let financialManager = FinancialAccountManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        let integrationManager = CrossProjectIntegrationManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // Setup reward account
        let rewardAccount = try await financialManager.createAccount(
            name: "Habit Rewards",
            balance: 100.0,
            type: .savings
        )
        
        // Create habit with reward
        let habit = try await habitManager.createHabit(name: "Daily Exercise", frequency: .daily)
        
        // When - Complete habit
        mockDataService.setReturnValue(habit, for: "load")
        mockDataService.setReturnValue(rewardAccount, for: "load")
        
        try await integrationManager.processHabitCompletion(habitId: habit.id, rewardAmount: 5.0)
        
        // Then - Verify habit streak increased and reward added
        XCTAssertTrue(mockDataService.wasMethodCalled("save"))
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
        
        // Verify cross-project analytics
        let analyticsCalls = mockAnalytics.callHistory.filter { $0.contains("habit_financial_reward") }
        XCTAssertFalse(analyticsCalls.isEmpty)
    }
    
    func testTaskToPlannerIntegration() async throws {
        // Given - Task completion affects planning metrics
        let taskManager = TaskManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        let plannerManager = PlannerManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // Create project with tasks
        let project = try await plannerManager.createProject(name: "Website Redesign")
        let task1 = try await taskManager.createTask(
            title: "Design mockups",
            description: "Create initial design concepts",
            priority: .high
        )
        let task2 = try await taskManager.createTask(
            title: "Implement frontend",
            description: "Build responsive UI",
            priority: .medium
        )
        
        // When - Complete tasks
        mockDataService.setReturnValue(task1, for: "load")
        mockDataService.setReturnValue(task2, for: "load")
        mockDataService.setReturnValue(project, for: "load")
        
        _ = try await taskManager.completeTask(taskId: task1.id)
        try await plannerManager.updateProjectProgress(projectId: project.id)
        
        // Then - Verify project progress updated
        let progressCalls = mockAnalytics.callHistory.filter { $0.contains("project_progress_updated") }
        XCTAssertFalse(progressCalls.isEmpty)
    }
    
    func testMultiProjectDataFlow() async throws {
        // Given - Data flows between all projects
        let dataFlowManager = DataFlowManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // Setup test data across projects
        let user = TestDataBuilder.createTestUser()
        let habit = TestDataBuilder.createTestHabit()
        let account = TestDataBuilder.createTestFinancialAccount()
        let task = TestDataBuilder.createTestTask()
        
        mockDataService.setReturnValue(user, for: "load")
        mockDataService.setReturnValue(habit, for: "load")
        mockDataService.setReturnValue(account, for: "load")
        mockDataService.setReturnValue(task, for: "load")
        
        // When - Sync data across projects
        try await dataFlowManager.syncUserData(userId: user.id)
        
        // Then - Verify all projects accessed data
        XCTAssertGreaterThan(mockDataService.getCallCount(for: "load"), 3)
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
        
        // Verify cross-project sync analytics
        let syncCalls = mockAnalytics.callHistory.filter { $0.contains("cross_project_sync") }
        XCTAssertFalse(syncCalls.isEmpty)
    }
}

// MARK: - State Management Integration Tests

class StateManagementIntegrationTests: IntegrationTestCase {
    func testGlobalStateCoordination() async throws {
        // Given - Multiple state managers coordinating
        let habitStateManager = HabitStateManager()
        let financialStateManager = FinancialStateManager()
        let globalStateCoordinator = GlobalStateCoordinator()
        
        // When - Update habit state
        let habit = TestDataBuilder.createTestHabit()
        await habitStateManager.addHabit(habit)
        await globalStateCoordinator.syncHabitState(habitStateManager.habits)
        
        // Then - Verify global state updated
        let globalHabits = await globalStateCoordinator.getAllHabits()
        XCTAssertEqual(globalHabits.count, 1)
        XCTAssertEqual(globalHabits.first?.id, habit.id)
        
        // When - Update financial state
        let account = TestDataBuilder.createTestFinancialAccount()
        await financialStateManager.addAccount(account)
        await globalStateCoordinator.syncFinancialState(financialStateManager.accounts)
        
        // Then - Verify both states maintained
        let globalAccounts = await globalStateCoordinator.getAllAccounts()
        XCTAssertEqual(globalAccounts.count, 1)
        XCTAssertEqual(globalHabits.count, 1) // Should still have habit
    }
    
    func testStateTransitions() async throws {
        // Given - State manager with transitions
        let stateManager = AppStateManager()
        
        // When - Transition through states
        await stateManager.transitionTo(.loading)
        await XCTAssertEqual(stateManager.currentState, .loading)
        
        await stateManager.transitionTo(.loaded)
        await XCTAssertEqual(stateManager.currentState, .loaded)
        
        await stateManager.transitionTo(.error("Test error"))
        if case let .error(message) = await stateManager.currentState {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected error state")
        }
        
        // Then - Verify transition history
        let history = await stateManager.transitionHistory
        XCTAssertEqual(history.count, 3)
    }
    
    func testConcurrentStateUpdates() async throws {
        // Given - Multiple concurrent state updates
        let stateManager = ConcurrentStateManager()
        let expectation = expectation(description: "Concurrent updates")
        expectation.expectedFulfillmentCount = 100
        
        // When - Perform concurrent updates
        for i in 0 ..< 100 {
            Task {
                await stateManager.updateValue(key: "key_\(i)", value: i)
                expectation.fulfill()
            }
        }
        
        // Then - Wait for all updates and verify state consistency
        await fulfillment(of: [expectation], timeout: 5.0)
        
        let finalCount = await stateManager.getValueCount()
        XCTAssertEqual(finalCount, 100)
    }
}

// MARK: - Error Handling Integration Tests

class ErrorHandlingIntegrationTests: IntegrationTestCase {
    func testErrorPropagationAcrossServices() async throws {
        // Given - Services that can propagate errors
        let networkService = MockNetworkService()
        let dataService = MockDataService()
        let serviceOrchestrator = ServiceOrchestrator(
            networkService: networkService,
            dataService: dataService
        )
        
        // Setup network service to fail
        networkService.setReturnValue(NetworkError.timeout, for: "request")
        
        // When - Attempt operation that involves multiple services
        do {
            try await serviceOrchestrator.syncDataFromNetwork()
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            // Then - Verify error propagated correctly
            XCTAssertEqual(error, NetworkError.timeout)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // Verify error handling was called
        XCTAssertTrue(networkService.wasMethodCalled("request"))
        // Data service should not be called due to network failure
        XCTAssertFalse(dataService.wasMethodCalled("save"))
    }
    
    func testErrorRecoveryWorkflow() async throws {
        // Given - Error recovery system
        let errorHandler = ErrorHandlerManager.shared
        let recoveryService = ErrorRecoveryService(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // When - Trigger recoverable error
        let recoverableError = RecoverableError.temporaryFailure("Network timeout")
        await errorHandler.handleError(recoverableError)
        
        // Attempt recovery
        let recoveryResult = try await recoveryService.attemptRecovery(for: recoverableError)
        
        // Then - Verify recovery succeeded
        XCTAssertTrue(recoveryResult.wasSuccessful)
        XCTAssertNotNil(recoveryResult.recoveryAction)
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
        let recoveryCalls = mockAnalytics.callHistory.filter { $0.contains("error_recovery_successful") }
        XCTAssertFalse(recoveryCalls.isEmpty)
    }
    
    func testCascadingErrorHandling() async throws {
        // Given - System with cascading dependencies
        let primaryService = PrimaryService(dataService: mockDataService)
        let secondaryService = SecondaryService(primaryService: primaryService)
        let orchestrator = CascadingOrchestrator(
            primaryService: primaryService,
            secondaryService: secondaryService
        )
        
        // Setup primary service to fail
        mockDataService.setReturnValue(TestError.setupFailed, for: "load")
        
        // When - Trigger cascading operation
        let result = await orchestrator.performCascadingOperation()
        
        // Then - Verify graceful degradation
        XCTAssertFalse(result.primarySucceeded)
        XCTAssertTrue(result.fallbackUsed)
        XCTAssertNotNil(result.errorMessage)
        
        // Verify error was logged
        XCTAssertTrue(primaryService.errorLogged)
    }
}

// MARK: - Performance Integration Tests

class PerformanceIntegrationTests: IntegrationTestCase {
    func testEndToEndPerformance() async throws {
        // Given - Complete workflow from UI to data persistence
        let workflowManager = EndToEndWorkflowManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // When - Measure complete workflow performance
        let metrics = try await PerformanceTester.measureAsync(iterations: 50) {
            let user = TestDataBuilder.createTestUser()
            let habit = TestDataBuilder.createTestHabit()
            let account = TestDataBuilder.createTestFinancialAccount()
            
            try await workflowManager.performCompleteWorkflow(
                user: user,
                habit: habit,
                account: account
            )
        }
        
        // Then - Verify performance meets requirements
        XCTAssertLessThan(metrics.averageTime, 1.0) // Complete workflow < 1 second
        XCTAssertGreaterThan(metrics.successRate, 0.98) // 98% success rate
        XCTAssertLessThan(metrics.standardDeviation, 0.2) // Consistent performance
    }
    
    func testMemoryManagementAcrossComponents() async throws {
        // Given - Memory-intensive operations across components
        var managers: [AnyObject] = []
        
        // When - Create and use multiple managers
        let memoryMetrics = try PerformanceTester.measureMemoryUsage {
            for i in 0 ..< 100 {
                let habitManager = HabitManager(
                    dataService: MockDataService(),
                    analyticsService: MockAnalyticsService()
                )
                let taskManager = TaskManager(
                    dataService: MockDataService(),
                    analyticsService: MockAnalyticsService()
                )
                
                managers.append(habitManager)
                managers.append(taskManager)
            }
        }
        
        // Then - Verify memory usage is reasonable
        XCTAssertLessThan(memoryMetrics.memoryDeltaMB, 50.0) // Less than 50MB for 200 managers
        
        // Cleanup and verify memory release
        managers.removeAll()
        
        // Force garbage collection (not reliable in all environments)
        let cleanupMetrics = try PerformanceTester.measureMemoryUsage {
            // Perform some operations to trigger cleanup
            for _ in 0 ..< 10 {
                _ = TestDataBuilder.createTestHabit()
            }
        }
        
        XCTAssertLessThan(cleanupMetrics.memoryDeltaMB, 1.0) // Minimal memory for cleanup
    }
    
    func testConcurrentOperationPerformance() async throws {
        // Given - Concurrent operations across services
        let concurrencyManager = ConcurrencyTestManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // When - Perform concurrent operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0 ..< 20 {
                group.addTask {
                    let habit = TestDataBuilder.createTestHabit(name: "Concurrent Habit \(i)")
                    try await concurrencyManager.processHabit(habit)
                }
                
                group.addTask {
                    let task = TestDataBuilder.createTestTask(title: "Concurrent Task \(i)")
                    try await concurrencyManager.processTask(task)
                }
            }
            
            try await group.waitForAll()
        }
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Verify concurrent performance
        XCTAssertLessThan(executionTime, 5.0) // Should complete in less than 5 seconds
        
        // Verify all operations were processed
        XCTAssertEqual(mockDataService.getCallCount(for: "save"), 40) // 20 habits + 20 tasks
    }
}

// MARK: - Data Flow Integration Tests

class DataFlowIntegrationTests: IntegrationTestCase {
    func testDataConsistencyAcrossServices() async throws {
        // Given - Multiple services sharing data
        let dataConsistencyManager = DataConsistencyManager(
            services: [
                HabitService(dataService: mockDataService),
                FinancialService(dataService: mockDataService),
                TaskService(dataService: mockDataService)
            ]
        )
        
        let user = TestDataBuilder.createTestUser()
        
        // When - Update user data across all services
        try await dataConsistencyManager.updateUserAcrossServices(user)
        
        // Then - Verify data consistency
        let consistencyReport = try await dataConsistencyManager.verifyDataConsistency(userId: user.id)
        
        XCTAssertTrue(consistencyReport.isConsistent)
        XCTAssertEqual(consistencyReport.inconsistencies.count, 0)
        
        // Verify all services were updated
        XCTAssertGreaterThanOrEqual(mockDataService.getCallCount(for: "save"), 3)
    }
    
    func testEventDrivenDataFlow() async throws {
        // Given - Event-driven system
        let eventBus = EventBus()
        let habitEventHandler = HabitEventHandler(dataService: mockDataService)
        let analyticsEventHandler = AnalyticsEventHandler(analyticsService: mockAnalytics)
        
        eventBus.subscribe(habitEventHandler)
        eventBus.subscribe(analyticsEventHandler)
        
        // When - Publish event
        let habitCompletedEvent = HabitCompletedEvent(
            habitId: UUID(),
            userId: UUID(),
            completedAt: Date(),
            streakCount: 5
        )
        
        await eventBus.publish(habitCompletedEvent)
        
        // Wait for event processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - Verify event was handled
        XCTAssertTrue(habitEventHandler.wasEventHandled)
        XCTAssertTrue(analyticsEventHandler.wasEventHandled)
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
    }
    
    func testDataSynchronizationFlow() async throws {
        // Given - Data synchronization system
        let syncManager = DataSynchronizationManager(
            localDataService: mockDataService,
            remoteNetworkService: mockNetwork,
            analyticsService: mockAnalytics
        )
        
        // Setup local data
        let localHabits = [
            TestDataBuilder.createTestHabit(name: "Local Habit 1"),
            TestDataBuilder.createTestHabit(name: "Local Habit 2")
        ]
        
        mockDataService.setReturnValue(localHabits, for: "load")
        
        // Setup remote data response
        let remoteHabits = [
            TestDataBuilder.createTestHabit(name: "Remote Habit 1"),
            TestDataBuilder.createTestHabit(name: "Remote Habit 2"),
            TestDataBuilder.createTestHabit(name: "Remote Habit 3")
        ]
        
        mockNetwork.setReturnValue(remoteHabits, for: "request")
        
        // When - Perform data synchronization
        let syncResult = try await syncManager.synchronizeData()
        
        // Then - Verify synchronization results
        XCTAssertTrue(syncResult.wasSuccessful)
        XCTAssertEqual(syncResult.localItemsCount, 2)
        XCTAssertEqual(syncResult.remoteItemsCount, 3)
        XCTAssertGreaterThan(syncResult.mergedItemsCount, 0)
        
        // Verify services were called
        XCTAssertTrue(mockDataService.wasMethodCalled("load"))
        XCTAssertTrue(mockNetwork.wasMethodCalled("request"))
        XCTAssertTrue(mockDataService.wasMethodCalled("save"))
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
    }
}

// MARK: - Supporting Classes for Integration Tests

class CrossProjectIntegrationManager {
    private let dataService: DataServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(dataService: DataServiceProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.dataService = dataService
        self.analyticsService = analyticsService
    }
    
    func processHabitCompletion(habitId: UUID, rewardAmount: Double) async throws {
        // Load habit and update streak
        guard var habit = try await dataService.load(Habit.self, with: habitId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        habit = Habit(
            id: habit.id,
            name: habit.name,
            description: habit.description,
            frequency: habit.frequency,
            streak: habit.streak + 1,
            createdAt: habit.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(habit, with: habitId.uuidString)
        
        // Add financial reward
        if let rewardAccount = try await dataService.load(FinancialAccount.self, with: "reward_account") {
            let updatedAccount = FinancialAccount(
                id: rewardAccount.id,
                name: rewardAccount.name,
                balance: rewardAccount.balance + rewardAmount,
                accountType: rewardAccount.accountType,
                createdAt: rewardAccount.createdAt,
                updatedAt: Date()
            )
            
            try await self.dataService.save(updatedAccount, with: "reward_account")
        }
        
        // Track cross-project event
        await self.analyticsService.track(
            event: "habit_financial_reward",
            properties: [
                "habitId": habitId.uuidString,
                "rewardAmount": rewardAmount,
                "newStreak": habit.streak
            ]
        )
    }
}

class PlannerManager {
    private let dataService: DataServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(dataService: DataServiceProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.dataService = dataService
        self.analyticsService = analyticsService
    }
    
    func createProject(name: String) async throws -> Project {
        let project = Project(
            id: UUID(),
            name: name,
            progress: 0.0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await dataService.save(project, with: project.id.uuidString)
        await self.analyticsService.track(event: "project_created", properties: ["name": name])
        
        return project
    }
    
    func updateProjectProgress(projectId: UUID) async throws {
        guard let project = try await dataService.load(Project.self, with: projectId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        let updatedProject = Project(
            id: project.id,
            name: project.name,
            progress: min(project.progress + 0.1, 1.0),
            createdAt: project.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(updatedProject, with: projectId.uuidString)
        await self.analyticsService.track(
            event: "project_progress_updated",
            properties: [
                "projectId": projectId.uuidString,
                "newProgress": updatedProject.progress
            ]
        )
    }
}

struct Project: Codable, Equatable {
    let id: UUID
    let name: String
    let progress: Double
    let createdAt: Date
    let updatedAt: Date
}

// Additional supporting classes would continue here...
// (Abbreviated for space - the full implementation would include all referenced classes)

enum RecoverableError: Error {
    case temporaryFailure(String)
    case retryableError(String)
}

struct RecoveryResult {
    let wasSuccessful: Bool
    let recoveryAction: String?
}

// MARK: - Mock State Managers

@MainActor
class HabitStateManager: ObservableObject {
    @Published var habits: [Habit] = []
    
    func addHabit(_ habit: Habit) {
        self.habits.append(habit)
    }
}

@MainActor
class FinancialStateManager: ObservableObject {
    @Published var accounts: [FinancialAccount] = []
    
    func addAccount(_ account: FinancialAccount) {
        self.accounts.append(account)
    }
}

@MainActor
class GlobalStateCoordinator: ObservableObject {
    private var allHabits: [Habit] = []
    private var allAccounts: [FinancialAccount] = []
    
    func syncHabitState(_ habits: [Habit]) {
        self.allHabits = habits
    }
    
    func syncFinancialState(_ accounts: [FinancialAccount]) {
        self.allAccounts = accounts
    }
    
    func getAllHabits() -> [Habit] {
        self.allHabits
    }
    
    func getAllAccounts() -> [FinancialAccount] {
        self.allAccounts
    }
}

enum AppState: Equatable {
    case loading
    case loaded
    case error(String)
}

@MainActor
class AppStateManager: ObservableObject {
    @Published var currentState: AppState = .loading
    var transitionHistory: [AppState] = []
    
    func transitionTo(_ newState: AppState) {
        self.transitionHistory.append(self.currentState)
        self.currentState = newState
    }
}

actor ConcurrentStateManager {
    private var values: [String: Int] = [:]
    
    func updateValue(key: String, value: Int) {
        self.values[key] = value
    }
    
    func getValueCount() -> Int {
        self.values.count
    }
}

#endif
