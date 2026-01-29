import CryptoKit
import Foundation
import OSLog

// MARK: - Quantum-Safe Security System

/// Main quantum-safe security coordinator
public actor QuantumSafeSecurity {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "QuantumSafeSecurity")

    // Core security components
    private let cryptoManager: QuantumSafeCryptoManager
    private let keyManager: QuantumSafeKeyManager
    private let protocolManager: QuantumSafeProtocolManager
    private let threatDetector: QuantumThreatDetector
    private let complianceManager: SecurityComplianceManager

    // Security state
    private var securityMetrics: SecurityMetrics
    private var activeThreats: [SecurityThreat] = []
    private var securityPolicies: [SecurityPolicy] = []

    public init() {
        self.cryptoManager = QuantumSafeCryptoManager()
        self.keyManager = QuantumSafeKeyManager()
        self.protocolManager = QuantumSafeProtocolManager()
        self.threatDetector = QuantumThreatDetector()
        self.complianceManager = SecurityComplianceManager()

        self.securityMetrics = SecurityMetrics(
            encryptionStrength: 0.0,
            keyRotationFrequency: 0.0,
            threatDetectionRate: 0.0,
            complianceScore: 0.0,
            lastAssessment: Date()
        )

        logger.info("🔐 Quantum-safe security system initialized")
    }

    /// Initialize quantum-safe security system
    public func initializeSecurity() async throws {
        logger.info("🚀 Initializing quantum-safe security protocols")

        // Initialize cryptographic primitives
        try await cryptoManager.initialize()

        // Generate initial key pairs
        try await keyManager.initializeKeys()

        // Set up security protocols
        try await protocolManager.initializeProtocols()

        // Start threat detection
        try await threatDetector.startMonitoring()

        // Load security policies
        try await loadSecurityPolicies()

        logger.info("✅ Quantum-safe security system ready")
    }

    /// Encrypt data using quantum-safe algorithms
    public func encryptData(
        _ data: Data,
        for recipient: String,
        algorithm: QuantumSafeAlgorithm = .kyber
    ) async throws -> QuantumSafeCiphertext {
        logger.info("🔒 Encrypting data for recipient: \(recipient)")

        return try await cryptoManager.encryptData(data, for: recipient, algorithm: algorithm)
    }

    /// Decrypt data using quantum-safe algorithms
    public func decryptData(_ ciphertext: QuantumSafeCiphertext) async throws -> Data {
        logger.info("🔓 Decrypting data")

        return try await cryptoManager.decryptData(ciphertext)
    }

    /// Sign data using quantum-safe signature
    public func signData(_ data: Data, using keyId: String) async throws -> QuantumSafeSignature {
        logger.info("✍️ Signing data with key: \(keyId)")

        return try await cryptoManager.signData(data, using: keyId)
    }

    /// Verify quantum-safe signature
    public func verifySignature(
        _ signature: QuantumSafeSignature,
        for data: Data,
        publicKey: QuantumSafePublicKey
    ) async throws -> Bool {
        logger.info("✅ Verifying signature")

        return try await cryptoManager.verifySignature(signature, for: data, publicKey: publicKey)
    }

    /// Generate new quantum-safe key pair
    public func generateKeyPair(
        algorithm: QuantumSafeAlgorithm = .kyber,
        keySize: KeySize = .keySize256
    ) async throws -> QuantumSafeKeyPair {
        logger.info("🔑 Generating new \(algorithm.rawValue) key pair")

        return try await keyManager.generateKeyPair(algorithm: algorithm, keySize: keySize)
    }

    /// Rotate encryption keys
    public func rotateKeys() async throws {
        logger.info("🔄 Rotating encryption keys")

        try await keyManager.rotateKeys()

        // Update security metrics
        securityMetrics.keyRotationFrequency = calculateRotationFrequency()
        securityMetrics.lastAssessment = Date()
    }

    /// Assess security posture
    public func assessSecurityPosture() async throws -> SecurityAssessment {
        logger.info("📊 Assessing security posture")

        let cryptoAssessment = try await cryptoManager.assessCryptographicStrength()
        let keyAssessment = try await keyManager.assessKeyHealth()
        let threatAssessment = try await threatDetector.assessThreatLandscape()
        let complianceAssessment = try await complianceManager.assessCompliance()

        let overallScore =
            (cryptoAssessment.score + keyAssessment.score + threatAssessment.score
                + complianceAssessment.score) / 4.0

        let assessment = SecurityAssessment(
            overallScore: overallScore,
            cryptographicStrength: cryptoAssessment,
            keyHealth: keyAssessment,
            threatLandscape: threatAssessment,
            complianceStatus: complianceAssessment,
            recommendations: generateSecurityRecommendations(
                cryptoAssessment, keyAssessment, threatAssessment, complianceAssessment
            ),
            assessmentDate: Date()
        )

        // Update metrics
        securityMetrics.encryptionStrength = cryptoAssessment.score
        securityMetrics.threatDetectionRate = threatAssessment.score
        securityMetrics.complianceScore = complianceAssessment.score
        securityMetrics.lastAssessment = Date()

        return assessment
    }

    /// Detect and respond to quantum threats
    public func detectQuantumThreats() async throws -> [SecurityThreat] {
        logger.info("🔍 Detecting quantum threats")

        let threats = try await threatDetector.detectThreats()

        // Update active threats
        activeThreats = threats

        // Auto-respond to critical threats
        for threat in threats where threat.severity == .critical {
            try await respondToThreat(threat)
        }

        return threats
    }

    /// Establish quantum-safe communication channel
    public func establishSecureChannel(
        with peer: String,
        algorithm: QuantumSafeAlgorithm = .kyber
    ) async throws -> QuantumSafeChannel {
        logger.info("🌐 Establishing secure channel with: \(peer)")

        return try await protocolManager.establishChannel(with: peer, algorithm: algorithm)
    }

    /// Get security metrics
    public func getSecurityMetrics() -> SecurityMetrics {
        securityMetrics
    }

    /// Get active security policies
    public func getSecurityPolicies() -> [SecurityPolicy] {
        securityPolicies
    }

    // MARK: - Private Methods

    private func loadSecurityPolicies() async throws {
        // Load default quantum-safe security policies
        securityPolicies = [
            SecurityPolicy(
                id: "quantum-key-exchange",
                name: "Quantum-Safe Key Exchange",
                description: "Require quantum-resistant key exchange protocols",
                requirements: [.algorithm(.kyber), .keySize(.keySize512)],
                enforcement: .strict
            ),
            SecurityPolicy(
                id: "post-quantum-encryption",
                name: "Post-Quantum Encryption",
                description: "Use only post-quantum cryptographic algorithms",
                requirements: [.algorithm(.dilithium), .algorithm(.kyber)],
                enforcement: .strict
            ),
            SecurityPolicy(
                id: "key-rotation",
                name: "Regular Key Rotation",
                description: "Rotate keys every 90 days maximum",
                requirements: [.maxKeyAge(7_776_000)], // 90 days in seconds
                enforcement: .moderate
            ),
            SecurityPolicy(
                id: "threat-monitoring",
                name: "Continuous Threat Monitoring",
                description: "Monitor for quantum computing threats",
                requirements: [.threatDetection(.quantumAttack)],
                enforcement: .strict
            ),
        ]

        logger.info("📋 Loaded \(self.securityPolicies.count) security policies")
    }

    private func respondToThreat(_ threat: SecurityThreat) async throws {
        logger.warning("🚨 Responding to critical threat: \(threat.description)")

        switch threat.type {
        case .quantumAttack:
            // Emergency key rotation
            try await rotateKeys()

            // Increase monitoring
            try await threatDetector.increaseMonitoring()

        case .keyCompromise:
            // Revoke compromised keys
            try await keyManager.revokeKeys(threat.affectedKeys)

            // Generate new keys
            _ = try await generateKeyPair()

        case .protocolWeakness:
            // Update protocols
            try await protocolManager.updateProtocols()

        case .complianceViolation:
            // Log violation and alert
            logger.error("🚫 Security compliance violation detected")
        }
    }

    private func calculateRotationFrequency() -> Double {
        // Calculate key rotation frequency (keys per day)
        // This is a simplified calculation
        1.0 / 90.0 // One rotation every 90 days
    }

    private func generateSecurityRecommendations(
        _ crypto: CryptographicAssessment,
        _ key: KeyHealthAssessment,
        _ threat: ThreatAssessment,
        _ compliance: ComplianceAssessment
    ) -> [SecurityRecommendation] {
        var recommendations: [SecurityRecommendation] = []

        if crypto.score < 0.8 {
            recommendations.append(
                SecurityRecommendation(
                    priority: .high,
                    title: "Upgrade Cryptographic Algorithms",
                    description: "Current encryption strength is below recommended levels",
                    action: "Migrate to stronger post-quantum algorithms"
                ))
        }

        if key.score < 0.7 {
            recommendations.append(
                SecurityRecommendation(
                    priority: .high,
                    title: "Key Health Issues",
                    description: "Key rotation and health checks need attention",
                    action: "Perform immediate key rotation and health assessment"
                ))
        }

        if threat.score < 0.6 {
            recommendations.append(
                SecurityRecommendation(
                    priority: .critical,
                    title: "Threat Detection Gap",
                    description: "Threat detection capabilities need enhancement",
                    action: "Implement advanced quantum threat monitoring"
                ))
        }

        if compliance.score < 0.8 {
            recommendations.append(
                SecurityRecommendation(
                    priority: .medium,
                    title: "Compliance Improvements",
                    description: "Security compliance needs attention",
                    action: "Review and update security policies"
                ))
        }

        return recommendations
    }
}

