// Spiking Neural Networks Implementation
// Phase 7B: Event-driven neural processing for energy efficiency
// Task 74: Spiking Neural Networks

import Foundation

// MARK: - Spiking Neuron Models

/// Leaky Integrate-and-Fire (LIF) neuron model
public class LIFNeuron: NeuromorphicNeuron {
    public var leakRate: Double
    public var restingPotential: Double

    public init(
        threshold: Double = 1.0,
        leakRate: Double = 0.9,
        restingPotential: Double = 0.0,
        refractoryPeriod: TimeInterval = 0.005
    ) {
        self.leakRate = leakRate
        self.restingPotential = restingPotential
        super.init(threshold: threshold, refractoryPeriod: refractoryPeriod)
    }

    /// Update membrane potential with leaky integration
    override public func processSpike(_ spike: NeuromorphicSpike, at time: TimeInterval) -> Bool {
        // Apply leak
        membranePotential = restingPotential + (membranePotential - restingPotential) * leakRate

        // Add synaptic input
        let synapticEffect = spike.weight * exp(-(time - spike.timestamp) / spike.decayTime)
        membranePotential += synapticEffect

        // Check for spiking
        if membranePotential >= threshold {
            fire(at: time)
            return true
        }

        return false
    }
}

/// Adaptive Exponential Integrate-and-Fire (AdEx) neuron model
public class AdExNeuron: LIFNeuron {
    public var adaptationCurrent: Double = 0.0
    public var adaptationTimeConstant: Double
    public var adaptationCoupling: Double
    public var slopeFactor: Double

    public init(
        threshold: Double = 1.0,
        adaptationTimeConstant: Double = 0.1,
        adaptationCoupling: Double = 2.0,
        slopeFactor: Double = 2.0
    ) {
        self.adaptationTimeConstant = adaptationTimeConstant
        self.adaptationCoupling = adaptationCoupling
        self.slopeFactor = slopeFactor
        super.init(threshold: threshold)
    }

    override public func processSpike(_ spike: NeuromorphicSpike, at time: TimeInterval) -> Bool {
        // Update adaptation current
        adaptationCurrent *= exp(-0.001 / adaptationTimeConstant) // dt = 1ms

        // Exponential term for spike initiation
        let exponentialTerm = slopeFactor * exp((membranePotential - threshold) / slopeFactor)

        // Update membrane potential
        let dv = -membranePotential + exponentialTerm - adaptationCurrent
        membranePotential += dv * 0.001 // dt = 1ms

        // Add synaptic input
        let synapticEffect = spike.weight * exp(-(time - spike.timestamp) / spike.decayTime)
        membranePotential += synapticEffect

        // Check for spiking
        if membranePotential >= threshold {
            fire(at: time)
            adaptationCurrent += adaptationCoupling
            return true
        }

        return false
    }
}

/// Izhikevich neuron model - computationally efficient
public class IzhikevichNeuron: NeuromorphicNeuron {
    public var recoveryVariable: Double = 0.0
    public var a: Double // Recovery time constant
    public var b: Double // Recovery sensitivity
    public var c: Double // Reset value
    public var d: Double // Recovery reset

    public init(a: Double = 0.02, b: Double = 0.2, c: Double = -65.0, d: Double = 8.0) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        super.init(threshold: 30.0)
    }

    override public func processSpike(_ spike: NeuromorphicSpike, at time: TimeInterval) -> Bool {
        // Izhikevich model equations
        let dv =
            0.04 * membranePotential * membranePotential + 5.0 * membranePotential + 140.0
                - recoveryVariable
        let du = a * (b * membranePotential - recoveryVariable)

        membranePotential += dv * 0.001 // dt = 1ms
        recoveryVariable += du * 0.001

        // Add synaptic input
        let synapticEffect = spike.weight * exp(-(time - spike.timestamp) / spike.decayTime)
        membranePotential += synapticEffect

        // Check for spiking
        if membranePotential >= threshold {
            fire(at: time)
            membranePotential = c
            recoveryVariable += d
            return true
        }

        return false
    }
}

// MARK: - Spiking Neural Network Architectures

/// Feedforward Spiking Neural Network
public class FeedforwardSNN: NeuromorphicNetwork {

