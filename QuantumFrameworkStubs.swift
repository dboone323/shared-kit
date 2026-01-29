// Stub implementations for missing quantum framework types
// These provide minimal implementations to allow compilation of core quantum intelligence systems

import Combine
import Foundation

// MARK: - Workflow Performance Metrics

/// Performance metrics for workflow execution
public struct WorkflowPerformanceMetrics: Sendable {
    public let totalExecutions: Int
    public let successfulExecutions: Int
    public let averageExecutionTime: TimeInterval
    public let errorRate: Double
    public let throughput: Double // executions per second

    public init(
        totalExecutions: Int = 0,
        successfulExecutions: Int = 0,
        averageExecutionTime: TimeInterval = 0.0,
        errorRate: Double = 0.0,
        throughput: Double = 0.0
    ) {
        self.totalExecutions = totalExecutions
        self.successfulExecutions = successfulExecutions
        self.averageExecutionTime = averageExecutionTime
        self.errorRate = errorRate
        self.throughput = throughput
    }
}

// MARK: - Quantum Network Types

/// Basic quantum internet implementation
public class QuantumInternet: ObservableObject {
    @Published public var isConnected: Bool = false
    @Published public var activeConnections: Int = 0

    public init() {
        self.isConnected = true
        self.activeConnections = 1
    }

    @MainActor
    public func initializeQuantumInternet() async {
        // Stub implementation
        print("Initializing quantum internet...")
        isConnected = true
        activeConnections = 1
    }
}

/// Result of a data transmission
public struct TransmissionResult: Sendable {
    public let success: Bool
    public let latency: TimeInterval
    public let dataTransferred: Int
    public let errorMessage: String?

    public init(
        success: Bool,
        latency: TimeInterval = 0.0,
        dataTransferred: Int = 0,
        errorMessage: String? = nil
    ) {
        self.success = success
        self.latency = latency
        self.dataTransferred = dataTransferred
        self.errorMessage = errorMessage
    }
}

/// Quantum entanglement pair for secure communication
public struct EntanglementPair: Sendable {
    public let id: String
    public let isActive: Bool
    public let fidelity: Double

    public init(id: String, isActive: Bool = true, fidelity: Double = 1.0) {
        self.id = id
        self.isActive = isActive
        self.fidelity = fidelity
    }
}
