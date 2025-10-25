import Foundation
import OSLog

// MARK: - Multi-Agent Systems

/// Main multi-agent system coordinator
public actor MultiAgentSystem {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "MultiAgentSystem")

    // Core agent components
    private let agentCoordinator: AgentCoordinator
    private let intelligenceEngine: EmergentIntelligenceEngine
    private let communicationNetwork: AgentCommunicationNetwork
    private let taskDispatcher: TaskDispatcher
    private let performanceMonitor: AgentPerformanceMonitor

    // System state
    private var activeAgents: [String: Agent] = [:]
    private var systemMetrics: SystemMetrics
    private var intelligencePatterns: [IntelligencePattern] = []

    public init() {
        self.agentCoordinator = AgentCoordinator()
        self.intelligenceEngine = EmergentIntelligenceEngine()
        self.communicationNetwork = AgentCommunicationNetwork()
        self.taskDispatcher = TaskDispatcher()
        self.performanceMonitor = AgentPerformanceMonitor()

        self.systemMetrics = SystemMetrics(
            totalAgents: 0,
            activeAgents: 0,
            emergentIntelligence: 0.0,
            coordinationEfficiency: 0.0,
            taskCompletionRate: 0.0,
            lastUpdate: Date()
        )

        logger.info("🤖 Multi-agent system initialized")
    }

    /// Initialize multi-agent system
    public func initializeSystem() async throws {
        logger.info("🚀 Initializing multi-agent system")

        // Initialize communication network
        try await communicationNetwork.initialize()

        // Start intelligence engine
        try await intelligenceEngine.startEngine()

        // Initialize task dispatcher
        try await taskDispatcher.initialize()

        // Start performance monitoring
        try await performanceMonitor.startMonitoring()

        logger.info("✅ Multi-agent system ready")
    }

    /// Deploy new agent
    public func deployAgent(
        _ agent: Agent,
        capabilities: [AgentCapability]
    ) async throws -> String {
        logger.info("🚀 Deploying agent: \(agent.name)")

        let agentId = try await agentCoordinator.deployAgent(agent, capabilities: capabilities)

        // Update system metrics
        systemMetrics.totalAgents += 1
        systemMetrics.activeAgents += 1

        activeAgents[agentId] = agent

        logger.info("✅ Agent deployed with ID: \(agentId)")

        return agentId
    }

    /// Submit task to agent system
    public func submitTask(_ task: AgentTask) async throws -> String {
        logger.info("📋 Submitting task: \(task.title)")

        let taskId = try await taskDispatcher.submitTask(task)

        // Distribute to appropriate agents
        try await distributeTaskToAgents(task, taskId: taskId)

        return taskId
    }

    /// Get agent system status
    public func getSystemStatus() async throws -> SystemStatus {
        logger.info("📊 Getting system status")

        let agentStatuses = try await agentCoordinator.getAgentStatuses()
        let networkStatus = try await communicationNetwork.getNetworkStatus()
        let intelligenceStatus = try await intelligenceEngine.getIntelligenceStatus()

        return SystemStatus(
            agents: agentStatuses,
            network: networkStatus,
            intelligence: intelligenceStatus,
            metrics: systemMetrics,
            timestamp: Date()
        )
    }

    /// Evolve system intelligence
    public func evolveIntelligence() async throws {
        logger.info("🧠 Evolving system intelligence")

        let patterns = try await intelligenceEngine.analyzeEmergentPatterns()
        intelligencePatterns = patterns

        // Update system metrics
        systemMetrics.emergentIntelligence = calculateEmergentIntelligence(patterns)

        // Adapt agent behaviors based on patterns
        try await adaptAgentBehaviors(patterns)

        logger.info("✅ Intelligence evolved with \(patterns.count) patterns")
    }

    /// Optimize agent coordination
    public func optimizeCoordination() async throws {
        logger.info("🔄 Optimizing agent coordination")

        let coordinationMetrics = try await communicationNetwork.analyzeCoordination()
        let efficiency = try await taskDispatcher.calculateEfficiency()

        systemMetrics.coordinationEfficiency = efficiency

        // Optimize based on metrics
        try await optimizeBasedOnMetrics(coordinationMetrics, efficiency: efficiency)

        logger.info("✅ Coordination optimized")
    }

    /// Get system metrics
    public func getSystemMetrics() -> SystemMetrics {
        systemMetrics
    }

    /// Get intelligence patterns
    public func getIntelligencePatterns() -> [IntelligencePattern] {
        intelligencePatterns
    }

    // MARK: - Private Methods

    private func distributeTaskToAgents(_ task: AgentTask, taskId: String) async throws {
        // Find agents capable of handling this task
        let capableAgents = try await findCapableAgents(for: task)

        if capableAgents.isEmpty {
            throw MultiAgentError.noCapableAgents(task.type)
        }

        // Distribute task to agents
        for agentId in capableAgents {
            try await communicationNetwork.sendMessage(
                AgentMessage(
                    id: UUID().uuidString,
                    from: "system",
                    to: agentId,
                    type: .taskAssignment,
                    content: [
                        "taskId": SendableMessageContent.string(taskId),
                        "task": SendableMessageContent.task(task),
                    ],
                    timestamp: Date()
                )
            )
        }
    }

    private func findCapableAgents(for task: AgentTask) async throws -> [String] {
        var capableAgents: [String] = []

        for (agentId, agent) in activeAgents {
            if agent.capabilities.contains(where: { $0.canHandle(task.type) }) {
                capableAgents.append(agentId)
            }
        }

        return capableAgents
    }

    private func calculateEmergentIntelligence(_ patterns: [IntelligencePattern]) -> Double {
        // Calculate emergent intelligence score based on pattern complexity and emergence
        let complexityScore =
            patterns.map(\.complexity).reduce(0, +) / Double(max(patterns.count, 1))
        let emergenceScore = patterns.filter(\.emergent).count > 0 ? 0.8 : 0.4

        return (complexityScore + emergenceScore) / 2.0
    }

    private func adaptAgentBehaviors(_ patterns: [IntelligencePattern]) async throws {
        for pattern in patterns where pattern.emergent {
            // Adapt agent behaviors based on emergent patterns
            for (agentId, _) in activeAgents {
                try await communicationNetwork.sendMessage(
                    AgentMessage(
                        id: UUID().uuidString,
                        from: "intelligence-engine",
                        to: agentId,
                        type: .behaviorAdaptation,
                        content: ["pattern": SendableMessageContent.pattern(pattern)],
                        timestamp: Date()
                    )
                )
            }
        }
    }

    private func optimizeBasedOnMetrics(
        _ coordinationMetrics: CoordinationMetrics,
        efficiency: Double
    ) async throws {
        // Optimize agent allocation based on metrics
        if coordinationMetrics.messageOverhead > 0.7 {
            // Reduce communication overhead
            try await communicationNetwork.optimizeBandwidth()
        }

        if efficiency < 0.6 {
            // Improve task distribution
            try await taskDispatcher.rebalanceLoad()
        }
    }
}

