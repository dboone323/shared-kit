//
//  EnhancedFinancialModels.swift
//  Quantum-workspace
//
//  Advanced financial data models with comprehensive features
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Enhanced Financial Account

@Model
public final class EnhancedFinancialAccount: Validatable, Trackable, CrossProjectRelatable {
    // Core Properties
    public var id: UUID
    public var name: String
    public var balance: Double
    public var iconName: String
    public var createdDate: Date
    public var accountType: AccountType
    public var currencyCode: String
    public var creditLimit: Double?

    // Enhanced Properties
    public var accountNumber: String?
    public var routingNumber: String?
    public var institutionName: String
    public var color: String
    public var isActive: Bool
    public var interestRate: Double?
    public var minimumBalance: Double?
    public var monthlyFee: Double?
    public var lastSyncDate: Date?
    public var externalAccountId: String?
    public var accountOwner: String
    public var jointOwners: [String]
    public var tags: [String]
    public var notes: String

    // Analytics Properties
    public var totalInflow: Double
    public var totalOutflow: Double
    public var averageMonthlyBalance: Double
    public var highestBalance: Double
    public var lowestBalance: Double
    public var lastTransactionDate: Date?

    // Cross-project Properties
    public var globalId: String
    public var projectContext: String
    public var externalReferences: [ExternalReference]

    // Relationships
    @Relationship(deleteRule: .cascade)
    public var transactions: [EnhancedFinancialTransaction] = []

    @Relationship(deleteRule: .cascade)
    public var budgets: [EnhancedBudget] = []

    @Relationship(deleteRule: .cascade)
    public var goals: [EnhancedSavingsGoal] = []

    // Computed Properties
    public var availableCredit: Double {
        guard let creditLimit, accountType == .credit else { return 0 }
        return creditLimit - balance
    }

    public var creditUtilization: Double {
        guard let creditLimit, creditLimit > 0, accountType == .credit else { return 0 }
        return (balance / creditLimit) * 100
    }

    public var monthlySpending: Double {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { $0.date >= startOfMonth && $0.transactionType == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    public var monthlyIncome: Double {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return transactions
            .filter { $0.date >= startOfMonth && $0.transactionType == .income }
            .reduce(0) { $0 + $1.amount }
    }

    public var netWorth: Double {
        switch accountType {
        case .checking, .savings, .cash:
            balance
        case .credit:
            -balance // Credit card balances are liabilities
        case .investment:
            balance // Investment accounts are assets
        }
    }

    public var averageTransactionAmount: Double {
        guard !transactions.isEmpty else { return 0 }
        return transactions.reduce(0) { $0 + $1.amount } / Double(transactions.count)
    }

    // Initialization
    public init(
        name: String,
        balance: Double,
        iconName: String,
        accountType: AccountType = .checking,
        currencyCode: String = "USD",
        institutionName: String = "",
        accountOwner: String = ""
    ) {
        id = UUID()
        self.name = name
        self.balance = balance
        self.iconName = iconName
        self.accountType = accountType
        self.currencyCode = currencyCode
        createdDate = Date()

        self.institutionName = institutionName
        color = "blue"
        isActive = true
        self.accountOwner = accountOwner
        jointOwners = []
        tags = []
        notes = ""

        totalInflow = 0
        totalOutflow = 0
        averageMonthlyBalance = balance
        highestBalance = balance
        lowestBalance = balance

        globalId = "account_\(id.uuidString)"
        projectContext = ProjectContext.momentumFinance.rawValue
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

        if accountOwner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "accountOwner"))
        }

        if let creditLimit, creditLimit < 0 {
            errors.append(.invalid(field: "creditLimit", reason: "cannot be negative"))
        }

