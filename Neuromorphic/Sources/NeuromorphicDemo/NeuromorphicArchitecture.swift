// Neuromorphic Computing Architecture
// Phase 7B: Brain-inspired computing models and architectures
// Task 73: Neural Architecture Design

import Foundation

// MARK: - Core Neural Architecture

/// Represents a neuron in the neuromorphic system
public class NeuromorphicNeuron {
    public let id: UUID
    public var membranePotential: Double = 0.0
    public var threshold: Double
    public var refractoryPeriod: TimeInterval
    public var lastSpikeTime: TimeInterval = 0.0

    // Synaptic connections
    public var dendrites: [NeuromorphicSynapse] = []
    public var axon: NeuromorphicAxon?

    // Learning parameters
    public var learningRate: Double
    public var adaptationRate: Double

    public init(
        threshold: Double = 1.0,
        refractoryPeriod: TimeInterval = 0.005,
        learningRate: Double = 0.01,
        adaptationRate: Double = 0.001
    ) {
        self.id = UUID()
        self.threshold = threshold
        self.refractoryPeriod = refractoryPeriod
        self.learningRate = learningRate
        self.adaptationRate = adaptationRate
        self.axon = NeuromorphicAxon(neuron: self)
    }

    /// Process incoming spike and update membrane potential
    public func processSpike(_ spike: NeuromorphicSpike, at time: TimeInterval) -> Bool {
        // Check refractory period
        if time - lastSpikeTime < refractoryPeriod {
            return false
        }

        // Update membrane potential with synaptic input
        let synapticEffect = spike.weight * exp(-(time - spike.timestamp) / spike.decayTime)
        membranePotential += synapticEffect

        // Check for spiking
        if membranePotential >= threshold {
            fire(at: time)
            return true
        }

        return false
    }

    /// Fire a spike
    func fire(at time: TimeInterval) {
        lastSpikeTime = time
        membranePotential = 0.0 // Reset after spiking

        // Propagate spike through axon
        axon?.propagateSpike(at: time)

        // Trigger synaptic plasticity
        updateSynapticPlasticity(at: time)
    }

    /// Update synaptic weights based on spike timing
    private func updateSynapticPlasticity(at time: TimeInterval) {
        for synapse in dendrites {
            let timeDifference = time - synapse.lastActivationTime
            let weightChange = learningRate * exp(-abs(timeDifference) / adaptationRate)

            if timeDifference > 0 {
                // LTP: Long-term potentiation for causal spikes
                synapse.weight += weightChange
            } else {
                // LTD: Long-term depression for anti-causal spikes
                synapse.weight -= weightChange
            }

            // Bound weights
            synapse.weight = max(0.0, min(1.0, synapse.weight))
        }
    }
}

/// Represents a synapse connecting neurons
public class NeuromorphicSynapse {
    public let presynapticNeuron: NeuromorphicNeuron
    public let postsynapticNeuron: NeuromorphicNeuron
    public var weight: Double
    public var lastActivationTime: TimeInterval = 0.0
    public var delay: TimeInterval

    public init(
        from presynaptic: NeuromorphicNeuron,
        to postsynaptic: NeuromorphicNeuron,
        weight: Double = 0.5,
        delay: TimeInterval = 0.001
    ) {
        self.presynapticNeuron = presynaptic
        self.postsynapticNeuron = postsynaptic
        self.weight = weight
        self.delay = delay

        // Add to postsynaptic neuron's dendrites
        postsynaptic.dendrites.append(self)
    }
}

/// Represents an axon that propagates spikes
public class NeuromorphicAxon {
    public weak var neuron: NeuromorphicNeuron?
    public var synapses: [NeuromorphicSynapse] = []

    public init(neuron: NeuromorphicNeuron) {
        self.neuron = neuron
    }

    /// Propagate spike to all connected synapses
    public func propagateSpike(at time: TimeInterval) {
        for synapse in synapses {
            let spike = NeuromorphicSpike(
                sourceNeuron: neuron!,
                targetSynapse: synapse,
                timestamp: time + synapse.delay,
                weight: synapse.weight
            )

            // Schedule spike processing
            DispatchQueue.global().asyncAfter(deadline: .now() + synapse.delay) {
                _ = synapse.postsynapticNeuron.processSpike(spike, at: time + synapse.delay)
            }
        }
    }
}

/// Represents a spike event
public struct NeuromorphicSpike {
    public let sourceNeuron: NeuromorphicNeuron
    public let targetSynapse: NeuromorphicSynapse
    public let timestamp: TimeInterval
    public let weight: Double
    public let decayTime: TimeInterval = 0.01 // Spike decay time constant
}

// MARK: - Neural Network Architectures

