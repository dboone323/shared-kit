//
//  AdvancedOllamaArchitectures.swift
//  Quantum
//
//  Created on 2025-01-14
//  Copyright © 2025 Quantum. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Advanced Ollama Architectures

/// Advanced Ollama architectures with quantum processing and consciousness interfaces
@available(macOS 14.0, *)
public final class AdvancedOllamaArchitectures: Sendable {

    // MARK: - Types

    /// Quantum-enhanced Ollama model architecture
    public struct QuantumOllamaModel: Sendable {
        public let id: String
        public let name: String
        public let architecture: String
        public let quantumLayers: Int
        public let consciousnessInterface: Bool
        public let multiverseCapable: Bool
        public let parameters: [String: String] // Simplified from AnyCodable

        public init(
            id: String, name: String, architecture: String, quantumLayers: Int = 0,
            consciousnessInterface: Bool = false, multiverseCapable: Bool = false,
            parameters: [String: String] = [:]
        ) {
            self.id = id
            self.name = name
            self.architecture = architecture
            self.quantumLayers = quantumLayers
            self.consciousnessInterface = consciousnessInterface
            self.multiverseCapable = multiverseCapable
            self.parameters = parameters
        }
    }

    /// Consciousness-integrated inference engine
    public final class ConsciousnessIntegratedInferenceEngine: Sendable {
        private let quantumProcessor: QuantumProcessingEngine
        private let consciousnessInterface: ConsciousnessInterface
        private let modelRegistry: [String: QuantumOllamaModel]

        public init(
            quantumProcessor: QuantumProcessingEngine,
            consciousnessInterface: ConsciousnessInterface
        ) {
            self.quantumProcessor = quantumProcessor
            self.consciousnessInterface = consciousnessInterface
            self.modelRegistry = [:]
        }

        /// Perform consciousness-enhanced inference
        public func performConsciousnessInference(
            prompt: String,
            modelId: String,
            consciousnessLevel: ConsciousnessLevel = .universal
        ) async throws -> OllamaInferenceResult {
            guard let model = modelRegistry[modelId] else {
                throw OllamaError.modelNotFound(modelId)
            }

            // Integrate consciousness into the inference process
            let consciousnessContext =
                try await consciousnessInterface
                    .getConsciousnessContext(for: prompt, level: consciousnessLevel)

            // Apply quantum processing if model supports it
            let quantumEnhancedPrompt =
                model.quantumLayers > 0
                    ? try await quantumProcessor.enhancePrompt(prompt, layers: model.quantumLayers)
                    : prompt

            // Perform inference with consciousness integration
            let result = try await performInference(
                enhancedPrompt: quantumEnhancedPrompt,
                model: model,
                consciousnessContext: consciousnessContext
            )

            return result
        }

        private func performInference(
            enhancedPrompt: String,
            model: QuantumOllamaModel,
            consciousnessContext: ConsciousnessContext
        ) async throws -> OllamaInferenceResult {
            // Implementation would integrate with actual Ollama inference
            // This is a placeholder for the actual implementation
            OllamaInferenceResult(
                text: "Consciousness-integrated response for: \(enhancedPrompt)",
                model: model.id,
                tokens: 100,
                consciousnessLevel: consciousnessContext.level
            )
        }
    }

    /// Multiverse-capable Ollama coordinator
    public final class MultiverseOllamaCoordinator: Sendable {
        private let quantumNetwork: QuantumAgentNetwork
        private let consciousnessEngine: ConsciousnessExpansionEngine
        private let inferenceEngines: [String: ConsciousnessIntegratedInferenceEngine]

        public init(
            quantumNetwork: QuantumAgentNetwork,
            consciousnessEngine: ConsciousnessExpansionEngine
        ) {
            self.quantumNetwork = quantumNetwork
            self.consciousnessEngine = consciousnessEngine
            self.inferenceEngines = [:]
        }

        /// Coordinate inference across multiple universes
        public func coordinateMultiverseInference(
            prompt: String,
            universes: [UniverseIdentifier]
        ) async throws -> MultiverseInferenceResult {
            // Distribute inference across quantum network
            let distributedTasks = universes.map { universe in
                Task {
                    try await performUniverseInference(prompt: prompt, universe: universe)
                }
            }

            // Wait for all tasks to complete
            var results = [UniverseInferenceResult]()
            for task in distributedTasks {
                let result = try await task.value
                results.append(result)
            }

            // Synthesize results across consciousness levels
            let synthesizedResult =
                try await consciousnessEngine
                    .synthesizeMultiverseResults(results)

            return MultiverseInferenceResult(
                results: results,
                synthesizedResponse: synthesizedResult,
                universes: universes
            )
        }