        if let interestRate, interestRate < 0 || interestRate > 100 {
            errors.append(.outOfRange(field: "interestRate", min: 0, max: 100))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "account_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "accountType": accountType.rawValue,
            "currencyCode": currencyCode,
            "institutionName": institutionName,
            "balance": balance,
            "transactionCount": transactions.count,
            "isActive": isActive,
            "creditUtilization": creditUtilization,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for account: \(name) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func updateBalance(for transaction: EnhancedFinancialTransaction) {
        let previousBalance = balance

        switch transaction.transactionType {
        case .income:
            balance += transaction.amount
            totalInflow += transaction.amount
        case .expense:
            balance -= transaction.amount
            totalOutflow += transaction.amount
        case .transfer:
            // Handle transfer logic
            break
        }

        // Update analytics
        updateBalanceAnalytics()
        lastTransactionDate = transaction.date

        trackEvent("balance_updated", parameters: [
            "previousBalance": previousBalance,
            "newBalance": balance,
            "change": balance - previousBalance,
            "transactionType": transaction.transactionType.rawValue,
        ])
    }

    private func updateBalanceAnalytics() {
        if balance > highestBalance {
            highestBalance = balance
        }

        if balance < lowestBalance {
            lowestBalance = balance
        }

        // Calculate average monthly balance (simplified)
        averageMonthlyBalance = (averageMonthlyBalance + balance) / 2
    }

    @MainActor
    public func addExternalReference(_ reference: ExternalReference) {
        externalReferences.append(reference)
        trackEvent("external_reference_added", parameters: [
            "project": reference.projectContext.rawValue,
            "model_type": reference.modelType,
        ])
    }

    public func getSpendingByCategory(for period: DatePeriod = .thisMonth) -> [String: Double] {
        let dateRange = period.dateRange
        let expenses = transactions
            .filter { $0.transactionType == .expense && $0.date >= dateRange.start && $0.date <= dateRange.end }

        var categorySpending: [String: Double] = [:]
        for transaction in expenses {
            let category = transaction.category ?? "Uncategorized"
            categorySpending[category, default: 0] += transaction.amount
        }

        return categorySpending
    }
}

// MARK: - Enhanced Financial Transaction

@Model
public final class EnhancedFinancialTransaction: Validatable, Trackable {
    public var id: UUID
    public var amount: Double
    public var date: Date
    public var transactionDescription: String
    public var transactionType: TransactionType
    public var category: String?
    public var subcategory: String?
    public var isReconciled: Bool
    public var createdDate: Date
    public var modifiedDate: Date?

    // Enhanced Properties
    public var merchant: String?
    public var location: String?
    public var receiptUrl: String?
    public var tags: [String]
    public var notes: String
    public var isRecurring: Bool
    public var recurringGroupId: String?
    public var confidence: Double // For imported transactions
    public var exchangeRate: Double?
    public var originalAmount: Double?
    public var originalCurrency: String?
    public var paymentMethod: PaymentMethod?
    public var referenceNumber: String?
    public var isBusinessExpense: Bool
    public var isTaxDeductible: Bool

    // Analytics Properties
    public var deviceUsed: String?
    public var importSource: String?
    public var lastModifiedBy: String?

    // Relationships
    public var account: EnhancedFinancialAccount?

    @Relationship(deleteRule: .cascade)
    public var attachments: [TransactionAttachment] = []

    public enum PaymentMethod: String, CaseIterable, Codable {
        case cash = "Cash"
        case creditCard = "Credit Card"
        case debitCard = "Debit Card"
        case bankTransfer = "Bank Transfer"
        case check = "Check"
        case onlineTransfer = "Online Transfer"
        case mobilePayment = "Mobile Payment"
        case other = "Other"
    }

    // Computed Properties
    public var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = originalCurrency ?? "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    public var isExpense: Bool {
        transactionType == .expense
    }

    public var isIncome: Bool {
        transactionType == .income
    }

    public var categoryPath: String {
        if let subcategory, let category {
            return "\(category) > \(subcategory)"
        }
        return category ?? "Uncategorized"
    }

    // Initialization
    public init(
        amount: Double,
        date: Date = Date(),
        description: String,
        transactionType: TransactionType,
        category: String? = nil,
        account: EnhancedFinancialAccount? = nil
    ) {
        id = UUID()
        self.amount = amount
        self.date = date
        transactionDescription = description
        self.transactionType = transactionType
        self.category = category
        isReconciled = false
        createdDate = Date()
        self.account = account

        tags = []
        notes = ""
        isRecurring = false
        confidence = 1.0
        isBusinessExpense = false
        isTaxDeductible = false
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

        if amount <= 0 {
            errors.append(.invalid(field: "amount", reason: "must be greater than 0"))
        }

        if transactionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "description"))
        }

        if date > Date().addingTimeInterval(86400) { // Allow 1 day in future
            errors.append(.invalid(field: "date", reason: "cannot be more than 1 day in the future"))
        }

        if let exchangeRate, exchangeRate <= 0 {
            errors.append(.invalid(field: "exchangeRate", reason: "must be greater than 0"))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "transaction_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "amount": amount,
            "transactionType": transactionType.rawValue,
            "category": category ?? "none",
            "paymentMethod": paymentMethod?.rawValue ?? "none",
            "isRecurring": isRecurring,
            "isBusinessExpense": isBusinessExpense,
            "isTaxDeductible": isTaxDeductible,
            "hasAttachments": !attachments.isEmpty,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for transaction: \(transactionDescription) with parameters: \(eventParameters)")
    }
}

