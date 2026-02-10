//
//  AdvancedSecurityFramework.swift
//  Shared-Kit
//
//  Created on February 10, 2026
//  Phase 7: Advanced Features - Advanced Security
//
//  This framework provides advanced security features including biometric authentication,
//  secure key management, and comprehensive security controls.
//

import Foundation
import LocalAuthentication
import Security
import CryptoKit
import Combine

// MARK: - Core Security Engine

@available(iOS 17.0, macOS 14.0, *)
public final class SecurityEngine {
    public static let shared = SecurityEngine()

    private let biometricManager: BiometricManager
    private let keyManager: KeyManager
    private let encryptionManager: EncryptionManager
    private let threatDetector: ThreatDetector

    private init() {
        self.biometricManager = BiometricManager()
        self.keyManager = KeyManager()
        self.encryptionManager = EncryptionManager()
        self.threatDetector = ThreatDetector()
    }

    // MARK: - Public API

    /// Authenticate user with biometrics
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        return try await biometricManager.authenticate(reason: reason)
    }

    /// Check if biometric authentication is available
    public func isBiometricAvailable() -> BiometricAvailability {
        return biometricManager.checkAvailability()
    }

    /// Encrypt sensitive data
    public func encrypt(data: Data, for key: String) async throws -> EncryptedData {
        return try await encryptionManager.encrypt(data: data, keyIdentifier: key)
    }

    /// Decrypt sensitive data
    public func decrypt(encryptedData: EncryptedData, for key: String) async throws -> Data {
        return try await encryptionManager.decrypt(encryptedData: encryptedData, keyIdentifier: key)
    }

    /// Store secure data
    public func storeSecure(data: Data, for key: String, accessLevel: AccessLevel = .whenUnlocked) async throws {
        try await keyManager.store(data: data, key: key, accessLevel: accessLevel)
    }

    /// Retrieve secure data
    public func retrieveSecure(for key: String) async throws -> Data {
        return try await keyManager.retrieve(key: key)
    }

    /// Generate secure random data
    public func generateSecureRandom(bytes: Int) -> Data {
        return encryptionManager.generateRandom(bytes: bytes)
    }

    /// Detect security threats
    public func detectThreats() async -> [SecurityThreat] {
        return await threatDetector.detectThreats()
    }

    /// Configure security settings
    public func configure(settings: SecuritySettings) {
        biometricManager.configure(settings.biometric)
        keyManager.configure(settings.keyManagement)
        threatDetector.configure(settings.threatDetection)
    }
}

// MARK: - Biometric Authentication

@available(iOS 17.0, macOS 14.0, *)
private final class BiometricManager {
    private var settings: BiometricSettings = BiometricSettings()

    func configure(_ settings: BiometricSettings) {
        self.settings = settings
    }

    func checkAvailability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            switch context.biometryType {
            case .faceID:
                return .available(.faceID)
            case .touchID:
                return .available(.touchID)
            case .opticID:
                return .available(.opticID)
            default:
                return .available(.none)
            }
        } else {
            return .unavailable(error?.localizedDescription ?? "Unknown error")
        }
    }

    func authenticate(reason: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let context = LAContext()

            // Configure context based on settings
            if settings.allowBiometricFallback {
                context.localizedFallbackTitle = "Use Passcode"
            } else {
                context.localizedFallbackTitle = ""
            }

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: SecurityError.biometricFailed(error.localizedDescription))
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}

public enum BiometricAvailability {
    case available(BiometricType)
    case unavailable(String)
}

public enum BiometricType {
    case faceID, touchID, opticID, none
}

public struct BiometricSettings {
    public let allowBiometricFallback: Bool
    public let requireBiometricForSensitive: Bool
    public let biometricTimeout: TimeInterval

    public init(allowBiometricFallback: Bool = true,
                requireBiometricForSensitive: Bool = true,
                biometricTimeout: TimeInterval = 300) { // 5 minutes
        self.allowBiometricFallback = allowBiometricFallback
        self.requireBiometricForSensitive = requireBiometricForSensitive
        self.biometricTimeout = biometricTimeout
    }
}

// MARK: - Key Management

@available(iOS 17.0, macOS 14.0, *)
private final class KeyManager {
    private var settings: KeyManagementSettings = KeyManagementSettings()