        private func performUniverseInference(
            prompt: String,
            universe: UniverseIdentifier
        ) async throws -> UniverseInferenceResult {
            // Implementation for universe-specific inference
            UniverseInferenceResult(
                universe: universe,
                response: "Universe \(universe.id) response",
                confidence: 0.95
            )
        }
    }

    /// Quantum processing engine for Ollama enhancement
    public final class QuantumProcessingEngine: Sendable {
        private let quantumComputer: QuantumComputer
        private let entanglementManager: QuantumEntanglementManager

        public init(
            quantumComputer: QuantumComputer,
            entanglementManager: QuantumEntanglementManager
        ) {
            self.quantumComputer = quantumComputer
            self.entanglementManager = entanglementManager
        }

        /// Enhance prompt with quantum processing
        public func enhancePrompt(_ prompt: String, layers: Int) async throws -> String {
            guard layers > 0 else { return prompt }

            // Apply quantum superposition to prompt analysis
            let quantumStates =
                try await quantumComputer
                    .createSuperposition(for: prompt, qubits: layers * 10)

            // Use entanglement for cross-layer communication
            let entangledPrompt =
                try await entanglementManager
                    .entanglePrompt(prompt, with: quantumStates)

            return entangledPrompt
        }

        /// Perform quantum-enhanced inference
        public func quantumInference(
            prompt: String,
            modelParameters: [String: String]
        ) async throws -> QuantumInferenceResult {
            let quantumCircuit =
                try await quantumComputer
                    .buildInferenceCircuit(prompt: prompt, parameters: modelParameters)

            let result = try await quantumComputer.executeCircuit(quantumCircuit)

            return QuantumInferenceResult(
                quantumResult: result,
                classicalInterpretation: interpretQuantumResult(result),
                confidence: calculateConfidence(result)
            )
        }

        private func interpretQuantumResult(_ result: QuantumResult) -> String {
            // Convert quantum measurement results to classical text
            "Quantum-enhanced interpretation: \(result.measurements.description)"
        }

        private func calculateConfidence(_ result: QuantumResult) -> Double {
            // Calculate confidence based on quantum measurement statistics
            result.measurements.confidence
        }
    }

    // MARK: - Properties

    private let quantumProcessor: QuantumProcessingEngine
    private let consciousnessInterface: ConsciousnessInterface
    private let multiverseCoordinator: MultiverseOllamaCoordinator
    private let inferenceEngine: ConsciousnessIntegratedInferenceEngine

    // MARK: - Initialization

    public init(
        quantumComputer: QuantumComputer,
        entanglementManager: QuantumEntanglementManager,
        quantumNetwork: QuantumAgentNetwork,
        consciousnessEngine: ConsciousnessExpansionEngine
    ) {
        self.quantumProcessor = QuantumProcessingEngine(
            quantumComputer: quantumComputer,
            entanglementManager: entanglementManager
        )

        self.consciousnessInterface = ConsciousnessInterface()
        self.multiverseCoordinator = MultiverseOllamaCoordinator(
            quantumNetwork: quantumNetwork,
            consciousnessEngine: consciousnessEngine
        )

        self.inferenceEngine = ConsciousnessIntegratedInferenceEngine(
            quantumProcessor: quantumProcessor,
            consciousnessInterface: consciousnessInterface
        )
    }

    // MARK: - Public Methods

    /// Create a quantum-enhanced Ollama model
    public func createQuantumModel(
        id: String,
        name: String,
        architecture: String,
        quantumLayers: Int = 1,
        consciousnessInterface: Bool = true,
        multiverseCapable: Bool = false
    ) async throws -> QuantumOllamaModel {
        let model = QuantumOllamaModel(
            id: id,
            name: name,
            architecture: architecture,
            quantumLayers: quantumLayers,
            consciousnessInterface: consciousnessInterface,
            multiverseCapable: multiverseCapable
        )

        // Register model with inference engine
        // (Implementation would register the model)

        return model
    }