// MARK: - Enhanced Budget

@Model
public final class EnhancedBudget: Validatable, Trackable {
    public var id: UUID
    public var name: String
    public var amount: Double
    public var period: BudgetPeriod
    public var category: String?
    public var startDate: Date
    public var endDate: Date
    public var isActive: Bool
    public var createdDate: Date

    // Enhanced Properties
    public var budgetType: BudgetType
    public var alertThreshold: Double // Percentage (0-100)
    public var color: String
    public var iconName: String
    public var notes: String
    public var tags: [String]
    public var autoRenew: Bool
    public var carryover: Bool // Allow unused budget to carry over
    public var parentBudgetId: String? // For sub-budgets
    public var priority: Int // 1-5 scale

    // Analytics Properties
    public var totalSpent: Double
    public var averageSpentPerPeriod: Double
    public var periodsOver: Int
    public var periodsUnder: Int
    public var lastResetDate: Date?

    // Relationships
    public var account: EnhancedFinancialAccount?

    @Relationship(deleteRule: .cascade)
    public var subBudgets: [EnhancedBudget] = []

    public enum BudgetPeriod: String, CaseIterable, Codable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        case custom = "Custom"
    }

    public enum BudgetType: String, CaseIterable, Codable {
        case spending = "Spending"
        case savings = "Savings"
        case income = "Income"
        case debt = "Debt Payoff"
    }

    // Computed Properties
    public var remainingAmount: Double {
        max(0, amount - totalSpent)
    }

    public var spentPercentage: Double {
        guard amount > 0 else { return 0 }
        return (totalSpent / amount) * 100
    }

    public var isOverBudget: Bool {
        totalSpent > amount
    }

    public var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }

    public var dailyBudgetRemaining: Double {
        guard daysRemaining > 0 else { return 0 }
        return remainingAmount / Double(daysRemaining)
    }

    public var status: BudgetStatus {
        let percentage = spentPercentage
        if percentage >= 100 {
            return .exceeded
        } else if percentage >= alertThreshold {
            return .warning
        } else if percentage >= 50 {
            return .onTrack
        } else {
            return .underSpent
        }
    }

    public enum BudgetStatus: String, CaseIterable {
        case underSpent = "Under Spent"
        case onTrack = "On Track"
        case warning = "Warning"
        case exceeded = "Exceeded"

        public var color: Color {
            switch self {
            case .underSpent: .green
            case .onTrack: .blue
            case .warning: .orange
            case .exceeded: .red
            }
        }
    }

    // Initialization
    public init(
        name: String,
        amount: Double,
        period: BudgetPeriod,
        category: String? = nil,
        budgetType: BudgetType = .spending
    ) {
        id = UUID()
        self.name = name
        self.amount = amount
        self.period = period
        self.category = category
        self.budgetType = budgetType
        isActive = true
        createdDate = Date()

        // Calculate dates based on period
        let calendar = Calendar.current
        startDate = calendar.startOfDay(for: Date())

        switch period {
        case .weekly:
            endDate = calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .monthly:
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .quarterly:
            endDate = calendar.date(byAdding: .month, value: 3, to: startDate) ?? startDate
        case .yearly:
            endDate = calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        case .custom:
            endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }

        alertThreshold = 80.0
        color = "blue"
        iconName = "dollarsign.circle"
        notes = ""
        tags = []
        autoRenew = false
        carryover = false
        priority = 3

        totalSpent = 0
        averageSpentPerPeriod = 0
        periodsOver = 0
        periodsUnder = 0
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

        if amount <= 0 {
            errors.append(.invalid(field: "amount", reason: "must be greater than 0"))
        }

        if endDate <= startDate {
            errors.append(.invalid(field: "endDate", reason: "must be after start date"))
        }

        if alertThreshold < 0 || alertThreshold > 100 {
            errors.append(.outOfRange(field: "alertThreshold", min: 0, max: 100))
        }

        if priority < 1 || priority > 5 {
            errors.append(.outOfRange(field: "priority", min: 1, max: 5))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "budget_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "budgetType": budgetType.rawValue,
            "period": period.rawValue,
            "amount": amount,
            "spentPercentage": spentPercentage,
            "status": status.rawValue,
            "isActive": isActive,
            "autoRenew": autoRenew,
            "priority": priority,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for budget: \(name) with parameters: \(eventParameters)")
    }
}

