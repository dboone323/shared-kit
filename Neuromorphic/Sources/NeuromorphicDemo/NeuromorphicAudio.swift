// Neuromorphic Audio Processing
// Phase 7B: Brain-inspired audio processing with spiking neural networks
// Task 77: Neuromorphic Audio - Speech and sound processing with neuromorphic architectures

import Foundation

// MARK: - Cochlear Models

/// Basilar membrane model for frequency analysis
public class BasilarMembrane {
    public var segments: [MembraneSegment] = []
    public var samplingRate: Double = 44100.0 // Hz

    public init(numSegments: Int = 100) {
        // Create segments with different resonant frequencies (logarithmic spacing)
        for i in 0 ..< numSegments {
            let frequency = 20.0 * pow(10.0, Double(i) / Double(numSegments) * 3.0) // 20Hz to 20kHz
            let segment = MembraneSegment(resonantFrequency: frequency, segmentIndex: i)
            segments.append(segment)
        }
    }

    /// Process audio signal through basilar membrane
    public func processAudioSignal(_ audioSamples: [Double]) -> [[Double]] {
        var responses: [[Double]] = Array(repeating: [], count: segments.count)

        for sample in audioSamples {
            for (index, segment) in segments.enumerated() {
                let response = segment.processSample(sample)
                responses[index].append(response)
            }
        }

        return responses
    }
}

/// Individual segment of the basilar membrane
public class MembraneSegment {
    public let resonantFrequency: Double
    public let segmentIndex: Int

    // Simple resonant filter state
    private var y1: Double = 0.0 // previous output
    private var y2: Double = 0.0 // output before that

    public init(resonantFrequency: Double, segmentIndex: Int) {
        self.resonantFrequency = resonantFrequency
        self.segmentIndex = segmentIndex
    }

    /// Process single audio sample using simple resonant filter
    public func processSample(_ input: Double) -> Double {
        let sampleRate = 44100.0
        let omega = 2.0 * .pi * resonantFrequency / sampleRate

        // Simple second-order resonant filter coefficients
        let r = 0.95 // pole radius (close to 1 for sharp resonance)
        let cosOmega = cos(omega)
        let sinOmega = sin(omega)

        // Filter coefficients for bandpass response
        let b0 = (1.0 - r * r) * sinOmega
        let a1 = -2.0 * r * cosOmega
        let a2 = r * r

        // Apply filter: y[n] = b0*x[n] - a1*y[n-1] - a2*y[n-2]
        let output = b0 * input - a1 * y1 - a2 * y2

        // Update state
        y2 = y1
        y1 = output

        // Return envelope for cochlear response
        return abs(output)
    }
}

/// Inner hair cell model for spike generation
public class InnerHairCell {
    public var membranePotential: Double = 0.0
    public var threshold: Double = 0.5
    public var adaptation: Double = 0.0
    public var refractoryPeriod: TimeInterval = 0.001
    public var lastSpikeTime: TimeInterval = 0.0

    /// Process membrane displacement and generate spikes
    public func processDisplacement(_ displacement: Double, at time: TimeInterval) -> Bool {
        // Check refractory period
        if time - lastSpikeTime < refractoryPeriod {
            return false
        }

        // Adaptation decay
        adaptation *= 0.99

        // Membrane potential update
        membranePotential = displacement - adaptation

        // Spike generation
        if membranePotential > threshold {
            lastSpikeTime = time
            adaptation += 0.1 // Adaptation increase
            return true
        }

        return false
    }
}

/// Auditory nerve fiber model
public class AuditoryNerveFiber {
    public var hairCell: InnerHairCell
    public var spikes: [NeuromorphicSpike] = []
    public var spontaneousRate: Double // Spontaneous firing rate

    public init(spontaneousRate: Double = 10.0) { // spikes per second
        self.spontaneousRate = spontaneousRate
        self.hairCell = InnerHairCell()
    }

    /// Process audio input and generate spike train
    public func processAudioInput(_ audioSamples: [Double], startTime: TimeInterval = 0.0)
        -> [NeuromorphicSpike]
    {
        spikes.removeAll()
        var currentTime = startTime

        for sample in audioSamples {
            let spiked = hairCell.processDisplacement(sample, at: currentTime)
            if spiked {
                let spike = NeuromorphicSpike(
                    sourceNeuron: NeuromorphicNeuron(), // Dummy source
                    targetSynapse: NeuromorphicSynapse(
                        from: NeuromorphicNeuron(), to: NeuromorphicNeuron()
                    ), // Dummy synapse
                    timestamp: currentTime,
                    weight: 1.0
                )
                spikes.append(spike)
            }

            currentTime += 1.0 / 44100.0 // Sample period
        }

        return spikes
    }
}