// MARK: - Agent Coordinator

/// Coordinates agent deployment and management
public actor AgentCoordinator {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "AgentCoordinator")

    private var deployedAgents: [String: Agent] = [:]
    private var agentCapabilities: [String: [AgentCapability]] = [:]

    /// Deploy agent
    public func deployAgent(_ agent: Agent, capabilities: [AgentCapability]) async throws -> String {
        let agentId = UUID().uuidString

        var mutableAgent = agent
        deployedAgents[agentId] = mutableAgent
        agentCapabilities[agentId] = capabilities

        // Initialize agent
        try await mutableAgent.initialize()
        deployedAgents[agentId] = mutableAgent

        logger.info("✅ Agent \(agent.name) deployed with ID: \(agentId)")

        return agentId
    }

    /// Get agent statuses
    public func getAgentStatuses() async throws -> [AgentStatus] {
        var statuses: [AgentStatus] = []

        for (agentId, agent) in deployedAgents {
            let status = AgentStatus(
                agentId: agentId,
                name: agent.name,
                state: agent.state,
                capabilities: agentCapabilities[agentId] ?? [],
                performance: agent.performance,
                lastActive: agent.lastActive
            )
            statuses.append(status)
        }

        return statuses
    }

    /// Remove agent
    public func removeAgent(_ agentId: String) async throws {
        deployedAgents.removeValue(forKey: agentId)
        agentCapabilities.removeValue(forKey: agentId)

        logger.info("🗑️ Agent \(agentId) removed")
    }
}