/// Base class for neuromorphic neural networks
public class NeuromorphicNetwork {
    public var neurons: [NeuromorphicNeuron] = []
    public var inputLayer: [NeuromorphicNeuron] = []
    public var outputLayer: [NeuromorphicNeuron] = []
    public var hiddenLayers: [[NeuromorphicNeuron]] = []
    public var layers: [[NeuromorphicNeuron]] = []

    public var learningRule: NeuromorphicLearningRule

    public init(learningRule: NeuromorphicLearningRule = STDP()) {
        self.learningRule = learningRule
    }

    /// Add a neuron to the network
    public func addNeuron(_ neuron: NeuromorphicNeuron) {
        neurons.append(neuron)
    }

    /// Connect two neurons with a synapse
    public func connect(
        from source: NeuromorphicNeuron,
        to target: NeuromorphicNeuron,
        weight: Double = 0.5,
        delay: TimeInterval = 0.001
    ) -> NeuromorphicSynapse {
        let synapse = NeuromorphicSynapse(from: source, to: target, weight: weight, delay: delay)
        source.axon?.synapses.append(synapse)
        return synapse
    }

    /// Process input spikes through the network
    public func processInput(_ inputSpikes: [NeuromorphicSpike]) {
        for spike in inputSpikes {
            _ = spike.targetSynapse.postsynapticNeuron.processSpike(spike, at: spike.timestamp)
        }

        // Allow time for spike propagation (synchronous delay)
        Thread.sleep(forTimeInterval: 0.1) // 100ms
    }

    /// Get output from the network
    public func getOutput() -> [Double] {
        outputLayer.map(\.membranePotential)
    }
}

/// Learning rules for synaptic plasticity
public protocol NeuromorphicLearningRule {
    func updateSynapse(
        _ synapse: NeuromorphicSynapse, preSpikeTime: TimeInterval, postSpikeTime: TimeInterval
    )
}

/// Spike-Timing Dependent Plasticity (STDP)
public class STDP: NeuromorphicLearningRule {
    public let learningRate: Double
    public let timeWindow: TimeInterval

    public init(learningRate: Double = 0.01, timeWindow: TimeInterval = 0.02) {
        self.learningRate = learningRate
        self.timeWindow = timeWindow
    }

    public func updateSynapse(
        _ synapse: NeuromorphicSynapse, preSpikeTime: TimeInterval, postSpikeTime: TimeInterval
    ) {
        let deltaT = postSpikeTime - preSpikeTime

        if abs(deltaT) < timeWindow {
            let weightChange = learningRate * exp(-abs(deltaT) / timeWindow)

            if deltaT > 0 {
                // LTP: presynaptic spike before postsynaptic
                synapse.weight += weightChange
            } else {
                // LTD: postsynaptic spike before presynaptic
                synapse.weight -= weightChange
            }

            // Bound weights
            synapse.weight = max(0.0, min(1.0, synapse.weight))
        }
    }
}

// MARK: - Brain-Inspired Architectures

/// Hierarchical Temporal Memory (HTM) inspired architecture
public class HTMNetwork: NeuromorphicNetwork {
    public var columns: [[NeuromorphicNeuron]] = []
    public var minicolumnsPerColumn: Int = 4

    /// Create HTM-style columnar architecture
    public func createColumns(numColumns: Int, neuronsPerColumn: Int) {
        for _ in 0 ..< numColumns {
            var column: [NeuromorphicNeuron] = []
            for _ in 0 ..< neuronsPerColumn {
                let neuron = NeuromorphicNeuron(threshold: 0.8, learningRate: 0.02)
                addNeuron(neuron)
                column.append(neuron)
            }
            columns.append(column)
        }

        // Create horizontal connections within columns
        for column in columns {
            for i in 0 ..< column.count {
                for j in (i + 1) ..< column.count {
                    connect(from: column[i], to: column[j], weight: 0.3)
                    connect(from: column[j], to: column[i], weight: 0.3)
                }
            }
        }

        // Create sparse vertical connections between columns
        for i in 0 ..< columns.count {
            for j in (i + 1) ..< columns.count {
                if Double.random(in: 0 ... 1) < 0.1 { // 10% connectivity
                    let sourceNeuron = columns[i].randomElement()!
                    let targetNeuron = columns[j].randomElement()!
                    connect(from: sourceNeuron, to: targetNeuron, weight: 0.1)
                }
            }
        }
    }
}

/// Liquid State Machine (LSM) inspired architecture
public class LSMNetwork: NeuromorphicNetwork {
    public var reservoir: [NeuromorphicNeuron] = []
    public var inputConnections: [(inputIndex: Int, neuron: NeuromorphicNeuron)] = []
    public var outputConnections: [(neuron: NeuromorphicNeuron, outputIndex: Int)] = []

