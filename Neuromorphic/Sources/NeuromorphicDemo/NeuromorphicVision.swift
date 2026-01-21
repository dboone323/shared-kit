// Neuromorphic Vision System
// Phase 7B: Advanced computer vision with brain-inspired processing
// Task 76: Neuromorphic Vision

import CoreGraphics
import Foundation

// MARK: - Visual Processing Components

/// Retina-inspired visual sensor
public class NeuromorphicRetina {
    public var resolution: (width: Int, height: Int)
    public var receptiveFields: [[ReceptiveField]] = []
    public var ganglionCells: [NeuromorphicNeuron] = []

    public struct ReceptiveField {
        public var center: (x: Int, y: Int)
        public var radius: Int
        public var onCenter: Bool // ON-center or OFF-center
        public var sensitivity: Double

        public init(
            center: (x: Int, y: Int), radius: Int, onCenter: Bool = true, sensitivity: Double = 1.0
        ) {
            self.center = center
            self.radius = radius
            self.onCenter = onCenter
            self.sensitivity = sensitivity
        }

        public func processPixel(intensity: Double, at position: (x: Int, y: Int)) -> Double {
            let distance = sqrt(
                pow(Double(position.x - center.x), 2) + pow(Double(position.y - center.y), 2))

            if distance <= Double(radius) {
                let gaussian = exp(-pow(distance, 2) / (2 * pow(Double(radius) / 3, 2)))
                let response = onCenter ? intensity * gaussian : (1.0 - intensity) * gaussian
                return response * sensitivity
            }

            return 0.0
        }
    }

    public init(resolution: (width: Int, height: Int), fieldSize: Int = 5) {
        self.resolution = resolution

        // Create receptive fields
        for y in 0 ..< resolution.height {
            var row: [ReceptiveField] = []
            for x in 0 ..< resolution.width {
                let onCenter = ((x + y) % 2 == 0) // Checkerboard pattern
                let field = ReceptiveField(center: (x, y), radius: fieldSize, onCenter: onCenter)
                row.append(field)
            }
            receptiveFields.append(row)
        }

        // Create ganglion cells
        for _ in 0 ..< (resolution.width * resolution.height) {
            let ganglionCell = LIFNeuron(threshold: 0.7, leakRate: 0.95)
            ganglionCells.append(ganglionCell)
        }
    }

    public func processImage(_ image: [[Double]]) -> [NeuromorphicSpike] {
        var spikes: [NeuromorphicSpike] = []

        for y in 0 ..< min(resolution.height, image.count) {
            for x in 0 ..< min(resolution.width, image[y].count) {
                let intensity = image[y][x]
                let field = receptiveFields[y][x]
                let response = field.processPixel(intensity: intensity, at: (x, y))

                // Generate spike if response is strong enough
                if response > 0.5 {
                    let ganglionIndex = y * resolution.width + x
                    let ganglionCell = ganglionCells[ganglionIndex]

                    let dummySynapse = NeuromorphicSynapse(
                        from: NeuromorphicNeuron(),
                        to: ganglionCell,
                        weight: response
                    )

                    let spike = NeuromorphicSpike(
                        sourceNeuron: dummySynapse.presynapticNeuron,
                        targetSynapse: dummySynapse,
                        timestamp: 0.0,
                        weight: response
                    )

                    spikes.append(spike)
                }
            }
        }

        return spikes
    }

    public func processImageAsync(_ image: [[Double]]) async -> [NeuromorphicSpike] {
        // Simplified synchronous version for compatibility
        processImage(image)
    }
}

/// Lateral Geniculate Nucleus (LGN) model
public class LGNLayer {
    public var magnocellularCells: [NeuromorphicNeuron] = [] // Motion/parallax
    public var parvocellularCells: [NeuromorphicNeuron] = [] // Color/form
    public var koniocellularCells: [NeuromorphicNeuron] = [] // Blue color

    public init(cellCount: Int = 100) {
        // Create different cell types
        for _ in 0 ..< cellCount {
            magnocellularCells.append(LIFNeuron(threshold: 0.6, leakRate: 0.9))
            parvocellularCells.append(LIFNeuron(threshold: 0.8, leakRate: 0.95))
            koniocellularCells.append(LIFNeuron(threshold: 0.7, leakRate: 0.92))
        }
    }