    func configure(_ settings: KeyManagementSettings) {
        self.settings = settings
    }

    func store(data: Data, key: String, accessLevel: AccessLevel) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessLevel.secAccessibility
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: accessLevel.secAccessibility
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw SecurityError.keyStoreFailed("Update failed: \(updateStatus)")
            }
        } else if status != errSecSuccess {
            throw SecurityError.keyStoreFailed("Store failed: \(status)")
        }
    }

    func retrieve(key: String) async throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            throw SecurityError.keyRetrievalFailed("Retrieval failed: \(status)")
        }

        return data
    }

    func delete(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keyDeletionFailed("Deletion failed: \(status)")
        }
    }
}

public enum AccessLevel {
    case whenUnlocked, afterFirstUnlock, whenUnlockedThisDeviceOnly, afterFirstUnlockThisDeviceOnly

    var secAccessibility: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

public struct KeyManagementSettings {
    public let autoRotateKeys: Bool
    public let keyRotationInterval: TimeInterval
    public let maxKeyAge: TimeInterval
    public let enableBackup: Bool

    public init(autoRotateKeys: Bool = true,
                keyRotationInterval: TimeInterval = 30 * 24 * 60 * 60, // 30 days
                maxKeyAge: TimeInterval = 365 * 24 * 60 * 60, // 1 year
                enableBackup: Bool = true) {
        self.autoRotateKeys = autoRotateKeys
        self.keyRotationInterval = keyRotationInterval
        self.maxKeyAge = maxKeyAge
        self.enableBackup = enableBackup
    }
}

// MARK: - Encryption Manager

@available(iOS 17.0, macOS 14.0, *)
private final class EncryptionManager {
    private var keys: [String: SymmetricKey] = [:]
    private let keyQueue = DispatchQueue(label: "com.tools-automation.security.keys")

    func encrypt(data: Data, keyIdentifier: String) async throws -> EncryptedData {
        let key = try await getOrCreateKey(for: keyIdentifier)

        let sealedBox = try AES.GCM.seal(data, using: key)

        return EncryptedData(
            ciphertext: sealedBox.ciphertext,
            nonce: sealedBox.nonce,
            tag: sealedBox.tag,
            keyIdentifier: keyIdentifier
        )
    }

    func decrypt(encryptedData: EncryptedData, keyIdentifier: String) async throws -> Data {
        let key = try await getOrCreateKey(for: keyIdentifier)

        let sealedBox = try AES.GCM.SealedBox(
            nonce: encryptedData.nonce,
            ciphertext: encryptedData.ciphertext,
            tag: encryptedData.tag
        )

        return try AES.GCM.open(sealedBox, using: key)
    }

    func generateRandom(bytes: Int) -> Data {
        var data = Data(count: bytes)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, bytes, $0.baseAddress!)
        }
        guard result == errSecSuccess else {
            fatalError("Failed to generate secure random data")
        }
        return data
    }

    private func getOrCreateKey(for identifier: String) async throws -> SymmetricKey {
        return try await withCheckedThrowingContinuation { continuation in
            keyQueue.async {
                if let existingKey = self.keys[identifier] {
                    continuation.resume(returning: existingKey)
                } else {
                    // Generate a new key
                    let key = SymmetricKey(size: .bits256)
                    self.keys[identifier] = key
                    continuation.resume(returning: key)
                }
            }
        }
    }
}

public struct EncryptedData {
    public let ciphertext: Data
    public let nonce: AES.GCM.Nonce
    public let tag: Data
    public let keyIdentifier: String

    public init(ciphertext: Data, nonce: AES.GCM.Nonce, tag: Data, keyIdentifier: String) {
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.keyIdentifier = keyIdentifier
    }
}

// MARK: - Threat Detector

@available(iOS 17.0, macOS 14.0, *)
private final class ThreatDetector {
    private var settings: ThreatDetectionSettings = ThreatDetectionSettings()

    func configure(_ settings: ThreatDetectionSettings) {
        self.settings = settings
    }