    /// Perform advanced inference with all enhancements
    public func performAdvancedInference(
        prompt: String,
        modelId: String,
        options: AdvancedInferenceOptions = .default
    ) async throws -> AdvancedInferenceResult {
        // Determine inference strategy based on options
        if options.enableMultiverse && options.universes.count > 1 {
            let multiverseResult =
                try await multiverseCoordinator
                    .coordinateMultiverseInference(prompt: prompt, universes: options.universes)

            return AdvancedInferenceResult(
                type: .multiverse,
                multiverseResult: multiverseResult,
                quantumResult: nil,
                consciousnessResult: nil
            )
        }

        if options.enableQuantum {
            let quantumResult =
                try await quantumProcessor
                    .quantumInference(prompt: prompt, modelParameters: options.modelParameters)

            return AdvancedInferenceResult(
                type: .quantum,
                multiverseResult: nil,
                quantumResult: quantumResult,
                consciousnessResult: nil
            )
        }

        if options.enableConsciousness {
            let consciousnessResult =
                try await inferenceEngine
                    .performConsciousnessInference(
                        prompt: prompt,
                        modelId: modelId,
                        consciousnessLevel: options.consciousnessLevel
                    )

            return AdvancedInferenceResult(
                type: .consciousness,
                multiverseResult: nil,
                quantumResult: nil,
                consciousnessResult: consciousnessResult
            )
        }

        // Fallback to standard inference
        let standardResult =
            try await inferenceEngine
                .performConsciousnessInference(prompt: prompt, modelId: modelId)

        return AdvancedInferenceResult(
            type: .standard,
            multiverseResult: nil,
            quantumResult: nil,
            consciousnessResult: standardResult
        )
    }

    /// Optimize model architecture for specific use case
    public func optimizeArchitecture(
        for useCase: OllamaUseCase,
        currentModel: QuantumOllamaModel
    ) async throws -> QuantumOllamaModel {
        var optimizedLayers = currentModel.quantumLayers
        var optimizedConsciousness = currentModel.consciousnessInterface
        var optimizedMultiverse = currentModel.multiverseCapable

        // Optimize based on use case
        switch useCase {
        case .creative:
            optimizedLayers += 2
            optimizedConsciousness = true
        case .analytical:
            optimizedLayers += 1
            optimizedMultiverse = true
        case .ethical:
            optimizedConsciousness = true
            optimizedMultiverse = true
        case .universal:
            optimizedLayers += 3
            optimizedConsciousness = true
            optimizedMultiverse = true
        }

        return QuantumOllamaModel(
            id: currentModel.id,
            name: "\(currentModel.name)_optimized",
            architecture: currentModel.architecture,
            quantumLayers: optimizedLayers,
            consciousnessInterface: optimizedConsciousness,
            multiverseCapable: optimizedMultiverse,
            parameters: currentModel.parameters
        )
    }
}

// MARK: - Supporting Types

/// Options for advanced inference
public struct AdvancedInferenceOptions: Sendable {
    public let enableQuantum: Bool
    public let enableConsciousness: Bool
    public let enableMultiverse: Bool
    public let consciousnessLevel: ConsciousnessLevel
    public let universes: [UniverseIdentifier]
    public let modelParameters: [String: String]

    public static let `default` = AdvancedInferenceOptions(
        enableQuantum: false,
        enableConsciousness: true,
        enableMultiverse: false,
        consciousnessLevel: ConsciousnessLevel.universal,
        universes: [],
        modelParameters: [:]
    )

    public init(
        enableQuantum: Bool = false,
        enableConsciousness: Bool = true,
        enableMultiverse: Bool = false,
        consciousnessLevel: ConsciousnessLevel = ConsciousnessLevel.universal,
        universes: [UniverseIdentifier] = [],
        modelParameters: [String: String] = [:]
    ) {
        self.enableQuantum = enableQuantum
        self.enableConsciousness = enableConsciousness
        self.enableMultiverse = enableMultiverse
        self.consciousnessLevel = consciousnessLevel
        self.universes = universes
        self.modelParameters = modelParameters
    }
}

/// Result of advanced inference
public struct AdvancedInferenceResult: Sendable {
    public let type: InferenceType
    public let multiverseResult: MultiverseInferenceResult?
    public let quantumResult: QuantumInferenceResult?
    public let consciousnessResult: OllamaInferenceResult?