    public func createNetwork(layerSizes: [Int], neuronType: NeuronType = .lif) {
        layers = []

        // Create layers
        for (layerIndex, size) in layerSizes.enumerated() {
            var layer: [NeuromorphicNeuron] = []

            for _ in 0 ..< size {
                let neuron: NeuromorphicNeuron
                switch neuronType {
                case .lif:
                    neuron = LIFNeuron()
                case .adex:
                    neuron = AdExNeuron()
                case .izhikevich:
                    neuron = IzhikevichNeuron()
                }

                addNeuron(neuron)
                layer.append(neuron)
            }

            layers.append(layer)

            // Set input/output layers
            if layerIndex == 0 {
                inputLayer = layer
            } else if layerIndex == layerSizes.count - 1 {
                outputLayer = layer
            } else {
                hiddenLayers.append(layer)
            }
        }

        // Create connections between layers
        for i in 0 ..< (layers.count - 1) {
            connectLayers(from: layers[i], to: layers[i + 1])
        }
    }

    private func connectLayers(
        from sourceLayer: [NeuromorphicNeuron], to targetLayer: [NeuromorphicNeuron]
    ) {
        for sourceNeuron in sourceLayer {
            for targetNeuron in targetLayer {
                let weight = Double.random(in: 0.1 ... 0.9)
                let delay = Double.random(in: 0.001 ... 0.005)
                connect(from: sourceNeuron, to: targetNeuron, weight: weight, delay: delay)
            }
        }
    }

    public enum NeuronType {
        case lif, adex, izhikevich
    }
}

/// Recurrent Spiking Neural Network
public class RecurrentSNN: NeuromorphicNetwork {
    public var recurrentConnections: [NeuromorphicSynapse] = []

    public func createRecurrentNetwork(layerSizes: [Int], recurrentProbability: Double = 0.1) {
        // Create feedforward structure first
        let ffnn = FeedforwardSNN()
        ffnn.createNetwork(layerSizes: layerSizes)
        neurons = ffnn.neurons
        layers = ffnn.layers
        inputLayer = ffnn.inputLayer
        outputLayer = ffnn.outputLayer
        hiddenLayers = ffnn.hiddenLayers

        // Add recurrent connections within layers
        for layer in layers {
            for i in 0 ..< layer.count {
                for j in 0 ..< layer.count {
                    if i != j && Double.random(in: 0 ... 1) < recurrentProbability {
                        let weight = Double.random(in: -0.5 ... 0.5) // Can be inhibitory
                        let delay = Double.random(in: 0.001 ... 0.01)
                        let synapse = connect(
                            from: layer[i], to: layer[j], weight: weight, delay: delay
                        )
                        recurrentConnections.append(synapse)
                    }
                }
            }
        }
    }
}

/// Convolutional Spiking Neural Network
public class ConvolutionalSNN: NeuromorphicNetwork {
    public var convLayers: [ConvLayer] = []

    public struct ConvLayer {
        public var kernels: [[NeuromorphicNeuron]] // 2D array of neurons
        public var kernelSize: (width: Int, height: Int)
        public var stride: Int
        public var inputSize: (width: Int, height: Int)
        public var outputSize: (width: Int, height: Int)

        public init(
            kernels: [[NeuromorphicNeuron]],
            kernelSize: (width: Int, height: Int),
            stride: Int,
            inputSize: (width: Int, height: Int)
        ) {
            self.kernels = kernels
            self.kernelSize = kernelSize
            self.stride = stride
            self.inputSize = inputSize

            let outputWidth = (inputSize.width - kernelSize.width) / stride + 1
            let outputHeight = (inputSize.height - kernelSize.height) / stride + 1
            self.outputSize = (width: outputWidth, height: outputHeight)
        }
    }

    public func addConvLayer(
        inputSize: (width: Int, height: Int),
        kernelSize: (width: Int, height: Int),
        numKernels: Int,
        stride: Int = 1
    ) {
        var kernels: [[NeuromorphicNeuron]] = []

        for _ in 0 ..< numKernels {
            var kernel: [NeuromorphicNeuron] = []
            for _ in 0 ..< (kernelSize.width * kernelSize.height) {
                let neuron = LIFNeuron()
                addNeuron(neuron)
                kernel.append(neuron)
            }
            kernels.append(kernel)
        }

        let convLayer = ConvLayer(
            kernels: kernels,
            kernelSize: kernelSize,
            stride: stride,
            inputSize: inputSize
        )
        convLayers.append(convLayer)
    }

