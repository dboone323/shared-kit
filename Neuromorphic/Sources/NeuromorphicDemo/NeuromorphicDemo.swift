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

func demonstrateNeuromorphicAudio() {
    print("🔊 Demonstrating Neuromorphic Audio Processing")
    print("==================================================")

    // Create speech recognizer
    let speechRecognizer = NeuromorphicSpeechRecognizer()

    // Generate synthetic speech-like audio (simplified)
    let sampleRate = 44100.0
    let duration = 1.0 // 1 second
    let numSamples = Int(sampleRate * duration)

    // Create a simple tone sweep (simulating speech formants)
    var audioSamples: [Double] = []
    for i in 0 ..< numSamples {
        let t = Double(i) / sampleRate
        // Simple formant-like frequencies
        let f1 = 700.0 + 200.0 * sin(2 * .pi * 2.0 * t) // First formant
        let f2 = 1200.0 + 300.0 * sin(2 * .pi * 3.0 * t) // Second formant

        let sample = 0.3 * sin(2 * .pi * f1 * t) + 0.2 * sin(2 * .pi * f2 * t)
        audioSamples.append(sample)
    }

    print("Processing \(numSamples) audio samples...")

    // Process speech
    let result = speechRecognizer.processSpeech(audioSamples)

    print("Processing time: \(String(format: "%.3f", result.processingTime))s")
    print("Spike count: \(result.spikeCount)")
    print("Spike efficiency: \(String(format: "%.1f", result.spikeEfficiency)) spikes/s")
    print("Detected phonemes: \(result.detectedPhonemes.joined(separator: ", "))")
    print("Recognized words: \(result.recognizedWords.joined(separator: ", "))")
    print("Confidence: \(String(format: "%.3f", result.confidence))")

    print()
}

func demonstrateSoundLocalization() {
    print("📍 Demonstrating Sound Localization")
    print("==================================================")

    let localizationSystem = BinauralLocalizationSystem()

    // Create binaural audio with ITD (simulating sound from the right)
    let sampleRate = 44100.0
    let duration = 0.5 // 0.5 seconds
    let numSamples = Int(sampleRate * duration)
    let itdSamples = Int(0.0003 * sampleRate) // 0.3ms ITD for 30-degree angle

    // Generate click sound
    let clickDuration = Int(0.001 * sampleRate) // 1ms click
    var clickSound: [Double] = []
    for i in 0 ..< numSamples {
        if i < clickDuration {
            clickSound.append(sin(.pi * Double(i) / Double(clickDuration))) // Rising click
        } else {
            clickSound.append(0.0)
        }
    }

    // Create binaural signals
    var leftAudio = clickSound // Direct sound
    var rightAudio = Array(repeating: 0.0, count: itdSamples) + clickSound // Delayed sound
    rightAudio = Array(rightAudio.prefix(numSamples)) // Trim to same length

    print("Processing binaural audio (simulated 30° right sound)...")

    let result = localizationSystem.localizeSound(leftAudio: leftAudio, rightAudio: rightAudio)

    print("Processing time: \(String(format: "%.3f", result.processingTime))s")
    print("Estimated direction: \(String(format: "%.1f", result.estimatedDirection))°")
    print("Direction: \(result.directionDescription)")
    print("Confidence: \(String(format: "%.3f", result.confidence))")
    print(
        "ITD range: \(String(format: "%.3f", result.itdValues.min() ?? 0)) to \(String(format: "%.3f", result.itdValues.max() ?? 0))"
    )
    print(
        "ILD range: \(String(format: "%.1f", result.ildValues.min() ?? 0))dB to \(String(format: "%.1f", result.ildValues.max() ?? 0))dB"
    )

    print()
}

func demonstrateCochlearProcessing() {
    print("👂 Demonstrating Cochlear Processing")
    print("==================================================")

    let cochlea = BasilarMembrane(numSegments: 50)

    // Create test signal with multiple frequencies
    let sampleRate = 44100.0
    let duration = 0.1 // 100ms
    let numSamples = Int(sampleRate * duration)

    var testSignal: [Double] = []
    for i in 0 ..< numSamples {
        let t = Double(i) / sampleRate
        // Mix of 500Hz, 1000Hz, and 2000Hz tones
        let sample =
            0.3 * sin(2 * .pi * 500.0 * t) + 0.2 * sin(2 * .pi * 1000.0 * t) + 0.1
                * sin(2 * .pi * 2000.0 * t)
        testSignal.append(sample)
    }

    print("Processing multi-frequency signal...")

    let responses = cochlea.processAudioSignal(testSignal)

    // Find peak responses for each frequency
    var peakFrequencies: [(frequency: Double, peakResponse: Double)] = []
    for (index, response) in responses.enumerated() {
        let peak = response.max() ?? 0.0
        if peak > 0.01 { // Significant response
            peakFrequencies.append((cochlea.segments[index].resonantFrequency, peak))
        }
    }

    // Sort by peak response
    peakFrequencies.sort { $0.peakResponse > $1.peakResponse }

    print("Top frequency responses:")
    for (freq, peak) in peakFrequencies.prefix(5) {
        print("  \(String(format: "%.0f", freq))Hz: \(String(format: "%.3f", peak))")
    }

    print("Frequency analysis completed with \(responses.count) channels")

    print()
}