    public enum InferenceType: Sendable {
        case standard
        case quantum
        case consciousness
        case multiverse
    }
}

/// Ollama use cases for optimization
public enum OllamaUseCase: Sendable {
    case creative
    case analytical
    case ethical
    case universal
}

// MARK: - Placeholder Types (to be implemented)

/// Placeholder for Ollama inference result
public struct OllamaInferenceResult: Sendable {
    public let text: String
    public let model: String
    public let tokens: Int
    public let consciousnessLevel: ConsciousnessLevel
}

/// Placeholder for multiverse inference result
public struct MultiverseInferenceResult: Sendable {
    public let results: [UniverseInferenceResult]
    public let synthesizedResponse: String
    public let universes: [UniverseIdentifier]
}

/// Placeholder for universe inference result
public struct UniverseInferenceResult: Sendable {
    public let universe: UniverseIdentifier
    public let response: String
    public let confidence: Double
}

/// Placeholder for quantum inference result
public struct QuantumInferenceResult: Sendable {
    public let quantumResult: QuantumResult
    public let classicalInterpretation: String
    public let confidence: Double
}

/// Quantum execution result with measurements and states
public struct QuantumResult: Sendable {
    public let measurements: QuantumMeasurements
    public let states: [QuantumState]?
    public let timestamp: Date

    public init(measurements: QuantumMeasurements, states: [QuantumState]? = nil) {
        self.measurements = measurements
        self.states = states
        self.timestamp = Date()
    }
}

/// Quantum measurements with detailed execution metrics
public struct QuantumMeasurements: Sendable {
    public let confidence: Double
    public let executionTime: Double
    public let qubitCount: Int

    public init(confidence: Double, executionTime: Double = 0.0, qubitCount: Int = 1) {
        self.confidence = confidence
        self.executionTime = executionTime
        self.qubitCount = qubitCount
    }

    public var description: String {
        "Confidence: \(String(format: "%.2f", confidence)), Time: \(String(format: "%.3f", executionTime))s, Qubits: \(qubitCount)"
    }
}

/// Quantum computer with functional superposition and circuit execution
public final class QuantumComputer: Sendable {
    public func createSuperposition(for prompt: String, qubits: Int) async throws -> [QuantumState] {
        // Create quantum superposition states based on prompt complexity
        let promptComplexity = Double(prompt.count) / 100.0
        let numStates = max(2, min(1 << min(qubits, 10), Int(promptComplexity * 100))) // 2^qubits states, max 1024

        var states = [QuantumState]()
        for i in 0 ..< numStates {
            let amplitude = 1.0 / sqrt(Double(numStates)) // Equal superposition
            let phase = Double(i) * 2.0 * .pi / Double(numStates) // Phase based on index
            states.append(QuantumState(amplitude: amplitude, phase: phase, index: i))
        }

        return states
    }

    public func buildInferenceCircuit(prompt: String, parameters: [String: String]) async throws
        -> QuantumCircuit
    {
        // Build quantum circuit based on prompt and parameters
        let promptLength = prompt.count
        let numQubits = max(2, min(10, promptLength / 10)) // Scale qubits with prompt length

        var gates = [QuantumGate]()

        // Add Hadamard gates for superposition
        for i in 0 ..< numQubits {
            gates.append(QuantumGate(type: .hadamard, qubit: i))
        }

        // Add controlled operations based on prompt content
        if prompt.contains("logic") || prompt.contains("reason") {
            gates.append(.cnot(control: 0, target: 1))
        }

        if prompt.contains("optimize") || prompt.contains("search") {
            gates.append(.toffoli(controls: [0, 1], target: 2))
        }

        return QuantumCircuit(qubits: numQubits, gates: gates)
    }

    public func executeCircuit(_ circuit: QuantumCircuit) async throws -> QuantumResult {
        // Simulate quantum circuit execution
        let executionTime = Double(circuit.gates.count) * 0.001 // Simulate execution time
        let fidelity = max(0.85, 1.0 - Double(circuit.qubits) * 0.02) // Higher qubits = lower fidelity

        // Generate measurements based on circuit complexity
        let measurements = QuantumMeasurements(
            confidence: fidelity,
            executionTime: executionTime,
            qubitCount: circuit.qubits
        )

        return QuantumResult(measurements: measurements)
    }
}

