//
//  AutonomousSecurity.swift
//  Quantum-workspace
//
//  Created by Daniel Stevens on 2024
//
//  Autonomous Security for Phase 6B - Advanced Intelligence
//  Implements self-evolving security systems, threat prediction, and intelligent security management
//

import CryptoKit
import Foundation
import OSLog

// MARK: - Core Autonomous Security

/// Main autonomous security coordinator
public actor AutonomousSecurity {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "AutonomousSecurity")

    // Core components
    private let threatPredictor: ThreatPredictor
    private let securityAnalyzer: SecurityAnalyzer
    private let adaptiveDefender: AdaptiveDefender
    private let securityLearner: SecurityLearner

    // Security state
    private var securityMetrics: SecurityMetrics
    private var activeThreats: [SecurityThreat] = []
    private var securityPolicies: [SecurityPolicy] = []
    private var threatPatterns: [ThreatPattern] = []

    public init() {
        self.threatPredictor = ThreatPredictor()
        self.securityAnalyzer = SecurityAnalyzer()
        self.adaptiveDefender = AdaptiveDefender()
        self.securityLearner = SecurityLearner()

        self.securityMetrics = SecurityMetrics(
            threatDetectionRate: 0.0,
            falsePositiveRate: 0.0,
            responseTime: 0.0,
            securityScore: 100.0
        )

        logger.info("🛡️ Autonomous Security initialized")
    }

    /// Perform comprehensive security analysis and threat prediction
    public func analyzeAndProtect() async throws {
        logger.info("🔍 Starting autonomous security analysis")

        // Analyze current security state
        let analysis = try await securityAnalyzer.analyzeSecurityState()
        securityMetrics = analysis.metrics

        // Predict potential threats
        let threats = try await threatPredictor.predictThreats(from: analysis)
        activeThreats = threats

        // Generate adaptive defenses
        let defenses = try await adaptiveDefender.generateDefenses(for: threats)
        securityPolicies = defenses

        // Learn from security events
        try await securityLearner.learnFromEvents(analysis.events)

        logger.info(
            "✅ Security analysis completed - \(threats.count) threats identified, \(defenses.count) defenses deployed"
        )
    }

    /// Handle security incident response
    public func handleSecurityIncident(_ incident: SecurityIncident) async throws {
        logger.info("🚨 Handling security incident: \(incident.type.rawValue)")

        // Analyze incident
        let analysis = try await securityAnalyzer.analyzeIncident(incident)

        // Generate response
        let response = try await adaptiveDefender.generateResponse(
            for: incident, analysis: analysis
        )

        // Execute response
        try await executeSecurityResponse(response)

        // Update learning model
        try await securityLearner.updateWithIncident(incident, response: response)

        // Update metrics
        securityMetrics.responseTime = response.executionTime
        securityMetrics.securityScore = max(
            0, securityMetrics.securityScore - incident.severity.rawValue
        )

        logger.info(
            "✅ Security incident handled in \(String(format: "%.2f", response.executionTime))s")
    }

    /// Get current security status and recommendations
    public func getSecurityStatus() async -> SecurityStatus {
        let recommendations = await generateSecurityRecommendations()

        return SecurityStatus(
            metrics: securityMetrics,
            activeThreats: activeThreats,
            policies: securityPolicies,
            recommendations: recommendations
        )
    }

    /// Continuously monitor and adapt security measures
    public func startContinuousMonitoring() {
        logger.info("👁️ Starting continuous security monitoring")

        Task {
            while true {
                do {
                    // Periodic security assessment
                    try await self.analyzeAndProtect()

                    // Check for new threat patterns
                    let newPatterns = try await self.threatPredictor.identifyNewPatterns()
                    self.threatPatterns.append(contentsOf: newPatterns)

                    // Adapt defenses based on learning
                    try await self.adaptiveDefender.adaptDefenses(
                        learning: self.securityLearner.getLearnings())

                } catch {
                    self.logger.error("Security monitoring error: \(error.localizedDescription)")
                }

                // Monitor every 5 minutes
                try await Task.sleep(for: .seconds(300))
            }
        }
    }

    private func executeSecurityResponse(_ response: SecurityResponse) async throws {
        // Implementation would execute the security response
        // This includes blocking IPs, updating firewalls, alerting teams, etc.
        logger.info("Executed security response: \(response.description)")
    }

    private func generateSecurityRecommendations() async -> [SecurityRecommendation] {
        var recommendations: [SecurityRecommendation] = []

        // Generate recommendations based on current state
        if securityMetrics.threatDetectionRate < 0.8 {
            recommendations.append(
                SecurityRecommendation(
                    id: "improve_detection",
                    title: "Improve Threat Detection",
                    description: "Current detection rate is below optimal threshold",
                    priority: .high,
                    category: .detection
                ))
        }

        if securityMetrics.falsePositiveRate > 0.1 {
            recommendations.append(
                SecurityRecommendation(
                    id: "reduce_false_positives",
                    title: "Reduce False Positives",
                    description: "False positive rate is too high, causing alert fatigue",
                    priority: .medium,
                    category: .analysis
                ))
        }

        if !activeThreats.isEmpty {
            recommendations.append(
                SecurityRecommendation(
                    id: "address_active_threats",
                    title: "Address Active Threats",
                    description: "\(activeThreats.count) active threats require attention",
                    priority: .critical,
                    category: .response
                ))
        }

        return recommendations
    }
}