// MARK: - Emergent Intelligence Engine

/// Engine for emergent intelligence and pattern recognition
public actor EmergentIntelligenceEngine {
    private let logger = Logger(
        subsystem: "com.quantum.workspace", category: "EmergentIntelligence"
    )

    private var intelligencePatterns: [IntelligencePattern] = []
    private var agentInteractions: [AgentInteraction] = []
    private var isRunning = false

    /// Start intelligence engine
    public func startEngine() async throws {
        guard !isRunning else { return }

        isRunning = true
        logger.info("🧠 Intelligence engine started")
    }

    /// Analyze emergent patterns
    public func analyzeEmergentPatterns() async throws -> [IntelligencePattern] {
        // Analyze agent interactions for emergent patterns
        var patterns: [IntelligencePattern] = []

        // Pattern 1: Collaborative problem solving
        let collaborationPattern = analyzeCollaborationPatterns()
        if collaborationPattern.confidence > 0.6 {
            patterns.append(collaborationPattern)
        }

        // Pattern 2: Adaptive learning
        let learningPattern = analyzeLearningPatterns()
        if learningPattern.confidence > 0.5 {
            patterns.append(learningPattern)
        }

        // Pattern 3: Emergent specialization
        let specializationPattern = analyzeSpecializationPatterns()
        if specializationPattern.confidence > 0.7 {
            patterns.append(specializationPattern)
        }

        intelligencePatterns = patterns

        return patterns
    }

    /// Get intelligence status
    public func getIntelligenceStatus() async throws -> IntelligenceStatus {
        IntelligenceStatus(
            patterns: intelligencePatterns,
            emergenceLevel: calculateEmergenceLevel(),
            learningRate: calculateLearningRate(),
            timestamp: Date()
        )
    }

    private func analyzeCollaborationPatterns() -> IntelligencePattern {
        // Analyze how agents collaborate on tasks
        let collaborationInteractions = agentInteractions.filter { $0.type == .collaboration }

        let complexity = Double(collaborationInteractions.count) / 10.0 // Normalize
        let confidence = min(1.0, Double(collaborationInteractions.count) / 50.0)

        return IntelligencePattern(
            id: UUID().uuidString,
            type: .collaboration,
            description: "Agents demonstrating collaborative problem-solving",
            complexity: complexity,
            confidence: confidence,
            emergent: confidence > 0.7,
            data: ["interactions": .interactions(collaborationInteractions.count)]
        )
    }

    private func analyzeLearningPatterns() -> IntelligencePattern {
        // Analyze how agents learn from interactions
        let learningInteractions = agentInteractions.filter { $0.type == .learning }

        let complexity = Double(learningInteractions.count) / 15.0
        let confidence = min(1.0, Double(learningInteractions.count) / 30.0)

        return IntelligencePattern(
            id: UUID().uuidString,
            type: .learning,
            description: "Agents adapting behavior through learning",
            complexity: complexity,
            confidence: confidence,
            emergent: confidence > 0.6,
            data: ["learning_events": .interactions(learningInteractions.count)]
        )
    }

    private func analyzeSpecializationPatterns() -> IntelligencePattern {
        // Analyze how agents develop specialized capabilities
        let specializationScore = calculateSpecializationScore()

        return IntelligencePattern(
            id: UUID().uuidString,
            type: .specialization,
            description: "Agents developing specialized capabilities",
            complexity: specializationScore,
            confidence: specializationScore > 0.5 ? 0.8 : 0.4,
            emergent: specializationScore > 0.7,
            data: ["specialization_score": .score(specializationScore)]
        )
    }

    private func calculateEmergenceLevel() -> Double {
        let emergentPatterns = intelligencePatterns.filter(\.emergent)
        return Double(emergentPatterns.count) / Double(max(intelligencePatterns.count, 1))
    }

    private func calculateLearningRate() -> Double {
        let recentInteractions = agentInteractions.filter {
            Date().timeIntervalSince($0.timestamp) < 3600 // Last hour
        }

        return Double(recentInteractions.count) / 3600.0 // Interactions per second
    }

    private func calculateSpecializationScore() -> Double {
        // Simplified specialization calculation
        Double.random(in: 0.3 ... 0.9)
    }
}

