// Synaptic Plasticity Mechanisms
// Phase 7B: Learning and memory mechanisms in neuromorphic systems
// Task 75: Synaptic Plasticity

import Foundation

// MARK: - Synaptic Plasticity Models

/// Base protocol for synaptic plasticity rules
public protocol SynapticPlasticityRule {
    func updateWeight(
        synapse: NeuromorphicSynapse,
        preSpikeTime: TimeInterval,
        postSpikeTime: TimeInterval,
        currentTime: TimeInterval
    ) -> Double
}

/// Spike-Timing Dependent Plasticity (STDP)
public class STDPRule: SynapticPlasticityRule {
    public var learningRate: Double
    public var timeWindow: TimeInterval
    public var maxWeight: Double
    public var minWeight: Double

    public init(
        learningRate: Double = 0.01,
        timeWindow: TimeInterval = 0.02,
        maxWeight: Double = 1.0,
        minWeight: Double = 0.0
    ) {
        self.learningRate = learningRate
        self.timeWindow = timeWindow
        self.maxWeight = maxWeight
        self.minWeight = minWeight
    }

    public func updateWeight(
        synapse: NeuromorphicSynapse,
        preSpikeTime: TimeInterval,
        postSpikeTime: TimeInterval,
        currentTime: TimeInterval
    ) -> Double {
        let deltaT = postSpikeTime - preSpikeTime

        if abs(deltaT) < timeWindow {
            let weightChange = learningRate * exp(-abs(deltaT) / timeWindow)

            if deltaT > 0 {
                // LTP: presynaptic spike before postsynaptic (causal)
                synapse.weight += weightChange
            } else {
                // LTD: postsynaptic spike before presynaptic (anti-causal)
                synapse.weight -= weightChange
            }

            // Bound weights
            synapse.weight = max(minWeight, min(maxWeight, synapse.weight))
        }

        return synapse.weight
    }
}

/// Triplet STDP - accounts for higher-order spike patterns
public class TripletSTDPRule: STDPRule {
    public var tripletLearningRate: Double
    public var tripletTimeWindow: TimeInterval

    // Triplet traces
    private var presynapticTrace: Double = 0.0
    private var postsynapticTrace: Double = 0.0
    private var presynapticTriplet: Double = 0.0
    private var postsynapticTriplet: Double = 0.0

    public init(
        learningRate: Double = 0.01,
        tripletLearningRate: Double = 0.005,
        timeWindow: TimeInterval = 0.02,
        tripletTimeWindow: TimeInterval = 0.1
    ) {
        self.tripletLearningRate = tripletLearningRate
        self.tripletTimeWindow = tripletTimeWindow
        super.init(learningRate: learningRate, timeWindow: timeWindow)
    }

    override public func updateWeight(
        synapse: NeuromorphicSynapse,
        preSpikeTime: TimeInterval,
        postSpikeTime: TimeInterval,
        currentTime: TimeInterval
    ) -> Double {
        let deltaT = postSpikeTime - preSpikeTime

        // Update traces
        updateTraces(deltaT: deltaT, currentTime: currentTime)

        // Triplet STDP update
        let tripletWeightChange = tripletLearningRate * postsynapticTriplet * presynapticTrace
        synapse.weight += tripletWeightChange

        // Standard STDP update
        let stdpWeightChange = super.updateWeight(
            synapse: synapse,
            preSpikeTime: preSpikeTime,
            postSpikeTime: postSpikeTime,
            currentTime: currentTime
        )

        return synapse.weight
    }

    private func updateTraces(deltaT: TimeInterval, currentTime: TimeInterval) {
        let traceDecay = 0.95 // Decay factor
        let tripletDecay = 0.97

        if deltaT > 0 {
            // Presynaptic spike before postsynaptic
            presynapticTrace = 1.0 + presynapticTrace * traceDecay
            presynapticTriplet = 1.0 + presynapticTriplet * tripletDecay
        } else {
            // Postsynaptic spike before presynaptic
            postsynapticTrace = 1.0 + postsynapticTrace * traceDecay
            postsynapticTriplet = 1.0 + postsynapticTriplet * tripletDecay
        }
    }
}