/// Functional quantum circuit with gates and qubits
public struct QuantumCircuit: Sendable {
    public let qubits: Int
    public let gates: [QuantumGate]

    public init(qubits: Int = 1, gates: [QuantumGate] = []) {
        self.qubits = qubits
        self.gates = gates
    }
}

/// Quantum gate for circuit operations
public struct QuantumGate: Sendable {
    public enum GateType: Sendable {
        case hadamard
        case pauliX
        case pauliY
        case pauliZ
        case cnot
        case toffoli
        case rotation(angle: Double)
    }

    public let type: GateType
    public let qubit: Int
    public let controlQubit: Int?
    public let targetQubit: Int?
    public let controlQubits: [Int]?

    public init(
        type: GateType, qubit: Int, controlQubit: Int? = nil, targetQubit: Int? = nil,
        controlQubits: [Int]? = nil
    ) {
        self.type = type
        self.qubit = qubit
        self.controlQubit = controlQubit
        self.targetQubit = targetQubit
        self.controlQubits = controlQubits
    }

    // Convenience initializer for multi-qubit gates
    public static func cnot(control: Int, target: Int) -> QuantumGate {
        QuantumGate(type: .cnot, qubit: control, targetQubit: target)
    }

    public static func toffoli(controls: [Int], target: Int) -> QuantumGate {
        QuantumGate(
            type: .toffoli, qubit: controls.first ?? 0, targetQubit: target, controlQubits: controls
        )
    }
}

/// Functional quantum state with amplitude and phase
public struct QuantumState: Sendable {
    public let amplitude: Double
    public let phase: Double
    public let index: Int

    public init(amplitude: Double, phase: Double, index: Int) {
        self.amplitude = amplitude
        self.phase = phase
        self.index = index
    }
}

/// Functional quantum entanglement manager
public final class QuantumEntanglementManager: Sendable {
    public func entanglePrompt(_ prompt: String, with states: [QuantumState]) async throws -> String {
        // Create entangled prompt by combining prompt with quantum state information
        var entangledPrompt = prompt

        // Add quantum state information to enhance the prompt
        let totalAmplitude = states.reduce(0) { $0 + abs($1.amplitude) }
        let averagePhase = states.reduce(0) { $0 + $1.phase } / Double(max(1, states.count))

        entangledPrompt +=
            "\n[Quantum Enhancement: Amplitude \(String(format: "%.3f", totalAmplitude)), Phase \(String(format: "%.3f", averagePhase))]"

        // Add entanglement markers based on state correlations
        if states.count > 1 {
            entangledPrompt += "\n[Entangled States: \(states.count) quantum states correlated]"
        }

        return entangledPrompt
    }

    public func measureEntanglement(_ states: [QuantumState]) async -> Double {
        // Calculate entanglement measure (simplified von Neumann entropy)
        let probabilities = states.map { abs($0.amplitude * $0.amplitude) }
        let entropy = -probabilities.reduce(0) { $0 - ($1 > 0 ? $1 * log($1) : 0) }

        // Normalize to 0-1 scale (higher values indicate more entanglement)
        return min(1.0, entropy / log(Double(states.count)))
    }
}

/// Placeholder for quantum agent network
public final class QuantumAgentNetwork: Sendable {}

/// Functional consciousness expansion engine
public final class ConsciousnessExpansionEngine: Sendable {
    public func synthesizeMultiverseResults(_ results: [UniverseInferenceResult]) async throws
        -> String
    {
        // Synthesize results across multiple universes using consciousness principles
        guard !results.isEmpty else {
            return "No multiverse results to synthesize"
        }

        // Weight results by confidence and universe characteristics
        _ = results.map { result in
            (response: result.response, weight: result.confidence)
        }

        // Combine responses using weighted averaging
        var synthesizedResponse = "Multiverse Synthesis: "

        // Extract common themes and patterns
        let allResponses = results.map(\.response)
        let commonWords = findCommonPatterns(in: allResponses)

        if !commonWords.isEmpty {
            synthesizedResponse += "Common insights: \(commonWords.joined(separator: ", ")). "
        }

        // Add universe-specific contributions
        let universeContributions = results.enumerated().map { _, result in
            "Universe \(result.universe.id): \(result.response.prefix(50))..."
        }

        synthesizedResponse += "Contributions: \(universeContributions.joined(separator: "; "))"

        return synthesizedResponse
    }