// MARK: - Agent Communication Network

/// Network for agent-to-agent communication
public actor AgentCommunicationNetwork {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "AgentCommunication")

    private var messageQueue: [AgentMessage] = []
    private var networkMetrics: NetworkMetrics

    public init() {
        self.networkMetrics = NetworkMetrics(
            totalMessages: 0,
            messageLatency: 0.0,
            bandwidthUsage: 0.0,
            errorRate: 0.0,
            lastUpdate: Date()
        )
    }

    /// Initialize network
    public func initialize() async throws {
        logger.info("🌐 Initializing agent communication network")
    }

    /// Send message
    public func sendMessage(_ message: AgentMessage) async throws {
        messageQueue.append(message)
        networkMetrics.totalMessages += 1

        // Simulate message delivery
        try await deliverMessage(message)

        logger.info("📤 Message sent from \(message.from) to \(message.to)")
    }

    /// Receive messages for agent
    public func receiveMessages(for agentId: String) async throws -> [AgentMessage] {
        let messages = messageQueue.filter { $0.to == agentId }
        messageQueue.removeAll { $0.to == agentId }

        return messages
    }

    /// Get network status
    public func getNetworkStatus() async throws -> NetworkStatus {
        NetworkStatus(
            activeConnections: 1, // Simplified
            messageQueueSize: messageQueue.count,
            averageLatency: networkMetrics.messageLatency,
            bandwidthUtilization: networkMetrics.bandwidthUsage,
            timestamp: Date()
        )
    }

    /// Analyze coordination metrics
    public func analyzeCoordination() async throws -> CoordinationMetrics {
        let messageCount = networkMetrics.totalMessages
        let errorRate = networkMetrics.errorRate

        return CoordinationMetrics(
            messageOverhead: Double(messageCount) / 1000.0, // Simplified
            coordinationEfficiency: 1.0 - errorRate,
            agentUtilization: 0.8, // Simplified
            timestamp: Date()
        )
    }

    /// Optimize bandwidth
    public func optimizeBandwidth() async throws {
        // Implement bandwidth optimization
        networkMetrics.bandwidthUsage *= 0.8 // Reduce usage
        logger.info("📊 Bandwidth optimized")
    }

    private func deliverMessage(_ message: AgentMessage) async throws {
        // Simulate network latency
        let latency = Double.random(in: 0.001 ... 0.01) // 1-10ms
        networkMetrics.messageLatency = latency

        // Simulate occasional errors
        if Double.random(in: 0 ... 1) < 0.02 { // 2% error rate
            networkMetrics.errorRate += 0.02
            throw MultiAgentError.messageDeliveryFailed(message.id)
        }
    }
}

// MARK: - Task Dispatcher