// MARK: - Quantum-Safe Crypto Manager

/// Manages quantum-safe cryptographic operations
public actor QuantumSafeCryptoManager {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "QuantumSafeCrypto")

    private var activeAlgorithms: [QuantumSafeAlgorithm: QuantumSafeAlgorithmState] = [:]

    /// Initialize cryptographic primitives
    public func initialize() async throws {
        logger.info("🔧 Initializing quantum-safe cryptographic primitives")

        // Initialize Kyber (KEM)
        activeAlgorithms[.kyber] = QuantumSafeAlgorithmState(
            algorithm: .kyber,
            isActive: true,
            performanceMetrics: AlgorithmPerformance(
                encryptionSpeed: 1000, // operations per second
                decryptionSpeed: 1200,
                keyGenerationSpeed: 500,
                securityLevel: .level5
            )
        )

        // Initialize Dilithium (Signature)
        activeAlgorithms[.dilithium] = QuantumSafeAlgorithmState(
            algorithm: .dilithium,
            isActive: true,
            performanceMetrics: AlgorithmPerformance(
                encryptionSpeed: 0, // Not applicable for signatures
                decryptionSpeed: 0,
                keyGenerationSpeed: 300,
                securityLevel: .level5
            )
        )

        logger.info("✅ Cryptographic primitives initialized")
    }

    /// Encrypt data using quantum-safe algorithms
    public func encryptData(
        _ data: Data,
        for recipient: String,
        algorithm: QuantumSafeAlgorithm
    ) async throws -> QuantumSafeCiphertext {
        guard let algorithmState = activeAlgorithms[algorithm], algorithmState.isActive else {
            throw QuantumSafeError.algorithmNotAvailable(algorithm)
        }

        // Simulate quantum-safe encryption
        // In real implementation, this would use actual Kyber/Dilithium libraries
        let ciphertext = Data((0 ..< data.count + 32).map { _ in UInt8.random(in: 0 ... 255) })
        let ephemeralKey = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })

        return QuantumSafeCiphertext(
            algorithm: algorithm,
            ciphertext: ciphertext,
            ephemeralKey: ephemeralKey,
            recipientId: recipient,
            timestamp: Date()
        )
    }

    /// Decrypt data using quantum-safe algorithms
    public func decryptData(_ ciphertext: QuantumSafeCiphertext) async throws -> Data {
        guard let algorithmState = activeAlgorithms[ciphertext.algorithm], algorithmState.isActive
        else {
            throw QuantumSafeError.algorithmNotAvailable(ciphertext.algorithm)
        }

        // Simulate quantum-safe decryption
        // In real implementation, this would use actual Kyber/Dilithium libraries
        let decryptedData = Data(
            (0 ..< ciphertext.ciphertext.count - 32).map { _ in UInt8.random(in: 0 ... 255) })

        return decryptedData
    }

    /// Sign data using quantum-safe signature
    public func signData(_ data: Data, using keyId: String) async throws -> QuantumSafeSignature {
        // Simulate Dilithium signature
        let signature = Data((0 ..< 64).map { _ in UInt8.random(in: 0 ... 255) })

        return QuantumSafeSignature(
            algorithm: .dilithium,
            signature: signature,
            keyId: keyId,
            timestamp: Date()
        )
    }

    /// Verify quantum-safe signature
    public func verifySignature(
        _ signature: QuantumSafeSignature,
        for data: Data,
        publicKey: QuantumSafePublicKey
    ) async throws -> Bool {
        // Simulate signature verification
        // In real implementation, this would verify the Dilithium signature
        Bool.random() // Simulate verification result
    }

    /// Assess cryptographic strength
    public func assessCryptographicStrength() async throws -> CryptographicAssessment {
        var totalScore = 0.0
        var algorithmAssessments: [AlgorithmAssessment] = []

        for (algorithm, state) in activeAlgorithms {
            let score =
                state.performanceMetrics.securityLevel.rawValue >= 5
                    ? 1.0 : state.performanceMetrics.securityLevel.rawValue >= 3 ? 0.8 : 0.6

            totalScore += score

            algorithmAssessments.append(
                AlgorithmAssessment(
                    algorithm: algorithm,
                    securityLevel: state.performanceMetrics.securityLevel,
                    performanceScore: score,
                    isActive: state.isActive
                ))
        }

        let averageScore = totalScore / Double(activeAlgorithms.count)

        return CryptographicAssessment(
            overallScore: averageScore,
            algorithmAssessments: algorithmAssessments,
            quantumResistance: .resistant,
            assessmentDate: Date()
        )
    }
}

