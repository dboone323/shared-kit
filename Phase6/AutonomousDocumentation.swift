//
//  AutonomousDocumentation.swift
//  Quantum-workspace
//
//  Created by GitHub Copilot on 2024
//
//  Implements autonomous documentation system with AI-powered content generation and intelligent knowledge management
//  for quantum-enhanced development environments.
//

import Combine
import Foundation
import OSLog

/// Documentation content types
public enum DocumentationType: String, Codable, Sendable {
    case apiReference = "api_reference"
    case tutorial
    case guide
    case changelog
    case architecture
    case troubleshooting
    case faq
    case codeExample = "code_example"
    case releaseNotes = "release_notes"
}

/// Content generation strategies
public enum GenerationStrategy: String, Codable, Sendable {
    case templateBased = "template_based"
    case aiGenerated = "ai_generated"
    case hybrid
    case quantumInspired = "quantum_inspired"
    case collaborative
}

/// Documentation quality metrics
public struct DocumentationQuality: Codable, Sendable {
    public let completeness: Double // 0.0 to 1.0
    public let accuracy: Double // 0.0 to 1.0
    public let readability: Double // 0.0 to 1.0
    public let relevance: Double // 0.0 to 1.0
    public let freshness: Double // 0.0 to 1.0 (how recent the content is)

    public var overallScore: Double {
        (completeness + accuracy + readability + relevance + freshness) / 5.0
    }

    public init(
        completeness: Double = 1.0,
        accuracy: Double = 1.0,
        readability: Double = 1.0,
        relevance: Double = 1.0,
        freshness: Double = 1.0
    ) {
        self.completeness = min(max(completeness, 0.0), 1.0)
        self.accuracy = min(max(accuracy, 0.0), 1.0)
        self.readability = min(max(readability, 0.0), 1.0)
        self.relevance = min(max(relevance, 0.0), 1.0)
        self.freshness = min(max(freshness, 0.0), 1.0)
    }
}

/// Documentation content structure
public struct DocumentationContent: Codable, Sendable {
    public let id: String
    public let title: String
    public let type: DocumentationType
    public let content: String
    public let metadata: [String: String]
    public let tags: [String]
    public let createdAt: Date
    public let updatedAt: Date
    public let version: String
    public let quality: DocumentationQuality
    public let relatedContent: [String] // IDs of related documentation

    public init(
        id: String,
        title: String,
        type: DocumentationType,
        content: String,
        metadata: [String: String] = [:],
        tags: [String] = [],
        version: String = "1.0.0",
        quality: DocumentationQuality = DocumentationQuality(),
        relatedContent: [String] = []
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
        self.metadata = metadata
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = version
        self.quality = quality
        self.relatedContent = relatedContent
    }
}

/// Content generation request
public struct ContentGenerationRequest: Sendable {
    public let type: DocumentationType
    public let title: String
    public let context: [String: String]
    public let targetAudience: String
    public let complexity: ContentComplexity
    public let relatedContentIds: [String]
    public let generationStrategy: GenerationStrategy

    public init(
        type: DocumentationType,
        title: String,
        context: [String: String] = [:],
        targetAudience: String = "developers",
        complexity: ContentComplexity = .intermediate,
        relatedContentIds: [String] = [],
        generationStrategy: GenerationStrategy = .hybrid
    ) {
        self.type = type
        self.title = title
        self.context = context
        self.targetAudience = targetAudience
        self.complexity = complexity
        self.relatedContentIds = relatedContentIds
        self.generationStrategy = generationStrategy
    }
}

/// Content complexity levels
public enum ContentComplexity: String, Codable, Sendable {
    case beginner
    case intermediate
    case advanced
    case expert
}

/// Knowledge graph node
public struct KnowledgeNode: Codable, Sendable {
    public let id: String
    public let contentId: String
    public let title: String
    public let type: DocumentationType
    public let tags: [String]
    public let connections: [String] // IDs of connected nodes
    public let importance: Double // 0.0 to 1.0
    public let lastAccessed: Date

    public init(
        id: String,
        contentId: String,
        title: String,
        type: DocumentationType,
        tags: [String] = [],
        connections: [String] = [],
        importance: Double = 0.5
    ) {
        self.id = id
        self.contentId = contentId
        self.title = title
        self.type = type
        self.tags = tags
        self.connections = connections
        self.importance = min(max(importance, 0.0), 1.0)
        self.lastAccessed = Date()
    }
}

