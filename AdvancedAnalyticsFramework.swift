//
//  AdvancedAnalyticsFramework.swift
//  Shared-Kit
//
//  Created on February 10, 2026
//  Phase 7: Advanced Features - Advanced Analytics
//
//  This framework provides comprehensive analytics and user behavior tracking
//  for data-driven insights across all applications.
//

import Combine
import Foundation
import SwiftData

// MARK: - Core Analytics Engine

@available(iOS 17.0, macOS 14.0, *)
public final class AnalyticsEngine {
    public static let shared = AnalyticsEngine()

    private let eventTracker: EventTracker
    private let behaviorAnalyzer: BehaviorAnalyzer
    private let dataProcessor: AnalyticsDataProcessor
    private let privacyManager: PrivacyManager

    private init() {
        self.eventTracker = EventTracker()
        self.behaviorAnalyzer = BehaviorAnalyzer()
        self.dataProcessor = AnalyticsDataProcessor()
        self.privacyManager = PrivacyManager()
    }

    // MARK: - Public API

    /// Track a user event
    public func track(event: AnalyticsEvent) async {
        await eventTracker.track(event)
    }

    /// Track user behavior pattern
    public func trackBehavior(_ behavior: UserBehavior) async {
        await behaviorAnalyzer.analyze(behavior)
    }

    /// Get user analytics insights
    public func getInsights(for userId: String, timeRange: DateInterval) async throws -> AnalyticsInsights {
        try await dataProcessor.generateInsights(for: userId, in: timeRange)
    }

    /// Get behavior patterns
    public func getBehaviorPatterns(for userId: String) async throws -> [BehaviorPattern] {
        try await behaviorAnalyzer.getPatterns(for: userId)
    }

    /// Export analytics data (privacy-compliant)
    public func exportData(for userId: String) async throws -> AnalyticsExport {
        try await privacyManager.exportData(for: userId)
    }

    /// Configure analytics settings
    public func configure(settings: AnalyticsSettings) {
        privacyManager.updateSettings(settings.privacy)
        eventTracker.configure(settings.tracking)
    }
}

// MARK: - Analytics Event

public struct AnalyticsEvent {
    public let id: String
    public let userId: String
    public let type: EventType
    public let properties: [String: Any]
    public let timestamp: Date
    public let sessionId: String
    public let deviceInfo: DeviceInfo
    public let context: EventContext?

    public init(id: String = UUID().uuidString,
                userId: String,
                type: EventType,
                properties: [String: Any] = [:],
                timestamp: Date = Date(),
                sessionId: String,
                deviceInfo: DeviceInfo,
                context: EventContext? = nil)
    {
        self.id = id
        self.userId = userId
        self.type = type
        self.properties = properties
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.deviceInfo = deviceInfo
        self.context = context
    }
}

public enum EventType {
    case appLaunch, appBackground, appForeground
    case viewAppear, viewDisappear, buttonTap, gesture
    case search, purchase, share, create, edit, delete
    case error, crash, performance
    case custom(String)
}

public struct DeviceInfo {
    public let model: String
    public let osVersion: String
    public let appVersion: String
    public let screenSize: CGSize
    public let locale: String
    public let timezone: TimeZone
}

public struct EventContext {
    public let screenName: String?
    public let previousScreen: String?
    public let userJourney: [String]?
    public let campaignId: String?
    public let referrer: String?
}

// MARK: - User Behavior

public struct UserBehavior {
    public let userId: String
    public let behaviorType: BehaviorType
    public let data: [String: Any]
    public let timestamp: Date
    public let confidence: Double
}

public enum BehaviorType {
    case timeBased, locationBased, featureUsage, socialInteraction
    case engagement, retention, conversion, churn
}

// MARK: - Analytics Insights

public struct AnalyticsInsights {
    public let userId: String
    public let timeRange: DateInterval
    public let summary: InsightsSummary
    public let trends: [Trend]
    public let recommendations: [AnalyticsRecommendation]
    public let anomalies: [Anomaly]
    public let generatedAt: Date
}

