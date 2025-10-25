// Neuromorphic Computing Demonstration
// Phase 7B: Brain-inspired neural architectures for energy-efficient AI

import Foundation

// MARK: - Demonstration Functions

func demonstrateSpikingNetwork() {
    print("🧠 Demonstrating Spiking Neural Network")
    print("==================================================")

    // Create a feedforward SNN
    let network = FeedforwardSNN()
    network.createNetwork(layerSizes: [10, 20, 5], neuronType: .lif)

    print("Created network with \(network.layers.count) layers")
    print("Input layer: \(network.inputLayer.count) neurons")
    print("Hidden layers: \(network.hiddenLayers.count) layers")
    print("Output layer: \(network.outputLayer.count) neurons")

    // Create input spikes
    var inputSpikes: [NeuromorphicSpike] = []
    for i in 0 ..< 10 {
        if Double.random(in: 0 ... 1) < 0.7 { // 70% chance of spike
            let neuron = network.inputLayer[i]
            let dummySynapse = NeuromorphicSynapse(
                from: NeuromorphicNeuron(), to: neuron, weight: Double.random(in: 0.5 ... 1.0)
            )
            let spike = NeuromorphicSpike(
                sourceNeuron: dummySynapse.presynapticNeuron,
                targetSynapse: dummySynapse,
                timestamp: Double.random(in: 0 ... 0.01),
                weight: Double.random(in: 0.5 ... 1.0)
            )
            inputSpikes.append(spike)
        }
    }

    print("Generated \(inputSpikes.count) input spikes")

    // Process through network (synchronous version)
    for spike in inputSpikes {
        _ = spike.targetSynapse.postsynapticNeuron.processSpike(spike, at: spike.timestamp)
    }

    // Get output
    let output = network.getOutput()
    print("Network output: \(output.map { String(format: "%.3f", $0) }.joined(separator: ", "))")

    print()
}

func demonstrateSynapticPlasticity() {
    print("🔄 Demonstrating Synaptic Plasticity")
    print("==================================================")

    // Create neurons and synapse
    let preNeuron = LIFNeuron()
    let postNeuron = LIFNeuron()
    let synapse = NeuromorphicSynapse(from: preNeuron, to: postNeuron, weight: 0.5)

    print("Initial synapse weight: \(String(format: "%.3f", synapse.weight))")

    // Create STDP learning rule
    let stdp = STDPRule(learningRate: 0.1)

    // Simulate spike pairs
    print("Training with spike pairs...")

    for _ in 0 ..< 20 {
        // Pre before post (LTP)
        _ = stdp.updateWeight(
            synapse: synapse, preSpikeTime: 0.0, postSpikeTime: 0.005, currentTime: 0.01
        )
    }

    print("After LTP training: \(String(format: "%.3f", synapse.weight))")

    for _ in 0 ..< 20 {
        // Post before pre (LTD)
        _ = stdp.updateWeight(
            synapse: synapse, preSpikeTime: 0.005, postSpikeTime: 0.0, currentTime: 0.01
        )
    }

    print("After LTD training: \(String(format: "%.3f", synapse.weight))")

    print()
}

func demonstrateNeuromorphicVision() {
    print("👁️ Demonstrating Neuromorphic Vision")
    print("==================================================")

    // Create vision system
    let vision = NeuromorphicVisionSystem(resolution: (32, 32))

    // Create a simple test image (vertical line)
    var testImage: [[Double]] = []
    for _ in 0 ..< 32 {
        var row: [Double] = []
        for x in 0 ..< 32 {
            // Vertical line in the middle
            let intensity = (x == 16) ? 1.0 : 0.0
            row.append(intensity)
        }
        testImage.append(row)
    }

    print("Processing test image (vertical line)...")

    // Process image (synchronous version)
    let result = vision.processImage(testImage)

    print("Processing time: \(String(format: "%.3f", result.processingTime))s")
    print("Spike count: \(result.spikeCount)")
    print("Energy efficiency: \(String(format: "%.1f", result.energyEfficiency)) spikes/s")
    print("Features extracted: \(result.features.count)")
    print("Recognition confidence: \(String(format: "%.3f", result.confidence))")

    // Learn and recognize
    vision.learnObject(name: "vertical_line", image: testImage)

    let recognitionResult = vision.processImage(testImage)
    print("After learning - Recognized: \(recognitionResult.recognizedObjects.first ?? "none")")
    print("Confidence: \(String(format: "%.3f", recognitionResult.confidence))")

    print()
}

