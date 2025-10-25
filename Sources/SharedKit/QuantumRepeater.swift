import Foundation

// MARK: - Quantum Repeaters

/// Quantum repeater for extending the range of quantum communication through entanglement swapping
@MainActor
public class QuantumRepeater: ObservableObject {
    @Published public var id: String
    @Published public var location: String
    @Published public var entanglementPairs: [EntanglementPair]
    @Published public var purificationLevel: Double
    @Published public var operationalStatus: RepeaterStatus
    @Published public var successRate: Double

    public init(id: String, location: String) {
        self.id = id
        self.location = location
        self.entanglementPairs = []
        self.purificationLevel = 1.0
        self.operationalStatus = .initializing
        self.successRate = 0.0
    }

    /// Initialize the quantum repeater
    public func initialize() async {
        print("🔄 Initializing quantum repeater \(id) at \(location)")

        operationalStatus = .initializing

        // Simulate initialization process
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        operationalStatus = .operational
        successRate = Double.random(in: 0.85 ... 0.95)

        print("✅ Quantum repeater \(id) initialized with \(String(format: "%.1f", successRate * 100))% success rate")
    }

    /// Perform entanglement swapping to extend communication range
    public func performEntanglementSwapping(
        pair1: EntanglementPair,
        pair2: EntanglementPair
    ) async -> EntanglementPair? {
        guard operationalStatus == .operational else { return nil }

        // Check if pairs can be swapped (must share a common node)
        let commonNodes = Set([pair1.nodeA, pair1.nodeB]).intersection(Set([pair2.nodeA, pair2.nodeB]))

        guard !commonNodes.isEmpty else {
            print("❌ Cannot swap entanglement: no common nodes between pairs")
            return nil
        }

        // Simulate entanglement swapping process
        let swappingSuccess = Double.random(in: 0 ... 1) < successRate

        if swappingSuccess {
            // Create new extended entanglement pair
            let endNodes = Set([pair1.nodeA, pair1.nodeB, pair2.nodeA, pair2.nodeB]).subtracting(commonNodes)
            guard endNodes.count == 2 else { return nil }

            let endNodeArray = Array(endNodes)
            let newDistance = pair1.distance + pair2.distance

            // Fidelity decreases with distance and number of swaps
            let baseFidelity = min(pair1.currentFidelity, pair2.currentFidelity)
            let distancePenalty = exp(-newDistance / 1000.0) // Exponential decay
            let newFidelity = baseFidelity * distancePenalty * purificationLevel

            let extendedPair = EntanglementPair(
                id: "\(pair1.id)_\(pair2.id)_swapped",
                nodeA: endNodeArray[0],
                nodeB: endNodeArray[1],
                fidelity: newFidelity,
                decoherenceRate: (pair1.decoherenceRate + pair2.decoherenceRate) / 2.0,
                distance: newDistance
            )

            entanglementPairs.append(extendedPair)

            print("✅ Entanglement swapping successful:")
            print("- Extended range from \(String(format: "%.1f", pair1.distance + pair2.distance)) km to \(String(format: "%.1f", newDistance)) km")
            print("- New fidelity: \(String(format: "%.3f", newFidelity))")

            return extendedPair
        } else {
            print("❌ Entanglement swapping failed")
            return nil
        }
    }