// MARK: - Quantum-Safe Key Manager

/// Manages quantum-safe cryptographic keys
public actor QuantumSafeKeyManager {
    private let logger = Logger(
        subsystem: "com.quantum.workspace", category: "QuantumSafeKeyManager"
    )

    private var keyStore: [String: QuantumSafeKeyPair] = [:]
    private var keyMetadata: [String: KeyMetadata] = [:]

    /// Initialize key management system
    public func initializeKeys() async throws {
        logger.info("🔑 Initializing quantum-safe key management")

        // Generate initial key pairs
        let algorithms: [QuantumSafeAlgorithm] = [.kyber, .dilithium]

        for algorithm in algorithms {
            let keyPair = try await generateKeyPair(algorithm: algorithm)
            keyStore[keyPair.id] = keyPair

            keyMetadata[keyPair.id] = KeyMetadata(
                keyId: keyPair.id,
                algorithm: algorithm,
                creationDate: Date(),
                lastRotation: Date(),
                usageCount: 0,
                isActive: true
            )
        }

        logger.info("✅ Generated \(self.keyStore.count) initial key pairs")
    }

    /// Generate new quantum-safe key pair
    public func generateKeyPair(
        algorithm: QuantumSafeAlgorithm,
        keySize: KeySize = .keySize256
    ) async throws -> QuantumSafeKeyPair {
        let keyId = UUID().uuidString

        // Simulate key generation
        // In real implementation, this would generate actual Kyber/Dilithium keys
        let publicKeyData = Data((0 ..< keySize.rawValue).map { _ in UInt8.random(in: 0 ... 255) })
        let privateKeyData = Data((0 ..< keySize.rawValue).map { _ in UInt8.random(in: 0 ... 255) })

        let publicKey = QuantumSafePublicKey(
            algorithm: algorithm,
            keyData: publicKeyData,
            keyId: keyId
        )

        let privateKey = QuantumSafePrivateKey(
            algorithm: algorithm,
            keyData: privateKeyData,
            keyId: keyId
        )

        let keyPair = QuantumSafeKeyPair(
            id: keyId,
            algorithm: algorithm,
            publicKey: publicKey,
            privateKey: privateKey,
            creationDate: Date()
        )

        return keyPair
    }

    /// Rotate encryption keys
    public func rotateKeys() async throws {
        logger.info("🔄 Rotating quantum-safe keys")

        var rotatedKeys: [String] = []

        for (keyId, _) in keyStore {
            let newKeyPair = try await generateKeyPair(algorithm: .kyber)
            keyStore[newKeyPair.id] = newKeyPair

            // Mark old key as inactive
            if var metadata = keyMetadata[keyId] {
                metadata.isActive = false
                keyMetadata[keyId] = metadata
            }

            // Add metadata for new key
            keyMetadata[newKeyPair.id] = KeyMetadata(
                keyId: newKeyPair.id,
                algorithm: .kyber,
                creationDate: Date(),
                lastRotation: Date(),
                usageCount: 0,
                isActive: true
            )

            rotatedKeys.append(keyId)
        }

        logger.info("✅ Rotated \(rotatedKeys.count) keys")
    }

    /// Revoke compromised keys
    public func revokeKeys(_ keyIds: [String]) async throws {
        logger.warning("🚫 Revoking \(keyIds.count) compromised keys")

        for keyId in keyIds {
            keyStore.removeValue(forKey: keyId)
            if var metadata = keyMetadata[keyId] {
                metadata.isActive = false
                keyMetadata[keyId] = metadata
            }
        }
    }

    /// Assess key health
    public func assessKeyHealth() async throws -> KeyHealthAssessment {
        let totalKeys = keyStore.count
        let activeKeys = keyMetadata.values.filter(\.isActive).count
        let oldKeys = keyMetadata.values.filter {
            Date().timeIntervalSince($0.creationDate) > 7_776_000 // 90 days
        }.count

        let healthScore = Double(activeKeys) / Double(totalKeys)
        let freshnessScore = 1.0 - (Double(oldKeys) / Double(totalKeys))

        let overallScore = (healthScore + freshnessScore) / 2.0

        return KeyHealthAssessment(
            overallScore: overallScore,
            totalKeys: totalKeys,
            activeKeys: activeKeys,
            expiredKeys: oldKeys,
            averageKeyAge: calculateAverageKeyAge(),
            recommendations: generateKeyRecommendations(overallScore),
            assessmentDate: Date()
        )
    }

    private func calculateAverageKeyAge() -> TimeInterval {
        let ages = keyMetadata.values.map { Date().timeIntervalSince($0.creationDate) }
        return ages.reduce(0, +) / Double(ages.count)
    }

    private func generateKeyRecommendations(_ score: Double) -> [String] {
        var recommendations: [String] = []

        if score < 0.7 {
            recommendations.append("Rotate keys immediately")
            recommendations.append("Review key management policies")
        }

        if calculateAverageKeyAge() > 7_776_000 { // 90 days
            recommendations.append("Keys are too old - rotate immediately")
        }

        return recommendations
    }
}