    public func processRetinalInput(_ retinalSpikes: [NeuromorphicSpike]) -> [NeuromorphicSpike] {
        var lgnSpikes: [NeuromorphicSpike] = []

        // Distribute retinal input to different pathways
        for spike in retinalSpikes {
            // Magnocellular pathway (fast, motion-sensitive)
            if let magCell = magnocellularCells.randomElement() {
                let magSynapse = NeuromorphicSynapse(
                    from: spike.sourceNeuron, to: magCell, weight: 0.8
                )
                let magSpike = NeuromorphicSpike(
                    sourceNeuron: spike.sourceNeuron,
                    targetSynapse: magSynapse,
                    timestamp: spike.timestamp + 0.001,
                    weight: spike.weight * 0.8
                )
                lgnSpikes.append(magSpike)
            }

            // Parvocellular pathway (detailed, color-sensitive)
            if let parCell = parvocellularCells.randomElement() {
                let parSynapse = NeuromorphicSynapse(
                    from: spike.sourceNeuron, to: parCell, weight: 0.9
                )
                let parSpike = NeuromorphicSpike(
                    sourceNeuron: spike.sourceNeuron,
                    targetSynapse: parSynapse,
                    timestamp: spike.timestamp + 0.002,
                    weight: spike.weight * 0.9
                )
                lgnSpikes.append(parSpike)
            }

            // Koniocellular pathway (blue-sensitive)
            if Double.random(in: 0 ... 1) < 0.3 { // Less common
                if let konCell = koniocellularCells.randomElement() {
                    let konSynapse = NeuromorphicSynapse(
                        from: spike.sourceNeuron, to: konCell, weight: 0.7
                    )
                    let konSpike = NeuromorphicSpike(
                        sourceNeuron: spike.sourceNeuron,
                        targetSynapse: konSynapse,
                        timestamp: spike.timestamp + 0.003,
                        weight: spike.weight * 0.7
                    )
                    lgnSpikes.append(konSpike)
                }
            }
        }

        return lgnSpikes
    }
}

// MARK: - Visual Cortex Models

/// Primary Visual Cortex (V1) model
public class V1Cortex {
    public var simpleCells: [SimpleCell] = [] // Orientation selective
    public var complexCells: [ComplexCell] = [] // Motion sensitive
    public var hypercomplexCells: [HypercomplexCell] = [] // End-stopped

    public class SimpleCell {
        public var preferredOrientation: Double // In radians
        public var receptiveFieldSize: (width: Int, height: Int)
        public var neurons: [NeuromorphicNeuron] = []

        public init(orientation: Double, fieldSize: (width: Int, height: Int)) {
            self.preferredOrientation = orientation
            self.receptiveFieldSize = fieldSize

            // Create neurons for different spatial frequencies
            for _ in 0 ..< 10 {
                neurons.append(LIFNeuron(threshold: 0.75, leakRate: 0.93))
            }
        }

        public func respondToStimulus(orientation: Double, contrast: Double) -> Double {
            // Gabor-like response
            let orientationDifference = abs(orientation - preferredOrientation)
            let orientationTuning = exp(-pow(orientationDifference, 2) / (2 * pow(.pi / 8, 2)))
            return orientationTuning * contrast
        }
    }

    public class ComplexCell {
        public var preferredOrientation: Double
        public var preferredSpeed: Double
        public var neurons: [NeuromorphicNeuron] = []

        public init(orientation: Double, speed: Double) {
            self.preferredOrientation = orientation
            self.preferredSpeed = speed

            for _ in 0 ..< 8 {
                neurons.append(LIFNeuron(threshold: 0.7, leakRate: 0.91))
            }
        }

        public func respondToMotion(orientation: Double, speed: Double, direction: Double) -> Double {
            let orientationMatch = exp(
                -pow(orientation - preferredOrientation, 2) / (2 * pow(.pi / 6, 2)))
            let speedMatch = exp(-pow(speed - preferredSpeed, 2) / (2 * pow(preferredSpeed / 2, 2)))
            return orientationMatch * speedMatch
        }
    }

    public class HypercomplexCell {
        public var preferredOrientation: Double
        public var endStopLength: Double
        public var neurons: [NeuromorphicNeuron] = []

        public init(orientation: Double, endStopLength: Double) {
            self.preferredOrientation = orientation
            self.endStopLength = endStopLength

            for _ in 0 ..< 6 {
                neurons.append(LIFNeuron(threshold: 0.8, leakRate: 0.94))
            }
        }

