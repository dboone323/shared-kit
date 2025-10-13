// MARK: - Quantum Internet Types

/// Quantum state representation
public struct QuantumState {
    public let alpha: Double  // |0⟩ amplitude
    public let beta: Double   // |1⟩ amplitude

    public init(alpha: Double, beta: Double) {
        self.alpha = alpha
        self.beta = beta
    }

    public var fidelity: Double {
        return alpha * alpha + beta * beta
    }
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

    public init(id: String, nodeA: String, nodeB: String, fidelity: Double, decoherenceRate: Double, distance: Double) {
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
        return Date() > expiresAt
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
    public let capacity: Double  // qubits per second
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

    public init(minFidelity: Double, maxLatency: Double, maxHops: Int = 10, requiredSecurity: SecurityLevel = .high) {
        self.minFidelity = minFidelity
        self.maxLatency = maxLatency
        self.maxHops = maxHops
        self.requiredSecurity = requiredSecurity
    }
}

/// Security levels for quantum communication
public enum SecurityLevel: String {
    case low, medium, high, quantum
}

/// Quantum network route
public struct QuantumRoute {
    public let path: [String]
    public let totalFidelity: Double
    public let estimatedLatency: Double
    public let repeatersUsed: Int
    public let securityLevel: SecurityLevel

    public init(path: [String], totalFidelity: Double, estimatedLatency: Double, repeatersUsed: Int, securityLevel: SecurityLevel) {
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

    public init(keyLength: Int, securityLevel: SecurityLevel, errorRate: Double, siftedKeyRate: Double, finalKey: [UInt8]) {
        self.keyLength = keyLength
        self.securityLevel = securityLevel
        self.errorRate = errorRate
        self.siftedKeyRate = siftedKeyRate
        self.finalKey = finalKey
    }
}

/// Quantum teleportation result
public struct TeleportationResult {
    public let fidelity: Double
    public let successRate: Double
    public let distance: Double
    public let latency: Double
    public let classicalBitsUsed: Int

    public init(fidelity: Double, successRate: Double, distance: Double, latency: Double, classicalBitsUsed: Int) {
        self.fidelity = fidelity
        self.successRate = successRate
        self.distance = distance
        self.latency = latency
        self.classicalBitsUsed = classicalBitsUsed
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

    public init(messageSize: Int, encryptionType: String, latency: Double, securityLevel: SecurityLevel, quantumChannelUsed: Bool, classicalChannelUsed: Bool) {
        self.messageSize = messageSize
        self.encryptionType = encryptionType
        self.latency = latency
        self.securityLevel = securityLevel
        self.quantumChannelUsed = quantumChannelUsed
        self.classicalChannelUsed = classicalChannelUsed
    }
}