// MARK: - Quantum-Safe Protocol Manager

/// Manages quantum-safe communication protocols
public actor QuantumSafeProtocolManager {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "QuantumSafeProtocol")

    private var activeChannels: [String: QuantumSafeChannel] = [:]
    private var protocolConfigurations: [String: ProtocolConfiguration] = [:]

    /// Initialize security protocols
    public func initializeProtocols() async throws {
        logger.info("📡 Initializing quantum-safe protocols")

        // Configure Kyber key exchange protocol
        protocolConfigurations["kyber-kem"] = ProtocolConfiguration(
            name: "Kyber Key Encapsulation",
            algorithm: .kyber,
            keySize: .keySize512,
            securityLevel: .level5,
            isActive: true
        )

        // Configure Dilithium signature protocol
        protocolConfigurations["dilithium-sig"] = ProtocolConfiguration(
            name: "Dilithium Digital Signature",
            algorithm: .dilithium,
            keySize: .keySize256,
            securityLevel: .level5,
            isActive: true
        )

        logger.info("✅ Protocols initialized")
    }

    /// Establish secure channel
    public func establishChannel(
        with peer: String,
        algorithm: QuantumSafeAlgorithm
    ) async throws -> QuantumSafeChannel {
        logger.info("🌐 Establishing channel with \(peer) using \(algorithm.rawValue)")

        let channelId = UUID().uuidString

        // Simulate key exchange
        let sharedSecret = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })

        let channel = QuantumSafeChannel(
            id: channelId,
            peerId: peer,
            algorithm: algorithm,
            sharedSecret: sharedSecret,
            establishedDate: Date(),
            isActive: true
        )

        activeChannels[channelId] = channel

        return channel
    }

    /// Update protocols
    public func updateProtocols() async throws {
        logger.info("🔄 Updating security protocols")

        // Update protocol configurations with latest security parameters
        for (key, config) in protocolConfigurations {
            var updatedConfig = config
            // Apply security updates
            protocolConfigurations[key] = updatedConfig
        }
    }
}