    public func connectConvLayers(
        from input: [NeuromorphicNeuron],
        to convLayer: ConvLayer,
        inputSize: (width: Int, height: Int)
    ) {
        let (inputWidth, inputHeight) = inputSize
        let (kernelWidth, kernelHeight) = convLayer.kernelSize
        let stride = convLayer.stride

        for kernelIndex in 0 ..< convLayer.kernels.count {
            let kernel = convLayer.kernels[kernelIndex]

            for y in stride ..< inputHeight where (y - kernelHeight + 1) % stride == 0 {
                for x in stride ..< inputWidth where (x - kernelWidth + 1) % stride == 0 {
                    // Connect receptive field to kernel neurons
                    var kernelNeuronIndex = 0
                    for ky in 0 ..< kernelHeight {
                        for kx in 0 ..< kernelWidth {
                            let inputX = x + kx - kernelWidth + 1
                            let inputY = y + ky - kernelHeight + 1

                            if inputX >= 0 && inputX < inputWidth && inputY >= 0
                                && inputY < inputHeight
                            {
                                let inputIndex = inputY * inputWidth + inputX
                                if inputIndex < input.count {
                                    let weight = Double.random(in: 0.1 ... 0.9)
                                    connect(
                                        from: input[inputIndex],
                                        to: kernel[kernelNeuronIndex],
                                        weight: weight
                                    )
                                }
                            }
                            kernelNeuronIndex += 1
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Event-Driven Processing

/// Event queue for spike processing
public class SpikeEventQueue {
    private var events: [(time: TimeInterval, spike: NeuromorphicSpike)] = []
    private let queue = DispatchQueue(label: "com.neuromorphic.spikequeue", qos: .userInitiated)

    public func enqueue(_ spike: NeuromorphicSpike, at time: TimeInterval) {
        queue.async {
            self.events.append((time: time, spike: spike))
            self.events.sort { $0.time < $1.time } // Keep sorted by time
        }
    }

    public func dequeue() -> (time: TimeInterval, spike: NeuromorphicSpike)? {
        queue.sync {
            guard !events.isEmpty else { return nil }
            return events.removeFirst()
        }
    }

    public func peek() -> (time: TimeInterval, spike: NeuromorphicSpike)? {
        queue.sync {
            events.first
        }
    }

    public var isEmpty: Bool {
        queue.sync { events.isEmpty }
    }

    public var count: Int {
        queue.sync { events.count }
    }
}

/// Real-time spike processor
public class RealTimeSpikeProcessor {
    public let eventQueue = SpikeEventQueue()
    public var neurons: [UUID: NeuromorphicNeuron] = [:]
    public var currentTime: TimeInterval = 0.0
    public let timeStep: TimeInterval = 0.001 // 1ms resolution

    public func registerNeuron(_ neuron: NeuromorphicNeuron) {
        neurons[neuron.id] = neuron
    }

    public func processTimeStep() {
        // Process events for this time step
        while let event = eventQueue.peek(), event.time <= currentTime {
            _ = eventQueue.dequeue() // Remove from queue
            if let neuron = neurons[event.spike.targetSynapse.postsynapticNeuron.id] {
                let spiked = neuron.processSpike(event.spike, at: event.time)
                if spiked {
                    // Handle output spike
                    handleOutputSpike(event.spike, from: neuron)
                }
            }
        }

        currentTime += timeStep
    }

    private func handleOutputSpike(_ spike: NeuromorphicSpike, from neuron: NeuromorphicNeuron) {
        // Propagate to connected neurons
        if let axon = neuron.axon {
            for synapse in axon.synapses {
                let propagatedSpike = NeuromorphicSpike(
                    sourceNeuron: neuron,
                    targetSynapse: synapse,
                    timestamp: currentTime + synapse.delay,
                    weight: synapse.weight
                )
                eventQueue.enqueue(propagatedSpike, at: currentTime + synapse.delay)
            }
        }
    }

    public func injectInputSpike(targetNeuronId: UUID, weight: Double) {
        guard let neuron = neurons[targetNeuronId] else { return }

        // Create artificial input synapse
        let dummySynapse = NeuromorphicSynapse(
            from: NeuromorphicNeuron(),
            to: neuron,
            weight: weight
        )

        let spike = NeuromorphicSpike(
            sourceNeuron: dummySynapse.presynapticNeuron,
            targetSynapse: dummySynapse,
            timestamp: currentTime,
            weight: weight
        )

        eventQueue.enqueue(spike, at: currentTime)
    }
}

// MARK: - Energy-Efficient Processing

/// Power-aware spike processing
public class EnergyEfficientProcessor {
    public var powerBudget: Double // Watts
    public var currentPower: Double = 0.0
    public var energyEfficiency: Double = 0.0

    private var neuronActivity: [UUID: TimeInterval] = [:]
    private var lastActivityTime: [UUID: TimeInterval] = [:]

    public init(powerBudget: Double = 1.0) {
        self.powerBudget = powerBudget
    }

    /// Calculate power consumption for spike processing
    public func calculatePowerConsumption(for neuron: NeuromorphicNeuron, spikeCount: Int) -> Double {
        // Power model: base power + spike processing power
        let basePower = 0.001 // 1mW base
        let spikePower = Double(spikeCount) * 0.01 // 10mW per spike
        return basePower + spikePower
    }

    /// Optimize processing based on power constraints
    public func optimizeForPower(_ neurons: [NeuromorphicNeuron]) -> [NeuromorphicNeuron] {
        // Sort neurons by recent activity (prioritize active neurons)
        let sortedNeurons = neurons.sorted { n1, n2 -> Bool in
            let activity1 = neuronActivity[n1.id, default: 0.0]
            let activity2 = neuronActivity[n2.id, default: 0.0]
            return activity1 > activity2
        }

        // Select neurons within power budget
        var selectedNeurons: [NeuromorphicNeuron] = []
        var totalPower = 0.0

        for neuron in sortedNeurons {
            let neuronPower = calculatePowerConsumption(for: neuron, spikeCount: 1)
            if totalPower + neuronPower <= powerBudget {
                selectedNeurons.append(neuron)
                totalPower += neuronPower
            } else {
                break
            }
        }

        currentPower = totalPower
        energyEfficiency = Double(selectedNeurons.count) / Double(neurons.count)

        return selectedNeurons
    }

    /// Update neuron activity tracking
    public func updateActivity(for neuronId: UUID, at time: TimeInterval) {
        neuronActivity[neuronId, default: 0.0] += 1.0
        lastActivityTime[neuronId] = time
    }

    /// Decay activity over time (implement forgetting)
    public func decayActivity(decayRate: Double = 0.99) {
        for (neuronId, activity) in neuronActivity {
            neuronActivity[neuronId] = activity * decayRate

            // Remove inactive neurons
            if let lastTime = lastActivityTime[neuronId],
               Date.timeIntervalSinceReferenceDate - lastTime > 60.0
            { // 1 minute
                neuronActivity.removeValue(forKey: neuronId)
                lastActivityTime.removeValue(forKey: neuronId)
            }
        }
    }
}

// MARK: - Integration with Quantum Processing

/// Quantum-enhanced spiking neural network
public class QuantumSNN: FeedforwardSNN {
    public var quantumProcessor: QuantumProcessor?
    public var quantumLayers: Set<Int> = [] // Layer indices that use quantum processing

    public func enableQuantumLayer(at index: Int) {
        quantumLayers.insert(index)
    }

    override public func processInput(_ inputSpikes: [NeuromorphicSpike]) {
        guard let quantumProcessor else {
            super.processInput(inputSpikes)
            return
        }

        // Process layers sequentially, using quantum processing where enabled
        var currentSpikes = inputSpikes

        for (layerIndex, layer) in layers.enumerated() {
            if quantumLayers.contains(layerIndex) {
                // Use quantum processing for this layer
                let layerInput = convertSpikesToVector(currentSpikes)
                let quantumOutput = quantumProcessor.processQuantum(layerInput)
                currentSpikes = convertVectorToSpikes(quantumOutput, targetLayer: layer)
            } else {
                // Use traditional spiking processing
                processLayerSpikes(currentSpikes, layer: layer)
                currentSpikes = [] // Will be populated by layer processing
            }
        }
    }

    private func convertSpikesToVector(_ spikes: [NeuromorphicSpike]) -> [Double] {
        // Convert spike train to continuous values
        var vector: [Double] = Array(repeating: 0.0, count: spikes.count)
        for (index, spike) in spikes.enumerated() {
            vector[index] = spike.weight
        }
        return vector
    }

    private func convertVectorToSpikes(_ vector: [Double], targetLayer: [NeuromorphicNeuron])
        -> [NeuromorphicSpike]
    {
        var spikes: [NeuromorphicSpike] = []

        for (index, value) in vector.enumerated() {
            if index < targetLayer.count && value > 0.5 {
                let neuron = targetLayer[index]
                let dummySynapse = NeuromorphicSynapse(
                    from: NeuromorphicNeuron(), to: neuron, weight: value
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

    private func processLayerSpikes(_ spikes: [NeuromorphicSpike], layer: [NeuromorphicNeuron]) {
        for spike in spikes {
            _ = spike.targetSynapse.postsynapticNeuron.processSpike(spike, at: spike.timestamp)
        }
    }
}