        public func respondToLine(length: Double, orientation: Double) -> Double {
            let orientationMatch = exp(
                -pow(orientation - preferredOrientation, 2) / (2 * pow(.pi / 8, 2)))
            let lengthInhibition = 1.0 / (1.0 + exp(length - endStopLength))
            return orientationMatch * lengthInhibition
        }
    }

    public init() {
        createOrientationColumns()
    }

    private func createOrientationColumns() {
        let orientations = stride(from: 0.0, to: .pi, by: .pi / 8) // 8 orientations

        for orientation in orientations {
            // Simple cells
            simpleCells.append(SimpleCell(orientation: orientation, fieldSize: (10, 10)))

            // Complex cells
            for speed in [1.0, 2.0, 4.0, 8.0] {
                complexCells.append(ComplexCell(orientation: orientation, speed: speed))
            }

            // Hypercomplex cells
            hypercomplexCells.append(
                HypercomplexCell(orientation: orientation, endStopLength: 20.0))
        }
    }

    public func processVisualInput(_ lgnSpikes: [NeuromorphicSpike]) -> [String:
        [NeuromorphicSpike]]
    {
        var responses: [String: [NeuromorphicSpike]] = [:]

        // Process through different cell types
        responses["simple"] = processSimpleCells(lgnSpikes)
        responses["complex"] = processComplexCells(lgnSpikes)
        responses["hypercomplex"] = processHypercomplexCells(lgnSpikes)

        return responses
    }

    private func processSimpleCells(_ spikes: [NeuromorphicSpike]) -> [NeuromorphicSpike] {
        var outputSpikes: [NeuromorphicSpike] = []

        for cell in simpleCells {
            let response = Double.random(in: 0 ... 1) // Simplified - would analyze spike patterns

            if response > 0.6 {
                if let neuron = cell.neurons.randomElement() {
                    let dummySynapse = NeuromorphicSynapse(
                        from: NeuromorphicNeuron(), to: neuron, weight: response
                    )
                    let spike = NeuromorphicSpike(
                        sourceNeuron: dummySynapse.presynapticNeuron,
                        targetSynapse: dummySynapse,
                        timestamp: 0.0,
                        weight: response
                    )
                    outputSpikes.append(spike)
                }
            }
        }

        return outputSpikes
    }

    private func processComplexCells(_ spikes: [NeuromorphicSpike]) -> [NeuromorphicSpike] {
        var outputSpikes: [NeuromorphicSpike] = []

        for cell in complexCells {
            let response = Double.random(in: 0 ... 1) // Would analyze motion patterns

            if response > 0.5 {
                if let neuron = cell.neurons.randomElement() {
                    let dummySynapse = NeuromorphicSynapse(
                        from: NeuromorphicNeuron(), to: neuron, weight: response
                    )
                    let spike = NeuromorphicSpike(
                        sourceNeuron: dummySynapse.presynapticNeuron,
                        targetSynapse: dummySynapse,
                        timestamp: 0.0,
                        weight: response
                    )
                    outputSpikes.append(spike)
                }
            }
        }

        return outputSpikes
    }

    private func processHypercomplexCells(_ spikes: [NeuromorphicSpike]) -> [NeuromorphicSpike] {
        var outputSpikes: [NeuromorphicSpike] = []

        for cell in hypercomplexCells {
            let response = Double.random(in: 0 ... 1) // Would analyze line segments

            if response > 0.7 {
                if let neuron = cell.neurons.randomElement() {
                    let dummySynapse = NeuromorphicSynapse(
                        from: NeuromorphicNeuron(), to: neuron, weight: response
                    )
                    let spike = NeuromorphicSpike(
                        sourceNeuron: dummySynapse.presynapticNeuron,
                        targetSynapse: dummySynapse,
                        timestamp: 0.0,
                        weight: response
                    )
                    outputSpikes.append(spike)
                }
            }
        }

        return outputSpikes
    }
}

/// Inferior Temporal (IT) Cortex - object recognition
public class ITCortex {
    public var objectTemplates: [String: [Double]] = [:] // Object feature templates
    public var recognitionNeurons: [NeuromorphicNeuron] = []

    public init(templateCount: Int = 1000) {
        for _ in 0 ..< templateCount {
            recognitionNeurons.append(LIFNeuron(threshold: 0.85, leakRate: 0.96))
        }
    }

    public func learnObject(name: String, features: [Double]) {
        objectTemplates[name] = features
    }

