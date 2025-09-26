//
//  EnhancedPlannerModels.swift
//  Quantum-workspace
//
//  Advanced planner data models with comprehensive features
//

import CloudKit
import Foundation
import SwiftData
import SwiftUI

// MARK: - Enhanced Core Data Protocols (from EnhancedDataModels)

/// Protocol for models that support validation
@MainActor
public protocol Validatable {
    /// Validates the model and returns any validation errors
    func validate() throws

    /// Returns true if the model is in a valid state
    var isValid: Bool { get }

    /// Returns validation errors without throwing
    var validationErrors: [ValidationError] { get }
}

/// Protocol for models that support analytics tracking
public protocol Trackable {
    /// Unique identifier for analytics
    var trackingId: String { get }

    /// Metadata for analytics
    var analyticsMetadata: [String: Any] { get }

    /// Records an analytics event
    func trackEvent(_ event: String, parameters: [String: Any]?)
}

/// Protocol for models that support cross-project relationships
public protocol CrossProjectRelatable {
    /// Unique identifier that can be referenced across projects
    var globalId: String { get }

    /// Project context this model belongs to
    var projectContext: String { get }

    /// External references to other models
    var externalReferences: [ExternalReference] { get set }
}

// MARK: - Supporting Types

public enum ValidationError: Error, LocalizedError {
    case required(field: String)
    case invalid(field: String, reason: String)
    case outOfRange(field: String, min: Any?, max: Any?)
    case custom(message: String)

    public var errorDescription: String? {
        switch self {
        case let .required(field):
            "\(field) is required"
        case let .invalid(field, reason):
            "\(field) is invalid: \(reason)"
        case let .outOfRange(field, min, max):
            "\(field) is out of range (\(min ?? "nil") - \(max ?? "nil"))"
        case let .custom(message):
            message
        }
    }
}

public enum ProjectContext: String, CaseIterable, Codable {
    case habitQuest
    case momentumFinance
    case plannerApp
    case codingReviewer
    case avoidObstaclesGame
}

public struct ExternalReference: Codable, Identifiable {
    public let id: UUID
    public let projectContext: String
    public let modelType: String
    public let modelId: String
    public let relationshipType: String
    public let createdAt: Date

    public init(projectContext: String, modelType: String, modelId: String, relationshipType: String) {
        id = UUID()
        self.projectContext = projectContext
        self.modelType = modelType
        self.modelId = modelId
        self.relationshipType = relationshipType
        createdAt = Date()
    }
}

// MARK: - Enhanced Task Model

@Model
public final class EnhancedTask: Validatable, Trackable, CrossProjectRelatable {
    // Core Properties
    public var id: UUID
    public var title: String
    public var taskDescription: String
    public var isCompleted: Bool
    public var priority: TaskPriority
    public var dueDate: Date?
    public var createdAt: Date
    public var modifiedAt: Date?

    // Enhanced Properties
    public var estimatedDuration: TimeInterval? // in seconds
    public var actualDuration: TimeInterval?
    public var completionDate: Date?
    public var startDate: Date?
    public var category: TaskCategory
    public var tags: [String]
    public var color: String
    public var iconName: String
    public var notes: String
    public var reminderDate: Date?
    public var reminderEnabled: Bool
    public var repeatFrequency: RepeatFrequency?
    public var parentTaskId: String?
    public var orderIndex: Int
    public var energyLevel: EnergyLevel?
    public var context: TaskContext?
    public var location: String?
    public var progress: Double // 0.0 to 1.0

    // Analytics Properties
    public var timeSpentTotal: TimeInterval
    public var postponedCount: Int
    public var lastPostponedDate: Date?
    public var completionStreak: Int
    public var averageCompletionTime: TimeInterval
    public var difficultyRating: Int? // 1-5 scale, set after completion
    public var satisfactionRating: Int? // 1-5 scale, set after completion

    // Cross-project Properties
    public var globalId: String
    public var projectContext: String
    public var externalReferences: [ExternalReference]

    // Relationships
    @Relationship(deleteRule: .cascade)
    public var subtasks: [EnhancedTask] = []

