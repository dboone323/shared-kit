// MARK: - Quantum Internet Types

import Foundation

/// Quantum state representation
public struct QuantumState {
    public let alpha: Double // |0⟩ amplitude
    public let beta: Double // |1⟩ amplitude
    public let amplitude: Double
    public let phase: Double
    public let polarization: Polarization

    public init(alpha: Double, beta: Double) {
        self.alpha = alpha
        self.beta = beta
        self.amplitude = sqrt(alpha * alpha + beta * beta)
        self.phase = atan2(beta, alpha)
        self.polarization = .horizontal // Default
    }

    public init(amplitude: Double, phase: Double, polarization: Polarization) {
        self.amplitude = amplitude
        self.phase = phase
        self.polarization = polarization
        self.alpha = amplitude * cos(phase)
        self.beta = amplitude * sin(phase)
    }

    public var fidelity: Double {
        alpha * alpha + beta * beta
    }
}

/// Quantum bit polarization
public enum Polarization {
    case horizontal, vertical, diagonal, antiDiagonal
}

/// Entanglement pair between two nodes
public struct EntanglementPair {
    public let id: String
    public let nodeA: String
    public let nodeB: String
    public let fidelity: Double
    public let decoherenceRate: Double
    public let distance: Double
    public let createdAt: Date
    public let expiresAt: Date

    public init(
        id: String, nodeA: String, nodeB: String, fidelity: Double, decoherenceRate: Double,
        distance: Double
    ) {
        self.id = id
        self.nodeA = nodeA
        self.nodeB = nodeB
        self.fidelity = fidelity
        self.decoherenceRate = decoherenceRate
        self.distance = distance
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(3600) // 1 hour lifetime
    }

    public var isExpired: Bool {
        Date() > expiresAt
    }

    public var currentFidelity: Double {
        let timeElapsed = Date().timeIntervalSince(createdAt)
        return max(0.0, fidelity * exp(-decoherenceRate * timeElapsed))
    }
}

/// Quantum bit (qubit) representation
public struct Qubit {
    public let state: QuantumState
    public let polarization: Double
    public let phase: Double

    public init(state: QuantumState, polarization: Double = 0.0, phase: Double = 0.0) {
        self.state = state
        self.polarization = polarization
        self.phase = phase
    }
}

/// Quantum channel characteristics
public struct QuantumChannel {
    public let lossRate: Double
    public let noiseLevel: Double
    public let capacity: Double // qubits per second
    public let maxDistance: Double

    public init(lossRate: Double, noiseLevel: Double, capacity: Double, maxDistance: Double) {
        self.lossRate = lossRate
        self.noiseLevel = noiseLevel
        self.capacity = capacity
        self.maxDistance = maxDistance
    }
}

/// Routing constraints for quantum networks
public struct RoutingConstraints {
    public let minFidelity: Double
    public let maxLatency: Double
    public let maxHops: Int
    public let requiredSecurity: SecurityLevel
    public let maxDistance: Double
    public let priority: RoutingPriority

    public init(
        minFidelity: Double, maxLatency: Double, maxHops: Int = 10,
        requiredSecurity: SecurityLevel = .high
    ) {
        self.minFidelity = minFidelity
        self.maxLatency = maxLatency
        self.maxHops = maxHops
        self.requiredSecurity = requiredSecurity
        self.maxDistance = 1000.0 // Default max distance
        self.priority = .fidelity // Default priority
    }

    public init(minFidelity: Double, maxDistance: Double, maxHops: Int, priority: RoutingPriority) {
        self.minFidelity = minFidelity
        self.maxLatency = 100.0 // Default latency
        self.maxHops = maxHops
        self.requiredSecurity = .high
        self.maxDistance = maxDistance
        self.priority = priority
    }
}

/// Routing priority for path selection
public enum RoutingPriority {
    case fidelity, latency, distance, security, speed, reliability
}

/// Security levels for quantum communication
public enum SecurityLevel: String {
    case low, medium, high, quantum, standard
}

/// Quantum network route
public struct QuantumRoute {
    public let path: [String]
    public let totalFidelity: Double
    public let estimatedLatency: Double
    public let repeatersUsed: Int
    public let securityLevel: SecurityLevel

    public init(
        path: [String], totalFidelity: Double, estimatedLatency: Double, repeatersUsed: Int,
        securityLevel: SecurityLevel
    ) {
        self.path = path
        self.totalFidelity = totalFidelity
        self.estimatedLatency = estimatedLatency
        self.repeatersUsed = repeatersUsed
        self.securityLevel = securityLevel
    }
}

/// Quantum key distribution result
public struct QKDResult {
    public let keyLength: Int
    public let securityLevel: SecurityLevel
    public let errorRate: Double
    public let siftedKeyRate: Double
    public let finalKey: [UInt8]

    public init(
        keyLength: Int, securityLevel: SecurityLevel, errorRate: Double, siftedKeyRate: Double,
        finalKey: [UInt8]
    ) {
        self.keyLength = keyLength
        self.securityLevel = securityLevel
        self.errorRate = errorRate
        self.siftedKeyRate = siftedKeyRate
        self.finalKey = finalKey
    }
}

/// Quantum teleportation result
public struct TeleportationResult {
    public let teleportId: String
    public let source: String
    public let destination: String
    public let originalState: QuantumState
    public let teleportedState: QuantumState
    public let fidelity: Double
    public let success: Bool
    public let successRate: Double
    public let distance: Double
    public let latency: Double
    public let classicalBitsTransmitted: Int
    public let entangledPairUsed: Bool
    public let timestamp: Date

    public init(
        teleportId: String,
        source: String,
        destination: String,
        originalState: QuantumState,
        teleportedState: QuantumState,
        fidelity: Double,
        success: Bool,
        successRate: Double,
        distance: Double,
        latency: Double,
        classicalBitsTransmitted: Int,
        entangledPairUsed: Bool,
        timestamp: Date
    ) {
        self.teleportId = teleportId
        self.source = source
        self.destination = destination
        self.originalState = originalState
        self.teleportedState = teleportedState
        self.fidelity = fidelity
        self.success = success
        self.successRate = successRate
        self.distance = distance
        self.latency = latency
        self.classicalBitsTransmitted = classicalBitsTransmitted
        self.entangledPairUsed = entangledPairUsed
        self.timestamp = timestamp
    }
}

/// Hybrid communication result
public struct HybridCommunicationResult {
    public let messageSize: Int
    public let encryptionType: String
    public let latency: Double
    public let securityLevel: SecurityLevel
    public let quantumChannelUsed: Bool
    public let classicalChannelUsed: Bool

    public init(
        messageSize: Int, encryptionType: String, latency: Double, securityLevel: SecurityLevel,
        quantumChannelUsed: Bool, classicalChannelUsed: Bool
    ) {
        self.messageSize = messageSize
        self.encryptionType = encryptionType
        self.latency = latency
        self.securityLevel = securityLevel
        self.quantumChannelUsed = quantumChannelUsed
        self.classicalChannelUsed = classicalChannelUsed
    }
}