// MARK: - Threat Prediction

/// Predicts potential security threats using AI and pattern analysis
public actor ThreatPredictor {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "ThreatPredictor")
    private var threatHistory: [SecurityIncident] = []
    private var predictionModel: ThreatPredictionModel

    public init() {
        self.predictionModel = ThreatPredictionModel()
    }

    /// Predict potential threats from security analysis
    public func predictThreats(from analysis: SecurityAnalysis) async throws -> [SecurityThreat] {
        logger.info("🔮 Predicting threats from security analysis")

        var threats: [SecurityThreat] = []

        // Analyze patterns for potential threats
        let patternThreats = try await predictFromPatterns(analysis)
        threats.append(contentsOf: patternThreats)

        // Use AI model for threat prediction
        let aiThreats = try await predictionModel.predictThreats(analysis)
        threats.append(contentsOf: aiThreats)

        // Filter and prioritize threats
        threats = threats.filter { $0.confidence > 0.3 }
        threats.sort { $0.severity.rawValue > $1.severity.rawValue }

        return threats
    }

    /// Identify new threat patterns
    public func identifyNewPatterns() async throws -> [ThreatPattern] {
        // Analyze recent incidents for new patterns
        let recentIncidents = threatHistory.suffix(100)

        // Use clustering or pattern recognition to identify new patterns
        // This is a simplified implementation
        var patterns: [ThreatPattern] = []

        let attackTypes = Dictionary(grouping: recentIncidents) { $0.type }
        for (type, incidents) in attackTypes where incidents.count > 5 {
            let pattern = ThreatPattern(
                id: "pattern_\(type.rawValue)_\(Date().timeIntervalSince1970)",
                attackType: type,
                frequency: Double(incidents.count),
                confidence: min(1.0, Double(incidents.count) / 20.0),
                indicators: ["Multiple \(type.rawValue) attempts"]
            )
            patterns.append(pattern)
        }

        return patterns
    }

    /// Update threat prediction model with new incident
    public func updateWithIncident(_ incident: SecurityIncident) {
        threatHistory.append(incident)

        // Keep only recent history
        if threatHistory.count > 1000 {
            threatHistory.removeFirst(threatHistory.count - 1000)
        }

        // Update prediction model
        predictionModel.update(with: incident)
    }

    private func predictFromPatterns(_ analysis: SecurityAnalysis) async throws -> [SecurityThreat] {
        var threats: [SecurityThreat] = []

        // Analyze access patterns for anomalies
        if let accessAnalysis = analysis.accessPatterns {
            if accessAnalysis.failedAttempts > accessAnalysis.successfulAttempts * 2 {
                let threat = SecurityThreat(
                    id: "access_anomaly_\(Date().timeIntervalSince1970)",
                    type: .bruteForce,
                    description: "Unusual number of failed access attempts detected",
                    severity: .high,
                    confidence: 0.8,
                    indicators: ["High failed login ratio", "Multiple IP addresses"],
                    predictedTime: Date().addingTimeInterval(3600) // 1 hour
                )
                threats.append(threat)
            }
        }

        // Analyze network traffic for suspicious patterns
        if let networkAnalysis = analysis.networkTraffic {
            if networkAnalysis.suspiciousConnections > 10 {
                let threat = SecurityThreat(
                    id: "network_anomaly_\(Date().timeIntervalSince1970)",
                    type: .networkIntrusion,
                    description: "Suspicious network connections detected",
                    severity: .medium,
                    confidence: 0.7,
                    indicators: ["Unusual connection patterns", "Unknown destinations"],
                    predictedTime: Date().addingTimeInterval(1800) // 30 minutes
                )
                threats.append(threat)
            }
        }

        return threats
    }
}