// MARK: - Auditory Cortex Models

/// Auditory cortex model for higher-level processing
public class AuditoryCortex {
    public var primaryAuditoryCortex: [NeuromorphicNeuron] = []
    public var beltArea: [NeuromorphicNeuron] = []
    public var parabeltArea: [NeuromorphicNeuron] = []

    public var frequencyMap: [[NeuromorphicNeuron]] = [] // Tonotopic organization
    public var temporalPatterns: [String: [NeuromorphicSpike]] = [:]

    public init(numFrequencyBins: Int = 50, neuronsPerBin: Int = 10) {
        // Create tonotopic map
        for _ in 0 ..< numFrequencyBins {
            var frequencyColumn: [NeuromorphicNeuron] = []
            for _ in 0 ..< neuronsPerBin {
                let neuron = LIFNeuron(threshold: 0.8, leakRate: 0.95)
                frequencyColumn.append(neuron)
                primaryAuditoryCortex.append(neuron)
            }
            frequencyMap.append(frequencyColumn)
        }

        // Create higher-order areas
        for _ in 0 ..< 200 {
            beltArea.append(LIFNeuron(threshold: 0.7))
            parabeltArea.append(LIFNeuron(threshold: 0.6))
        }
    }

    /// Process auditory nerve spikes
    public func processAuditoryInput(_ nerveSpikes: [[NeuromorphicSpike]]) {
        // Map spikes to tonotopic representation
        for (frequencyIndex, spikeTrain) in nerveSpikes.enumerated() {
            if frequencyIndex < frequencyMap.count {
                for spike in spikeTrain {
                    // Distribute spike to neurons in this frequency column
                    for neuron in frequencyMap[frequencyIndex] {
                        _ = neuron.processSpike(spike, at: spike.timestamp)
                    }
                }
            }
        }

        // Process through hierarchical areas
        processHierarchicalProcessing()
    }

    private func processHierarchicalProcessing() {
        // Simple hierarchical processing - belt area processes primary area output
        for beltNeuron in beltArea {
            // Connect to random primary neurons
            let connectedNeurons = primaryAuditoryCortex.shuffled().prefix(5)
            for primaryNeuron in connectedNeurons {
                if primaryNeuron.membranePotential > 0.5 {
                    // Create artificial input spike
                    let dummySynapse = NeuromorphicSynapse(from: primaryNeuron, to: beltNeuron)
                    let spike = NeuromorphicSpike(
                        sourceNeuron: primaryNeuron,
                        targetSynapse: dummySynapse,
                        timestamp: Date.timeIntervalSinceReferenceDate,
                        weight: primaryNeuron.membranePotential
                    )
                    _ = beltNeuron.processSpike(spike, at: spike.timestamp)
                }
            }
        }

        // Parabelt processes belt area
        for parabeltNeuron in parabeltArea {
            let connectedNeurons = beltArea.shuffled().prefix(3)
            for beltNeuron in connectedNeurons {
                if beltNeuron.membranePotential > 0.4 {
                    let dummySynapse = NeuromorphicSynapse(from: beltNeuron, to: parabeltNeuron)
                    let spike = NeuromorphicSpike(
                        sourceNeuron: beltNeuron,
                        targetSynapse: dummySynapse,
                        timestamp: Date.timeIntervalSinceReferenceDate,
                        weight: beltNeuron.membranePotential
                    )
                    _ = parabeltNeuron.processSpike(spike, at: spike.timestamp)
                }
            }
        }
    }

    /// Extract temporal patterns for speech recognition
    public func extractTemporalPatterns() -> [String: Double] {
        var patterns: [String: Double] = [:]

        // Analyze spike timing patterns
        for (patternName, spikes) in temporalPatterns {
            if !spikes.isEmpty {
                let activity = Double(spikes.count) / 1.0 // Normalize to 1 second
                patterns[patternName] = activity
            }
        }

        return patterns
    }
}

// MARK: - Speech Recognition

/// Neuromorphic speech recognition system
public class NeuromorphicSpeechRecognizer {
    public var auditoryCortex: AuditoryCortex
    public var phonemeDetectors: [String: [NeuromorphicNeuron]] = [:]
    public var wordDetectors: [String: [NeuromorphicNeuron]] = [:]

