//
//  EnhancedEducationSupport.swift
//  SharedKitCore
//

import Foundation
import SwiftData

public enum CourseDifficulty: String, CaseIterable, Codable {
    case beginner
    case intermediate
    case advanced
    case expert
}

public enum LearningStyle: String, CaseIterable, Codable {
    case visual
    case auditory
    case reading
    case kinesthetic
    case adaptive
}

public enum ContentType: String, CaseIterable, Codable {
    case video
    case interactive
    case quiz
    case reading
    case simulation
}

@Model
public final class EnhancedEducationCourse {
    public var id: UUID
    public var title: String
    public var subject: String
    public var difficulty: CourseDifficulty
    public var duration: TimeInterval
    public var prerequisites: [UUID]
    public var creationDate: Date

    public var educationSystem: EnhancedQuantumEducationSystem?

    @Relationship(deleteRule: .cascade, inverse: \EnhancedLearningModule.course)
    public var modules: [EnhancedLearningModule] = []

    public init(
        educationSystem: EnhancedQuantumEducationSystem,
        title: String,
        subject: String,
        difficulty: CourseDifficulty,
        duration: TimeInterval,
        prerequisites: [UUID] = []
    ) {
        self.id = UUID()
        self.educationSystem = educationSystem
        self.title = title
        self.subject = subject
        self.difficulty = difficulty
        self.duration = duration
        self.prerequisites = prerequisites
        self.creationDate = Date()
    }
}

@Model
public final class EnhancedLearningModule {
    public var id: UUID
    public var title: String
    public var courseId: UUID
    public var contentType: ContentType
    public var adaptiveDifficulty: Bool
    public var completionRate: Double

    public var educationSystem: EnhancedQuantumEducationSystem?
    public var course: EnhancedEducationCourse?

    public init(
        educationSystem: EnhancedQuantumEducationSystem,
        title: String,
        courseId: UUID,
        contentType: ContentType,
        adaptiveDifficulty: Bool = true
    ) {
        self.id = UUID()
        self.educationSystem = educationSystem
        self.title = title
        self.courseId = courseId
        self.contentType = contentType
        self.adaptiveDifficulty = adaptiveDifficulty
        self.completionRate = 0.0
    }
}

@Model
public final class EnhancedStudentProfile {
    public var id: UUID
    public var studentId: String
    public var courseIds: [UUID]
    public var learningStyle: LearningStyle
    public var priorKnowledge: Double
    public var overallProgress: Double
    public var averageEngagement: Double
    public var satisfaction: Double

    public var educationSystem: EnhancedQuantumEducationSystem?

    public init(
        educationSystem: EnhancedQuantumEducationSystem,
        studentId: String,
        courseIds: [UUID],
        learningStyle: LearningStyle,
        priorKnowledge: Double
    ) {
        self.id = UUID()
        self.educationSystem = educationSystem
        self.studentId = studentId
        self.courseIds = courseIds
        self.learningStyle = learningStyle
        self.priorKnowledge = priorKnowledge
        self.overallProgress = 0.0
        self.averageEngagement = 0.0
        self.satisfaction = 0.0
    }

    @MainActor
    public func updateProgress(
        courseId: UUID, progress: Double, comprehension: Double, engagement: Double
    ) {
        // Simple mock logic for progress update
        self.overallProgress = (self.overallProgress + progress) / 2.0
        self.averageEngagement = (self.averageEngagement + engagement) / 2.0
        self.satisfaction = min(1.0, comprehension * engagement * 1.2)
    }
}

@Model
public final class EnhancedEducatorProfile {
    public var id: UUID
    public var educatorId: String
    public var specializations: [String]
    public var experience: Double
    public var aiProficiency: Double
    public var rating: Double

    public var educationSystem: EnhancedQuantumEducationSystem?

    public init(
        educationSystem: EnhancedQuantumEducationSystem,
        educatorId: String,
        specializations: [String],
        experience: Double,
        aiProficiency: Double
    ) {
        self.id = UUID()
        self.educationSystem = educationSystem
        self.educatorId = educatorId
        self.specializations = specializations
        self.experience = experience
        self.aiProficiency = aiProficiency
        self.rating = 5.0
    }
}

@Model
public final class EnhancedEducationMetric {
    public var id: UUID
    public var metricName: String
    public var value: Double
    public var unit: String
    public var targetValue: Double?
    public var category: String
    public var timestamp: Date

    public var educationSystem: EnhancedQuantumEducationSystem?

    public init(
        educationSystem: EnhancedQuantumEducationSystem,
        metricName: String,
        value: Double,
        unit: String,
        targetValue: Double?,
        category: String
    ) {
        self.id = UUID()
        self.educationSystem = educationSystem
        self.metricName = metricName
        self.value = value
        self.unit = unit
        self.targetValue = targetValue
        self.category = category
        self.timestamp = Date()
    }
}