    /// Perform entanglement purification to improve fidelity
    public func purifyEntanglement(_ pair: EntanglementPair) async -> EntanglementPair? {
        guard operationalStatus == .operational else { return nil }

        // Simulate purification process
        let purificationEfficiency = Double.random(in: 0.7 ... 0.9)
        let purifiedFidelity = min(0.99, pair.currentFidelity * purificationEfficiency)

        // Purification may fail if fidelity is too low
        let purificationSuccess = pair.currentFidelity > 0.3 && Double.random(in: 0 ... 1) < 0.8

        if purificationSuccess {
            let purifiedPair = EntanglementPair(
                id: "\(pair.id)_purified",
                nodeA: pair.nodeA,
                nodeB: pair.nodeB,
                fidelity: purifiedFidelity,
                decoherenceRate: pair.decoherenceRate * 0.8, // Decoherence rate improves
                distance: pair.distance
            )

            // Update purification level based on success
            purificationLevel = min(1.0, purificationLevel + 0.01)

            print("🧹 Entanglement purification successful:")
            print("- Improved fidelity from \(String(format: "%.3f", pair.currentFidelity)) to \(String(format: "%.3f", purifiedFidelity))")

            return purifiedPair
        } else {
            // Purification failed, slightly degrade the pair
            let degradedPair = EntanglementPair(
                id: "\(pair.id)_degraded",
                nodeA: pair.nodeA,
                nodeB: pair.nodeB,
                fidelity: pair.currentFidelity * 0.9,
                decoherenceRate: pair.decoherenceRate * 1.1,
                distance: pair.distance
            )

            // Decrease purification level due to failure
            purificationLevel = max(0.5, purificationLevel - 0.02)

            print("❌ Entanglement purification failed - pair degraded")

            return degradedPair
        }
    }

    /// Cascade multiple repeaters for long-distance communication
    public func cascadeRepeaters(
        with downstreamRepeater: QuantumRepeater,
        initialPair: EntanglementPair
    ) async -> EntanglementPair? {
        guard operationalStatus == .operational && downstreamRepeater.operationalStatus == .operational else {
            return nil
        }

        // Create local entanglement pair
        guard let localPair = await downstreamRepeater.createLocalEntanglementPair() else {
            return nil
        }

        // Perform entanglement swapping
        return await performEntanglementSwapping(pair1: initialPair, pair2: localPair)
    }

    private func createLocalEntanglementPair() async -> EntanglementPair? {
        // Simulate creating a local high-fidelity entanglement pair
        let localFidelity = Double.random(in: 0.95 ... 0.99)
        let localDistance = Double.random(in: 1 ... 10)

        return EntanglementPair(
            id: "\(id)_local_\(UUID().uuidString.prefix(8))",
            nodeA: "\(id)_input",
            nodeB: "\(id)_output",
            fidelity: localFidelity,
            decoherenceRate: 0.001,
            distance: localDistance
        )
    }

    /// Monitor repeater performance and health
    public func monitorPerformance() async -> RepeaterPerformanceMetrics {
        let uptime = Double.random(in: 0.95 ... 0.99)
        let averageFidelity = entanglementPairs.map(\.currentFidelity).reduce(0, +) / Double(max(1, entanglementPairs.count))
        let throughput = Double(entanglementPairs.count) / 3600.0 // pairs per hour
        let errorRate = 1.0 - successRate

        return RepeaterPerformanceMetrics(
            uptime: uptime,
            averageFidelity: averageFidelity,
            throughput: throughput,
            errorRate: errorRate,
            purificationLevel: purificationLevel,
            operationalStatus: operationalStatus
        )
    }

    /// Perform maintenance operations
    public func performMaintenance() async {
        print("🔧 Performing maintenance on quantum repeater \(id)")

        operationalStatus = .maintenance

        // Simulate maintenance process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Improve purification level through maintenance
        purificationLevel = min(1.0, purificationLevel + 0.05)

        // Improve success rate
        successRate = min(0.98, successRate + 0.01)

        operationalStatus = .operational

        print("✅ Maintenance completed - purification level: \(String(format: "%.2f", purificationLevel))")
    }
}

/// Status of quantum repeater operation
public enum RepeaterStatus {
    case initializing, operational, maintenance, offline, error
}

/// Performance metrics for quantum repeater
public struct RepeaterPerformanceMetrics {
    public let uptime: Double
    public let averageFidelity: Double
    public let throughput: Double
    public let errorRate: Double
    public let purificationLevel: Double
    public let operationalStatus: RepeaterStatus
}