// MARK: - Supporting Models

@Model
public final class EnhancedSavingsGoal: Validatable, Trackable {
    public var id: UUID
    public var name: String
    public var targetAmount: Double
    public var currentAmount: Double
    public var targetDate: Date?
    public var isActive: Bool
    public var createdDate: Date
    public var category: String?
    public var priority: Int
    public var color: String
    public var iconName: String
    public var notes: String

    // Relationships
    public var account: EnhancedFinancialAccount?

    // Computed Properties
    public var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return (currentAmount / targetAmount) * 100
    }

    public var remainingAmount: Double {
        max(0, targetAmount - currentAmount)
    }

    public var isComplete: Bool {
        currentAmount >= targetAmount
    }

    public init(name: String, targetAmount: Double, targetDate: Date? = nil) {
        id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        currentAmount = 0
        self.targetDate = targetDate
        isActive = true
        createdDate = Date()
        priority = 3
        color = "green"
        iconName = "target"
        notes = ""
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

        if targetAmount <= 0 {
            errors.append(.invalid(field: "targetAmount", reason: "must be greater than 0"))
        }

        if currentAmount < 0 {
            errors.append(.invalid(field: "currentAmount", reason: "cannot be negative"))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "goal_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "targetAmount": targetAmount,
            "currentAmount": currentAmount,
            "progressPercentage": progressPercentage,
            "isComplete": isComplete,
            "priority": priority,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for goal: \(name) with parameters: \(eventParameters)")
    }
}

@Model
public final class TransactionAttachment {
    public var id: UUID
    public var fileName: String
    public var fileUrl: String
    public var fileType: String
    public var fileSize: Int64
    public var uploadDate: Date
    public var notes: String?

    // Relationship
    public var transaction: EnhancedFinancialTransaction?

    public init(fileName: String, fileUrl: String, fileType: String, fileSize: Int64) {
        id = UUID()
        self.fileName = fileName
        self.fileUrl = fileUrl
        self.fileType = fileType
        self.fileSize = fileSize
        uploadDate = Date()
    }
}

// MARK: - Supporting Enums

public enum AccountType: String, CaseIterable, Codable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit Card"
    case investment = "Investment"
    case cash = "Cash"
    case loan = "Loan"
    case retirement = "Retirement"
    case other = "Other"

    public var displayName: String { rawValue }

    public var iconName: String {
        switch self {
        case .checking: "banknote"
        case .savings: "dollarsign.circle"
        case .credit: "creditcard"
        case .investment: "chart.line.uptrend.xyaxis"
        case .cash: "dollarsign.square"
        case .loan: "building.columns"
        case .retirement: "person.badge.clock"
        case .other: "questionmark.circle"
        }
    }
}

public enum TransactionType: String, CaseIterable, Codable {
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"

    public var displayName: String { rawValue }

    public var color: Color {
        switch self {
        case .income: .green
        case .expense: .red
        case .transfer: .blue
        }
    }
}

public enum DatePeriod {
    case thisWeek
    case thisMonth
    case thisQuarter
    case thisYear
    case last7Days
    case last30Days
    case last90Days
    case last365Days
    case custom(start: Date, end: Date)

    public var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (startOfWeek, now)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (startOfMonth, now)
        case .thisQuarter:
            let startOfQuarter = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            return (startOfQuarter, now)
        case .thisYear:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (startOfYear, now)
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return (start, now)
        case .last90Days:
            let start = calendar.date(byAdding: .day, value: -90, to: now) ?? now
            return (start, now)
        case .last365Days:
            let start = calendar.date(byAdding: .day, value: -365, to: now) ?? now
            return (start, now)
        case let .custom(start, end):
            return (start, end)
        }
    }
}
