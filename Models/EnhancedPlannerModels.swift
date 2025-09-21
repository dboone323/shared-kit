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
        self.id = UUID()
        self.projectContext = projectContext
        self.modelType = modelType
        self.modelId = modelId
        self.relationshipType = relationshipType
        self.createdAt = Date()
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
        if self.isCompleted { return 100.0 }
        if self.subtasks.isEmpty { return self.progress * 100.0 }
        
        let completedSubtasks = self.subtasks.count(where: { $0.isCompleted })
        return Double(completedSubtasks) / Double(self.subtasks.count) * 100.0
    }
    
    public var hasSubtasks: Bool {
        !self.subtasks.isEmpty
    }
    
    public var totalEstimatedTime: TimeInterval {
        let baseTime = self.estimatedDuration ?? 0
        let subtaskTime = self.subtasks.reduce(0) { $0 + $1.totalEstimatedTime }
        return baseTime + subtaskTime
    }
    
    public var urgencyScore: Int {
        let priorityValues: [TaskPriority: Int] = [.low: 1, .medium: 2, .high: 3, .urgent: 4]
        var score = (priorityValues[priority] ?? 2) * 10
        
        if self.isOverdue { score += 50 }
        else if self.isDueToday { score += 30 }
        else if self.isDueTomorrow { score += 20 }
        else if self.isDueThisWeek { score += 10 }
        
        if self.energyLevel == .low { score -= 5 }
        else if self.energyLevel == .high { score += 5 }
        
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
        self.id = UUID()
        self.title = title
        self.taskDescription = description
        self.isCompleted = false
        self.priority = priority
        self.dueDate = dueDate
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        self.category = category
        self.tags = []
        self.color = "blue"
        self.iconName = "circle"
        self.notes = ""
        self.reminderEnabled = false
        self.orderIndex = 0
        self.progress = 0.0
        
        self.timeSpentTotal = 0
        self.postponedCount = 0
        self.completionStreak = 0
        self.averageCompletionTime = 0
        
        self.globalId = "task_\(self.id.uuidString)"
        self.projectContext = ProjectContext.plannerApp.rawValue
        self.externalReferences = []
    }
    
    // MARK: - Validatable Implementation
    
    @MainActor
    public func validate() throws {
        let errors = self.validationErrors
        if !errors.isEmpty {
            throw errors.first!
        }
    }
    
    public var isValid: Bool {
        self.validationErrors.isEmpty
    }
    
    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []
        
        if self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "title"))
        }
        
        if self.title.count > 200 {
            errors.append(.invalid(field: "title", reason: "must be 200 characters or less"))
        }
        
        if self.taskDescription.count > 1000 {
            errors.append(.invalid(field: "description", reason: "must be 1000 characters or less"))
        }
        
        if self.progress < 0 || self.progress > 1 {
            errors.append(.outOfRange(field: "progress", min: 0, max: 1))
        }
        
        if let estimatedDuration, estimatedDuration < 0 {
            errors.append(.invalid(field: "estimatedDuration", reason: "cannot be negative"))
        }
        
        return errors
    }
    
    // MARK: - Trackable Implementation
    
    public var trackingId: String {
        "task_\(self.id.uuidString)"
    }
    
    public var analyticsMetadata: [String: Any] {
        [
            "priority": self.priority.rawValue,
            "category": self.category.rawValue,
            "hasSubtasks": self.hasSubtasks,
            "isCompleted": self.isCompleted,
            "isOverdue": self.isOverdue,
            "urgencyScore": self.urgencyScore,
            "completionPercentage": self.completionPercentage,
            "postponedCount": self.postponedCount,
            "timeSpentTotal": self.timeSpentTotal
        ]
    }
    
    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = self.analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }
        
        print("Tracking event: \(event) for task: \(self.title) with parameters: \(eventParameters)")
    }
    
    // MARK: - Business Logic Methods
    
    @MainActor
    public func complete() {
        guard !self.isCompleted else { return }
        
        self.isCompleted = true
        self.completionDate = Date()
        self.progress = 1.0
        self.modifiedAt = Date()
        
        // Update analytics
        self.completionStreak += 1
        
        if let estimatedDuration {
            self.actualDuration = self.timeSpentTotal
            self.updateAverageCompletionTime()
        }
        
        self.trackEvent("task_completed", parameters: [
            "actual_duration": self.actualDuration ?? 0,
            "estimated_duration": estimatedDuration ?? 0,
            "completion_streak": self.completionStreak
        ])
        
        // Auto-complete subtasks if configured
        for subtask in self.subtasks where !subtask.isCompleted {
            subtask.complete()
        }
    }
    
    @MainActor
    public func postpone(to newDate: Date) {
        guard !self.isCompleted else { return }
        
        self.dueDate = newDate
        self.postponedCount += 1
        self.lastPostponedDate = Date()
        self.modifiedAt = Date()
        
        self.trackEvent("task_postponed", parameters: [
            "new_due_date": newDate,
            "postponed_count": self.postponedCount
        ])
    }
    
    @MainActor
    public func updateProgress(_ newProgress: Double) {
        guard newProgress >= 0, newProgress <= 1 else { return }
        
        let oldProgress = self.progress
        self.progress = newProgress
        self.modifiedAt = Date()
        
        // Auto-complete if progress reaches 100%
        if self.progress == 1.0, !self.isCompleted {
            self.complete()
        }
        
        self.trackEvent("progress_updated", parameters: [
            "old_progress": oldProgress,
            "new_progress": newProgress
        ])
    }
    
    @MainActor
    public func addSubtask(_ subtask: EnhancedTask) {
        subtask.parentTaskId = self.id.uuidString
        self.subtasks.append(subtask)
        self.modifiedAt = Date()
        
        self.trackEvent("subtask_added", parameters: [
            "subtask_title": subtask.title
        ])
    }
    
    @MainActor
    public func startWork() {
        self.startDate = Date()
        let timeEntry = TimeEntry(task: self, startTime: Date())
        self.timeEntries.append(timeEntry)
        
        self.trackEvent("work_started")
    }
    
    @MainActor
    public func stopWork() {
        guard let currentEntry = timeEntries.last, currentEntry.endTime == nil else { return }
        
        currentEntry.endTime = Date()
        let duration = currentEntry.duration
        self.timeSpentTotal += duration
        
        self.trackEvent("work_stopped", parameters: [
            "session_duration": duration,
            "total_time_spent": self.timeSpentTotal
        ])
    }
    
    private func updateAverageCompletionTime() {
        guard let actualDuration else { return }
        
        self
            .averageCompletionTime = (self.averageCompletionTime * Double(self.completionStreak - 1) + actualDuration) /
            Double(self.completionStreak)
    }
    
    // MARK: - CloudKit Support
    
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Task", recordID: CKRecord.ID(recordName: self.id.uuidString))
        record["title"] = self.title
        record["taskDescription"] = self.taskDescription
        record["isCompleted"] = self.isCompleted
        record["priority"] = self.priority.rawValue
        record["dueDate"] = self.dueDate
        record["createdAt"] = self.createdAt
        record["modifiedAt"] = self.modifiedAt
        record["category"] = self.category.rawValue
        record["progress"] = self.progress
        record["globalId"] = self.globalId
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
        self.progress * 100.0
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
        self.relatedTasks.count(where: { $0.isCompleted })
    }
    
    public var totalTasksCount: Int {
        self.relatedTasks.count
    }
    
    // Initialization
    public init(
        title: String,
        description: String = "",
        targetDate: Date? = nil,
        category: GoalCategory = .personal,
        priority: GoalPriority = .medium
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        self.category = category
        self.priority = priority
        self.progress = 0.0
        self.milestones = []
        self.tags = []
        self.color = "green"
        self.iconName = "target"
        self.notes = ""
        self.isPublic = false
        self.estimatedEffort = .medium
        
        self.totalTimeSpent = 0
        self.milestoneCount = 0
        self.completedMilestones = 0
        self.averageProgressPerWeek = 0
        
        self.globalId = "goal_\(self.id.uuidString)"
        self.projectContext = ProjectContext.plannerApp.rawValue
        self.externalReferences = []
    }
    
    // MARK: - Validatable Implementation
    
    @MainActor
    public func validate() throws {
        let errors = self.validationErrors
        if !errors.isEmpty {
            throw errors.first!
        }
    }
    
    public var isValid: Bool {
        self.validationErrors.isEmpty
    }
    
    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []
        
        if self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "title"))
        }
        
        if self.title.count > 200 {
            errors.append(.invalid(field: "title", reason: "must be 200 characters or less"))
        }
        
        if self.progress < 0 || self.progress > 1 {
            errors.append(.outOfRange(field: "progress", min: 0, max: 1))
        }
        
        return errors
    }
    
    // MARK: - Trackable Implementation
    
    public var trackingId: String {
        "goal_\(self.id.uuidString)"
    }
    
    public var analyticsMetadata: [String: Any] {
        [
            "category": self.category.rawValue,
            "priority": self.priority.rawValue,
            "progress": self.progress,
            "isCompleted": self.isCompleted,
            "isOverdue": self.isOverdue,
            "totalTasksCount": self.totalTasksCount,
            "completedTasksCount": self.completedTasksCount,
            "estimatedEffort": self.estimatedEffort.rawValue
        ]
    }
    
    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = self.analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }
        
        print("Tracking event: \(event) for goal: \(self.title) with parameters: \(eventParameters)")
    }
    
    // MARK: - Business Logic Methods
    
    @MainActor
    public func updateProgress(_ newProgress: Double, note: String? = nil) {
        guard newProgress >= 0, newProgress <= 1 else { return }
        
        let oldProgress = self.progress
        self.progress = newProgress
        self.modifiedAt = Date()
        self.lastProgressUpdate = Date()
        
        // Create progress entry
        let entry = GoalProgressEntry(goal: self, progress: newProgress, note: note)
        self.progressEntries.append(entry)
        
        // Auto-complete if progress reaches 100%
        if self.progress == 1.0, !self.isCompleted {
            self.complete()
        }
        
        self.updateAverageProgress()
        
        self.trackEvent("progress_updated", parameters: [
            "old_progress": oldProgress,
            "new_progress": newProgress,
            "has_note": note != nil
        ])
    }
    
    @MainActor
    public func complete() {
        guard !self.isCompleted else { return }
        
        self.isCompleted = true
        self.progress = 1.0
        self.modifiedAt = Date()
        
        self.trackEvent("goal_completed", parameters: [
            "days_to_complete": Calendar.current.dateComponents([.day], from: self.createdAt, to: Date()).day ?? 0,
            "total_tasks": self.totalTasksCount
        ])
    }
    
    @MainActor
    public func addTask(_ task: EnhancedTask) {
        self.relatedTasks.append(task)
        self.modifiedAt = Date()
        
        self.trackEvent("task_added", parameters: [
            "task_title": task.title
        ])
    }
    
    private func updateAverageProgress() {
        let weeksSinceCreation = max(1, Calendar.current.dateComponents([.weekOfYear], from: self.createdAt, to: Date()).weekOfYear ?? 1)
        self.averageProgressPerWeek = self.progress / Double(weeksSinceCreation)
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
        Double(self.wordCount) / 200.0 * 60.0
    }
    
    public var hasAttachments: Bool {
        !self.photos.isEmpty
    }
    
    // Initialization
    public init(title: String, content: String, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.date = date
        self.createdAt = Date()
        self.modifiedAt = Date()
        
        self.tags = []
        self.isPrivate = false
        self.isFavorite = false
        self.wordCount = content.components(separatedBy: .whitespacesAndNewlines).count(where: { !$0.isEmpty })
        self.readingTime = 0
        self.category = .general
        self.gratitudeItems = []
        self.goals = []
        self.reflections = []
        self.photos = []
        
        self.sentimentScore = 0.0
        self.keyTopics = []
        
        self.globalId = "journal_\(self.id.uuidString)"
        self.projectContext = ProjectContext.plannerApp.rawValue
        self.externalReferences = []
    }
    
    // MARK: - Validatable Implementation
    
    @MainActor
    public func validate() throws {
        let errors = self.validationErrors
        if !errors.isEmpty {
            throw errors.first!
        }
    }
    
    public var isValid: Bool {
        self.validationErrors.isEmpty
    }
    
    public var validationErrors: [ValidationError] {
        var errors: [ValidationError] = []
        
        if self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "title"))
        }
        
        if self.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.required(field: "content"))
        }
        
        if self.sentimentScore < -1 || self.sentimentScore > 1 {
            errors.append(.outOfRange(field: "sentimentScore", min: -1, max: 1))
        }
        
        return errors
    }
    
    // MARK: - Trackable Implementation
    
    public var trackingId: String {
        "journal_\(self.id.uuidString)"
    }
    
    public var analyticsMetadata: [String: Any] {
        [
            "wordCount": self.wordCount,
            "category": self.category.rawValue,
            "mood": self.mood?.rawValue ?? "none",
            "hasAttachments": self.hasAttachments,
            "isPrivate": self.isPrivate,
            "sentimentScore": self.sentimentScore,
            "keyTopicsCount": self.keyTopics.count
        ]
    }
    
    public func trackEvent(_ event: String, parameters: [String: Any]? = nil) {
        var eventParameters = self.analyticsMetadata
        parameters?.forEach { key, value in
            eventParameters[key] = value
        }
        
        print("Tracking event: \(event) for journal entry: \(self.title) with parameters: \(eventParameters)")
    }
    
    // MARK: - Business Logic Methods
    
    @MainActor
    public func updateContent(_ newContent: String) {
        self.content = newContent
        self.wordCount = newContent.components(separatedBy: .whitespacesAndNewlines).count(where: { !$0.isEmpty })
        self.modifiedAt = Date()
        
        // TODO: Implement sentiment analysis
        self.analyzeSentiment()
        
        self.trackEvent("content_updated", parameters: [
            "new_word_count": self.wordCount
        ])
    }
    
    private func analyzeSentiment() {
        // Placeholder for sentiment analysis
        // In a real implementation, this would use NLP libraries or services
        self.sentimentScore = 0.0
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
        self.id = UUID()
        self.fileName = fileName
        self.fileUrl = fileUrl
        self.fileType = fileType
        self.fileSize = fileSize
        self.uploadDate = Date()
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
        return endTime.timeIntervalSince(self.startTime)
    }
    
    public init(task: EnhancedTask, startTime: Date) {
        self.id = UUID()
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
        self.id = UUID()
        self.goal = goal
        self.date = Date()
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
              let rhsIndex = order.firstIndex(of: rhs) else {
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