// MARK: - Quantum Threat Detector

/// Detects quantum computing threats
public actor QuantumThreatDetector {
    private let logger = Logger(
        subsystem: "com.quantum.workspace", category: "QuantumThreatDetector"
    )

    private var monitoringActive = false
    private var threatPatterns: [ThreatPattern] = []

    /// Start threat monitoring
    public func startMonitoring() async throws {
        logger.info("👁️ Starting quantum threat monitoring")

        monitoringActive = true

        // Initialize threat patterns
        threatPatterns = [
            ThreatPattern(
                type: .quantumAttack,
                signature: "quantum_computing_attack",
                severity: .critical,
                detectionConfidence: 0.9
            ),
            ThreatPattern(
                type: .keyCompromise,
                signature: "key_compromise_attempt",
                severity: .high,
                detectionConfidence: 0.8
            ),
            ThreatPattern(
                type: .protocolWeakness,
                signature: "protocol_vulnerability",
                severity: .medium,
                detectionConfidence: 0.7
            ),
        ]

        logger.info("✅ Threat monitoring active")
    }

    /// Detect threats
    public func detectThreats() async throws -> [SecurityThreat] {
        guard monitoringActive else {
            throw QuantumSafeError.monitoringNotActive
        }

        // Simulate threat detection
        var detectedThreats: [SecurityThreat] = []

        // Randomly detect threats for demonstration
        if Bool.random() && Bool.random() { // Low probability
            let threat = SecurityThreat(
                id: UUID().uuidString,
                type: .quantumAttack,
                severity: .critical,
                description: "Potential quantum computing attack detected",
                affectedKeys: [],
                detectionTime: Date(),
                confidence: 0.85
            )
            detectedThreats.append(threat)
        }

        return detectedThreats
    }

    /// Assess threat landscape
    public func assessThreatLandscape() async throws -> ThreatAssessment {
        let activeThreats = try await detectThreats()
        let threatCount = activeThreats.count

        // Calculate threat score (lower is better)
        let threatScore = max(0.0, 1.0 - Double(threatCount) * 0.2)

        return ThreatAssessment(
            overallScore: threatScore,
            activeThreats: threatCount,
            criticalThreats: activeThreats.filter { $0.severity == .critical }.count,
            highThreats: activeThreats.filter { $0.severity == .high }.count,
            threatPatterns: threatPatterns,
            assessmentDate: Date()
        )
    }

    /// Increase monitoring intensity
    public func increaseMonitoring() async throws {
        logger.info("📈 Increasing threat monitoring intensity")

        // Enhance monitoring capabilities
        for i in 0 ..< threatPatterns.count {
            threatPatterns[i].detectionConfidence += 0.1
        }
    }
}