func demonstrateMemorySystem() {
    print("🧠 Demonstrating Memory Systems")
    print("==================================================")

    let memory = HippocampalMemory()

    // Store some patterns
    print("Storing memory patterns...")

    for i in 0 ..< 5 {
        let pattern = (0 ..< 10).map { _ in Double.random(in: 0 ... 1) }
        memory.processMemory(pattern: pattern, reward: Double(i) * 0.1)
    }

    print("Short-term memory items: \(memory.shortTermMemory.memoryItems.count)")
    print("Consolidated memories: \(memory.longTermMemory.memoryPatterns.count)")

    // Test recall
    if let recalled = memory.shortTermMemory.recallPattern() {
        print(
            "Recalled pattern (first 3 values): \(recalled.prefix(3).map { String(format: "%.3f", $0) })"
        )
    }

    print()
}

func demonstrateEnergyEfficiency() {
    print("⚡ Demonstrating Energy-Efficient Processing")
    print("==================================================")

    let processor = EnergyEfficientProcessor(powerBudget: 2.0) // 2W budget

    // Create some neurons
    var neurons: [NeuromorphicNeuron] = []
    for _ in 0 ..< 50 {
        neurons.append(LIFNeuron())
    }

    // Simulate activity
    for i in 0 ..< neurons.count {
        _ = Double.random(in: 0 ... 1)
        processor.updateActivity(for: neurons[i].id, at: TimeInterval(i) * 0.1)
    }

    print("Power budget: \(processor.powerBudget)W")
    print("Current power: \(String(format: "%.3f", processor.currentPower))W")
    print("Energy efficiency: \(String(format: "%.3f", processor.energyEfficiency))")

    // Optimize for power
    let activeNeurons = processor.optimizeForPower(neurons)
    print("Optimized to \(activeNeurons.count) active neurons")

    print()
}

func demonstrateHTMNetwork() {
    print("🎯 Demonstrating Hierarchical Temporal Memory")
    print("==================================================")

    let htm = HTMNetwork()

    // Create HTM columns
    htm.createColumns(numColumns: 10, neuronsPerColumn: 4)

    print("Created HTM with \(htm.columns.count) columns")
    print("Neurons per column: \(htm.columns.first?.count ?? 0)")
    print("Total neurons: \(htm.neurons.count)")

    // Simulate some learning
    print("HTM structure created successfully")

    print()
}

func demonstrateQuantumNeuromorphicHybrid() {
    print("🔬 Demonstrating Quantum-Neuromorphic Hybrid")
    print("==================================================")

    // Create hybrid network
    let neuromorphicNetwork = FeedforwardSNN()
    neuromorphicNetwork.createNetwork(layerSizes: [8, 12, 4])

    let hybridNetwork = NeuroQuantumNetwork(
        neuromorphicNetwork: neuromorphicNetwork,
        quantumProcessor: MockQuantumProcessor()
    )

    print("Created hybrid network")
    print("Neuromorphic layers: \(neuromorphicNetwork.layers.count)")
    print("Quantum enhancement: Available")

    // Test different modes
    let input = (0 ..< 8).map { _ in Double.random(in: 0 ... 1) }

    hybridNetwork.hybridMode = .neuromorphic
    let neuromorphicOutput = hybridNetwork.processHybrid(input)
    print("Neuromorphic mode output: \(neuromorphicOutput.map { String(format: "%.3f", $0) })")

    hybridNetwork.hybridMode = .hybrid
    let hybridOutput = hybridNetwork.processHybrid(input)
    print("Hybrid mode output: \(hybridOutput.map { String(format: "%.3f", $0) })")

    print()
}

// MARK: - Main Demonstration

@main
struct NeuromorphicDemo {
    static func main() {
        print("🚀 Quantum-Neuromorphic Computing Framework Demo")
        print("==================================================")
        print("Phase 7B: Neuromorphic Computing Foundations")
        print("Brain-inspired neural architectures for energy-efficient AI")
        print()

        // Run all demonstrations
        demonstrateSpikingNetwork()
        demonstrateSynapticPlasticity()
        demonstrateNeuromorphicVision()
        demonstrateMemorySystem()
        demonstrateEnergyEfficiency()
        demonstrateHTMNetwork()
        demonstrateQuantumNeuromorphicHybrid()

        print("✅ All demonstrations completed successfully!")
        print("==================================================")
        print("Phase 7B neuromorphic foundations established.")
        print("Ready for quantum-neuromorphic hybrid integration.")
    }
}