// MARK: - Neuromorphic Robotics Demonstration

func demonstrateNeuromorphicRobotics() {
    print("🤖 Demonstrating Neuromorphic Robotics")
    print("=======================================")

    let robotController = NeuromorphicRobotController()

    // Simulate a scenario with visual obstacles and auditory cues
    var sensoryInput = SensoryInput()

    // Add visual obstacles
    sensoryInput.visualData = VisualData(
        position: SIMD3(1.0, 0.5, 0.0),
        objects: [
            VisualObject(position: SIMD3(1.5, 0.0, 0.0), size: SIMD3(0.5, 0.5, 1.0), type: "obstacle", confidence: 0.8),
            VisualObject(position: SIMD3(-1.0, 1.0, 0.0), size: SIMD3(0.3, 0.3, 0.8), type: "target", confidence: 0.9),
        ]
    )

    // Add auditory cue
    sensoryInput.auditoryData = AuditoryData(direction: 45.0, distance: 2.0, soundType: "speech")

    // Add proprioceptive data
    sensoryInput.proprioceptiveData = ProprioceptiveData()
    sensoryInput.proprioceptiveData.jointAngles = [0.1, -0.2, 0.3, 0.0, 0.1, -0.1, 0.2, 0.0, -0.1, 0.1]

    // Add tactile sensors
    sensoryInput.tactileData = [0.0, 0.0, 0.1, 0.0, 0.0] // Slight touch on one sensor

    print("Initial robot state:")
    print("  Position: (0.00, 0.00, 0.00)")
    print("  Energy: 100%")
    print("Sensory input:")
    print("  Visual: 2 objects detected (1 obstacle, 1 target)")
    print("  Auditory: Speech at 45° direction")
    print("  Tactile: Light touch detected")

    // Run control loop for several time steps
    var time: TimeInterval = 0.0
    let timeStep: TimeInterval = 0.1 // 100ms

    for step in 0 ..< 10 {
        print("\nTime step \(step + 1):")

        let action = robotController.controlLoop(sensoryInput: sensoryInput, time: time)

        print("  Active behaviors: \(action.behaviorState.activeBehaviors.map(\.name).joined(separator: ", "))")
        print("  Motor commands: \(action.commands.count)")

        if let firstCommand = action.commands.first {
            print("  Primary command: \(firstCommand.description)")
        }

        // Update robot state display
        let pos = robotController.currentState.position
        let energy = robotController.currentState.energyLevel
        print("  Robot position: (\(String(format: "%.2f", pos.x)), \(String(format: "%.2f", pos.y)), \(String(format: "%.2f", pos.z)))")
        print("  Energy remaining: \(String(format: "%.1f", energy * 100))%")

        time += timeStep

        // Simulate changing sensory conditions
        if step == 3 {
            // Add more obstacles
            sensoryInput.visualData?.objects.append(
                VisualObject(position: SIMD3(0.5, -1.0, 0.0), size: SIMD3(0.4, 0.4, 0.6), type: "obstacle", confidence: 0.7)
            )
            print("  Environment change: Additional obstacle detected!")
        }

        if step == 6 {
            // Change auditory cue
            sensoryInput.auditoryData = AuditoryData(direction: -30.0, distance: 1.5, soundType: "alarm")
            print("  Environment change: Alarm sound detected at -30°!")
        }
    }

    print("\nFinal robot state:")
    let finalPos = robotController.currentState.position
    let finalEnergy = robotController.currentState.energyLevel
    print("  Position: (\(String(format: "%.2f", finalPos.x)), \(String(format: "%.2f", finalPos.y)), \(String(format: "%.2f", finalPos.z)))")
    print("  Energy: \(String(format: "%.1f", finalEnergy * 100))%")
    print("  Behaviors demonstrated: Obstacle avoidance, object tracking, exploration")

    print()
}