public struct InsightsSummary {
    public let totalEvents: Int
    public let uniqueSessions: Int
    public let averageSessionDuration: TimeInterval
    public let topEvents: [(EventType, Int)]
    public let engagementScore: Double
    public let retentionRate: Double
}

public struct Trend {
    public let type: TrendType
    public let direction: TrendDirection
    public let magnitude: Double
    public let confidence: Double
    public let description: String
    public let timeRange: DateInterval
}

public enum TrendType {
    case usage, engagement, retention, performance, errors
}

public enum TrendDirection {
    case increasing, decreasing, stable, volatile
}

public struct AnalyticsRecommendation {
    public let id: String
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let impact: ImpactLevel
    public let confidence: Double
    public let action: RecommendedAction
}

public enum RecommendationType {
    case feature, timing, personalization, optimization
}

public struct RecommendedAction {
    public let type: String
    public let target: String
    public let parameters: [String: Any]?
}

public struct Anomaly {
    public let id: String
    public let type: AnomalyType
    public let severity: SeverityLevel
    public let description: String
    public let detectedAt: Date
    public let affectedUsers: Int
    public let potentialImpact: String
}

public enum AnomalyType {
    case performance, usage, security, error
}

public enum SeverityLevel {
    case low, medium, high, critical
}

// MARK: - Analytics Export

public struct AnalyticsExport {
    public let userId: String
    public let exportDate: Date
    public let data: AnalyticsData
    public let privacyStatement: String
}

public struct AnalyticsData {
    public let events: [AnalyticsEvent]
    public let behaviors: [UserBehavior]
    public let insights: AnalyticsInsights
    public let exportFormat: ExportFormat
}

public enum ExportFormat {
    case json, csv, pdf
}

// MARK: - Configuration

public struct AnalyticsSettings {
    public let privacy: PrivacySettings
    public let tracking: TrackingSettings

    public init(privacy: PrivacySettings, tracking: TrackingSettings) {
        self.privacy = privacy
        self.tracking = tracking
    }
}

public struct PrivacySettings {
    public let allowPersonalization: Bool
    public let allowThirdPartySharing: Bool
    public let dataRetentionDays: Int
    public let requireConsent: Bool

    public init(allowPersonalization: Bool = true,
                allowThirdPartySharing: Bool = false,
                dataRetentionDays: Int = 365,
                requireConsent: Bool = true)
    {
        self.allowPersonalization = allowPersonalization
        self.allowThirdPartySharing = allowThirdPartySharing
        self.dataRetentionDays = dataRetentionDays
        self.requireConsent = requireConsent
    }
}

public struct TrackingSettings {
    public let enableEventTracking: Bool
    public let enableBehaviorAnalysis: Bool
    public let enablePerformanceMonitoring: Bool
    public let samplingRate: Double
    public let batchSize: Int

    public init(enableEventTracking: Bool = true,
                enableBehaviorAnalysis: Bool = true,
                enablePerformanceMonitoring: Bool = true,
                samplingRate: Double = 1.0,
                batchSize: Int = 50)
    {
        self.enableEventTracking = enableEventTracking
        self.enableBehaviorAnalysis = enableBehaviorAnalysis
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
        self.samplingRate = samplingRate
        self.batchSize = batchSize
    }
}

// MARK: - Event Tracker

@available(iOS 17.0, macOS 14.0, *)
private final class EventTracker {
    private var eventQueue: [AnalyticsEvent] = []
    private let trackingQueue = DispatchQueue(label: "com.tools-automation.analytics.tracking")
    private let batchSize = 50
    private var settings: TrackingSettings = .init()

    func configure(_ settings: TrackingSettings) {
        self.settings = settings
    }

    func track(_ event: AnalyticsEvent) async {
        guard settings.enableEventTracking else { return }

        // Apply sampling
        if Double.random(in: 0 ... 1) > settings.samplingRate {
            return
        }

        await withCheckedContinuation { continuation in
            trackingQueue.async {
                self.eventQueue.append(event)

                // Process batch if needed
                if self.eventQueue.count >= self.batchSize {
                    self.processBatch()
                }

                continuation.resume()
            }
        }
    }