/// Homeostatic Plasticity - maintains network stability
public class HomeostaticPlasticityRule: SynapticPlasticityRule {
    public var targetFiringRate: Double
    public var homeostaticRate: Double
    public var timeWindow: TimeInterval

    private var firingHistory: [TimeInterval] = []
    private var lastUpdateTime: TimeInterval = 0.0

    public init(
        targetFiringRate: Double = 10.0, // Hz
        homeostaticRate: Double = 0.001,
        timeWindow: TimeInterval = 1.0
    ) {
        self.targetFiringRate = targetFiringRate
        self.homeostaticRate = homeostaticRate
        self.timeWindow = timeWindow
    }

    public func updateWeight(
        synapse: NeuromorphicSynapse,
        preSpikeTime: TimeInterval,
        postSpikeTime: TimeInterval,
        currentTime: TimeInterval
    ) -> Double {
        // Calculate current firing rate
        let currentFiringRate = calculateFiringRate(at: currentTime)

        // Homeostatic scaling
        let scalingFactor = targetFiringRate / (currentFiringRate + 1.0) // Avoid division by zero
        let homeostaticChange = homeostaticRate * (scalingFactor - 1.0)

        synapse.weight *= (1.0 + homeostaticChange)

        // Bound weights
        synapse.weight = max(0.0, min(1.0, synapse.weight))

        return synapse.weight
    }

    private func calculateFiringRate(at currentTime: TimeInterval) -> Double {
        // Remove old spikes outside time window
        firingHistory = firingHistory.filter { currentTime - $0 <= timeWindow }

        // Calculate rate in Hz
        let rate = Double(firingHistory.count) / timeWindow
        return rate
    }

    public func recordSpike(at time: TimeInterval) {
        firingHistory.append(time)
        lastUpdateTime = time
    }
}

/// Structural Plasticity - creates and removes synapses
public class StructuralPlasticityRule {
    public var creationThreshold: Double
    public var eliminationThreshold: Double
    public var maxSynapsesPerNeuron: Int
    public var plasticityRate: Double

    private var synapseCreationCandidates:
        [(source: NeuromorphicNeuron, target: NeuromorphicNeuron)] = []

    public init(
        creationThreshold: Double = 0.8,
        eliminationThreshold: Double = 0.1,
        maxSynapsesPerNeuron: Int = 100,
        plasticityRate: Double = 0.01
    ) {
        self.creationThreshold = creationThreshold
        self.eliminationThreshold = eliminationThreshold
        self.maxSynapsesPerNeuron = maxSynapsesPerNeuron
        self.plasticityRate = plasticityRate
    }

    public func evaluateStructuralChanges(network: NeuromorphicNetwork, currentTime: TimeInterval) {
        // Check for synapse elimination
        eliminateWeakSynapses(network: network)

        // Check for synapse creation
        createNewSynapses(network: network, currentTime: currentTime)
    }

    private func eliminateWeakSynapses(network: NeuromorphicNetwork) {
        for neuron in network.neurons {
            guard let axon = neuron.axon else { continue }

            // Sort synapses by weight
            let sortedSynapses = axon.synapses.sorted { $0.weight < $1.weight }

            // Eliminate weakest synapses if over limit or below threshold
            var synapsesToRemove: [NeuromorphicSynapse] = []

            for synapse in sortedSynapses {
                if synapse.weight < eliminationThreshold
                    || axon.synapses.count > maxSynapsesPerNeuron
                {
                    synapsesToRemove.append(synapse)
                }
            }

            // Remove synapses
            for synapse in synapsesToRemove {
                if let index = axon.synapses.firstIndex(where: { $0 === synapse }) {
                    axon.synapses.remove(at: index)
                }
                if let dendriteIndex = synapse.postsynapticNeuron.dendrites.firstIndex(where: {
                    $0 === synapse
                }) {
                    synapse.postsynapticNeuron.dendrites.remove(at: dendriteIndex)
                }
            }
        }
    }