    public init() {
        self.auditoryCortex = AuditoryCortex()

        // Initialize phoneme detectors
        let phonemes = [
            "a", "e", "i", "o", "u", "b", "d", "g", "m", "n", "p", "t", "k", "f", "s", "sh", "th",
        ]
        for phoneme in phonemes {
            phonemeDetectors[phoneme] = (0 ..< 20).map { _ in LIFNeuron(threshold: 0.6) }
        }

        // Initialize word detectors
        let words = ["hello", "world", "quantum", "neuromorphic", "computing"]
        for word in words {
            wordDetectors[word] = (0 ..< 30).map { _ in LIFNeuron(threshold: 0.5) }
        }
    }

    /// Process audio input for speech recognition
    public func processSpeech(_ audioSamples: [Double]) -> SpeechResult {
        let startTime = Date.timeIntervalSinceReferenceDate

        // Convert audio to spike trains
        let basilarMembrane = BasilarMembrane()
        let membraneResponses = basilarMembrane.processAudioSignal(audioSamples)

        // Generate auditory nerve spikes
        var nerveSpikes: [[NeuromorphicSpike]] = []
        for response in membraneResponses {
            let nerveFiber = AuditoryNerveFiber()
            let spikes = nerveFiber.processAudioInput(response)
            nerveSpikes.append(spikes)
        }

        // Process through auditory cortex
        auditoryCortex.processAuditoryInput(nerveSpikes)

        // Phoneme detection
        let detectedPhonemes = detectPhonemes()

        // Word recognition
        let recognizedWords = recognizeWords(detectedPhonemes)

        let processingTime = Date.timeIntervalSinceReferenceDate - startTime

        return SpeechResult(
            recognizedWords: recognizedWords,
            detectedPhonemes: detectedPhonemes,
            confidence: calculateConfidence(recognizedWords),
            processingTime: processingTime,
            spikeCount: nerveSpikes.flatMap { $0 }.count
        )
    }

    private func detectPhonemes() -> [String] {
        var detected: [String] = []

        for (phoneme, detectors) in phonemeDetectors {
            var totalActivity = 0.0
            for detector in detectors {
                // Simple activity-based detection
                if detector.membranePotential > 0.3 {
                    totalActivity += detector.membranePotential
                }
            }

            if totalActivity > 2.0 { // Threshold for detection
                detected.append(phoneme)
            }
        }

        return detected
    }

    private func recognizeWords(_ phonemes: [String]) -> [String] {
        var recognized: [String] = []

        for (word, detectors) in wordDetectors {
            var totalActivity = 0.0
            for detector in detectors {
                if detector.membranePotential > 0.2 {
                    totalActivity += detector.membranePotential
                }
            }

            if totalActivity > 3.0 { // Threshold for recognition
                recognized.append(word)
            }
        }

        return recognized
    }

    private func calculateConfidence(_ words: [String]) -> Double {
        // Simple confidence based on number of recognized words
        min(1.0, Double(words.count) * 0.3)
    }
}

/// Speech recognition result
public struct SpeechResult {
    public let recognizedWords: [String]
    public let detectedPhonemes: [String]
    public let confidence: Double
    public let processingTime: TimeInterval
    public let spikeCount: Int

    public var wordsPerSecond: Double {
        Double(recognizedWords.count) / processingTime
    }

    public var spikeEfficiency: Double {
        Double(spikeCount) / processingTime
    }
}

// MARK: - Binaural Processing

/// Sound localization system using binaural cues
public class BinauralLocalizationSystem {
    public var leftCochlea: BasilarMembrane
    public var rightCochlea: BasilarMembrane
    public var localizationNeurons: [DirectionSelectiveNeuron] = []

    public init() {
        self.leftCochlea = BasilarMembrane()
        self.rightCochlea = BasilarMembrane()

        // Create neurons sensitive to different directions
        for angle in stride(from: -90.0, to: 90.1, by: 15.0) {
            localizationNeurons.append(DirectionSelectiveNeuron(preferredDirection: angle))
        }
    }