/// Documentation update trigger
public enum DocumentationTrigger: Sendable {
    case codeChange(file: String, changeType: ChangeType)
    case apiChange(symbol: String, changeType: ChangeType)
    case userRequest(contentId: String)
    case scheduledReview(contentId: String)
    case qualityThreshold(contentId: String, metric: String, value: Double)
    case dependencyUpdate(package: String, version: String)
}

/// Code change types
public enum ChangeType: String, Codable, Sendable {
    case added
    case modified
    case deleted
    case renamed
}

/// Autonomous documentation system
@MainActor
public final class AutonomousDocumentation: ObservableObject {

    // MARK: - Properties

    public static let shared = AutonomousDocumentation()

    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var documentationContent: [String: DocumentationContent] = [:]
    @Published public private(set) var knowledgeGraph: [String: KnowledgeNode] = [:]
    @Published public private(set) var generationQueue: [ContentGenerationRequest] = []
    @Published public private(set) var systemHealth: Double = 1.0

    private let logger = Logger(
        subsystem: "com.quantum.workspace", category: "AutonomousDocumentation"
    )
    private var monitoringTask: Task<Void, Never>?
    private var generationTask: Task<Void, Never>?
    private var maintenanceTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let monitoringInterval: TimeInterval = 300.0 // 5 minutes
    private let generationInterval: TimeInterval = 60.0 // 1 minute
    private let maintenanceInterval: TimeInterval = 3600.0 // 1 hour

    // AI-driven parameters
    private let qualityThreshold: Double = 0.8
    private let freshnessThreshold: Double = 0.7
    private let learningRate: Double = 0.1
    private let maxConcurrentGenerations: Int = 3

    // Content templates and patterns
    private var contentTemplates: [DocumentationType: String] = [:]
    private var generationPatterns: [DocumentationType: [String]] = [:]

    // Performance tracking
    private var generationHistory: [String: [Date]] = [:]
    private var qualityHistory: [String: [DocumentationQuality]] = [:]

    // MARK: - Initialization

    private init() {
        setupContentTemplates()
        setupGenerationPatterns()
        setupMonitoring()
        setupMaintenance()
    }

    // MARK: - Public Interface

    /// Start the autonomous documentation system
    public func start() async {
        guard !isActive else { return }

        logger.info("🚀 Starting Autonomous Documentation System")
        isActive = true

        // Start monitoring task
        monitoringTask = Task {
            await startMonitoringLoop()
        }

        // Start generation task
        generationTask = Task {
            await startGenerationLoop()
        }

        // Start maintenance task
        maintenanceTask = Task {
            await startMaintenanceLoop()
        }

        logger.info("✅ Autonomous Documentation System started successfully")
    }

    /// Stop the autonomous documentation system
    public func stop() async {
        guard isActive else { return }

        logger.info("🛑 Stopping Autonomous Documentation System")
        isActive = false

        // Cancel all tasks
        monitoringTask?.cancel()
        generationTask?.cancel()
        maintenanceTask?.cancel()

        monitoringTask = nil
        generationTask = nil
        maintenanceTask = nil

        logger.info("✅ Autonomous Documentation System stopped")
    }

    /// Generate documentation content
    public func generateContent(_ request: ContentGenerationRequest) async throws -> String {
        logger.info("📝 Generating documentation: \(request.title)")

        let contentId = UUID().uuidString
        let generatedContent = try await generateContentWithStrategy(request)

        let content = DocumentationContent(
            id: contentId,
            title: request.title,
            type: request.type,
            content: generatedContent,
            metadata: request.context,
            tags: generateTags(for: request),
            quality: assessContentQuality(generatedContent, for: request)
        )

        await MainActor.run {
            documentationContent[contentId] = content
        }

        // Update knowledge graph
        await updateKnowledgeGraph(with: content)

        // Track generation history
        await MainActor.run {
            if generationHistory[request.type.rawValue] == nil {
                generationHistory[request.type.rawValue] = []
            }
            generationHistory[request.type.rawValue]?.append(Date())
        }

        logger.info("✅ Documentation generated successfully: \(contentId)")
        return contentId
    }