    private func createNewSynapses(network: NeuromorphicNetwork, currentTime: TimeInterval) {
        // Find neurons with high activity that could benefit from new connections
        let activeNeurons = network.neurons.filter { _ in
            // Calculate recent activity (simplified)
            let recentSpikes = Double.random(in: 0 ... 1) // Placeholder for actual calculation
            return recentSpikes > creationThreshold
        }

        // Create potential connection candidates
        for sourceNeuron in activeNeurons {
            for targetNeuron in network.neurons where targetNeuron !== sourceNeuron {
                if shouldCreateSynapse(from: sourceNeuron, to: targetNeuron) {
                    let weight = Double.random(in: 0.1 ... 0.3)
                    let delay = Double.random(in: 0.001 ... 0.005)
                    network.connect(
                        from: sourceNeuron, to: targetNeuron, weight: weight, delay: delay
                    )
                }
            }
        }
    }

    private func shouldCreateSynapse(from source: NeuromorphicNeuron, to target: NeuromorphicNeuron)
        -> Bool
    {
        // Check if connection already exists
        if let axon = source.axon,
           axon.synapses.contains(where: { $0.postsynapticNeuron === target })
        {
            return false
        }

        // Check synapse limits
        if let axon = source.axon, axon.synapses.count >= maxSynapsesPerNeuron {
            return false
        }

        if target.dendrites.count >= maxSynapsesPerNeuron {
            return false
        }

        // Probabilistic creation based on activity correlation
        return Double.random(in: 0 ... 1) < plasticityRate
    }
}

// MARK: - Learning Algorithms

/// Hebbian Learning - "Neurons that fire together wire together"
public class HebbianLearning {
    public var learningRate: Double
    public var decayRate: Double

    public init(learningRate: Double = 0.01, decayRate: Double = 0.99) {
        self.learningRate = learningRate
        self.decayRate = decayRate
    }

    public func applyHebbianRule(
        synapse: NeuromorphicSynapse,
        preActivity: Double,
        postActivity: Double
    ) {
        // Hebbian update: Δw = η * pre * post
        let weightChange = learningRate * preActivity * postActivity
        synapse.weight += weightChange

        // Apply decay
        synapse.weight *= decayRate

        // Bound weights
        synapse.weight = max(0.0, min(1.0, synapse.weight))
    }

    public func applyToNetwork(_ network: NeuromorphicNetwork, timeWindow: TimeInterval = 1.0) {
        for neuron in network.neurons {
            guard let axon = neuron.axon else { continue }

            // Calculate neuron activity (simplified - would need spike history)
            let postActivity = Double.random(in: 0 ... 1) // Placeholder

            for synapse in axon.synapses {
                let preActivity = Double.random(in: 0 ... 1) // Placeholder
                applyHebbianRule(
                    synapse: synapse, preActivity: preActivity, postActivity: postActivity
                )
            }
        }
    }
}

/// BCM Learning Rule - Bienenstock-Cooper-Munro theory
public class BCMLearning {
    public var learningRate: Double
    public var targetActivity: Double
    public var slidingThreshold: Double = 0.0

    public init(learningRate: Double = 0.01, targetActivity: Double = 0.5) {
        self.learningRate = learningRate
        self.targetActivity = targetActivity
    }

    public func applyBCMLearning(
        synapse: NeuromorphicSynapse,
        preActivity: Double,
        postActivity: Double
    ) {
        // BCM rule: Δw = η * pre * post * (post - θ)
        // where θ is a sliding threshold
        updateSlidingThreshold(postActivity: postActivity)

        let thresholdDifference = postActivity - slidingThreshold
        let weightChange = learningRate * preActivity * postActivity * thresholdDifference

        synapse.weight += weightChange

        // Bound weights
        synapse.weight = max(0.0, min(1.0, synapse.weight))
    }