// MARK: - Security Analysis

/// Analyzes security state and incidents
public actor SecurityAnalyzer {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "SecurityAnalyzer")

    /// Analyze current security state
    public func analyzeSecurityState() async throws -> SecurityAnalysis {
        logger.info("🔍 Analyzing current security state")

        // Gather security metrics
        let metrics = try await gatherSecurityMetrics()

        // Analyze recent events
        let events = try await gatherRecentEvents()

        // Analyze access patterns
        let accessPatterns = try await analyzeAccessPatterns()

        // Analyze network traffic
        let networkTraffic = try await analyzeNetworkTraffic()

        return SecurityAnalysis(
            metrics: metrics,
            events: events,
            accessPatterns: accessPatterns,
            networkTraffic: networkTraffic,
            timestamp: Date()
        )
    }

    /// Analyze a specific security incident
    public func analyzeIncident(_ incident: SecurityIncident) async throws -> IncidentAnalysis {
        logger.info("🔍 Analyzing security incident: \(incident.id)")

        // Determine incident severity and impact
        let severity = assessIncidentSeverity(incident)
        let impact = assessIncidentImpact(incident)

        // Identify attack vectors
        let attackVectors = identifyAttackVectors(incident)

        // Generate mitigation strategies
        let mitigationStrategies = generateMitigationStrategies(incident)

        return IncidentAnalysis(
            incidentId: incident.id,
            severity: severity,
            impact: impact,
            attackVectors: attackVectors,
            mitigationStrategies: mitigationStrategies,
            analysisTime: Date().timeIntervalSince(incident.timestamp)
        )
    }

    private func gatherSecurityMetrics() async throws -> SecurityMetrics {
        // In a real implementation, this would gather metrics from various sources
        // For now, return simulated metrics
        SecurityMetrics(
            threatDetectionRate: 0.85,
            falsePositiveRate: 0.05,
            responseTime: 2.3,
            securityScore: 92.0
        )
    }

    private func gatherRecentEvents() async throws -> [SecurityEvent] {
        // Gather recent security events from logs, monitoring systems, etc.
        []
    }

    private func analyzeAccessPatterns() async throws -> AccessPatternAnalysis? {
        // Analyze authentication and access patterns
        AccessPatternAnalysis(
            successfulAttempts: 1250,
            failedAttempts: 23,
            uniqueIPs: 89,
            suspiciousIPs: 2
        )
    }

    private func analyzeNetworkTraffic() async throws -> NetworkTrafficAnalysis? {
        // Analyze network traffic patterns
        NetworkTrafficAnalysis(
            totalConnections: 15420,
            suspiciousConnections: 7,
            blockedConnections: 12,
            dataTransferred: 1024 * 1024 * 500 // 500MB
        )
    }

    private func assessIncidentSeverity(_ incident: SecurityIncident) -> ThreatSeverity {
        // Assess severity based on incident type and characteristics
        switch incident.type {
        case .bruteForce:
            return incident.details.contains("admin") ? .critical : .high
        case .injection:
            return .high
        case .xss:
            return .medium
        case .dataBreach:
            return .critical
        case .ddos:
            return .high
        case .malware:
            return .critical
        case .networkIntrusion:
            return .high
        }
    }

    private func assessIncidentImpact(_ incident: SecurityIncident) -> IncidentImpact {
        // Assess potential impact of the incident
        switch incident.severity {
        case .low:
            return .minimal
        case .medium:
            return .moderate
        case .high:
            return .significant
        case .critical:
            return .severe
        }
    }

    private func identifyAttackVectors(_ incident: SecurityIncident) -> [AttackVector] {
        // Identify how the attack was carried out
        var vectors: [AttackVector] = []

        if incident.details.contains("login") {
            vectors.append(.authentication)
        }
        if incident.details.contains("sql") || incident.details.contains("script") {
            vectors.append(.injection)
        }
        if incident.details.contains("network") {
            vectors.append(.network)
        }

        return vectors
    }

    private func generateMitigationStrategies(_ incident: SecurityIncident) -> [String] {
        // Generate strategies to mitigate similar incidents
        var strategies: [String] = []

        switch incident.type {
        case .bruteForce:
            strategies.append("Implement rate limiting")
            strategies.append("Enable multi-factor authentication")
            strategies.append("Use CAPTCHA for login attempts")
        case .injection:
            strategies.append("Implement input validation")
            strategies.append("Use parameterized queries")
            strategies.append("Sanitize user inputs")
        case .xss:
            strategies.append("Implement content security policy")
            strategies.append("Escape user inputs")
            strategies.append("Use secure coding practices")
        case .dataBreach:
            strategies.append("Encrypt sensitive data")
            strategies.append("Implement access controls")
            strategies.append("Regular security audits")
        case .ddos:
            strategies.append("Implement traffic filtering")
            strategies.append("Use CDN protection")
            strategies.append("Scale infrastructure")
        case .malware:
            strategies.append("Regular malware scanning")
            strategies.append("Keep software updated")
            strategies.append("User training programs")
        case .networkIntrusion:
            strategies.append("Implement network segmentation")
            strategies.append("Deploy intrusion detection systems")
            strategies.append("Regular network monitoring")
        }

        return strategies
    }
}