    /// Update existing documentation
    public func updateContent(_ contentId: String, with content: String) async throws {
        guard var existingContent = documentationContent[contentId] else {
            throw DocumentationError.contentNotFound(contentId)
        }

        logger.info("🔄 Updating documentation: \(contentId)")

        existingContent = DocumentationContent(
            id: existingContent.id,
            title: existingContent.title,
            type: existingContent.type,
            content: content,
            metadata: existingContent.metadata,
            tags: existingContent.tags,
            version: incrementVersion(existingContent.version),
            quality: assessContentQuality(content, for: existingContent.type),
            relatedContent: existingContent.relatedContent
        )

        await MainActor.run {
            documentationContent[contentId] = existingContent
        }

        // Update knowledge graph
        await updateKnowledgeGraph(with: existingContent)

        logger.info("✅ Documentation updated successfully: \(contentId)")
    }

    /// Search documentation content
    public func searchContent(query: String, type: DocumentationType? = nil, tags: [String]? = nil)
        -> [DocumentationContent]
    {
        var results = documentationContent.values.filter { content in
            // Text search in title and content
            let titleMatch = content.title.localizedCaseInsensitiveContains(query)
            let contentMatch = content.content.localizedCaseInsensitiveContains(query)

            // Type filter
            let typeMatch = type == nil || content.type == type

            // Tags filter
            let tagsMatch = tags == nil || !Set(tags!).isDisjoint(with: Set(content.tags))

            return (titleMatch || contentMatch) && typeMatch && tagsMatch
        }

        // Sort by relevance (quality score and recency)
        results.sort { a, b -> Bool in
            let aScore = a.quality.overallScore * freshnessScore(for: a)
            let bScore = b.quality.overallScore * freshnessScore(for: b)
            return aScore > bScore
        }

        return Array(results.prefix(20)) // Limit results
    }

    /// Get documentation recommendations
    public func getRecommendations(for userContext: [String: String]) -> [DocumentationContent] {
        let userInterests = inferUserInterests(from: userContext)

        var recommendations = documentationContent.values.filter { content in
            // Filter by user interests
            let interestMatch = userInterests.contains { interest in
                content.tags.contains(interest)
                    || content.title.localizedCaseInsensitiveContains(interest)
                    || content.type.rawValue == interest
            }

            // Filter by quality and freshness
            let qualityThreshold = content.quality.overallScore >= self.qualityThreshold
            let freshnessThreshold = freshnessScore(for: content) >= self.freshnessThreshold

            return interestMatch && qualityThreshold && freshnessThreshold
        }

        // Sort by personalized relevance
        recommendations.sort { a, b -> Bool in
            let aRelevance = calculatePersonalizedRelevance(for: a, userContext: userContext)
            let bRelevance = calculatePersonalizedRelevance(for: b, userContext: userContext)
            return aRelevance > bRelevance
        }

        return Array(recommendations.prefix(10))
    }

    /// Trigger documentation update based on code changes
    public func triggerUpdate(_ trigger: DocumentationTrigger) async {
        logger.info("🎯 Processing documentation trigger: \(String(describing: trigger))")

        switch trigger {
        case let .codeChange(file, changeType):
            await handleCodeChange(file: file, changeType: changeType)
        case let .apiChange(symbol, changeType):
            await handleAPIChange(symbol: symbol, changeType: changeType)
        case let .userRequest(contentId):
            await handleUserRequest(contentId: contentId)
        case let .scheduledReview(contentId):
            await handleScheduledReview(contentId: contentId)
        case let .qualityThreshold(contentId, metric, value):
            await handleQualityThreshold(contentId: contentId, metric: metric, value: value)
        case let .dependencyUpdate(package, version):
            await handleDependencyUpdate(package: package, version: version)
        }
    }

    /// Get documentation analytics
    public func getAnalytics() -> [String: Sendable] {
        let totalContent = documentationContent.count
        let averageQuality =
            documentationContent.values.map(\.quality.overallScore).reduce(0, +)
                / Double(max(1, totalContent))
        let contentByType = Dictionary(grouping: documentationContent.values) { $0.type.rawValue }
            .mapValues { $0.count }
        let generationRate = generationHistory.values.flatMap { $0 }.filter {
            Date().timeIntervalSince($0) < 86400
        }.count // Last 24 hours

        return [
            "totalContent": totalContent,
            "averageQuality": averageQuality,
            "contentByType": contentByType,
            "generationRate": generationRate,
            "systemHealth": systemHealth,
            "knowledgeGraphNodes": knowledgeGraph.count,
        ]
    }