    /// Create liquid state machine reservoir
    public func createReservoir(numNeurons: Int, connectivity: Double = 0.1) {
        // Create reservoir neurons
        for _ in 0 ..< numNeurons {
            let neuron = NeuromorphicNeuron(
                threshold: Double.random(in: 0.5 ... 1.5),
                refractoryPeriod: Double.random(in: 0.001 ... 0.01),
                learningRate: 0.01
            )
            addNeuron(neuron)
            reservoir.append(neuron)
        }

        // Create random connections within reservoir
        for i in 0 ..< reservoir.count {
            for j in 0 ..< reservoir.count {
                if i != j && Double.random(in: 0 ... 1) < connectivity {
                    let weight = Double.random(in: 0.1 ... 0.9)
                    let delay = Double.random(in: 0.001 ... 0.005)
                    connect(from: reservoir[i], to: reservoir[j], weight: weight, delay: delay)
                }
            }
        }
    }

    /// Connect input to reservoir
    public func connectInput(inputSize: Int) {
        for i in 0 ..< inputSize {
            let randomNeuron = reservoir.randomElement()!
            inputConnections.append((inputIndex: i, neuron: randomNeuron))
        }
    }

    /// Connect reservoir to output
    public func connectOutput(outputSize: Int) {
        for i in 0 ..< outputSize {
            let randomNeuron = reservoir.randomElement()!
            outputConnections.append((neuron: randomNeuron, outputIndex: i))
        }
    }
}

// MARK: - Integration with Quantum Systems

/// Hybrid neuro-quantum architecture
public class NeuroQuantumNetwork {
    public let neuromorphicNetwork: NeuromorphicNetwork
    public let quantumProcessor: QuantumProcessor?
    public var hybridMode: HybridMode = .neuromorphic

    public enum HybridMode {
        case neuromorphic // Pure neuromorphic processing
        case quantum // Quantum-enhanced processing
        case hybrid // Combined neuro-quantum processing
    }

    public init(neuromorphicNetwork: NeuromorphicNetwork, quantumProcessor: QuantumProcessor? = nil) {
        self.neuromorphicNetwork = neuromorphicNetwork
        self.quantumProcessor = quantumProcessor
    }

    /// Process input using hybrid neuro-quantum approach
    public func processHybrid(_ input: [Double]) -> [Double] {
        switch hybridMode {
        case .neuromorphic:
            return processNeuromorphic(input)
        case .quantum:
            return processQuantum(input)
        case .hybrid:
            return processHybridCombined(input)
        }
    }

    private func processNeuromorphic(_ input: [Double]) -> [Double] {
        // Convert input to spikes
        let spikes = convertToSpikes(input)

        // Process through neuromorphic network (synchronous)
        for spike in spikes {
            _ = spike.targetSynapse.postsynapticNeuron.processSpike(spike, at: spike.timestamp)
        }

        return neuromorphicNetwork.getOutput()
    }

    private func processQuantum(_ input: [Double]) -> [Double] {
        // Use quantum processor for computation
        guard let quantumProcessor else {
            return input // Fallback
        }

        return quantumProcessor.processQuantum(input)
    }

    private func processHybridCombined(_ input: [Double]) -> [Double] {
        // Combine neuromorphic preprocessing with quantum processing
        let neuromorphicOutput = processNeuromorphic(input)

        if let quantumProcessor {
            return quantumProcessor.processQuantum(neuromorphicOutput)
        }

        return neuromorphicOutput
    }

    private func convertToSpikes(_ input: [Double]) -> [NeuromorphicSpike] {
        var spikes: [NeuromorphicSpike] = []

        for (index, value) in input.enumerated() {
            if value > 0.5 { // Threshold for spiking
                // Create artificial synapse for input
                let dummySynapse = NeuromorphicSynapse(
                    from: NeuromorphicNeuron(),
                    to: neuromorphicNetwork.inputLayer[
                        index % neuromorphicNetwork.inputLayer.count
                    ],
                    weight: value
                )

                let spike = NeuromorphicSpike(
                    sourceNeuron: dummySynapse.presynapticNeuron,
                    targetSynapse: dummySynapse,
                    timestamp: 0.0,
                    weight: value
                )

                spikes.append(spike)
            }
        }

        return spikes
    }
}

// MARK: - Quantum Processor Interface

/// Interface for quantum processing units
public protocol QuantumProcessor {
    func processQuantum(_ input: [Double]) -> [Double]
}

/// Mock quantum processor for development
public class MockQuantumProcessor: QuantumProcessor {
    public func processQuantum(_ input: [Double]) -> [Double] {
        // Simulate quantum advantage
        input.map { $0 * 1.5 } // 50% performance boost
    }
}