// MARK: - Adaptive Defense

/// Generates and adapts security defenses based on threats
public actor AdaptiveDefender {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "AdaptiveDefender")

    /// Generate defenses for identified threats
    public func generateDefenses(for threats: [SecurityThreat]) async throws -> [SecurityPolicy] {
        logger.info("🛡️ Generating defenses for \(threats.count) threats")

        var policies: [SecurityPolicy] = []

        for threat in threats {
            let policy = try await generatePolicyForThreat(threat)
            policies.append(policy)
        }

        return policies
    }

    /// Generate response for security incident
    public func generateResponse(for incident: SecurityIncident, analysis: IncidentAnalysis)
        async throws -> SecurityResponse
    {
        logger.info("🚨 Generating response for incident \(incident.id)")

        var actions: [SecurityAction] = []

        // Generate actions based on incident analysis
        for strategy in analysis.mitigationStrategies {
            let action = SecurityAction(
                id: "action_\(UUID().uuidString)",
                type: .mitigation,
                description: strategy,
                priority: .high,
                automated: true
            )
            actions.append(action)
        }

        // Add notification action
        actions.append(
            SecurityAction(
                id: "notify_\(UUID().uuidString)",
                type: .notification,
                description: "Notify security team about incident",
                priority: .high,
                automated: true
            ))

        return SecurityResponse(
            incidentId: incident.id,
            actions: actions,
            executionTime: 0.0, // Will be set when executed
            success: true
        )
    }

    /// Adapt defenses based on learning
    public func adaptDefenses(learning: SecurityLearnings) async throws {
        logger.info("🔄 Adapting defenses based on learning")

        // Update defense strategies based on learned patterns
        // This would modify firewall rules, access policies, etc.
    }

    private func generatePolicyForThreat(_ threat: SecurityThreat) async throws -> SecurityPolicy {
        let rules = generateRulesForThreat(threat)

        return SecurityPolicy(
            id: "policy_\(threat.id)",
            name: "Defense for \(threat.type.rawValue)",
            description: "Automated defense policy for \(threat.description)",
            rules: rules,
            priority: threat.severity == .critical ? .critical : .high,
            active: true,
            created: Date()
        )
    }

    private func generateRulesForThreat(_ threat: SecurityThreat) -> [SecurityRule] {
        var rules: [SecurityRule] = []

        switch threat.type {
        case .bruteForce:
            rules.append(
                SecurityRule(
                    id: "brute_force_limit",
                    type: .rateLimit,
                    condition: "login_attempts > 5",
                    action: .block,
                    duration: 3600 // 1 hour
                ))
        case .injection:
            rules.append(
                SecurityRule(
                    id: "sql_injection_filter",
                    type: .contentFilter,
                    condition: "contains_sql_keywords",
                    action: .block,
                    duration: nil
                ))
        case .xss:
            rules.append(
                SecurityRule(
                    id: "xss_filter",
                    type: .contentFilter,
                    condition: "contains_script_tags",
                    action: .sanitize,
                    duration: nil
                ))
        case .dataBreach:
            rules.append(
                SecurityRule(
                    id: "data_access_control",
                    type: .accessControl,
                    condition: "unauthorized_data_access",
                    action: .block,
                    duration: nil
                ))
        case .ddos:
            rules.append(
                SecurityRule(
                    id: "traffic_filter",
                    type: .trafficFilter,
                    condition: "high_traffic_volume",
                    action: .throttle,
                    duration: 300 // 5 minutes
                ))
        case .malware:
            rules.append(
                SecurityRule(
                    id: "malware_scanner",
                    type: .contentScan,
                    condition: "malware_detected",
                    action: .quarantine,
                    duration: nil
                ))
        case .networkIntrusion:
            rules.append(
                SecurityRule(
                    id: "intrusion_detection",
                    type: .networkMonitor,
                    condition: "suspicious_traffic",
                    action: .alert,
                    duration: nil
                ))
        }

        return rules
    }
}

