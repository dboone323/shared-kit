#if canImport(XCTest)
import Combine
import Foundation
@testable import TestingFramework
import XCTest

// MARK: - Unit Tests for Core Components

// Comprehensive unit tests for shared components across all projects

// MARK: - Habit Management Tests

class HabitManagerTests: BaseTestCase {
    var habitManager: HabitManager!
    var mockDataService: MockDataService!
    var mockAnalytics: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        self.mockDataService = MockDataService()
        self.mockAnalytics = MockAnalyticsService()
        self.habitManager = HabitManager(
            dataService: self.mockDataService,
            analyticsService: self.mockAnalytics
        )
    }
    
    func testCreateHabit() async throws {
        // Given
        let habitName = "Morning Exercise"
        let frequency = HabitFrequency.daily
        
        // When
        let habit = try await habitManager.createHabit(name: habitName, frequency: frequency)
        
        // Then
        XCTAssertEqual(habit.name, habitName)
        XCTAssertEqual(habit.frequency, frequency)
        XCTAssertEqual(habit.streak, 0)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
    
    func testCompleteHabit() async throws {
        // Given
        let habit = TestDataBuilder.createTestHabit(streak: 5)
        self.mockDataService.setReturnValue(habit, for: "load")
        
        // When
        let updatedHabit = try await habitManager.completeHabit(habitId: habit.id)
        
        // Then
        XCTAssertEqual(updatedHabit.streak, 6)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
    
    func testCompleteHabitIncreasesStreak() async throws {
        // Given
        let initialStreak = 10
        let habit = TestDataBuilder.createTestHabit(streak: initialStreak)
        self.mockDataService.setReturnValue(habit, for: "load")
        
        // When
        let completedHabit = try await habitManager.completeHabit(habitId: habit.id)
        
        // Then
        XCTAssertEqual(completedHabit.streak, initialStreak + 1)
        
        // Verify analytics tracking
        let trackCalls = self.mockAnalytics.callHistory.filter { $0.contains("track") }
        XCTAssertTrue(trackCalls.contains { $0.contains("habit_completed") })
    }
    
    func testGetHabitsByFrequency() async throws {
        // Given
        let dailyHabit = TestDataBuilder.createTestHabit(name: "Daily", frequency: .daily)
        let weeklyHabit = TestDataBuilder.createTestHabit(name: "Weekly", frequency: .weekly)
        let habits = [dailyHabit, weeklyHabit]
        self.mockDataService.setReturnValue(habits, for: "load")
        
        // When
        let dailyHabits = try await habitManager.getHabits(frequency: .daily)
        
        // Then
        XCTAssertEqual(dailyHabits.count, 1)
        XCTAssertEqual(dailyHabits.first?.name, "Daily")
    }
    
    func testDeleteHabit() async throws {
        // Given
        let habit = TestDataBuilder.createTestHabit()
        
        // When
        try await self.habitManager.deleteHabit(habitId: habit.id)
        
        // Then
        XCTAssertTrue(self.mockDataService.wasMethodCalled("delete"))
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
    
    func testHabitStreakReset() async throws {
        // Given
        let habit = TestDataBuilder.createTestHabit(streak: 15)
        self.mockDataService.setReturnValue(habit, for: "load")
        
        // When
        let resetHabit = try await habitManager.resetStreak(habitId: habit.id)
        
        // Then
        XCTAssertEqual(resetHabit.streak, 0)
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
}

// MARK: - Financial Account Tests

class FinancialAccountManagerTests: BaseTestCase {
    var accountManager: FinancialAccountManager!
    var mockDataService: MockDataService!
    var mockAnalytics: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        self.mockDataService = MockDataService()
        self.mockAnalytics = MockAnalyticsService()
        self.accountManager = FinancialAccountManager(
            dataService: self.mockDataService,
            analyticsService: self.mockAnalytics
        )
    }
    
    func testCreateAccount() async throws {
        // Given
        let accountName = "Checking Account"
        let initialBalance = 1000.0
        let accountType = AccountType.checking
        
        // When
        let account = try await accountManager.createAccount(
            name: accountName,
            balance: initialBalance,
            type: accountType
        )
        
        // Then
        XCTAssertEqual(account.name, accountName)
        XCTAssertEqual(account.balance, initialBalance)
        XCTAssertEqual(account.accountType, accountType)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
    }
    
    func testUpdateBalance() async throws {
        // Given
        let account = TestDataBuilder.createTestFinancialAccount(balance: 1000.0)
        let newBalance = 1500.0
        self.mockDataService.setReturnValue(account, for: "load")
        
        // When
        let updatedAccount = try await accountManager.updateBalance(
            accountId: account.id,
            newBalance: newBalance
        )
        
        // Then
        XCTAssertEqual(updatedAccount.balance, newBalance)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
    }
    
    func testTransferFunds() async throws {
        // Given
        let fromAccount = TestDataBuilder.createTestFinancialAccount(balance: 1000.0)
        let toAccount = TestDataBuilder.createTestFinancialAccount(balance: 500.0)
        let transferAmount = 200.0
        
        self.mockDataService.setReturnValue(fromAccount, for: "load")
        self.mockDataService.setReturnValue(toAccount, for: "load")
        
        // When
        try await self.accountManager.transferFunds(
            from: fromAccount.id,
            to: toAccount.id,
            amount: transferAmount
        )
        
        // Then
        XCTAssertEqual(self.mockDataService.getCallCount(for: "save"), 2)
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
    
    func testInsufficientFundsError() async {
        // Given
        let account = TestDataBuilder.createTestFinancialAccount(balance: 100.0)
        let transferAmount = 200.0
        let toAccount = TestDataBuilder.createTestFinancialAccount()
        
        self.mockDataService.setReturnValue(account, for: "load")
        
        // When/Then
        await assertThrowsAsync({
            try await self.accountManager.transferFunds(
                from: account.id,
                to: toAccount.id,
                amount: transferAmount
            )
        }, expectedError: FinancialError.insufficientFunds)
    }
    
    func testGetAccountsByType() async throws {
        // Given
        let checkingAccount = TestDataBuilder.createTestFinancialAccount(accountType: .checking)
        let savingsAccount = TestDataBuilder.createTestFinancialAccount(accountType: .savings)
        let accounts = [checkingAccount, savingsAccount]
        self.mockDataService.setReturnValue(accounts, for: "load")
        
        // When
        let checkingAccounts = try await accountManager.getAccounts(type: .checking)
        
        // Then
        XCTAssertEqual(checkingAccounts.count, 1)
        XCTAssertEqual(checkingAccounts.first?.accountType, .checking)
    }
}

// MARK: - Task Management Tests

class TaskManagerTests: BaseTestCase {
    var taskManager: TaskManager!
    var mockDataService: MockDataService!
    var mockAnalytics: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        self.mockDataService = MockDataService()
        self.mockAnalytics = MockAnalyticsService()
        self.taskManager = TaskManager(
            dataService: self.mockDataService,
            analyticsService: self.mockAnalytics
        )
    }
    
    func testCreateTask() async throws {
        // Given
        let title = "Complete project documentation"
        let description = "Write comprehensive docs for the project"
        let priority = TaskPriority.high
        
        // When
        let task = try await taskManager.createTask(
            title: title,
            description: description,
            priority: priority
        )
        
        // Then
        XCTAssertEqual(task.title, title)
        XCTAssertEqual(task.description, description)
        XCTAssertEqual(task.priority, priority)
        XCTAssertFalse(task.isCompleted)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
    }
    
    func testCompleteTask() async throws {
        // Given
        let task = TestDataBuilder.createTestTask(isCompleted: false)
        self.mockDataService.setReturnValue(task, for: "load")
        
        // When
        let completedTask = try await taskManager.completeTask(taskId: task.id)
        
        // Then
        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
    
    func testGetTasksByPriority() async throws {
        // Given
        let highPriorityTask = TestDataBuilder.createTestTask(priority: .high)
        let mediumPriorityTask = TestDataBuilder.createTestTask(priority: .medium)
        let tasks = [highPriorityTask, mediumPriorityTask]
        self.mockDataService.setReturnValue(tasks, for: "load")
        
        // When
        let highPriorityTasks = try await taskManager.getTasks(priority: .high)
        
        // Then
        XCTAssertEqual(highPriorityTasks.count, 1)
        XCTAssertEqual(highPriorityTasks.first?.priority, .high)
    }
    
    func testUpdateTaskPriority() async throws {
        // Given
        let task = TestDataBuilder.createTestTask(priority: .medium)
        let newPriority = TaskPriority.high
        self.mockDataService.setReturnValue(task, for: "load")
        
        // When
        let updatedTask = try await taskManager.updateTask(
            taskId: task.id,
            priority: newPriority
        )
        
        // Then
        XCTAssertEqual(updatedTask.priority, newPriority)
        XCTAssertTrue(self.mockDataService.wasMethodCalled("save"))
    }
    
    func testDeleteTask() async throws {
        // Given
        let task = TestDataBuilder.createTestTask()
        
        // When
        try await self.taskManager.deleteTask(taskId: task.id)
        
        // Then
        XCTAssertTrue(self.mockDataService.wasMethodCalled("delete"))
        XCTAssertTrue(self.mockAnalytics.wasMethodCalled("track"))
    }
}

// MARK: - Animation System Tests

class AnimationSystemTests: BaseTestCase {
    func testAnimationTiming() {
        // Given
        let springAnimation = AnimationTiming.springBouncy
        let easeAnimation = AnimationTiming.easeInOut
        
        // When/Then
        XCTAssertNotNil(springAnimation)
        XCTAssertNotNil(easeAnimation)
    }
    
    func testAnimatedValue() {
        // Given
        @AnimatedValue var scale: CGFloat = 1.0
        
        // When
        scale = 1.5
        
        // Then
        XCTAssertEqual(scale, 1.5)
    }
    
    func testGestureAnimations() {
        // Given/When
        GestureAnimations.hapticFeedback(style: 1)
        
        // Then - No crash should occur
        XCTAssertTrue(true)
    }
}

// MARK: - Error Handling Tests

class ErrorHandlingTests: BaseTestCase {
    var errorHandler: ErrorHandlerManager!
    
    override func setUp() {
        super.setUp()
        self.errorHandler = ErrorHandlerManager.shared
        self.errorHandler.clearErrorHistory()
    }
    
    func testBasicErrorHandling() async {
        // Given
        let testError = TestError.setupFailed
        
        // When
        await self.errorHandler.handleError(testError)
        
        // Then
        XCTAssertEqual(self.errorHandler.recentErrors.count, 1)
    }
    
    func testErrorRecovery() async {
        // Given
        let recoverableError = TestError.timeoutExceeded
        
        // When
        await self.errorHandler.handleError(recoverableError)
        let result = await errorHandler.attemptManualRecovery(for: recoverableError)
        
        // Then
        XCTAssertNotNil(result)
    }
    
    func testCriticalErrorHandling() async {
        // Given
        let criticalError = TestError.assertionFailed("Critical failure")
        
        // When
        await self.errorHandler.handleError(criticalError)
        
        // Then
        XCTAssertEqual(self.errorHandler.globalErrorState, .critical)
        XCTAssertEqual(self.errorHandler.criticalErrors.count, 1)
    }
}

// MARK: - Performance Tests

class PerformanceTests: BaseTestCase {
    func testHabitCreationPerformance() async throws {
        // Given
        let habitManager = HabitManager(
            dataService: MockDataService(),
            analyticsService: MockAnalyticsService()
        )
        
        // When
        let metrics = try await PerformanceTester.measureAsync(iterations: 100) {
            _ = try await habitManager.createHabit(name: "Test Habit", frequency: .daily)
        }
        
        // Then
        XCTAssertLessThan(metrics.averageTime, 0.1) // Should complete in less than 100ms
        XCTAssertGreaterThan(metrics.successRate, 0.95) // Should succeed 95% of the time
    }
    
    func testDataServicePerformance() async throws {
        // Given
        let dataService = MockDataService()
        let testObject = TestDataBuilder.createTestHabit()
        
        // When
        let metrics = try await PerformanceTester.measureAsync(iterations: 1000) {
            try await dataService.save(testObject, with: "test_key")
            _ = try await dataService.load(Habit.self, with: "test_key")
        }
        
        // Then
        XCTAssertLessThan(metrics.averageTime, 0.01) // Should complete in less than 10ms
        XCTAssertEqual(metrics.errors.count, 0) // No errors should occur
    }
    
    func testMemoryUsage() throws {
        // Given
        var habits: [Habit] = []
        
        // When
        let memoryMetrics = try PerformanceTester.measureMemoryUsage {
            for i in 0 ..< 1000 {
                habits.append(TestDataBuilder.createTestHabit(name: "Habit \(i)"))
            }
        }
        
        // Then
        XCTAssertLessThan(memoryMetrics.memoryDeltaMB, 10.0) // Should use less than 10MB
        XCTAssertGreaterThan(memoryMetrics.memoryDeltaMB, 0) // Should use some memory
    }
}

// MARK: - Integration Tests

class IntegrationTests: IntegrationTestCase {
    func testHabitWorkflow() async throws {
        // Given
        let habitManager = HabitManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // When - Create habit
        let habit = try await habitManager.createHabit(name: "Exercise", frequency: .daily)
        
        // Then
        XCTAssertTrue(mockDataService.wasMethodCalled("save"))
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
        
        // When - Complete habit
        mockDataService.setReturnValue(habit, for: "load")
        let completedHabit = try await habitManager.completeHabit(habitId: habit.id)
        
        // Then
        XCTAssertEqual(completedHabit.streak, 1)
        XCTAssertEqual(mockDataService.getCallCount(for: "save"), 2)
        XCTAssertEqual(mockAnalytics.getCallCount(for: "track"), 2)
    }
    
    func testFinancialWorkflow() async throws {
        // Given
        let accountManager = FinancialAccountManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // When - Create accounts
        let checkingAccount = try await accountManager.createAccount(
            name: "Checking",
            balance: 1000.0,
            type: .checking
        )
        let savingsAccount = try await accountManager.createAccount(
            name: "Savings",
            balance: 500.0,
            type: .savings
        )
        
        // Then
        XCTAssertEqual(mockDataService.getCallCount(for: "save"), 2)
        
        // When - Transfer funds
        mockDataService.setReturnValue(checkingAccount, for: "load")
        mockDataService.setReturnValue(savingsAccount, for: "load")
        
        try await accountManager.transferFunds(
            from: checkingAccount.id,
            to: savingsAccount.id,
            amount: 200.0
        )
        
        // Then
        XCTAssertEqual(mockDataService.getCallCount(for: "save"), 4) // 2 initial + 2 for transfer
        XCTAssertTrue(mockAnalytics.wasMethodCalled("track"))
    }
    
    func testTaskPlanningWorkflow() async throws {
        // Given
        let taskManager = TaskManager(
            dataService: mockDataService,
            analyticsService: mockAnalytics
        )
        
        // When - Create tasks with different priorities
        let highPriorityTask = try await taskManager.createTask(
            title: "Critical Bug Fix",
            description: "Fix production issue",
            priority: .high
        )
        let mediumPriorityTask = try await taskManager.createTask(
            title: "Documentation",
            description: "Update project docs",
            priority: .medium
        )
        
        // Then
        XCTAssertEqual(mockDataService.getCallCount(for: "save"), 2)
        
        // When - Complete high priority task
        mockDataService.setReturnValue(highPriorityTask, for: "load")
        let completedTask = try await taskManager.completeTask(taskId: highPriorityTask.id)
        
        // Then
        XCTAssertTrue(completedTask.isCompleted)
        XCTAssertEqual(mockDataService.getCallCount(for: "save"), 3)
    }
}

// MARK: - Mock Manager Classes

class HabitManager {
    private let dataService: DataServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(dataService: DataServiceProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.dataService = dataService
        self.analyticsService = analyticsService
    }
    
    func createHabit(name: String, frequency: HabitFrequency) async throws -> Habit {
        let habit = Habit(
            id: UUID(),
            name: name,
            description: nil,
            frequency: frequency,
            streak: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await dataService.save(habit, with: habit.id.uuidString)
        await self.analyticsService.track(event: "habit_created", properties: ["name": name])
        
        return habit
    }
    
    func completeHabit(habitId: UUID) async throws -> Habit {
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
        await self.analyticsService.track(event: "habit_completed", properties: ["habitId": habitId.uuidString])
        
        return habit
    }
    
    func getHabits(frequency: HabitFrequency) async throws -> [Habit] {
        guard let allHabits = try await dataService.load([Habit].self, with: "all_habits") else {
            return []
        }
        return allHabits.filter { $0.frequency == frequency }
    }
    
    func deleteHabit(habitId: UUID) async throws {
        try await self.dataService.delete(with: habitId.uuidString)
        await self.analyticsService.track(event: "habit_deleted", properties: ["habitId": habitId.uuidString])
    }
    
    func resetStreak(habitId: UUID) async throws -> Habit {
        guard var habit = try await dataService.load(Habit.self, with: habitId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        habit = Habit(
            id: habit.id,
            name: habit.name,
            description: habit.description,
            frequency: habit.frequency,
            streak: 0,
            createdAt: habit.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(habit, with: habitId.uuidString)
        await self.analyticsService.track(event: "habit_streak_reset", properties: ["habitId": habitId.uuidString])
        
        return habit
    }
}

class FinancialAccountManager {
    private let dataService: DataServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(dataService: DataServiceProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.dataService = dataService
        self.analyticsService = analyticsService
    }
    
    func createAccount(name: String, balance: Double, type: AccountType) async throws -> FinancialAccount {
        let account = FinancialAccount(
            id: UUID(),
            name: name,
            balance: balance,
            accountType: type,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await dataService.save(account, with: account.id.uuidString)
        await self.analyticsService.track(event: "account_created", properties: ["type": type.rawValue])
        
        return account
    }
    
    func updateBalance(accountId: UUID, newBalance: Double) async throws -> FinancialAccount {
        guard var account = try await dataService.load(FinancialAccount.self, with: accountId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        account = FinancialAccount(
            id: account.id,
            name: account.name,
            balance: newBalance,
            accountType: account.accountType,
            createdAt: account.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(account, with: accountId.uuidString)
        return account
    }
    
    func transferFunds(from fromAccountId: UUID, to toAccountId: UUID, amount: Double) async throws {
        guard let fromAccount = try await dataService.load(FinancialAccount.self, with: fromAccountId.uuidString),
              let toAccount = try await dataService.load(FinancialAccount.self, with: toAccountId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        guard fromAccount.balance >= amount else {
            throw FinancialError.insufficientFunds
        }
        
        let updatedFromAccount = FinancialAccount(
            id: fromAccount.id,
            name: fromAccount.name,
            balance: fromAccount.balance - amount,
            accountType: fromAccount.accountType,
            createdAt: fromAccount.createdAt,
            updatedAt: Date()
        )
        
        let updatedToAccount = FinancialAccount(
            id: toAccount.id,
            name: toAccount.name,
            balance: toAccount.balance + amount,
            accountType: toAccount.accountType,
            createdAt: toAccount.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(updatedFromAccount, with: fromAccountId.uuidString)
        try await self.dataService.save(updatedToAccount, with: toAccountId.uuidString)
        
        await self.analyticsService.track(event: "funds_transferred", properties: ["amount": amount])
    }
    
    func getAccounts(type: AccountType) async throws -> [FinancialAccount] {
        guard let allAccounts = try await dataService.load([FinancialAccount].self, with: "all_accounts") else {
            return []
        }
        return allAccounts.filter { $0.accountType == type }
    }
}

class TaskManager {
    private let dataService: DataServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(dataService: DataServiceProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.dataService = dataService
        self.analyticsService = analyticsService
    }
    
    func createTask(title: String, description: String?, priority: TaskPriority) async throws -> Task {
        let task = Task(
            id: UUID(),
            title: title,
            description: description,
            priority: priority,
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await dataService.save(task, with: task.id.uuidString)
        await self.analyticsService.track(event: "task_created", properties: ["priority": priority.rawValue])
        
        return task
    }
    
    func completeTask(taskId: UUID) async throws -> Task {
        guard var task = try await dataService.load(Task.self, with: taskId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        task = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            priority: task.priority,
            isCompleted: true,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(task, with: taskId.uuidString)
        await self.analyticsService.track(event: "task_completed", properties: ["taskId": taskId.uuidString])
        
        return task
    }
    
    func getTasks(priority: TaskPriority) async throws -> [Task] {
        guard let allTasks = try await dataService.load([Task].self, with: "all_tasks") else {
            return []
        }
        return allTasks.filter { $0.priority == priority }
    }
    
    func updateTask(taskId: UUID, priority: TaskPriority) async throws -> Task {
        guard var task = try await dataService.load(Task.self, with: taskId.uuidString) else {
            throw TestError.mockNotConfigured
        }
        
        task = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            priority: priority,
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        
        try await self.dataService.save(task, with: taskId.uuidString)
        return task
    }
    
    func deleteTask(taskId: UUID) async throws {
        try await self.dataService.delete(with: taskId.uuidString)
        await self.analyticsService.track(event: "task_deleted", properties: ["taskId": taskId.uuidString])
    }
}

enum FinancialError: Error {
    case insufficientFunds
}

#endif