    /// Process binaural audio for sound localization
    public func localizeSound(leftAudio: [Double], rightAudio: [Double]) -> LocalizationResult {
        let startTime = Date.timeIntervalSinceReferenceDate

        // Process both ears
        let leftResponses = leftCochlea.processAudioSignal(leftAudio)
        let rightResponses = rightCochlea.processAudioSignal(rightAudio)

        // Calculate interaural time differences (ITD) and level differences (ILD)
        var itdResponses: [Double] = []
        var ildResponses: [Double] = []

        for i in 0 ..< min(leftResponses.count, rightResponses.count) {
            let leftEnergy = leftResponses[i].reduce(0, +)
            let rightEnergy = rightResponses[i].reduce(0, +)

            // ITD: Cross-correlation based delay estimation (simplified)
            // For a click sound, ITD is the delay between ears
            let maxDelay = 20 // samples (about 0.45ms at 44.1kHz)
            var maxCorrelation = 0.0
            var bestDelay = 0

            for delay in -maxDelay ... maxDelay {
                var correlation = 0.0
                let count = min(leftResponses[i].count, rightResponses[i].count - abs(delay))

                for j in 0 ..< count {
                    let leftIdx = j
                    let rightIdx = j + max(0, delay)
                    if rightIdx < rightResponses[i].count {
                        correlation += leftResponses[i][leftIdx] * rightResponses[i][rightIdx]
                    }
                }

                if abs(correlation) > abs(maxCorrelation) {
                    maxCorrelation = correlation
                    bestDelay = delay
                }
            }

            let itd = Double(bestDelay) / 44100.0 * 1000.0 // Convert to milliseconds

            // ILD calculation (dB)
            let epsilon = 1e-10 // Avoid log(0)
            let ild = 10.0 * log10((leftEnergy + epsilon) / (rightEnergy + epsilon))

            itdResponses.append(itd)
            ildResponses.append(ild)
        }

        // Determine sound direction using population coding
        var directionResponses: [Double] = []
        for neuron in localizationNeurons {
            let response = neuron.processBinauralCues(itd: itdResponses, ild: ildResponses)
            directionResponses.append(response)
        }

        // Find best matching direction (population vector decoding)
        let maxResponse = directionResponses.max() ?? 0.0
        let bestDirectionIndex = directionResponses.firstIndex(of: maxResponse) ?? 0
        let estimatedDirection = localizationNeurons[bestDirectionIndex].preferredDirection

        let processingTime = Date.timeIntervalSinceReferenceDate - startTime

        return LocalizationResult(
            estimatedDirection: estimatedDirection,
            confidence: maxResponse,
            processingTime: processingTime,
            itdValues: itdResponses,
            ildValues: ildResponses
        )
    }
}

/// Direction-selective neuron for sound localization
public class DirectionSelectiveNeuron {
    public let preferredDirection: Double // degrees (-90 to +90)
    public var membranePotential: Double = 0.0
    public var preferredITD: Double // milliseconds
    public var preferredILD: Double // dB

    public init(preferredDirection: Double) {
        self.preferredDirection = preferredDirection

        // Convert angle to ITD using head radius approximation
        // ITD ≈ (headRadius/c) * sin(θ) where c = 343 m/s (speed of sound)
        let headRadius = 0.0875 // meters (average human head radius)
        let speedOfSound = 343.0 // m/s
        let maxITD = headRadius / speedOfSound * 1000.0 // Convert to milliseconds

        self.preferredITD = maxITD * sin(preferredDirection * .pi / 180.0)

        // ILD increases with angle (head shadow effect)
        self.preferredILD = 5.0 * sin(abs(preferredDirection) * .pi / 180.0)
    }

    /// Process binaural cues
    public func processBinauralCues(itd: [Double], ild: [Double]) -> Double {
        var response = 0.0

        for i in 0 ..< min(itd.count, ild.count) {
            // ITD response: Gaussian tuning around preferred ITD
            let itdDiff = itd[i] - preferredITD
            let itdResponse = exp(-0.5 * pow(itdDiff / 0.2, 2)) // σ = 0.2ms

            // ILD response: Gaussian tuning around preferred ILD
            let ildDiff = ild[i] - preferredILD
            let ildResponse = exp(-0.5 * pow(ildDiff / 3.0, 2)) // σ = 3dB

            // Combine ITD and ILD responses
            response += itdResponse * ildResponse
        }

        membranePotential = response / Double(max(1, itd.count))
        return membranePotential
    }
}

/// Sound localization result
public struct LocalizationResult {
    public let estimatedDirection: Double // degrees
    public let confidence: Double
    public let processingTime: TimeInterval
    public let itdValues: [Double]
    public let ildValues: [Double]

    public var directionDescription: String {
        if estimatedDirection > 30 {
            return "Right side"
        } else if estimatedDirection < -30 {
            return "Left side"
        } else {
            return "Center"
        }
    }
}