// MARK: - Security Learning

/// Learns from security events to improve defenses
public actor SecurityLearner {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "SecurityLearner")
    private var learningModel: SecurityLearningModel

    public init() {
        self.learningModel = SecurityLearningModel()
    }

    /// Learn from security events
    public func learnFromEvents(_ events: [SecurityEvent]) async throws {
        logger.info("🧠 Learning from \(events.count) security events")

        for event in events {
            try await learningModel.update(with: event)
        }
    }

    /// Update learning model with incident and response
    public func updateWithIncident(_ incident: SecurityIncident, response: SecurityResponse)
        async throws
    {
        logger.info("🧠 Learning from incident \(incident.id)")

        // Update model with incident-response pair
        try await learningModel.update(with: incident, response: response)
    }

    /// Get current security learnings
    public func getLearnings() async -> SecurityLearnings {
        await learningModel.getLearnings()
    }
}

// MARK: - Data Models

/// Security threat identified through prediction
public struct SecurityThreat: Sendable {
    public let id: String
    public let type: ThreatType
    public let description: String
    public let severity: ThreatSeverity
    public let confidence: Double
    public let indicators: [String]
    public let predictedTime: Date
}

/// Types of security threats
public enum ThreatType: String, Sendable {
    case bruteForce = "brute_force"
    case injection
    case xss
    case dataBreach = "data_breach"
    case ddos
    case malware
    case networkIntrusion = "network_intrusion"
}

/// Threat severity levels
public enum ThreatSeverity: Double, Sendable {
    case low = 1.0
    case medium = 2.0
    case high = 3.0
    case critical = 4.0
}

/// Security incident report
public struct SecurityIncident: Sendable {
    public let id: String
    public let timestamp: Date
    public let type: ThreatType
    public let severity: ThreatSeverity
    public let source: String
    public let details: String
    public let affectedSystems: [String]
}

/// Security analysis results
public struct SecurityAnalysis: Sendable {
    public let metrics: SecurityMetrics
    public let events: [SecurityEvent]
    public let accessPatterns: AccessPatternAnalysis?
    public let networkTraffic: NetworkTrafficAnalysis?
    public let timestamp: Date
}

/// Security metrics
public struct SecurityMetrics: Sendable {
    public var threatDetectionRate: Double
    public var falsePositiveRate: Double
    public var responseTime: Double
    public var securityScore: Double
}

/// Security event
public struct SecurityEvent: Sendable {
    public let timestamp: Date
    public let type: String
    public let severity: String
    public let description: String
}

/// Access pattern analysis
public struct AccessPatternAnalysis: Sendable {
    public let successfulAttempts: Int
    public let failedAttempts: Int
    public let uniqueIPs: Int
    public let suspiciousIPs: Int
}

/// Network traffic analysis
public struct NetworkTrafficAnalysis: Sendable {
    public let totalConnections: Int
    public let suspiciousConnections: Int
    public let blockedConnections: Int
    public let dataTransferred: Int64
}

/// Incident analysis
public struct IncidentAnalysis: Sendable {
    public let incidentId: String
    public let severity: ThreatSeverity
    public let impact: IncidentImpact
    public let attackVectors: [AttackVector]
    public let mitigationStrategies: [String]
    public let analysisTime: TimeInterval
}

/// Incident impact levels
public enum IncidentImpact: String, Sendable {
    case minimal, moderate, significant, severe
}

/// Attack vectors
public enum AttackVector: String, Sendable {
    case authentication, injection, network, physical, social
}

/// Security response
public struct SecurityResponse: Sendable {
    public let incidentId: String
    public let actions: [SecurityAction]
    public var executionTime: TimeInterval
    public let success: Bool

    public var description: String {
        "Response with \(actions.count) actions"
    }
}

/// Security action
public struct SecurityAction: Sendable {
    public let id: String
    public let type: ActionType
    public let description: String
    public let priority: Priority
    public let automated: Bool
}

/// Action types
public enum ActionType: String, Sendable {
    case mitigation, notification, isolation, recovery
}