    @Relationship(deleteRule: .cascade)
    public var attachments: [TaskAttachment] = []

    @Relationship(deleteRule: .cascade)
    public var timeEntries: [TimeEntry] = []

    // Computed Properties
    public var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    public var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    public var isDueTomorrow: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    public var isDueThisWeek: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    public var completionPercentage: Double {
        if isCompleted { return 100.0 }
        if subtasks.isEmpty { return progress * 100.0 }

        let completedSubtasks = subtasks.count(where: { $0.isCompleted })
        return Double(completedSubtasks) / Double(subtasks.count) * 100.0
    }

    public var hasSubtasks: Bool {
        !subtasks.isEmpty
    }

    public var totalEstimatedTime: TimeInterval {
        let baseTime = estimatedDuration ?? 0
        let subtaskTime = subtasks.reduce(0) { $0 + $1.totalEstimatedTime }
        return baseTime + subtaskTime
    }

    public var urgencyScore: Int {
        let priorityValues: [TaskPriority: Int] = [.low: 1, .medium: 2, .high: 3, .urgent: 4]
        var score = (priorityValues[priority] ?? 2) * 10

        if isOverdue { score += 50 }
        else if isDueToday { score += 30 }
        else if isDueTomorrow { score += 20 }
        else if isDueThisWeek { score += 10 }

        if energyLevel == .low { score -= 5 }
        else if energyLevel == .high { score += 5 }

        return score
    }

