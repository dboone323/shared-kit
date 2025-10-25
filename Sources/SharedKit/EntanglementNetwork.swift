import Foundation

// MARK: - Quantum Entanglement Networks

/// Quantum entanglement network for distributing and managing entangled particles
@MainActor
public class EntanglementNetwork: ObservableObject {
    @Published public var id: String
    @Published public var nodes: [String]
    @Published public var entanglementPairs: [EntanglementPair]
    @Published public var networkTopology: [String: [String]]
    @Published public var channelCharacteristics: [String: QuantumChannel]

    public init(id: String, nodes: [String], entanglementPairs: [EntanglementPair]) {
        self.id = id
        self.nodes = nodes
        self.entanglementPairs = entanglementPairs
        self.networkTopology = [:]
        self.channelCharacteristics = [:]

        initializeNetworkTopology()
        initializeChannelCharacteristics()
    }

    /// Initialize the entanglement network
    public func initialize() async {
        // Network is already initialized in init, but this provides async initialization point
        await generateEntanglementPairs()
    }

    private func initializeNetworkTopology() {
        // Create a mesh network topology
        for node in nodes {
            networkTopology[node] = nodes.filter { $0 != node }
        }
    }

    private func initializeChannelCharacteristics() {
        // Initialize quantum channels between nodes
        for sourceNode in nodes {
            for targetNode in networkTopology[sourceNode] ?? [] {
                let channelId = "\(sourceNode)_\(targetNode)"
                let distance = Double.random(in: 10 ... 1000) // km
                let lossRate = min(0.01 * distance / 100.0, 0.5) // Loss increases with distance
                let noiseLevel = Double.random(in: 0.001 ... 0.01)
                let capacity = 1000.0 / (1.0 + lossRate) // Capacity decreases with loss

                channelCharacteristics[channelId] = QuantumChannel(
                    lossRate: lossRate,
                    noiseLevel: noiseLevel,
                    capacity: capacity,
                    maxDistance: distance
                )
            }
        }
    }

    /// Generate initial entanglement pairs across the network
    public func generateEntanglementPairs() async {
        print("🔗 Generating entanglement pairs across network")

        var newPairs: [EntanglementPair] = []

        for sourceNode in nodes {
            for targetNode in networkTopology[sourceNode] ?? [] {
                let channelId = "\(sourceNode)_\(targetNode)"
                if let channel = channelCharacteristics[channelId] {
                    let pair = await createEntanglementPair(
                        between: sourceNode, and: targetNode, channel: channel
                    )
                    newPairs.append(pair)
                }
            }
        }

        entanglementPairs.append(contentsOf: newPairs)
        print("✅ Generated \(newPairs.count) entanglement pairs")
    }

    /// Create an entanglement pair between two nodes
    public func createEntanglementPair(between nodeA: String, and nodeB: String) async
        -> EntanglementPair
    {
        let channelId = "\(nodeA)_\(nodeB)"
        let channel =
            channelCharacteristics[channelId]
                ?? QuantumChannel(
                    lossRate: 0.01,
                    noiseLevel: 0.005,
                    capacity: 1000.0,
                    maxDistance: 100.0
                )

        return await createEntanglementPair(between: nodeA, and: nodeB, channel: channel)
    }

    private func createEntanglementPair(
        between nodeA: String, and nodeB: String, channel: QuantumChannel
    ) async -> EntanglementPair {
        // Simulate entanglement generation process
        let baseFidelity = Double.random(in: 0.85 ... 0.98)
        let distanceFactor = 1.0 - (channel.maxDistance / 2000.0) // Fidelity decreases with distance
        let fidelity = max(0.1, baseFidelity * distanceFactor)

        let decoherenceRate = channel.noiseLevel + (channel.lossRate * 0.1)

        let pairId = "\(nodeA)_\(nodeB)_\(UUID().uuidString.prefix(8))"

        return EntanglementPair(
            id: pairId,
            nodeA: nodeA,
            nodeB: nodeB,
            fidelity: fidelity,
            decoherenceRate: decoherenceRate,
            distance: channel.maxDistance
        )
    }

    /// Distribute entanglement to requesting nodes
    public func distributeEntanglement(to node: String) async -> EntanglementPair? {
        // Find available entanglement pairs for the node
        let availablePairs = entanglementPairs.filter { pair in
            (pair.nodeA == node || pair.nodeB == node) && !pair.isExpired
                && pair.currentFidelity > 0.7
        }

        guard let bestPair = availablePairs.max(by: { $0.currentFidelity < $1.currentFidelity })
        else {
            // Generate new entanglement if none available
            return await generateNewEntanglement(for: node)
        }

        return bestPair
    }

    private func generateNewEntanglement(for node: String) async -> EntanglementPair? {
        // Find a connected node to create entanglement with
        guard let connectedNode = networkTopology[node]?.randomElement() else {
            return nil
        }

        return await createEntanglementPair(between: node, and: connectedNode)
    }

    /// Monitor and maintain entanglement quality
    public func monitorEntanglementQuality() async {
        var expiredPairs: [String] = []
        var degradedPairs: [EntanglementPair] = []

        for pair in entanglementPairs {
            if pair.isExpired {
                expiredPairs.append(pair.id)
            } else if pair.currentFidelity < 0.5 {
                degradedPairs.append(pair)
            }
        }

        // Remove expired pairs
        entanglementPairs.removeAll { expiredPairs.contains($0.id) }

        // Attempt to refresh degraded pairs
        for pair in degradedPairs {
            if let refreshedPair = await refreshEntanglementPair(pair) {
                if let index = entanglementPairs.firstIndex(where: { $0.id == pair.id }) {
                    entanglementPairs[index] = refreshedPair
                }
            }
        }

        print("🔍 Entanglement monitoring complete:")
        print("- Removed \(expiredPairs.count) expired pairs")
        print("- Refreshed \(degradedPairs.count) degraded pairs")
    }

    private func refreshEntanglementPair(_ pair: EntanglementPair) async -> EntanglementPair? {
        // Simulate entanglement refresh process
        let refreshSuccess = Double.random(in: 0 ... 1) > 0.3 // 70% success rate

        if refreshSuccess {
            return await createEntanglementPair(between: pair.nodeA, and: pair.nodeB)
        }

        return nil
    }

    /// Get network statistics
    public func getNetworkStatistics() async -> EntanglementNetworkStatistics {
        let totalPairs = entanglementPairs.count
        let activePairs = entanglementPairs.filter { !$0.isExpired }.count
        let averageFidelity =
            entanglementPairs.map(\.currentFidelity).reduce(0, +)
                / Double(max(1, entanglementPairs.count))
        let totalNodes = nodes.count
        let averageConnectivity =
            Double(networkTopology.values.map(\.count).reduce(0, +))
                / Double(max(1, networkTopology.count))

        return EntanglementNetworkStatistics(
            totalPairs: totalPairs,
            activePairs: activePairs,
            averageFidelity: averageFidelity,
            totalNodes: totalNodes,
            averageConnectivity: averageConnectivity,
            networkCoverage: Double(activePairs) / Double(totalNodes * (totalNodes - 1) / 2)
        )
    }
}

/// Network statistics for entanglement networks
public struct EntanglementNetworkStatistics {
    public let totalPairs: Int
    public let activePairs: Int
    public let averageFidelity: Double
    public let totalNodes: Int
    public let averageConnectivity: Double
    public let networkCoverage: Double
}