    private func updateSlidingThreshold(postActivity: Double) {
        // Sliding threshold adapts to maintain target activity
        let thresholdChange = 0.01 * (postActivity - targetActivity)
        slidingThreshold += thresholdChange
        slidingThreshold = max(0.0, min(1.0, slidingThreshold))
    }
}

/// Reward-Modulated STDP
public class RewardModulatedSTDP: STDPRule {
    public var rewardSignal: Double = 0.0
    public var dopamineDecay: Double = 0.95
    public var eligibilityTrace: Double = 0.0

    override public func updateWeight(
        synapse: NeuromorphicSynapse,
        preSpikeTime: TimeInterval,
        postSpikeTime: TimeInterval,
        currentTime: TimeInterval
    ) -> Double {
        // Standard STDP update
        let stdpChange = super.updateWeight(
            synapse: synapse,
            preSpikeTime: preSpikeTime,
            postSpikeTime: postSpikeTime,
            currentTime: currentTime
        )

        // Apply reward modulation
        let modulatedChange = stdpChange * (1.0 + rewardSignal)

        synapse.weight += modulatedChange

        // Update eligibility trace
        eligibilityTrace = stdpChange

        return synapse.weight
    }

    public func deliverReward(reward: Double) {
        rewardSignal = reward
        // Reward propagates through eligibility traces
        // (simplified - would need more sophisticated implementation)
    }

    public func decayReward() {
        rewardSignal *= dopamineDecay
    }
}

// MARK: - Memory Systems

/// Short-term memory implementation
public class ShortTermMemory {
    public var memoryCapacity: Int
    public var decayRate: Double
    public var memoryItems: [(pattern: [Double], strength: Double, timestamp: TimeInterval)] = []

    public init(capacity: Int = 7, decayRate: Double = 0.95) {
        self.memoryCapacity = capacity
        self.decayRate = decayRate
    }

    public func storePattern(_ pattern: [Double], strength: Double = 1.0) {
        let timestamp = Date.timeIntervalSinceReferenceDate
        let memoryItem = (pattern: pattern, strength: strength, timestamp: timestamp)

        memoryItems.append(memoryItem)

        // Maintain capacity
        if memoryItems.count > memoryCapacity {
            memoryItems.removeFirst()
        }
    }

    public func recallPattern(threshold: Double = 0.8) -> [Double]? {
        decayMemories()

        // Find strongest memory above threshold
        let validMemories = memoryItems.filter { $0.strength >= threshold }
        return validMemories.max(by: { $0.strength < $1.strength })?.pattern
    }

    public func decayMemories() {
        let currentTime = Date.timeIntervalSinceReferenceDate

        for i in 0 ..< memoryItems.count {
            let age = currentTime - memoryItems[i].timestamp
            let ageFactor = pow(decayRate, age)
            memoryItems[i].strength *= ageFactor

            // Remove very weak memories
            if memoryItems[i].strength < 0.1 {
                memoryItems.remove(at: i)
                break
            }
        }
    }
}

/// Long-term memory with consolidation
public class LongTermMemory {
    public var consolidationThreshold: Double
    public var memoryStrength: [String: Double] = [:]
    public var memoryPatterns: [String: [Double]] = [:]

    public init(consolidationThreshold: Double = 0.9) {
        self.consolidationThreshold = consolidationThreshold
    }

    public func consolidateMemory(key: String, pattern: [Double], strength: Double) {
        if strength >= consolidationThreshold {
            memoryStrength[key] = strength
            memoryPatterns[key] = pattern
        }
    }

    public func retrieveMemory(key: String) -> [Double]? {
        memoryPatterns[key]
    }

    public func getMemoryStrength(key: String) -> Double {
        memoryStrength[key, default: 0.0]
    }

    public func forgetWeakMemories(threshold: Double = 0.3) {
        let weakKeys = memoryStrength.filter { $0.value < threshold }.keys
        for key in weakKeys {
            memoryStrength.removeValue(forKey: key)
            memoryPatterns.removeValue(forKey: key)
        }
    }
}