    public func recognizeObject(features: [Double]) -> (name: String?, confidence: Double) {
        var bestMatch: (name: String?, confidence: Double) = (nil, 0.0)

        for (name, template) in objectTemplates {
            let similarity = cosineSimilarity(features, template)
            if similarity > bestMatch.confidence {
                bestMatch = (name, similarity)
            }
        }

        return bestMatch
    }

    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dotProduct / (normA * normB)
    }
}

// MARK: - Complete Visual System

/// Hierarchical neuromorphic vision system
public class NeuromorphicVisionSystem {
    public var retina: NeuromorphicRetina
    public var lgn: LGNLayer
    public var v1: V1Cortex
    public var it: ITCortex

    public var processingMode: ProcessingMode = .realTime

    public enum ProcessingMode {
        case realTime // Low latency, lower accuracy
        case detailed // High accuracy, higher latency
        case energyEfficient // Balanced power consumption
    }

    public init(resolution: (width: Int, height: Int)) {
        self.retina = NeuromorphicRetina(resolution: resolution)
        self.lgn = LGNLayer()
        self.v1 = V1Cortex()
        self.it = ITCortex()
    }

    public func processImage(_ image: [[Double]]) -> VisionResult {
        let startTime = Date.timeIntervalSinceReferenceDate

        // Retina processing (synchronous version)
        let retinalSpikes = retina.processImage(image)

        // LGN processing
        let lgnSpikes = lgn.processRetinalInput(retinalSpikes)

        // V1 processing
        let v1Responses = v1.processVisualInput(lgnSpikes)

        // IT processing for object recognition
        let features = extractFeatures(from: v1Responses)
        let recognition = it.recognizeObject(features: features)

        let processingTime = Date.timeIntervalSinceReferenceDate - startTime

        return VisionResult(
            recognizedObjects: recognition.name.map { [$0] } ?? [],
            confidence: recognition.confidence,
            features: features,
            processingTime: processingTime,
            spikeCount: retinalSpikes.count + lgnSpikes.count
                + v1Responses.values.flatMap { $0 }.count
        )
    }

    private func extractFeatures(from v1Responses: [String: [NeuromorphicSpike]]) -> [Double] {
        var features: [Double] = []

        // Extract features from different V1 cell types
        for cellType in ["simple", "complex", "hypercomplex"] {
            if let spikes = v1Responses[cellType] {
                let activity = Double(spikes.count) / 100.0 // Normalize
                features.append(activity)
            } else {
                features.append(0.0)
            }
        }

        // Add orientation histogram features
        let orientations = (0 ..< 8).map { Double($0) * .pi / 8 }
        for orientation in orientations {
            let response =
                v1.simpleCells.first { abs($0.preferredOrientation - orientation) < 0.1 }?.neurons
                    .count ?? 0
            features.append(Double(response) / 10.0)
        }

        return features
    }

    public func learnObject(name: String, image: [[Double]]) {
        let result = processImage(image)
        it.learnObject(name: name, features: result.features)
    }

    public func getSystemMetrics() -> [String: Double] {
        [
            "retina_cells": Double(retina.ganglionCells.count),
            "lgn_cells": Double(
                lgn.magnocellularCells.count + lgn.parvocellularCells.count
                    + lgn.koniocellularCells.count),
            "v1_simple_cells": Double(v1.simpleCells.count),
            "v1_complex_cells": Double(v1.complexCells.count),
            "it_templates": Double(it.objectTemplates.count),
        ]
    }
}

/// Vision processing result
public struct VisionResult {
    public let recognizedObjects: [String]
    public let confidence: Double
    public let features: [Double]
    public let processingTime: TimeInterval
    public let spikeCount: Int

    public var energyEfficiency: Double {
        Double(spikeCount) / processingTime // spikes per second
    }
}

// MARK: - Motion Processing

/// Motion-sensitive visual pathway
public class MotionPathway {
    public var directionSelectiveCells: [DirectionSelectiveCell] = []

    public class DirectionSelectiveCell {
        public var preferredDirection: Double // In radians
        public var neurons: [NeuromorphicNeuron] = []
        public var temporalBuffer: [Double] = []

        public init(direction: Double) {
            self.preferredDirection = direction
            for _ in 0 ..< 5 {
                neurons.append(LIFNeuron(threshold: 0.65, leakRate: 0.88))
            }
        }