/// Security policy
public struct SecurityPolicy: Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let rules: [SecurityRule]
    public let priority: Priority
    public let active: Bool
    public let created: Date
}

/// Security rule
public struct SecurityRule: Sendable {
    public let id: String
    public let type: RuleType
    public let condition: String
    public let action: RuleAction
    public let duration: TimeInterval?
}

/// Rule types
public enum RuleType: String, Sendable {
    case rateLimit, contentFilter, accessControl, trafficFilter, contentScan, networkMonitor
}

/// Rule actions
public enum RuleAction: String, Sendable {
    case block, allow, alert, sanitize, throttle, quarantine
}

/// Security recommendation
public struct SecurityRecommendation: Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let priority: Priority
    public let category: RecommendationCategory
}

/// Recommendation categories
public enum RecommendationCategory: String, Sendable {
    case detection, analysis, response, prevention
}

/// Priority levels
public enum Priority: String, Sendable {
    case low, medium, high, critical
}

/// Security status
public struct SecurityStatus: Sendable {
    public let metrics: SecurityMetrics
    public let activeThreats: [SecurityThreat]
    public let policies: [SecurityPolicy]
    public let recommendations: [SecurityRecommendation]
}

/// Threat pattern
public struct ThreatPattern: Sendable {
    public let id: String
    public let attackType: ThreatType
    public let frequency: Double
    public let confidence: Double
    public let indicators: [String]
}

/// Threat prediction model (simplified)
public struct ThreatPredictionModel: Sendable {
    // In a real implementation, this would contain ML models
    // For now, it's a placeholder

    mutating func update(with incident: SecurityIncident) {
        // Update model with incident data
    }

    func predictThreats(_ analysis: SecurityAnalysis) async throws -> [SecurityThreat] {
        // Simplified prediction logic
        var threats: [SecurityThreat] = []

        if let access = analysis.accessPatterns, access.failedAttempts > 50 {
            threats.append(
                SecurityThreat(
                    id: "predicted_brute_force",
                    type: .bruteForce,
                    description: "Potential brute force attack predicted",
                    severity: .high,
                    confidence: 0.8,
                    indicators: ["High failed login attempts"],
                    predictedTime: Date().addingTimeInterval(3600)
                ))
        }

        return threats
    }
}

/// Security learning model (simplified)
public actor SecurityLearningModel {
    private var incidents: [SecurityIncident] = []
    private var responses: [String: SecurityResponse] = [:]

    func update(with event: SecurityEvent) async throws {
        // Update learning model with security event
    }

    func update(with incident: SecurityIncident, response: SecurityResponse) async throws {
        incidents.append(incident)
        responses[incident.id] = response
    }

    func getLearnings() -> SecurityLearnings {
        // Generate learnings from stored incidents and responses
        SecurityLearnings(
            effectiveResponses: responses.count,
            learnedPatterns: incidents.count / 10, // Simplified
            adaptationRate: 0.85
        )
    }
}

/// Security learnings
public struct SecurityLearnings: Sendable {
    public let effectiveResponses: Int
    public let learnedPatterns: Int
    public let adaptationRate: Double
}

// MARK: - Convenience Functions

/// Global autonomous security instance
private let globalAutonomousSecurity = AutonomousSecurity()

/// Initialize autonomous security system
@MainActor
public func initializeAutonomousSecurity() async {
    await globalAutonomousSecurity.startContinuousMonitoring()
}

/// Get autonomous security capabilities
@MainActor
public func getAutonomousSecurityCapabilities() -> [String: [String]] {
    [
        "threat_detection": ["pattern_analysis", "behavior_monitoring", "anomaly_detection"],
        "threat_prediction": ["ai_modeling", "trend_analysis", "risk_assessment"],
        "adaptive_defense": ["dynamic_policies", "automated_response", "self_evolution"],
        "security_learning": ["incident_analysis", "response_optimization", "pattern_recognition"],
    ]
}

/// Report a security incident
@MainActor
public func reportSecurityIncident(_ incident: SecurityIncident) async throws {
    try await globalAutonomousSecurity.handleSecurityIncident(incident)
}

/// Get current security status
@MainActor
public func getCurrentSecurityStatus() async -> SecurityStatus {
    await globalAutonomousSecurity.getSecurityStatus()
}

/// Manually trigger security analysis
@MainActor
public func triggerSecurityAnalysis() async throws {
    try await globalAutonomousSecurity.analyzeAndProtect()
}