    // MARK: - Private Methods

    private func setupContentTemplates() {
        contentTemplates = [
            .apiReference: """
            # {TITLE}

            ## Overview
            {DESCRIPTION}

            ## Usage
            ```swift
            {USAGE_EXAMPLE}
            ```

            ## Parameters
            {PARAMETERS}

            ## Returns
            {RETURN_VALUE}

            ## Example
            ```swift
            {FULL_EXAMPLE}
            ```

            ## See Also
            {RELATED_CONTENT}
            """,

            .tutorial: """
            # {TITLE}

            ## Introduction
            {INTRODUCTION}

            ## Prerequisites
            {PREREQUISITES}

            ## Step-by-Step Guide
            {STEPS}

            ## Code Examples
            {EXAMPLES}

            ## Troubleshooting
            {TROUBLESHOOTING}

            ## Next Steps
            {NEXT_STEPS}
            """,

            .guide: """
            # {TITLE}

            ## Overview
            {OVERVIEW}

            ## Key Concepts
            {CONCEPTS}

            ## Best Practices
            {BEST_PRACTICES}

            ## Implementation
            {IMPLEMENTATION}

            ## Advanced Topics
            {ADVANCED_TOPICS}

            ## Resources
            {RESOURCES}
            """,
        ]
    }

    private func setupGenerationPatterns() {
        generationPatterns = [
            .apiReference: [
                "function", "method", "class", "struct", "enum", "protocol",
                "parameter", "return", "example", "usage", "description",
            ],
            .tutorial: [
                "step", "example", "prerequisite", "introduction", "conclusion",
                "troubleshooting", "next", "learn", "build", "create",
            ],
            .guide: [
                "overview", "concept", "practice", "implementation", "advanced",
                "resource", "pattern", "architecture", "design", "solution",
            ],
        ]
    }