    func detectThreats() async -> [SecurityThreat] {
        var threats: [SecurityThreat] = []

        // Check for common security threats
        if settings.detectJailbreak {
            let jailbreakDetected = detectJailbreak()
            if jailbreakDetected {
                threats.append(SecurityThreat(
                    type: .jailbreak,
                    severity: .critical,
                    description: "Device appears to be jailbroken",
                    detectedAt: Date(),
                    recommendedAction: "Restrict sensitive operations"
                ))
            }
        }

        if settings.detectDebugger {
            let debuggerDetected = detectDebugger()
            if debuggerDetected {
                threats.append(SecurityThreat(
                    type: .debugger,
                    severity: .high,
                    description: "Debugger attachment detected",
                    detectedAt: Date(),
                    recommendedAction: "Terminate session"
                ))
            }
        }

        // Check for suspicious network activity
        if settings.monitorNetwork {
            // This would integrate with network monitoring
            // For now, just return empty
        }

        return threats
    }

    private func detectJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let fileManager = FileManager.default

        // Check for common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]

        for path in jailbreakPaths {
            if fileManager.fileExists(atPath: path) {
                return true
            }
        }

        // Check if we can write to system directories
        let testPath = "/private/test"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try fileManager.removeItem(atPath: testPath)
            return true // Shouldn't be able to write here
        } catch {
            return false // Expected - can't write to system directory
        }
        #endif
    }

    private func detectDebugger() -> Bool {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }

        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
}

public struct SecurityThreat {
    public let type: ThreatType
    public let severity: ThreatSeverity
    public let description: String
    public let detectedAt: Date
    public let recommendedAction: String
}

public enum ThreatType {
    case jailbreak, debugger, networkAttack, suspiciousActivity
}

public enum ThreatSeverity {
    case low, medium, high, critical
}

public struct ThreatDetectionSettings {
    public let detectJailbreak: Bool
    public let detectDebugger: Bool
    public let monitorNetwork: Bool
    public let anomalyDetection: Bool
    public let alertThreshold: ThreatSeverity

    public init(detectJailbreak: Bool = true,
                detectDebugger: Bool = true,
                monitorNetwork: Bool = true,
                anomalyDetection: Bool = true,
                alertThreshold: ThreatSeverity = .medium) {
        self.detectJailbreak = detectJailbreak
        self.detectDebugger = detectDebugger
        self.monitorNetwork = monitorNetwork
        self.anomalyDetection = anomalyDetection
        self.alertThreshold = alertThreshold
    }
}

// MARK: - Security Settings

public struct SecuritySettings {
    public let biometric: BiometricSettings
    public let keyManagement: KeyManagementSettings
    public let threatDetection: ThreatDetectionSettings

    public init(biometric: BiometricSettings = BiometricSettings(),
                keyManagement: KeyManagementSettings = KeyManagementSettings(),
                threatDetection: ThreatDetectionSettings = ThreatDetectionSettings()) {
        self.biometric = biometric
        self.keyManagement = keyManagement
        self.threatDetection = threatDetection
    }
}

// MARK: - Security Observable

@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class SecurityObservable: ObservableObject {
    public static let shared = SecurityObservable()

    @Published public var biometricAvailable: BiometricAvailability = .unavailable("Not checked")
    @Published public var isAuthenticated: Bool = false
    @Published public var threats: [SecurityThreat] = []
    @Published public var lastThreatCheck: Date?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkBiometricAvailability()
    }

    private func checkBiometricAvailability() {
        biometricAvailable = SecurityEngine.shared.isBiometricAvailable()
    }

    public func authenticate(reason: String) async {
        do {
            isAuthenticated = try await SecurityEngine.shared.authenticateWithBiometrics(reason: reason)
        } catch {
            isAuthenticated = false
            print("Authentication failed: \(error)")
        }
    }

    public func checkThreats() async {
        threats = await SecurityEngine.shared.detectThreats()
        lastThreatCheck = Date()
    }
}

// MARK: - Errors

public enum SecurityError: Error {
    case biometricFailed(String)
    case keyStoreFailed(String)
    case keyRetrievalFailed(String)
    case keyDeletionFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)
}

// MARK: - Codable Extensions

extension BiometricAvailability: Codable {}
extension BiometricType: Codable {}
extension BiometricSettings: Codable {}
extension AccessLevel: Codable {}
extension KeyManagementSettings: Codable {}
extension EncryptedData: Codable {}
extension SecurityThreat: Codable {}
extension ThreatType: Codable {}
extension ThreatSeverity: Codable {}
extension ThreatDetectionSettings: Codable {}
extension SecuritySettings: Codable {}