        public func detectMotion(intensitySequence: [Double]) -> Double {
            temporalBuffer.append(contentsOf: intensitySequence)
            if temporalBuffer.count > 10 {
                temporalBuffer.removeFirst()
            }

            // Simple motion detection using temporal derivatives
            if temporalBuffer.count >= 2 {
                let derivative = temporalBuffer.last! - temporalBuffer[temporalBuffer.count - 2]
                return max(0, derivative) // Only positive changes (motion towards)
            }

            return 0.0
        }
    }

    public init() {
        // Create cells for different directions
        let directions = stride(from: 0.0, to: 2 * .pi, by: .pi / 4)
        for direction in directions {
            directionSelectiveCells.append(DirectionSelectiveCell(direction: direction))
        }
    }

    public func processMotionField(motionVectors: [(dx: Double, dy: Double)]) -> [Double] {
        var responses: [Double] = []

        for cell in directionSelectiveCells {
            var cellResponse = 0.0

            for vector in motionVectors {
                let direction = atan2(vector.dy, vector.dx)
                let directionMatch = exp(
                    -pow(direction - cell.preferredDirection, 2) / (2 * pow(.pi / 6, 2)))
                let speed = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)

                cellResponse += directionMatch * speed
            }

            responses.append(cellResponse / Double(motionVectors.count))
        }

        return responses
    }
}

// MARK: - Attention System

/// Visual attention mechanism
public class VisualAttentionSystem {
    public var saliencyMap: [[Double]] = []
    public var attentionFocus: (x: Int, y: Int)?
    public var attentionNeurons: [NeuromorphicNeuron] = []

    public init(mapSize: (width: Int, height: Int)) {
        saliencyMap = Array(
            repeating: Array(repeating: 0.0, count: mapSize.width), count: mapSize.height
        )

        for _ in 0 ..< (mapSize.width * mapSize.height) {
            attentionNeurons.append(LIFNeuron(threshold: 0.9, leakRate: 0.97))
        }
    }

    public func computeSaliency(features: [String: [[Double]]]) {
        // Reset saliency map
        for y in 0 ..< saliencyMap.count {
            for x in 0 ..< saliencyMap[y].count {
                saliencyMap[y][x] = 0.0
            }
        }

        // Compute saliency from different feature maps
        for (featureType, featureMap) in features {
            let weight = getFeatureWeight(featureType)

            for y in 0 ..< min(saliencyMap.count, featureMap.count) {
                for x in 0 ..< min(saliencyMap[y].count, featureMap[y].count) {
                    saliencyMap[y][x] += featureMap[y][x] * weight
                }
            }
        }

        // Apply center bias
        applyCenterBias()

        // Normalize
        normalizeSaliencyMap()
    }

    private func getFeatureWeight(_ featureType: String) -> Double {
        switch featureType {
        case "intensity": return 0.3
        case "orientation": return 0.4
        case "color": return 0.2
        case "motion": return 0.5
        default: return 0.1
        }
    }

    private func applyCenterBias() {
        let centerY = saliencyMap.count / 2
        let centerX = saliencyMap[0].count / 2

        for y in 0 ..< saliencyMap.count {
            for x in 0 ..< saliencyMap[y].count {
                let distanceFromCenter = sqrt(
                    pow(Double(x - centerX), 2) + pow(Double(y - centerY), 2))
                let bias = exp(-distanceFromCenter / 50.0) // Gaussian falloff
                saliencyMap[y][x] *= (0.5 + 0.5 * bias)
            }
        }
    }

    private func normalizeSaliencyMap() {
        let maxValue = saliencyMap.flatMap { $0 }.max() ?? 1.0
        if maxValue > 0 {
            for y in 0 ..< saliencyMap.count {
                for x in 0 ..< saliencyMap[y].count {
                    saliencyMap[y][x] /= maxValue
                }
            }
        }
    }

    public func getAttentionFocus() -> (x: Int, y: Int)? {
        var maxSaliency = 0.0
        var focus: (x: Int, y: Int)?

        for y in 0 ..< saliencyMap.count {
            for x in 0 ..< saliencyMap[y].count {
                if saliencyMap[y][x] > maxSaliency {
                    maxSaliency = saliencyMap[y][x]
                    focus = (x, y)
                }
            }
        }

        attentionFocus = focus
        return focus
    }

    public func shiftAttention() {
        // Inhibit currently attended location
        if let focus = attentionFocus {
            saliencyMap[focus.y][focus.x] *= 0.3 // Strong inhibition
        }

        // Find next attention location
        _ = getAttentionFocus()
    }
}