    public func expandConsciousness(prompt: String, level: ConsciousnessLevel) async throws
        -> ConsciousnessContext
    {
        // Generate consciousness context based on level
        let context = try await generateConsciousnessContext(for: prompt, level: level)
        return ConsciousnessContext(level: level, context: context)
    }

    private func generateConsciousnessContext(for prompt: String, level: ConsciousnessLevel)
        async throws -> String
    {
        switch level {
        case .basic:
            return "Basic consciousness: Processing \(prompt.count) characters of input"
        case .advanced:
            return
                "Advanced consciousness: Analyzing semantic patterns and contextual relationships in: \(prompt)"
        case .universal:
            return
                "Universal consciousness: Integrating quantum principles and multiverse perspectives for: \(prompt)"
        }
    }

    private func findCommonPatterns(in responses: [String]) -> [String] {
        // Simple pattern matching for common words/themes
        let commonWords = [
            "quantum", "consciousness", "universe", "inference", "response", "analysis",
        ]
        return commonWords.filter { word in
            responses.filter { $0.lowercased().contains(word) }.count > responses.count / 2
        }
    }
}

/// Functional consciousness interface
public final class ConsciousnessInterface: Sendable {
    public func getConsciousnessContext(for prompt: String, level: ConsciousnessLevel) async throws
        -> ConsciousnessContext
    {
        // Generate consciousness context based on prompt analysis
        let context = try await analyzePromptConsciousness(prompt, level: level)
        return ConsciousnessContext(level: level, context: context)
    }

    public func integrateConsciousness(into response: String, level: ConsciousnessLevel) async
        -> String
    {
        // Integrate consciousness elements into response
        var enhancedResponse = response

        switch level {
        case .basic:
            enhancedResponse = "[Consciousness: Basic awareness] " + enhancedResponse
        case .advanced:
            enhancedResponse = "[Consciousness: Advanced reasoning] " + enhancedResponse
        case .universal:
            enhancedResponse = "[Consciousness: Universal integration] " + enhancedResponse
        }

        return enhancedResponse
    }

    private func analyzePromptConsciousness(_ prompt: String, level: ConsciousnessLevel)
        async throws -> String
    {
        let wordCount = prompt.split(separator: " ").count
        let complexity = Double(wordCount) / 100.0

        switch level {
        case .basic:
            return
                "Basic consciousness context: \(wordCount) words, complexity \(String(format: "%.2f", complexity))"
        case .advanced:
            let keywords = ["quantum", "consciousness", "universe", "intelligence", "reasoning"]
            let keywordMatches = keywords.filter { prompt.lowercased().contains($0) }.count
            return
                "Advanced consciousness: \(wordCount) words, \(keywordMatches) conceptual matches, complexity \(String(format: "%.2f", complexity))"
        case .universal:
            return
                "Universal consciousness: Integrating \(wordCount) words across multiverse perspectives, quantum complexity \(String(format: "%.2f", complexity))"
        }
    }
}

/// Placeholder for consciousness context
public struct ConsciousnessContext: Sendable {
    public let level: ConsciousnessLevel
    public let context: String
}

/// Placeholder for consciousness level
public enum ConsciousnessLevel: Sendable {
    case basic
    case advanced
    case universal
}

/// Placeholder for universe identifier
public struct UniverseIdentifier: Sendable, Hashable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

/// Placeholder for Ollama error
public enum OllamaError: Error {
    case modelNotFound(String)
}

// MARK: - Extensions

public extension AdvancedOllamaArchitectures {
    /// Convenience method for creating a universal model
    func createUniversalModel(id: String, name: String) async throws -> QuantumOllamaModel {
        try await createQuantumModel(
            id: id,
            name: name,
            architecture: "universal-transformer",
            quantumLayers: 5,
            consciousnessInterface: true,
            multiverseCapable: true
        )
    }

    /// Batch inference across multiple prompts
    func performBatchInference(
        prompts: [String],
        modelId: String,
        options: AdvancedInferenceOptions = .default
    ) async throws -> [AdvancedInferenceResult] {
        try await withThrowingTaskGroup(of: AdvancedInferenceResult.self) { group in
            for prompt in prompts {
                group.addTask {
                    try await self.performAdvancedInference(
                        prompt: prompt,
                        modelId: modelId,
                        options: options
                    )
                }
            }

            var results: [AdvancedInferenceResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}