/// Hippocampal-inspired memory system
public class HippocampalMemory {
    public var shortTermMemory: ShortTermMemory
    public var longTermMemory: LongTermMemory
    public var replayFrequency: Double

    public init() {
        self.shortTermMemory = ShortTermMemory()
        self.longTermMemory = LongTermMemory()
        self.replayFrequency = 0.1 // 10% chance of replay
    }

    public func processMemory(pattern: [Double], reward: Double = 0.0) {
        // Store in short-term memory
        shortTermMemory.storePattern(pattern, strength: 1.0 + reward)

        // Consolidate to long-term if strong enough
        if let recalled = shortTermMemory.recallPattern() {
            let key = patternHash(recalled)
            longTermMemory.consolidateMemory(key: key, pattern: recalled, strength: 1.0 + reward)
        }

        // Occasional replay for memory consolidation
        if Double.random(in: 0 ... 1) < replayFrequency {
            performReplay()
        }
    }

    private func performReplay() {
        // Replay recent memories to strengthen them
        if let pattern = shortTermMemory.recallPattern(threshold: 0.5) {
            let key = patternHash(pattern)
            let currentStrength = longTermMemory.getMemoryStrength(key: key)
            longTermMemory.consolidateMemory(
                key: key, pattern: pattern, strength: currentStrength + 0.1
            )
        }
    }

    private func patternHash(_ pattern: [Double]) -> String {
        // Simple hash for pattern identification
        let hashValue = pattern.reduce(0.0) { $0 + $1 }.truncatingRemainder(dividingBy: 1000.0)
        return String(format: "%.3f", hashValue)
    }
}

// MARK: - Neuromorphic Learning Supervisor

/// Supervises learning across the neuromorphic system
public class NeuromorphicLearningSupervisor {
    public var plasticityRules: [SynapticPlasticityRule] = []
    public var structuralPlasticity: StructuralPlasticityRule?
    public var memorySystem: HippocampalMemory

    public var learningEnabled: Bool = true
    public var supervisionInterval: TimeInterval = 1.0

    public init() {
        self.memorySystem = HippocampalMemory()
        setupDefaultRules()
    }

    private func setupDefaultRules() {
        plasticityRules = [
            STDPRule(),
            TripletSTDPRule(),
            HomeostaticPlasticityRule(),
        ]
        structuralPlasticity = StructuralPlasticityRule()
    }

    public func superviseLearning(network: NeuromorphicNetwork, currentTime: TimeInterval) {
        guard learningEnabled else { return }

        // Apply synaptic plasticity
        for rule in plasticityRules {
            applyPlasticityRule(rule, to: network, at: currentTime)
        }

        // Apply structural plasticity
        structuralPlasticity?.evaluateStructuralChanges(network: network, currentTime: currentTime)

        // Update memory system
        updateMemorySystem(network: network)
    }

    private func applyPlasticityRule(
        _ rule: SynapticPlasticityRule,
        to network: NeuromorphicNetwork,
        at currentTime: TimeInterval
    ) {
        for neuron in network.neurons {
            guard let axon = neuron.axon else { continue }

            for synapse in axon.synapses {
                // Simplified: would need actual spike timing data
                let preSpikeTime = currentTime - Double.random(in: 0.001 ... 0.01)
                let postSpikeTime = currentTime

                _ = rule.updateWeight(
                    synapse: synapse,
                    preSpikeTime: preSpikeTime,
                    postSpikeTime: postSpikeTime,
                    currentTime: currentTime
                )
            }
        }
    }

    private func updateMemorySystem(network: NeuromorphicNetwork) {
        // Extract network state as pattern
        let pattern = network.neurons.map(\.membranePotential)
        memorySystem.processMemory(pattern: pattern)
    }

    public func getLearningMetrics() -> [String: Double] {
        [
            "memory_items": Double(memorySystem.shortTermMemory.memoryItems.count),
            "consolidated_memories": Double(memorySystem.longTermMemory.memoryPatterns.count),
            "plasticity_rules": Double(plasticityRules.count),
        ]
    }
}