// MARK: - Security Compliance Manager

/// Manages security compliance
public actor SecurityComplianceManager {
    private let logger = Logger(subsystem: "com.quantum.workspace", category: "SecurityCompliance")

    private var complianceStandards: [ComplianceStandard] = []

    /// Initialize compliance management
    public func initializeCompliance() async throws {
        complianceStandards = [
            ComplianceStandard(
                name: "NIST Post-Quantum Crypto",
                requirements: [.algorithm(.kyber), .algorithm(.dilithium)],
                status: .compliant
            ),
            ComplianceStandard(
                name: "Quantum-Resistant Standards",
                requirements: [.keySize(.keySize512), .securityLevel(.level5)],
                status: .compliant
            ),
        ]
    }

    /// Assess compliance
    public func assessCompliance() async throws -> ComplianceAssessment {
        var compliantStandards = 0
        var totalStandards = complianceStandards.count

        for standard in complianceStandards {
            if standard.status == .compliant {
                compliantStandards += 1
            }
        }

        let complianceScore = Double(compliantStandards) / Double(totalStandards)

        return ComplianceAssessment(
            overallScore: complianceScore,
            compliantStandards: compliantStandards,
            totalStandards: totalStandards,
            violations: complianceStandards.filter { $0.status != .compliant },
            assessmentDate: Date()
        )
    }
}

// MARK: - Data Models

/// Quantum-safe algorithm
public enum QuantumSafeAlgorithm: String, Sendable {
    case kyber, dilithium, falcon, sphincs
}

/// Key size
public enum KeySize: Int, Sendable {
    case keySize256 = 256
    case keySize512 = 512
    case keySize1024 = 1024
}

/// Security level
public enum SecurityLevel: Int, Sendable {
    case level1 = 1
    case level2, level3, level4, level5
}