    // Initialization
    public init(
        title: String,
        description: String = "",
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        category: TaskCategory = .general
    ) {
        id = UUID()
        self.title = title
        taskDescription = description
        isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        createdAt = Date()
        modifiedAt = Date()

        self.category = category
        tags = []
        color = "blue"
        iconName = "circle"
        notes = ""
        reminderEnabled = false
        orderIndex = 0
        progress = 0.0

        timeSpentTotal = 0
        postponedCount = 0
        completionStreak = 0
        averageCompletionTime = 0

        globalId = "task_\(id.uuidString)"
        projectContext = ProjectContext.plannerApp.rawValue
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

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "title"))
        }

        if title.count > 200 {
            errors.append(.invalid(field: "title", reason: "must be 200 characters or less"))
        }

        if taskDescription.count > 1000 {
            errors.append(.invalid(field: "description", reason: "must be 1000 characters or less"))
        }

        if progress < 0 || progress > 1 {
            errors.append(.outOfRange(field: "progress", min: 0, max: 1))
        }

        if let estimatedDuration, estimatedDuration < 0 {
            errors.append(.invalid(field: "estimatedDuration", reason: "cannot be negative"))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "task_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "priority": priority.rawValue,
            "category": category.rawValue,
            "hasSubtasks": hasSubtasks,
            "isCompleted": isCompleted,
            "isOverdue": isOverdue,
            "urgencyScore": urgencyScore,
            "completionPercentage": completionPercentage,
            "postponedCount": postponedCount,
            "timeSpentTotal": timeSpentTotal,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for task: \(title) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func complete() {
        guard !isCompleted else { return }

        isCompleted = true
        completionDate = Date()
        progress = 1.0
        modifiedAt = Date()

        // Update analytics
        completionStreak += 1

        if let estimatedDuration {
            actualDuration = timeSpentTotal
            updateAverageCompletionTime()
        }

        trackEvent("task_completed", parameters: [
            "actual_duration": actualDuration ?? 0,
            "estimated_duration": estimatedDuration ?? 0,
            "completion_streak": completionStreak,
        ])

        // Auto-complete subtasks if configured
        for subtask in subtasks where !subtask.isCompleted {
            subtask.complete()
        }
    }

    @MainActor
    public func postpone(to newDate: Date) {
        guard !isCompleted else { return }

        dueDate = newDate
        postponedCount += 1
        lastPostponedDate = Date()
        modifiedAt = Date()

        trackEvent("task_postponed", parameters: [
            "new_due_date": newDate,
            "postponed_count": postponedCount,
        ])
    }

    @MainActor
    public func updateProgress(_ newProgress: Double) {
        guard newProgress >= 0, newProgress <= 1 else { return }

        let oldProgress = progress
        progress = newProgress
        modifiedAt = Date()

        // Auto-complete if progress reaches 100%
        if progress == 1.0, !isCompleted {
            complete()
        }

        trackEvent("progress_updated", parameters: [
            "old_progress": oldProgress,
            "new_progress": newProgress,
        ])
    }

    @MainActor
    public func addSubtask(_ subtask: EnhancedTask) {
        subtask.parentTaskId = id.uuidString
        subtasks.append(subtask)
        modifiedAt = Date()

        trackEvent("subtask_added", parameters: [
            "subtask_title": subtask.title,
        ])
    }

    @MainActor
    public func startWork() {
        startDate = Date()
        let timeEntry = TimeEntry(task: self, startTime: Date())
        timeEntries.append(timeEntry)

        trackEvent("work_started")
    }

    @MainActor
    public func stopWork() {
        guard let currentEntry = timeEntries.last, currentEntry.endTime == nil else { return }

        currentEntry.endTime = Date()
        let duration = currentEntry.duration
        timeSpentTotal += duration

        trackEvent("work_stopped", parameters: [
            "session_duration": duration,
            "total_time_spent": timeSpentTotal,
        ])
    }

    private func updateAverageCompletionTime() {
        guard let actualDuration else { return }

        averageCompletionTime = (averageCompletionTime * Double(completionStreak - 1) + actualDuration) /
            Double(completionStreak)
    }

    // MARK: - CloudKit Support

    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Task", recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["taskDescription"] = taskDescription
        record["isCompleted"] = isCompleted
        record["priority"] = priority.rawValue
        record["dueDate"] = dueDate
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["category"] = category.rawValue
        record["progress"] = progress
        record["globalId"] = globalId
        return record
    }

    public static func from(ckRecord: CKRecord) throws -> EnhancedTask {
        guard
            let title = ckRecord["title"] as? String,
            let createdAt = ckRecord["createdAt"] as? Date,
            let idString = ckRecord.recordID.recordName,
            let id = UUID(uuidString: idString)
        else {
            throw NSError(
                domain: "TaskConversionError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert CloudKit record to Task"]
            )
        }

        let task = EnhancedTask(
            title: title,
            description: ckRecord["taskDescription"] as? String ?? "",
            priority: TaskPriority(rawValue: ckRecord["priority"] as? String ?? "medium") ?? .medium,
            dueDate: ckRecord["dueDate"] as? Date,
            category: TaskCategory(rawValue: ckRecord["category"] as? String ?? "general") ?? .general
        )

        task.id = id
        task.isCompleted = ckRecord["isCompleted"] as? Bool ?? false
        task.createdAt = createdAt
        task.modifiedAt = ckRecord["modifiedAt"] as? Date
        task.progress = ckRecord["progress"] as? Double ?? 0.0
        task.globalId = ckRecord["globalId"] as? String ?? "task_\(id.uuidString)"

        return task
    }
}

// MARK: - Enhanced Goal Model

@Model
public final class EnhancedGoal: Validatable, Trackable, CrossProjectRelatable {
    public var id: UUID
    public var title: String
    public var goalDescription: String
    public var targetDate: Date?
    public var isCompleted: Bool
    public var createdAt: Date
    public var modifiedAt: Date?

    // Enhanced Properties
    public var category: GoalCategory
    public var priority: GoalPriority
    public var progress: Double // 0.0 to 1.0
    public var milestones: [String] // JSON encoded milestones
    public var tags: [String]
    public var color: String
    public var iconName: String
    public var notes: String
    public var isPublic: Bool
    public var reminderFrequency: ReminderFrequency?
    public var lastReminderDate: Date?
    public var motivationalQuote: String?
    public var rewardDescription: String?
    public var estimatedEffort: EffortLevel

    // Analytics Properties
    public var totalTimeSpent: TimeInterval
    public var milestoneCount: Int
    public var completedMilestones: Int
    public var averageProgressPerWeek: Double
    public var lastProgressUpdate: Date?