/// Dispatches tasks to appropriate agents
public actor TaskDispatcher {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "TaskDispatcher")

    private var taskQueue: [String: AgentTask] = [:]
    private var taskAssignments: [String: [String]] = [:] // taskId -> [agentIds]

    /// Initialize dispatcher
    public func initialize() async throws {
        logger.info("📋 Task dispatcher initialized")
    }

    /// Submit task
    public func submitTask(_ task: AgentTask) async throws -> String {
        let taskId = UUID().uuidString
        taskQueue[taskId] = task

        logger.info("📝 Task submitted: \(task.title) (ID: \(taskId))")

        return taskId
    }

    /// Assign task to agent
    public func assignTask(_ taskId: String, to agentId: String) async throws {
        if taskAssignments[taskId] == nil {
            taskAssignments[taskId] = []
        }
        taskAssignments[taskId]?.append(agentId)

        logger.info("👤 Task \(taskId) assigned to agent \(agentId)")
    }

    /// Get task status
    public func getTaskStatus(_ taskId: String) -> TaskStatus? {
        guard let task = taskQueue[taskId] else { return nil }

        let assignments = taskAssignments[taskId] ?? []
        let completionRate = Double(assignments.count) / Double(max(task.requiredAgents, 1))

        return TaskStatus(
            taskId: taskId,
            state: completionRate >= 1.0 ? .completed : .inProgress,
            assignedAgents: assignments,
            completionRate: completionRate,
            lastUpdate: Date()
        )
    }

    /// Calculate efficiency
    public func calculateEfficiency() async throws -> Double {
        let totalTasks = taskQueue.count
        let completedTasks = taskQueue.values.filter { getTaskStatus($0.id)?.state == .completed }
            .count

        return Double(completedTasks) / Double(max(totalTasks, 1))
    }

    /// Rebalance load
    public func rebalanceLoad() async throws {
        // Implement load balancing logic
        logger.info("⚖️ Load rebalanced")
    }
}

// MARK: - Agent Performance Monitor

/// Monitors agent performance and health
public actor AgentPerformanceMonitor {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "AgentPerformance")

    private var performanceMetrics: [String: AgentPerformance] = [:]
    private var isMonitoring = false

    /// Start monitoring
    public func startMonitoring() async throws {
        guard !isMonitoring else { return }

        isMonitoring = true
        logger.info("📊 Performance monitoring started")
    }

    /// Record agent performance
    public func recordPerformance(_ agentId: String, metrics: AgentPerformance) async throws {
        performanceMetrics[agentId] = metrics

        // Check for performance issues
        if metrics.taskCompletionRate < 0.5 {
            logger.warning("⚠️ Agent \(agentId) has low performance: \(metrics.taskCompletionRate)")
        }
    }

    /// Get performance report
    public func getPerformanceReport() async throws -> PerformanceReport {
        let averagePerformance = calculateAveragePerformance()

        return PerformanceReport(
            agentMetrics: performanceMetrics,
            averageTaskCompletion: averagePerformance.completion,
            averageEfficiency: averagePerformance.efficiency,
            systemHealth: calculateSystemHealth(),
            timestamp: Date()
        )
    }

    private func calculateAveragePerformance() -> (completion: Double, efficiency: Double) {
        let metrics = Array(performanceMetrics.values)

        if metrics.isEmpty {
            return (0.0, 0.0)
        }

        let completion = metrics.map(\.taskCompletionRate).reduce(0, +) / Double(metrics.count)
        let efficiency = metrics.map(\.efficiency).reduce(0, +) / Double(metrics.count)

        return (completion, efficiency)
    }

    private func calculateSystemHealth() -> Double {
        let averagePerformance = calculateAveragePerformance()
        return (averagePerformance.completion + averagePerformance.efficiency) / 2.0
    }
}

// MARK: - Data Models

/// Agent
public struct Agent: Sendable {
    public let id: String
    public let name: String
    public let type: AgentType
    public var state: AgentState
    public let capabilities: [AgentCapability]
    public var performance: AgentPerformance
    public var lastActive: Date

    public init(
        id: String,
        name: String,
        type: AgentType,
        capabilities: [AgentCapability]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.capabilities = capabilities
        self.state = .idle
        self.performance = AgentPerformance(
            taskCompletionRate: 0.0,
            efficiency: 0.0,
            responseTime: 0.0,
            errorRate: 0.0
        )
        self.lastActive = Date()
    }

    public mutating func initialize() async throws {
        state = .active
        lastActive = Date()
    }
}