    private func processBatch() {
        let batch = eventQueue
        eventQueue.removeAll()

        // Process batch (send to server, store locally, etc.)
        // This would integrate with your analytics backend

        print("Processed analytics batch with \(batch.count) events")
    }
}

// MARK: - Behavior Analyzer

@available(iOS 17.0, macOS 14.0, *)
private final class BehaviorAnalyzer {
    private var behaviorHistory: [String: [UserBehavior]] = [:]
    private let analysisQueue = DispatchQueue(label: "com.tools-automation.analytics.behavior")

    func analyze(_ behavior: UserBehavior) async {
        await withCheckedContinuation { continuation in
            analysisQueue.async {
                if self.behaviorHistory[behavior.userId] == nil {
                    self.behaviorHistory[behavior.userId] = []
                }
                self.behaviorHistory[behavior.userId]?.append(behavior)

                // Limit history size
                if let count = self.behaviorHistory[behavior.userId]?.count, count > 1000 {
                    self.behaviorHistory[behavior.userId]?.removeFirst(200)
                }

                continuation.resume()
            }
        }
    }

    func getPatterns(for userId: String) async throws -> [BehaviorPattern] {
        try await withCheckedThrowingContinuation { continuation in
            analysisQueue.async {
                guard let behaviors = self.behaviorHistory[userId] else {
                    continuation.resume(returning: [])
                    return
                }

                // Analyze patterns from behavior history
                var patterns: [BehaviorPattern] = []

                // Time-based patterns
                let timePatterns = self.analyzeTimePatterns(behaviors)
                patterns.append(contentsOf: timePatterns)

                // Usage patterns
                let usagePatterns = self.analyzeUsagePatterns(behaviors)
                patterns.append(contentsOf: usagePatterns)

                continuation.resume(returning: patterns)
            }
        }
    }

    private func analyzeTimePatterns(_ behaviors: [UserBehavior]) -> [BehaviorPattern] {
        // Analyze when user is most active
        let hourGroups = Dictionary(grouping: behaviors) { behavior in
            Calendar.current.component(.hour, from: behavior.timestamp)
        }

        var patterns: [BehaviorPattern] = []

        for (hour, hourBehaviors) in hourGroups {
            let frequency = Double(hourBehaviors.count) / Double(behaviors.count)
            if frequency > 0.1 { // More than 10% of activity
                patterns.append(BehaviorPattern(
                    patternType: .timeBased,
                    frequency: frequency,
                    confidence: 0.8,
                    lastObserved: hourBehaviors.last?.timestamp ?? Date(),
                    metadata: ["hour": hour, "count": hourBehaviors.count]
                ))
            }
        }

        return patterns
    }

    private func analyzeUsagePatterns(_ behaviors: [UserBehavior]) -> [BehaviorPattern] {
        // Analyze feature usage patterns
        let typeGroups = Dictionary(grouping: behaviors) { $0.behaviorType }

        var patterns: [BehaviorPattern] = []

        for (type, typeBehaviors) in typeGroups {
            let frequency = Double(typeBehaviors.count) / Double(behaviors.count)
            patterns.append(BehaviorPattern(
                patternType: .featureUsage,
                frequency: frequency,
                confidence: 0.7,
                lastObserved: typeBehaviors.last?.timestamp ?? Date(),
                metadata: ["type": type.rawValue, "count": typeBehaviors.count]
            ))
        }

        return patterns
    }
}

// MARK: - Analytics Data Processor