    // Cross-project Properties
    public var globalId: String
    public var projectContext: String
    public var externalReferences: [ExternalReference]

    // Relationships
    @Relationship(deleteRule: .cascade)
    public var relatedTasks: [EnhancedTask] = []

    @Relationship(deleteRule: .cascade)
    public var progressEntries: [GoalProgressEntry] = []

    // Computed Properties
    public var progressPercentage: Double {
        progress * 100.0
    }

    public var isOverdue: Bool {
        guard let targetDate, !isCompleted else { return false }
        return targetDate < Date()
    }

    public var daysRemaining: Int {
        guard let targetDate else { return Int.max }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: targetDate).day ?? 0)
    }

    public var completedTasksCount: Int {
        relatedTasks.count(where: { $0.isCompleted })
    }

    public var totalTasksCount: Int {
        relatedTasks.count
    }

    // Initialization
    public init(
        title: String,
        description: String = "",
        targetDate: Date? = nil,
        category: GoalCategory = .personal,
        priority: GoalPriority = .medium
    ) {
        id = UUID()
        self.title = title
        goalDescription = description
        self.targetDate = targetDate
        isCompleted = false
        createdAt = Date()
        modifiedAt = Date()

        self.category = category
        self.priority = priority
        progress = 0.0
        milestones = []
        tags = []
        color = "green"
        iconName = "target"
        notes = ""
        isPublic = false
        estimatedEffort = .medium

        totalTimeSpent = 0
        milestoneCount = 0
        completedMilestones = 0
        averageProgressPerWeek = 0

        globalId = "goal_\(id.uuidString)"
        projectContext = ProjectContext.plannerApp.rawValue
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

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "title"))
        }

        if title.count > 200 {
            errors.append(.invalid(field: "title", reason: "must be 200 characters or less"))
        }

        if progress < 0 || progress > 1 {
            errors.append(.outOfRange(field: "progress", min: 0, max: 1))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "goal_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "category": category.rawValue,
            "priority": priority.rawValue,
            "progress": progress,
            "isCompleted": isCompleted,
            "isOverdue": isOverdue,
            "totalTasksCount": totalTasksCount,
            "completedTasksCount": completedTasksCount,
            "estimatedEffort": estimatedEffort.rawValue,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for goal: \(title) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func updateProgress(_ newProgress: Double, note: String? = nil) {
        guard newProgress >= 0, newProgress <= 1 else { return }

        let oldProgress = progress
        progress = newProgress
        modifiedAt = Date()
        lastProgressUpdate = Date()

        // Create progress entry
        let entry = GoalProgressEntry(goal: self, progress: newProgress, note: note)
        progressEntries.append(entry)

        // Auto-complete if progress reaches 100%
        if progress == 1.0, !isCompleted {
            complete()
        }

        updateAverageProgress()

        trackEvent("progress_updated", parameters: [
            "old_progress": oldProgress,
            "new_progress": newProgress,
            "has_note": note != nil,
        ])
    }

    @MainActor
    public func complete() {
        guard !isCompleted else { return }

        isCompleted = true
        progress = 1.0
        modifiedAt = Date()

        trackEvent("goal_completed", parameters: [
            "days_to_complete": Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0,
            "total_tasks": totalTasksCount,
        ])
    }

    @MainActor
    public func addTask(_ task: EnhancedTask) {
        relatedTasks.append(task)
        modifiedAt = Date()

        trackEvent("task_added", parameters: [
            "task_title": task.title,
        ])
    }

    private func updateAverageProgress() {
        let weeksSinceCreation = max(1, Calendar.current.dateComponents([.weekOfYear], from: createdAt, to: Date()).weekOfYear ?? 1)
        averageProgressPerWeek = progress / Double(weeksSinceCreation)
    }
}

// MARK: - Enhanced Journal Entry Model

@Model
public final class EnhancedJournalEntry: Validatable, Trackable, CrossProjectRelatable {
    public var id: UUID
    public var title: String
    public var content: String
    public var date: Date
    public var createdAt: Date
    public var modifiedAt: Date?