/// Agent type
public enum AgentType: String, Sendable {
    case worker, coordinator, specialist, learner, communicator
}

/// Agent state
public enum AgentState: String, Sendable {
    case idle, active, busy, error, offline
}

/// Agent capability
public struct AgentCapability: Sendable {
    public let type: CapabilityType
    public let proficiency: Double
    public let specializations: [String]

    public func canHandle(_ taskType: TaskType) -> Bool {
        switch (type, taskType) {
        case (.computation, .computation): return true
        case (.communication, .communication): return true
        case (.learning, .learning): return true
        case (.coordination, .coordination): return true
        case let (.specialized(spec), .specialized(taskSpec)): return spec == taskSpec
        default: return false
        }
    }
}

/// Capability type
public enum CapabilityType: Sendable {
    case computation, communication, learning, coordination
    case specialized(String)
}

/// Agent performance
public struct AgentPerformance: Sendable {
    public var taskCompletionRate: Double
    public var efficiency: Double
    public var responseTime: Double
    public var errorRate: Double
}

/// Agent task
public struct AgentTask: Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let type: TaskType
    public let priority: TaskPriority
    public let requiredCapabilities: [CapabilityType]
    public let requiredAgents: Int
    public let deadline: Date?
    public let dependencies: [String]

    public init(
        title: String,
        description: String,
        type: TaskType,
        priority: TaskPriority = .medium,
        requiredCapabilities: [CapabilityType] = [],
        requiredAgents: Int = 1,
        deadline: Date? = nil,
        dependencies: [String] = []
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.requiredCapabilities = requiredCapabilities
        self.requiredAgents = requiredAgents
        self.deadline = deadline
        self.dependencies = dependencies
    }
}

/// Task type
public enum TaskType: Sendable {
    case computation, communication, learning, coordination
    case specialized(String)
}

/// Task priority
public enum TaskPriority: String, Sendable {
    case low, medium, high, critical
}

/// Sendable message content
public enum SendableMessageContent: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case task(AgentTask)
    case pattern(IntelligencePattern)
}

/// Agent message
public struct AgentMessage: Sendable {
    public let id: String
    public let from: String
    public let to: String
    public let type: MessageType
    public let content: [String: SendableMessageContent]
    public let timestamp: Date

    public init(
        id: String,
        from: String,
        to: String,
        type: MessageType,
        content: [String: SendableMessageContent],
        timestamp: Date
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.type = type
        self.content = content
        self.timestamp = timestamp
    }
}

/// Message type
public enum MessageType: String, Sendable {
    case taskAssignment, statusUpdate, coordination, learning, error, behaviorAdaptation
}

/// Agent status
public struct AgentStatus: Sendable {
    public let agentId: String
    public let name: String
    public let state: AgentState
    public let capabilities: [AgentCapability]
    public let performance: AgentPerformance
    public let lastActive: Date
}

/// System status
public struct SystemStatus: Sendable {
    public let agents: [AgentStatus]
    public let network: NetworkStatus
    public let intelligence: IntelligenceStatus
    public let metrics: SystemMetrics
    public let timestamp: Date
}

/// Network status
public struct NetworkStatus: Sendable {
    public let activeConnections: Int
    public let messageQueueSize: Int
    public let averageLatency: Double
    public let bandwidthUtilization: Double
    public let timestamp: Date
}

/// Intelligence status
public struct IntelligenceStatus: Sendable {
    public let patterns: [IntelligencePattern]
    public let emergenceLevel: Double
    public let learningRate: Double
    public let timestamp: Date
}

/// Sendable pattern data
public enum SendablePatternData: Sendable {
    case int(Int)
    case double(Double)
    case string(String)
    case interactions(Int)
    case score(Double)
}

/// Intelligence pattern
public struct IntelligencePattern: Sendable {
    public let id: String
    public let type: PatternType
    public let description: String
    public let complexity: Double
    public let confidence: Double
    public let emergent: Bool
    public let data: [String: SendablePatternData]
}