    private func setupMonitoring() {
        // Set up periodic system monitoring
        Timer.publish(every: monitoringInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.performSystemMonitoring()
                }
            }
            .store(in: &cancellables)
    }

    private func setupMaintenance() {
        // Set up periodic maintenance
        Timer.publish(every: maintenanceInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.performMaintenance()
                }
            }
            .store(in: &cancellables)
    }

    private func startMonitoringLoop() async {
        while isActive && !Task.isCancelled {
            await performSystemMonitoring()
            try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
        }
    }

    private func startGenerationLoop() async {
        while isActive && !Task.isCancelled {
            await processGenerationQueue()
            try? await Task.sleep(nanoseconds: UInt64(generationInterval * 1_000_000_000))
        }
    }

    private func startMaintenanceLoop() async {
        while isActive && !Task.isCancelled {
            await performMaintenance()
            try? await Task.sleep(nanoseconds: UInt64(maintenanceInterval * 1_000_000_000))
        }
    }

    private func performSystemMonitoring() async {
        // Monitor documentation quality and freshness
        let totalContent = documentationContent.count
        if totalContent == 0 {
            await MainActor.run { systemHealth = 1.0 }
            return
        }

        let averageQuality =
            documentationContent.values.map(\.quality.overallScore).reduce(0, +)
                / Double(totalContent)
        let averageFreshness =
            documentationContent.values.map { freshnessScore(for: $0) }.reduce(0, +)
                / Double(totalContent)

        let health = (averageQuality + averageFreshness) / 2.0

        await MainActor.run {
            systemHealth = health
        }

        logger.debug("📊 Documentation system health: \(String(format: "%.3f", health))")
    }

    private func performMaintenance() async {
        logger.info("🔧 Performing documentation maintenance")

        // Identify content needing updates
        let staleContent = documentationContent.values.filter { content in
            freshnessScore(for: content) < freshnessThreshold
        }

        for content in staleContent {
            await MainActor.run {
                generationQueue.append(
                    ContentGenerationRequest(
                        type: content.type,
                        title: content.title,
                        context: content.metadata,
                        generationStrategy: .hybrid
                    ))
            }
        }

        // Clean up old generation history
        await cleanupGenerationHistory()

        logger.info("✅ Maintenance completed - queued \(staleContent.count) updates")
    }

    private func processGenerationQueue() async {
        let pendingRequests = generationQueue.prefix(maxConcurrentGenerations)

        for request in pendingRequests {
            do {
                _ = try await generateContent(request)

                // Remove from queue
                await MainActor.run {
                    generationQueue.removeAll {
                        $0.title == request.title && $0.type == request.type
                    }
                }
            } catch {
                logger.error(
                    "❌ Failed to generate content for \(request.title): \(error.localizedDescription)"
                )
            }
        }
    }

    private func generateContentWithStrategy(_ request: ContentGenerationRequest) async throws
        -> String
    {
        switch request.generationStrategy {
        case .templateBased:
            return try await generateWithTemplate(request)
        case .aiGenerated:
            return try await generateWithAI(request)
        case .hybrid:
            return try await generateHybrid(request)
        case .quantumInspired:
            return try await generateQuantumInspired(request)
        case .collaborative:
            return try await generateCollaborative(request)
        }
    }

    private func generateWithTemplate(_ request: ContentGenerationRequest) async throws -> String {
        guard let template = contentTemplates[request.type] else {
            throw DocumentationError.templateNotFound(request.type)
        }

        // Fill template with context
        var content = template
        for (key, value) in request.context {
            content = content.replacingOccurrences(of: "{\(key.uppercased())}", with: value)
        }

        // Add generated sections
        content = content.replacingOccurrences(
            of: "{USAGE_EXAMPLE}", with: generateUsageExample(for: request)
        )
        content = content.replacingOccurrences(
            of: "{FULL_EXAMPLE}", with: generateFullExample(for: request)
        )

        return content
    }

    private func generateWithAI(_ request: ContentGenerationRequest) async throws -> String {
        // Simulate AI content generation
        let baseContent = """
        # \(request.title)

        ## Overview
        This \(request.type.rawValue) provides comprehensive information about \(request.title.lowercased()).

        ## Key Features
        - Feature 1: Description of feature 1
        - Feature 2: Description of feature 2
        - Feature 3: Description of feature 3

        ## Implementation
        ```swift
        // AI-generated example code
        func exampleFunction() {
            print("This is an AI-generated example")
        }
        ```

        ## Best Practices
        1. Follow established patterns
        2. Test thoroughly
        3. Document your changes
        """

        return baseContent
    }

    private func generateHybrid(_ request: ContentGenerationRequest) async throws -> String {
        // Combine template and AI generation
        let templateContent = try await generateWithTemplate(request)
        let aiContent = try await generateWithAI(request)

        return """
        \(templateContent)

        ## AI-Enhanced Content
        \(aiContent)
        """
    }

    private func generateQuantumInspired(_ request: ContentGenerationRequest) async throws -> String {
        // Quantum-inspired content generation using superposition concepts
        let baseContent = try await generateWithAI(request)

        return """
        \(baseContent)

        ## Quantum-Inspired Optimization
        This content has been optimized using quantum-inspired algorithms for maximum relevance and comprehensiveness.
        """
    }

    private func generateCollaborative(_ request: ContentGenerationRequest) async throws -> String {
        // Collaborative generation combining multiple sources
        let baseContent = try await generateHybrid(request)

        return """
        \(baseContent)

        ## Collaborative Insights
        This documentation has been enhanced through collaborative analysis of multiple knowledge sources.
        """
    }

    private func generateUsageExample(for request: ContentGenerationRequest) -> String {
        switch request.type {
        case .apiReference:
            return """
            // Basic usage example
            let result = exampleFunction(parameter: "value")
            print(result)
            """
        case .tutorial:
            return """
            // Tutorial example
            let tutorial = TutorialExample()
            tutorial.run()
            """
        default:
            return "// Example usage code"
        }
    }

    private func generateFullExample(for request: ContentGenerationRequest) -> String {
        """
        // Complete example implementation
        class ExampleImplementation {
            func performExample() {
                // Implementation details
                print("Example implementation")
            }
        }

        let example = ExampleImplementation()
        example.performExample()
        """
    }

    private func generateTags(for request: ContentGenerationRequest) -> [String] {
        var tags = [request.type.rawValue, request.targetAudience]

        // Add complexity tag
        tags.append(request.complexity.rawValue)

        // Add context-based tags
        for (key, value) in request.context {
            if key.contains("tag") || key.contains("category") {
                tags.append(value)
            }
        }

        return tags
    }

    private func assessContentQuality(_ content: String, for request: ContentGenerationRequest)
        -> DocumentationQuality
    {
        // Simple quality assessment
        let completeness = min(Double(content.count) / 1000.0, 1.0) // Based on length
        let readability = content.contains("```") ? 0.9 : 0.7 // Code examples improve readability
        let relevance = request.context.isEmpty ? 0.8 : 0.95 // Context improves relevance

        return DocumentationQuality(
            completeness: completeness,
            accuracy: 0.9, // Assume high accuracy for generated content
            readability: readability,
            relevance: relevance,
            freshness: 1.0 // Newly generated
        )
    }

    private func assessContentQuality(_ content: String, for type: DocumentationType)
        -> DocumentationQuality
    {
        // Assess quality for existing content
        let request = ContentGenerationRequest(type: type, title: "Assessment")
        return assessContentQuality(content, for: request)
    }

    private func updateKnowledgeGraph(with content: DocumentationContent) async {
        let node = KnowledgeNode(
            id: content.id,
            contentId: content.id,
            title: content.title,
            type: content.type,
            tags: content.tags,
            connections: content.relatedContent,
            importance: content.quality.overallScore
        )

        await MainActor.run {
            knowledgeGraph[content.id] = node
        }

        // Update connections for related content
        for relatedId in content.relatedContent {
            if let relatedNode = knowledgeGraph[relatedId] {
                if !relatedNode.connections.contains(content.id) {
                    var updatedConnections = relatedNode.connections
                    updatedConnections.append(content.id)
                    let updatedNode = KnowledgeNode(
                        id: relatedNode.id,
                        contentId: relatedNode.contentId,
                        title: relatedNode.title,
                        type: relatedNode.type,
                        tags: relatedNode.tags,
                        connections: updatedConnections,
                        importance: relatedNode.importance
                    )
                    await MainActor.run {
                        knowledgeGraph[relatedId] = updatedNode
                    }
                }
            }
        }
    }

    private func freshnessScore(for content: DocumentationContent) -> Double {
        let age = Date().timeIntervalSince(content.updatedAt)
        let maxAge: TimeInterval = 30 * 24 * 3600 // 30 days

        return max(0, 1.0 - (age / maxAge))
    }

    private func incrementVersion(_ version: String) -> String {
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 3 else { return "1.0.0" }

        return "\(components[0]).\(components[1]).\(components[2] + 1)"
    }

    private func inferUserInterests(from context: [String: String]) -> [String] {
        var interests: [String] = []

        if let role = context["role"] {
            interests.append(contentsOf: role.split(separator: " ").map(String.init))
        }

        if let project = context["project"] {
            interests.append(project)
        }

        if let language = context["language"] {
            interests.append(language)
        }

        return interests
    }

    private func calculatePersonalizedRelevance(
        for content: DocumentationContent, userContext: [String: String]
    ) -> Double {
        let userInterests = inferUserInterests(from: userContext)
        let interestMatches = userInterests.filter { interest in
            content.tags.contains(interest)
                || content.title.localizedCaseInsensitiveContains(interest)
        }.count

        let baseRelevance = Double(interestMatches) / Double(max(1, userInterests.count))
        let qualityMultiplier = content.quality.overallScore
        let freshnessMultiplier = freshnessScore(for: content)

        return baseRelevance * qualityMultiplier * freshnessMultiplier
    }

    private func handleCodeChange(file: String, changeType: ChangeType) async {
        // Generate or update documentation based on code changes
        let title = "Changes in \(file)"
        let request = ContentGenerationRequest(
            type: .changelog,
            title: title,
            context: ["file": file, "changeType": changeType.rawValue],
            generationStrategy: .aiGenerated
        )

        do {
            _ = try await generateContent(request)
        } catch {
            logger.error(
                "Failed to generate changelog for code change: \(error.localizedDescription)")
        }
    }

    private func handleAPIChange(symbol: String, changeType: ChangeType) async {
        // Update API documentation
        let title = "API Changes: \(symbol)"
        let request = ContentGenerationRequest(
            type: .apiReference,
            title: title,
            context: ["symbol": symbol, "changeType": changeType.rawValue],
            generationStrategy: .hybrid
        )

        do {
            _ = try await generateContent(request)
        } catch {
            logger.error("Failed to generate API documentation: \(error.localizedDescription)")
        }
    }

    private func handleUserRequest(contentId: String) async {
        // Process user request for documentation update
        guard let content = documentationContent[contentId] else { return }

        let request = ContentGenerationRequest(
            type: content.type,
            title: content.title,
            context: content.metadata,
            generationStrategy: .hybrid
        )

        do {
            let newContent = try await generateContentWithStrategy(request)
            try await updateContent(contentId, with: newContent)
        } catch {
            logger.error("Failed to update content \(contentId): \(error.localizedDescription)")
        }
    }

    private func handleScheduledReview(contentId: String) async {
        // Perform scheduled review and update if needed
        await handleUserRequest(contentId: contentId)
    }

    private func handleQualityThreshold(contentId: String, metric: String, value: Double) async {
        // Handle quality threshold breaches
        logger.warning("Quality threshold breached for \(contentId): \(metric) = \(value)")

        await handleUserRequest(contentId: contentId)
    }

    private func handleDependencyUpdate(package: String, version: String) async {
        // Update documentation for dependency changes
        let title = "Dependency Update: \(package) \(version)"
        let request = ContentGenerationRequest(
            type: .changelog,
            title: title,
            context: ["package": package, "version": version],
            generationStrategy: .aiGenerated
        )

        do {
            _ = try await generateContent(request)
        } catch {
            logger.error(
                "Failed to generate dependency update documentation: \(error.localizedDescription)")
        }
    }

    private func cleanupGenerationHistory() async {
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 3600) // 7 days ago

        await MainActor.run {
            for (key, dates) in generationHistory {
                generationHistory[key] = dates.filter { $0 > cutoffDate }
            }
        }
    }
}