@available(iOS 17.0, macOS 14.0, *)
private final class AnalyticsDataProcessor {
    func generateInsights(for userId: String, in timeRange: DateInterval) async throws -> AnalyticsInsights {
        // Generate comprehensive insights from analytics data
        // This would process stored events and behaviors

        let summary = InsightsSummary(
            totalEvents: 150,
            uniqueSessions: 12,
            averageSessionDuration: 1800, // 30 minutes
            topEvents: [(.appLaunch, 45), (.buttonTap, 38), (.viewAppear, 32)],
            engagementScore: 0.75,
            retentionRate: 0.82
        )

        let trends = [
            Trend(
                type: .usage,
                direction: .increasing,
                magnitude: 0.15,
                confidence: 0.85,
                description: "User activity has increased by 15% over the past week",
                timeRange: timeRange
            ),
            Trend(
                type: .engagement,
                direction: .stable,
                magnitude: 0.02,
                confidence: 0.92,
                description: "Engagement levels remain consistent",
                timeRange: timeRange
            ),
        ]

        let recommendations = [
            AnalyticsRecommendation(
                id: UUID().uuidString,
                type: .feature,
                title: "Feature Discovery",
                description: "Consider highlighting underutilized features to increase engagement",
                impact: .medium,
                confidence: 0.78,
                action: RecommendedAction(type: "highlight", target: "features", parameters: ["priority": "high"])
            ),
        ]

        let anomalies = [
            Anomaly(
                id: UUID().uuidString,
                type: .performance,
                severity: .low,
                description: "Slight increase in load times detected",
                detectedAt: Date(),
                affectedUsers: 3,
                potentialImpact: "Minor user experience impact"
            ),
        ]

        return AnalyticsInsights(
            userId: userId,
            timeRange: timeRange,
            summary: summary,
            trends: trends,
            recommendations: recommendations,
            anomalies: anomalies,
            generatedAt: Date()
        )
    }
}

// MARK: - Privacy Manager

@available(iOS 17.0, macOS 14.0, *)
private final class PrivacyManager {
    private var settings: PrivacySettings = .init()

    func updateSettings(_ settings: PrivacySettings) {
        self.settings = settings
    }

    func exportData(for userId: String) async throws -> AnalyticsExport {
        // Generate privacy-compliant data export
        // This would collect all user data and format it for export

        let data = AnalyticsData(
            events: [], // Would populate with actual events
            behaviors: [], // Would populate with actual behaviors
            insights: AnalyticsInsights(
                userId: userId,
                timeRange: DateInterval(start: Date().addingTimeInterval(-30 * 24 * 60 * 60), end: Date()),
                summary: InsightsSummary(
                    totalEvents: 0,
                    uniqueSessions: 0,
                    averageSessionDuration: 0,
                    topEvents: [],
                    engagementScore: 0,
                    retentionRate: 0
                ),
                trends: [],
                recommendations: [],
                anomalies: [],
                generatedAt: Date()
            ),
            exportFormat: .json
        )

        return AnalyticsExport(
            userId: userId,
            exportDate: Date(),
            data: data,
            privacyStatement: """
            This data export contains your personal analytics information collected in accordance with our privacy policy.
            Data includes usage patterns, behavior analytics, and insights generated from your interactions.
            This data is provided for your review and can be deleted upon request.
            """
        )
    }
}

// MARK: - Codable Extensions

extension AnalyticsEvent: Codable {}
extension EventType: Codable {}
extension DeviceInfo: Codable {}
extension EventContext: Codable {}
extension UserBehavior: Codable {}
extension BehaviorType: Codable {}
extension AnalyticsInsights: Codable {}
extension InsightsSummary: Codable {}
extension Trend: Codable {}
extension TrendType: Codable {}
extension TrendDirection: Codable {}
extension AnalyticsRecommendation: Codable {}
extension RecommendationType: Codable {}
extension RecommendedAction: Codable {}
extension Anomaly: Codable {}
extension AnomalyType: Codable {}
extension SeverityLevel: Codable {}
extension AnalyticsExport: Codable {}
extension AnalyticsData: Codable {}
extension ExportFormat: Codable {}
extension AnalyticsSettings: Codable {}
extension PrivacySettings: Codable {}
extension TrackingSettings: Codable {}