// MARK: - Hybrid Neuro-Quantum Systems Demonstration

func demonstrateHybridNeuroQuantum() {
    print("🧠 Demonstrating Hybrid Neuro-Quantum Systems")
    print("==============================================")

    // Create quantum processor and neural network
    let quantumProcessor = MockQuantumProcessor()
    let neuralNetwork = NeuromorphicNetwork()

    // Create hybrid interface
    let hybridInterface = QuantumNeuralInterface(quantumProcessor: quantumProcessor, neuralNetwork: neuralNetwork)

    // Test different processing modes
    let testInput = [0.5, 0.3, 0.8, 0.2, 0.6, 0.1, 0.9, 0.4]

    print("Test input: \(testInput.map { String(format: "%.1f", $0) }.joined(separator: ", "))")

    // Test neuromorphic-only processing
    print("\n1. Neuromorphic-only processing:")
    hybridInterface.hybridMode = .neuromorphicOnly
    let neuralResult = hybridInterface.processHybrid(testInput, taskType: .classification)
    print("   Result: \(neuralResult.hybridOutput.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
    print("   Time: \(String(format: "%.3f", neuralResult.processingTime))s, Confidence: \(String(format: "%.3f", neuralResult.confidence))")

    // Test quantum-only processing
    print("\n2. Quantum-only processing:")
    hybridInterface.hybridMode = .quantumOnly
    let quantumResult = hybridInterface.processHybrid(testInput, taskType: .classification)
    print("   Result: \(quantumResult.hybridOutput.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
    print("   Time: \(String(format: "%.3f", quantumResult.processingTime))s, Confidence: \(String(format: "%.3f", quantumResult.confidence))")

    // Test hybrid parallel processing
    print("\n3. Hybrid parallel processing:")
    hybridInterface.hybridMode = .hybridParallel
    let parallelResult = hybridInterface.processHybrid(testInput, taskType: .classification)
    print("   Neural: \(parallelResult.neuralOutput.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
    print("   Quantum: \(parallelResult.quantumOutput.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
    print("   Hybrid: \(parallelResult.hybridOutput.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
    print("   Time: \(String(format: "%.3f", parallelResult.processingTime))s, Confidence: \(String(format: "%.3f", parallelResult.confidence))")

    // Test adaptive processing
    print("\n4. Adaptive processing (complex input):")
    let complexInput = [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0.05] // More complex signal
    hybridInterface.hybridMode = .adaptive
    let adaptiveResult = hybridInterface.processHybrid(complexInput, taskType: .optimization)
    print("   Input complexity triggers quantum processing")
    print("   Result: \(adaptiveResult.hybridOutput.map { String(format: "%.3f", $0) }.joined(separator: ", "))")
    print("   Mode: \(adaptiveResult.processingMode), Time: \(String(format: "%.3f", adaptiveResult.processingTime))s")

    // Demonstrate quantum-enhanced learning
    print("\n5. Quantum-enhanced learning:")
    let quantumNetwork = QuantumNeuromorphicNetwork(quantumProcessor: quantumProcessor)
    quantumNetwork.addQuantumNeuron(quantumProcessor)

    let learningResult = quantumNetwork.processQuantumNeural(testInput)
    print("   Quantum-neural network output: \(learningResult.map { String(format: "%.3f", $0) }.joined(separator: ", "))")

    // Demonstrate complete hybrid intelligence system
    print("\n6. Complete hybrid intelligence system:")
    let intelligenceSystem = HybridIntelligenceSystem(quantumProcessor: quantumProcessor)

    let classificationTask = intelligenceSystem.performIntelligentTask(testInput, task: .classify)
    print("   Classification: \(classificationTask.description)")

    let optimizationTask = intelligenceSystem.performIntelligentTask(complexInput, task: .optimize)
    print("   Optimization: \(optimizationTask.description)")

    let learningTask = intelligenceSystem.performIntelligentTask(testInput, task: .learn)
    print("   Learning: \(learningTask.description)")

    print("\nHybrid systems demonstrated: Adaptive processing, quantum-enhanced learning, and intelligent task execution.")

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
        demonstrateNeuromorphicAudio()
        demonstrateSoundLocalization()
        demonstrateCochlearProcessing()
        demonstrateNeuromorphicRobotics()
        demonstrateHybridNeuroQuantum()

        print("✅ All demonstrations completed successfully!")
        print("==================================================")
        print("Phase 7B neuromorphic foundations established.")
        print("Ready for quantum-neuromorphic hybrid integration.")
    }
}
