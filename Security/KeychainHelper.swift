//
//  KeychainHelper.swift
//  Shared
//
//  Secure storage utility for sensitive data using iOS Keychain
//  Created as part of Quantum-workspace security improvements
//

import Foundation
import Security

/// A utility class for securely storing and retrieving sensitive data using the iOS Keychain.
/// This replaces insecure UserDefaults storage for sensitive information like authentication settings.
public final class KeychainHelper {
    // MARK: - Singleton

    /// Shared instance for convenience
    public static let shared = KeychainHelper()

    // MARK: - Private Properties

    private let serviceName: String

    // MARK: - Initialization

    /// Initialize with a custom service name
    /// - Parameter serviceName: The service name to use for Keychain operations
    public init(serviceName: String = "com.quantum-workspace.shared") {
        self.serviceName = serviceName
    }

    // MARK: - Public Methods

    /// Store a string value securely in the Keychain
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The key to associate with the value
    /// - Returns: True if storage was successful, false otherwise
    @discardableResult
    public func setString(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("KeychainHelper: Failed to encode string to data")
            return false
        }
        return setData(data, forKey: key)
    }

    /// Retrieve a string value from the Keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The stored string value, or nil if not found
    public func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Store binary data securely in the Keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to associate with the data
    /// - Returns: True if storage was successful, false otherwise
    @discardableResult
    public func setData(_ data: Data, forKey key: String) -> Bool {
        // First, delete any existing item
        deleteItem(forKey: key)

        // Create the query for storing the data
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("KeychainHelper: Failed to store data for key '\(key)': \(status)")
            return false
        }

        return true
    }

    /// Retrieve binary data from the Keychain
    /// - Parameter key: The key associated with the data
    /// - Returns: The stored data, or nil if not found
    public func getData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status != errSecItemNotFound {
                print("KeychainHelper: Failed to retrieve data for key '\(key)': \(status)")
            }
            return nil
        }

        return result as? Data
    }

    /// Delete a stored value from the Keychain
    /// - Parameter key: The key associated with the value to delete
    /// - Returns: True if deletion was successful or item didn't exist, false otherwise
    @discardableResult
    public func deleteItem(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        // errSecItemNotFound is not an error in this context
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("KeychainHelper: Failed to delete item for key '\(key)': \(status)")
            return false
        }

        return true
    }

    /// Check if a value exists for the given key
    /// - Parameter key: The key to check
    /// - Returns: True if a value exists, false otherwise
    public func hasValue(forKey key: String) -> Bool {
        getData(forKey: key) != nil
    }

    // MARK: - Convenience Methods for Common Types

    /// Store a boolean value securely
    /// - Parameters:
    ///   - value: The boolean value to store
    ///   - key: The key to associate with the value
    /// - Returns: True if storage was successful, false otherwise
    @discardableResult
    public func setBool(_ value: Bool, forKey key: String) -> Bool {
        let stringValue = value ? "true" : "false"
        return setString(stringValue, forKey: key)
    }

    /// Retrieve a boolean value from the Keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The stored boolean value, or nil if not found
    public func getBool(forKey key: String) -> Bool? {
        guard let stringValue = getString(forKey: key) else { return nil }
        return stringValue == "true"
    }

    /// Store an integer value securely
    /// - Parameters:
    ///   - value: The integer value to store
    ///   - key: The key to associate with the value
    /// - Returns: True if storage was successful, false otherwise
    @discardableResult
    public func setInt(_ value: Int, forKey key: String) -> Bool {
        let stringValue = String(value)
        return setString(stringValue, forKey: key)
    }

    /// Retrieve an integer value from the Keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The stored integer value, or nil if not found
    public func getInt(forKey key: String) -> Int? {
        guard let stringValue = getString(forKey: key) else { return nil }
        return Int(stringValue)
    }
}

// MARK: - Migration Helper

public extension KeychainHelper {
    /// Migrate a sensitive setting from UserDefaults to Keychain
    /// - Parameters:
    ///   - key: The key to migrate
    ///   - userDefaults: The UserDefaults instance to migrate from (defaults to standard)
    /// - Returns: True if migration was successful or not needed, false otherwise
    @discardableResult
    func migrateFromUserDefaults(key: String, userDefaults: UserDefaults = .standard) -> Bool {
        // Check if already migrated
        if hasValue(forKey: key) {
            // Already in Keychain, remove from UserDefaults
            userDefaults.removeObject(forKey: key)
            return true
        }

        // Check if value exists in UserDefaults
        if let value = userDefaults.object(forKey: key) {
            var success = false

            // Migrate based on type
            if let stringValue = value as? String {
                success = setString(stringValue, forKey: key)
            } else if let boolValue = value as? Bool {
                success = setBool(boolValue, forKey: key)
            } else if let intValue = value as? Int {
                success = setInt(intValue, forKey: key)
            } else if let dataValue = value as? Data {
                success = setData(dataValue, forKey: key)
            }

            if success {
                // Remove from UserDefaults after successful migration
                userDefaults.removeObject(forKey: key)
                print("KeychainHelper: Successfully migrated '\(key)' from UserDefaults to Keychain")
                return true
            } else {
                print("KeychainHelper: Failed to migrate '\(key)' to Keychain")
                return false
            }
        }

        // No value to migrate
        return true
    }
} </ content>
<parameter name = "filePath" >/ Users / danielstevens / Desktop / Quantum - workspace / Shared / Security / KeychainHelper.swift