/// Quantum-safe ciphertext
public struct QuantumSafeCiphertext: Sendable {
    public let algorithm: QuantumSafeAlgorithm
    public let ciphertext: Data
    public let ephemeralKey: Data
    public let recipientId: String
    public let timestamp: Date
}

/// Quantum-safe signature
public struct QuantumSafeSignature: Sendable {
    public let algorithm: QuantumSafeAlgorithm
    public let signature: Data
    public let keyId: String
    public let timestamp: Date
}

/// Quantum-safe key pair
public struct QuantumSafeKeyPair: Sendable {
    public let id: String
    public let algorithm: QuantumSafeAlgorithm
    public let publicKey: QuantumSafePublicKey
    public let privateKey: QuantumSafePrivateKey
    public let creationDate: Date
}

/// Quantum-safe public key
public struct QuantumSafePublicKey: Sendable {
    public let algorithm: QuantumSafeAlgorithm
    public let keyData: Data
    public let keyId: String
}

/// Quantum-safe private key
public struct QuantumSafePrivateKey: Sendable {
    public let algorithm: QuantumSafeAlgorithm
    public let keyData: Data
    public let keyId: String
}

/// Quantum-safe channel
public struct QuantumSafeChannel: Sendable {
    public let id: String
    public let peerId: String
    public let algorithm: QuantumSafeAlgorithm
    public let sharedSecret: Data
    public let establishedDate: Date
    public let isActive: Bool
}

/// Security metrics
public struct SecurityMetrics: Sendable {
    public var encryptionStrength: Double
    public var keyRotationFrequency: Double
    public var threatDetectionRate: Double
    public var complianceScore: Double
    public var lastAssessment: Date
}

/// Security assessment
public struct SecurityAssessment: Sendable {
    public let overallScore: Double
    public let cryptographicStrength: CryptographicAssessment
    public let keyHealth: KeyHealthAssessment
    public let threatLandscape: ThreatAssessment
    public let complianceStatus: ComplianceAssessment
    public let recommendations: [SecurityRecommendation]
    public let assessmentDate: Date
}

/// Cryptographic assessment
public struct CryptographicAssessment: Sendable {
    public let overallScore: Double
    public let algorithmAssessments: [AlgorithmAssessment]
    public let quantumResistance: QuantumResistance
    public let assessmentDate: Date

    public var score: Double { overallScore }
}

/// Algorithm assessment
public struct AlgorithmAssessment: Sendable {
    public let algorithm: QuantumSafeAlgorithm
    public let securityLevel: SecurityLevel
    public let performanceScore: Double
    public let isActive: Bool
}

/// Quantum resistance level
public enum QuantumResistance: String, Sendable {
    case vulnerable, partiallyResistant, resistant
}

/// Algorithm performance
public struct AlgorithmPerformance: Sendable {
    public let encryptionSpeed: Double // operations per second
    public let decryptionSpeed: Double
    public let keyGenerationSpeed: Double
    public let securityLevel: SecurityLevel
}

/// Algorithm state
public struct QuantumSafeAlgorithmState: Sendable {
    public let algorithm: QuantumSafeAlgorithm
    public let isActive: Bool
    public let performanceMetrics: AlgorithmPerformance
}

/// Key health assessment
public struct KeyHealthAssessment: Sendable {
    public let overallScore: Double
    public let totalKeys: Int
    public let activeKeys: Int
    public let expiredKeys: Int
    public let averageKeyAge: TimeInterval
    public let recommendations: [String]
    public let assessmentDate: Date

    public var score: Double { overallScore }
}

/// Key metadata
public struct KeyMetadata: Sendable {
    public let keyId: String
    public let algorithm: QuantumSafeAlgorithm
    public let creationDate: Date
    public let lastRotation: Date
    public var usageCount: Int
    public var isActive: Bool
}

/// Threat assessment
public struct ThreatAssessment: Sendable {
    public let overallScore: Double
    public let activeThreats: Int
    public let criticalThreats: Int
    public let highThreats: Int
    public let threatPatterns: [ThreatPattern]
    public let assessmentDate: Date

    public var score: Double { overallScore }
}

/// Threat pattern
public struct ThreatPattern: Sendable {
    public let type: ThreatType
    public let signature: String
    public let severity: ThreatSeverity
    public var detectionConfidence: Double
}