/// Pattern type
public enum PatternType: String, Sendable {
    case collaboration, learning, specialization, adaptation, emergence
}

/// Agent interaction
public struct AgentInteraction: Sendable {
    public let id: String
    public let agents: [String]
    public let type: InteractionType
    public let outcome: InteractionOutcome
    public let timestamp: Date
}

/// Interaction type
public enum InteractionType: String, Sendable {
    case collaboration, competition, learning, communication
}

/// Interaction outcome
public enum InteractionOutcome: String, Sendable {
    case success, failure, neutral
}

/// System metrics
public struct SystemMetrics: Sendable {
    public var totalAgents: Int
    public var activeAgents: Int
    public var emergentIntelligence: Double
    public var coordinationEfficiency: Double
    public var taskCompletionRate: Double
    public var lastUpdate: Date
}

/// Network metrics
public struct NetworkMetrics: Sendable {
    public var totalMessages: Int
    public var messageLatency: Double
    public var bandwidthUsage: Double
    public var errorRate: Double
    public var lastUpdate: Date
}

/// Coordination metrics
public struct CoordinationMetrics: Sendable {
    public let messageOverhead: Double
    public let coordinationEfficiency: Double
    public let agentUtilization: Double
    public let timestamp: Date
}

/// Task status
public struct TaskStatus: Sendable {
    public let taskId: String
    public let state: TaskState
    public let assignedAgents: [String]
    public let completionRate: Double
    public let lastUpdate: Date
}

/// Task state
public enum TaskState: String, Sendable {
    case pending, inProgress, completed, failed
}

/// Performance report
public struct PerformanceReport: Sendable {
    public let agentMetrics: [String: AgentPerformance]
    public let averageTaskCompletion: Double
    public let averageEfficiency: Double
    public let systemHealth: Double
    public let timestamp: Date
}

/// Multi-agent error
public enum MultiAgentError: Error {
    case noCapableAgents(TaskType)
    case agentDeploymentFailed(String)
    case messageDeliveryFailed(String)
    case taskAssignmentFailed(String)
    case networkFailure
}

// MARK: - Convenience Functions

/// Initialize multi-agent system
@MainActor
public func initializeMultiAgentSystem() async throws {
    let system = MultiAgentSystem()
    try await system.initializeSystem()
}

/// Get multi-agent system capabilities
@MainActor
public func getMultiAgentCapabilities() -> [String: [String]] {
    [
        "agent_types": ["worker", "coordinator", "specialist", "learner", "communicator"],
        "intelligence": [
            "emergent_patterns", "adaptive_learning", "collaborative_problem_solving",
        ],
        "coordination": ["task_distribution", "load_balancing", "communication_network"],
        "monitoring": ["performance_tracking", "health_monitoring", "efficiency_analysis"],
        "optimization": ["resource_allocation", "capability_matching", "system_evolution"],
    ]
}

/// Deploy specialized agent
@MainActor
public func deploySpecializedAgent(
    name: String,
    type: AgentType,
    capabilities: [AgentCapability]
) async throws -> String {
    let system = MultiAgentSystem()
    try await system.initializeSystem()

    let agent = Agent(id: UUID().uuidString, name: name, type: type, capabilities: capabilities)
    return try await system.deployAgent(agent, capabilities: capabilities)
}

/// Submit collaborative task
@MainActor
public func submitCollaborativeTask(
    title: String,
    description: String,
    type: TaskType,
    requiredAgents: Int = 2
) async throws -> String {
    let system = MultiAgentSystem()
    try await system.initializeSystem()

    let task = AgentTask(
        title: title,
        description: description,
        type: type,
        requiredAgents: requiredAgents
    )

    return try await system.submitTask(task)
}

/// Evolve system intelligence
@MainActor
public func evolveSystemIntelligence() async throws {
    let system = MultiAgentSystem()
    try await system.initializeSystem()
    try await system.evolveIntelligence()
}

// MARK: - Global Instance

private let globalMultiAgentSystem = MultiAgentSystem()