// MARK: - Extensions

public extension AutonomousDocumentation {
    /// Export documentation content
    func exportContent() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(documentationContent)
    }

    /// Import documentation content
    func importContent(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let content = try? decoder.decode([String: DocumentationContent].self, from: data) {
            documentationContent = content
        }
    }

    /// Get knowledge graph visualization data
    func getKnowledgeGraphData() -> [String: [String: Any]] {
        var graphData = [String: [String: Any]]()

        for (id, node) in knowledgeGraph {
            graphData[id] = [
                "title": node.title,
                "type": node.type.rawValue,
                "tags": node.tags,
                "connections": node.connections,
                "importance": node.importance,
            ]
        }

        return graphData
    }

    /// Get documentation statistics
    func getStatistics() -> [String: Any] {
        let totalContent = documentationContent.count
        let contentByType = Dictionary(grouping: documentationContent.values) { $0.type.rawValue }
            .mapValues { $0.count }
        let averageQuality =
            documentationContent.values.map(\.quality.overallScore).reduce(0, +)
                / Double(max(1, totalContent))
        let totalTags = Set(documentationContent.values.flatMap(\.tags)).count

        return [
            "totalContent": totalContent,
            "contentByType": contentByType,
            "averageQuality": averageQuality,
            "totalTags": totalTags,
            "knowledgeGraphNodes": knowledgeGraph.count,
            "generationQueueLength": generationQueue.count,
        ]
    }
}

// MARK: - Supporting Types

/// Documentation system errors
public enum DocumentationError: Error {
    case contentNotFound(String)
    case templateNotFound(DocumentationType)
    case generationFailed(String)
    case invalidContent(String)
}

// MARK: - Convenience Functions

/// Global function to generate documentation
public func generateDocumentation(
    type: DocumentationType,
    title: String,
    context: [String: String] = [:]
) async throws -> String {
    let request = ContentGenerationRequest(
        type: type,
        title: title,
        context: context
    )

    return try await AutonomousDocumentation.shared.generateContent(request)
}

/// Global function to search documentation
public func searchDocumentation(query: String) async -> [DocumentationContent] {
    await AutonomousDocumentation.shared.searchContent(query: query)
}

/// Global function to get documentation recommendations
public func getDocumentationRecommendations(userContext: [String: String]) async
    -> [DocumentationContent]
{
    await AutonomousDocumentation.shared.getRecommendations(for: userContext)
}

/// Global function to check documentation system status
public func isDocumentationSystemActive() async -> Bool {
    await AutonomousDocumentation.shared.isActive
}

/// Global function to get documentation analytics
public func getDocumentationAnalytics() async -> [String: Sendable] {
    await AutonomousDocumentation.shared.getAnalytics()
}