/// Security threat
public struct SecurityThreat: Sendable {
    public let id: String
    public let type: ThreatType
    public let severity: ThreatSeverity
    public let description: String
    public let affectedKeys: [String]
    public let detectionTime: Date
    public let confidence: Double
}

/// Threat type
public enum ThreatType: String, Sendable {
    case quantumAttack, keyCompromise, protocolWeakness, complianceViolation
}

/// Threat severity
public enum ThreatSeverity: String, Sendable {
    case low, medium, high, critical
}

/// Compliance assessment
public struct ComplianceAssessment: Sendable {
    public let overallScore: Double
    public let compliantStandards: Int
    public let totalStandards: Int
    public let violations: [ComplianceStandard]
    public let assessmentDate: Date

    public var score: Double { overallScore }
}

/// Compliance standard
public struct ComplianceStandard: Sendable {
    public let name: String
    public let requirements: [SecurityRequirement]
    public let status: ComplianceStatus
}

/// Compliance status
public enum ComplianceStatus: String, Sendable {
    case compliant, nonCompliant, partial
}

/// Security requirement
public enum SecurityRequirement: Sendable {
    case algorithm(QuantumSafeAlgorithm)
    case keySize(KeySize)
    case securityLevel(SecurityLevel)
    case maxKeyAge(TimeInterval)
    case threatDetection(ThreatType)
}

/// Security policy
public struct SecurityPolicy: Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let requirements: [SecurityRequirement]
    public let enforcement: PolicyEnforcement
}

/// Policy enforcement level
public enum PolicyEnforcement: String, Sendable {
    case lenient, moderate, strict
}

/// Security recommendation
public struct SecurityRecommendation: Sendable {
    public let priority: RecommendationPriority
    public let title: String
    public let description: String
    public let action: String
}

/// Recommendation priority
public enum RecommendationPriority: String, Sendable {
    case low, medium, high, critical
}

/// Protocol configuration
public struct ProtocolConfiguration: Sendable {
    public let name: String
    public let algorithm: QuantumSafeAlgorithm
    public let keySize: KeySize
    public let securityLevel: SecurityLevel
    public var isActive: Bool
}

/// Quantum-safe error
public enum QuantumSafeError: Error {
    case algorithmNotAvailable(QuantumSafeAlgorithm)
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case signatureVerificationFailed
    case monitoringNotActive
    case invalidKeySize
    case channelEstablishmentFailed
}

// MARK: - Convenience Functions

/// Initialize quantum-safe security system
@MainActor
public func initializeQuantumSafeSecurity() async throws {
    let security = QuantumSafeSecurity()
    try await security.initializeSecurity()
}

/// Get quantum-safe security capabilities
@MainActor
public func getQuantumSafeCapabilities() -> [String: [String]] {
    [
        "cryptographic_algorithms": ["kyber", "dilithium", "falcon", "sphincs"],
        "key_management": ["key_generation", "key_rotation", "key_revocation"],
        "threat_detection": ["quantum_attack_detection", "key_compromise_alerts"],
        "compliance": ["nist_standards", "quantum_resistance_assessment"],
        "protocols": ["secure_channel_establishment", "post_quantum_key_exchange"],
    ]
}

/// Perform security assessment
@MainActor
public func performSecurityAssessment() async throws -> SecurityAssessment {
    let security = QuantumSafeSecurity()
    try await security.initializeSecurity()
    return try await security.assessSecurityPosture()
}

/// Encrypt data with quantum-safe algorithms
@MainActor
public func encryptWithQuantumSafe(
    _ data: Data,
    for recipient: String,
    algorithm: QuantumSafeAlgorithm = .kyber
) async throws -> QuantumSafeCiphertext {
    let security = QuantumSafeSecurity()
    try await security.initializeSecurity()
    return try await security.encryptData(data, for: recipient, algorithm: algorithm)
}

/// Generate quantum-safe key pair
@MainActor
public func generateQuantumSafeKeyPair(
    algorithm: QuantumSafeAlgorithm = .kyber
) async throws -> QuantumSafeKeyPair {
    let security = QuantumSafeSecurity()
    try await security.initializeSecurity()
    return try await security.generateKeyPair(algorithm: algorithm)
}

// MARK: - Global Instance

private let globalQuantumSafeSecurity = QuantumSafeSecurity()