    // Enhanced Properties
    public var mood: Mood?
    public var weather: Weather?
    public var location: String?
    public var tags: [String]
    public var isPrivate: Bool
    public var isFavorite: Bool
    public var wordCount: Int
    public var readingTime: TimeInterval
    public var category: JournalCategory
    public var gratitudeItems: [String] // Things user is grateful for
    public var goals: [String] // Daily/weekly goals mentioned
    public var reflections: [String] // Key insights or reflections
    public var photos: [String] // Photo URLs/paths

    // Analytics Properties
    public var emotionalTone: EmotionalTone?
    public var keyTopics: [String] // Automatically extracted topics
    public var sentimentScore: Double // -1.0 to 1.0

    // Cross-project Properties
    public var globalId: String
    public var projectContext: String
    public var externalReferences: [ExternalReference]

    // Computed Properties
    public var estimatedReadingTime: TimeInterval {
        // Average reading speed: 200 words per minute
        Double(wordCount) / 200.0 * 60.0
    }

    public var hasAttachments: Bool {
        !photos.isEmpty
    }

    // Initialization
    public init(title: String, content: String, date: Date = Date()) {
        id = UUID()
        self.title = title
        self.content = content
        self.date = date
        createdAt = Date()
        modifiedAt = Date()

        tags = []
        isPrivate = false
        isFavorite = false
        wordCount = content.components(separatedBy: .whitespacesAndNewlines).count(where: { !$0.isEmpty })
        readingTime = 0
        category = .general
        gratitudeItems = []
        goals = []
        reflections = []
        photos = []

        sentimentScore = 0.0
        keyTopics = []

        globalId = "journal_\(id.uuidString)"
        projectContext = ProjectContext.plannerApp.rawValue
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

        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "title"))
        }

        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "content"))
        }

        if sentimentScore < -1 || sentimentScore > 1 {
            errors.append(.outOfRange(field: "sentimentScore", min: -1, max: 1))
        }

        return errors
    }

    // MARK: - Trackable Implementation

    public var trackingId: String {
        "journal_\(id.uuidString)"
    }

    public var analyticsMetadata: [String: Any] {
        [
            "wordCount": wordCount,
            "category": category.rawValue,
            "mood": mood?.rawValue ?? "none",
            "hasAttachments": hasAttachments,
            "isPrivate": isPrivate,
            "sentimentScore": sentimentScore,
            "keyTopicsCount": keyTopics.count,
        ]
    }

    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }

        print("Tracking event: \(event) for journal entry: \(title) with parameters: \(eventParameters)")
    }

    // MARK: - Business Logic Methods

    @MainActor
    public func updateContent(_ newContent: String) {
        content = newContent
        wordCount = newContent.components(separatedBy: .whitespacesAndNewlines).count(where: { !$0.isEmpty })
        modifiedAt = Date()

        // TODO: Implement sentiment analysis
        analyzeSentiment()

        trackEvent("content_updated", parameters: [
            "new_word_count": wordCount,
        ])
    }

    private func analyzeSentiment() {
        // Placeholder for sentiment analysis
        // In a real implementation, this would use NLP libraries or services
        sentimentScore = 0.0
    }
}

// MARK: - Supporting Models

@Model
public final class TaskAttachment {
    public var id: UUID
    public var fileName: String
    public var fileUrl: String
    public var fileType: String
    public var fileSize: Int64
    public var uploadDate: Date

    public var task: EnhancedTask?

    public init(fileName: String, fileUrl: String, fileType: String, fileSize: Int64) {
        id = UUID()
        self.fileName = fileName
        self.fileUrl = fileUrl
        self.fileType = fileType
        self.fileSize = fileSize
        uploadDate = Date()
    }
}

@Model
public final class TimeEntry {
    public var id: UUID
    public var startTime: Date
    public var endTime: Date?
    public var notes: String?

    public var task: EnhancedTask?

    public var duration: TimeInterval {
        guard let endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }

    public init(task: EnhancedTask, startTime: Date) {
        id = UUID()
        self.task = task
        self.startTime = startTime
    }
}

@Model
public final class GoalProgressEntry {
    public var id: UUID
    public var date: Date
    public var progress: Double
    public var note: String?

    public var goal: EnhancedGoal?

    public init(goal: EnhancedGoal, progress: Double, note: String? = nil) {
        id = UUID()
        self.goal = goal
        date = Date()
        self.progress = progress
        self.note = note
    }
}

// MARK: - Supporting Enums

public enum TaskPriority: String, CaseIterable, Codable, Comparable {
    case low
    case medium
    case high
    case urgent

    public var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .urgent: "Urgent"
        }
    }

    public var color: Color {
        switch self {
        case .low: .gray
        case .medium: .blue
        case .high: .orange
        case .urgent: .red
        }
    }

    public var rawValue: String {
        switch self {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        case .urgent: "urgent"
        }
    }

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        let order: [TaskPriority] = [.low, .medium, .high, .urgent]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs)
        else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

public enum TaskCategory: String, CaseIterable, Codable {
    case general
    case work
    case personal
    case health
    case finance
    case learning
    case social
    case travel
    case home
    case creative

    public var displayName: String {
        rawValue.capitalized
    }

    public var iconName: String {
        switch self {
        case .general: "circle"
        case .work: "briefcase"
        case .personal: "person"
        case .health: "heart"
        case .finance: "dollarsign.circle"
        case .learning: "book"
        case .social: "person.2"
        case .travel: "airplane"
        case .home: "house"
        case .creative: "paintbrush"
        }
    }
}

public enum RepeatFrequency: String, CaseIterable, Codable {
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum EnergyLevel: String, CaseIterable, Codable {
    case low
    case medium
    case high

    public var displayName: String {
        rawValue.capitalized
    }

    public var color: Color {
        switch self {
        case .low: .red
        case .medium: .orange
        case .high: .green
        }
    }
}

public enum TaskContext: String, CaseIterable, Codable {
    case office
    case home
    case commute
    case errands
    case calls
    case computer
    case outdoors

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum GoalCategory: String, CaseIterable, Codable {
    case personal
    case career
    case health
    case financial
    case relationships
    case learning
    case travel
    case creative
    case spiritual

    public var displayName: String {
        rawValue.capitalized
    }

    public var iconName: String {
        switch self {
        case .personal: "person"
        case .career: "briefcase"
        case .health: "heart"
        case .financial: "dollarsign.circle"
        case .relationships: "person.2"
        case .learning: "book"
        case .travel: "airplane"
        case .creative: "paintbrush"
        case .spiritual: "leaf"
        }
    }
}

public enum GoalPriority: String, CaseIterable, Codable {
    case low
    case medium
    case high
    case critical

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum ReminderFrequency: String, CaseIterable, Codable {
    case daily
    case weekly
    case monthly
    case never

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum EffortLevel: String, CaseIterable, Codable {
    case minimal
    case low
    case medium
    case high
    case intensive

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum Mood: String, CaseIterable, Codable {
    case terrible
    case poor
    case okay
    case good
    case excellent

    public var emoji: String {
        switch self {
        case .terrible: "😞"
        case .poor: "😕"
        case .okay: "😐"
        case .good: "😊"
        case .excellent: "😄"
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum Weather: String, CaseIterable, Codable {
    case sunny
    case cloudy
    case rainy
    case snowy
    case stormy

    public var emoji: String {
        switch self {
        case .sunny: "☀️"
        case .cloudy: "☁️"
        case .rainy: "🌧️"
        case .snowy: "❄️"
        case .stormy: "⛈️"
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum JournalCategory: String, CaseIterable, Codable {
    case general
    case gratitude
    case reflection
    case goals
    case dreams
    case travel
    case relationships
    case work

    public var displayName: String {
        rawValue.capitalized
    }
}

public enum EmotionalTone: String, CaseIterable, Codable {
    case positive
    case neutral
    case negative
    case mixed

    public var displayName: String {
        rawValue.capitalized
    }
}
