//
//  AnyCodable.swift
//  QuantumAgentEcosystems
//
//  Created on October 14, 2025
//  Phase 9G: MCP Universal Intelligence - Task 314
//
//  A Sendable type that can encode/decode any Codable value for dynamic data handling.

import Foundation

/// A Sendable type that can encode/decode any Codable value
/// Used for dynamic parameter passing in quantum orchestration frameworks
public struct AnyCodable: Codable, Sendable {
    public let value: SendableValue

    public init(_ value: any Sendable) {
        if let stringValue = value as? String {
            self.value = .string(stringValue)
        } else if let intValue = value as? Int {
            self.value = .int(intValue)
        } else if let doubleValue = value as? Double {
            self.value = .double(doubleValue)
        } else if let boolValue = value as? Bool {
            self.value = .bool(boolValue)
        } else if let arrayValue = value as? [any Sendable] {
            self.value = .array(arrayValue.map { AnyCodable($0) })
        } else if let dictValue = value as? [String: any Sendable] {
            self.value = .dictionary(dictValue.mapValues { AnyCodable($0) })
        } else {
            // For non-Sendable values, store as string representation
            self.value = .string(String(describing: value))
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self.value = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self.value = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = .bool(boolValue)
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self.value = .array(arrayValue)
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            self.value = .dictionary(dictValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case .string(let stringValue):
            try container.encode(stringValue)
        case .int(let intValue):
            try container.encode(intValue)
        case .double(let doubleValue):
            try container.encode(doubleValue)
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .array(let arrayValue):
            try container.encode(arrayValue)
        case .dictionary(let dictValue):
            try container.encode(dictValue)
        }
    }

    /// The underlying Sendable value types
    public enum SendableValue: Codable, Sendable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case array([AnyCodable])
        case dictionary([String: AnyCodable])
    }

    /// Extract the value as a specific type
    public func asString() -> String? {
        if case .string(let value) = value { return value }
        return nil
    }

    public func asInt() -> Int? {
        if case .int(let value) = value { return value }
        return nil
    }

    public func asDouble() -> Double? {
        if case .double(let value) = value { return value }
        return nil
    }

    public func asBool() -> Bool? {
        if case .bool(let value) = value { return value }
        return nil
    }

    public func asArray() -> [AnyCodable]? {
        if case .array(let value) = value { return value }
        return nil
    }

    public func asDictionary() -> [String: AnyCodable]? {
        if case .dictionary(let value) = value { return value }
        return nil
    }
}

// MARK: - Convenience Initializers

extension AnyCodable {
    public static func string(_ value: String) -> AnyCodable {
        AnyCodable(value)
    }

    public static func int(_ value: Int) -> AnyCodable {
        AnyCodable(value)
    }

    public static func double(_ value: Double) -> AnyCodable {
        AnyCodable(value)
    }

    public static func bool(_ value: Bool) -> AnyCodable {
        AnyCodable(value)
    }

    public static func array(_ value: [any Sendable]) -> AnyCodable {
        AnyCodable(value)
    }

    public static func dictionary(_ value: [String: any Sendable]) -> AnyCodable {
        AnyCodable(value)
    }
}

// MARK: - CustomStringConvertible

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case .string(let value): return "\"\(value)\""
        case .int(let value): return "\(value)"
        case .double(let value): return "\(value)"
        case .bool(let value): return "\(value)"
        case .array(let value): return "\(value)"
        case .dictionary(let value): return "\(value)"
        }
    }
}

// MARK: - Equatable

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (.string(let lhs), .string(let rhs)): return lhs == rhs
        case (.int(let lhs), .int(let rhs)): return lhs == rhs
        case (.double(let lhs), .double(let rhs)): return lhs == rhs
        case (.bool(let lhs), .bool(let rhs)): return lhs == rhs
        case (.array(let lhs), .array(let rhs)): return lhs == rhs
        case (.dictionary(let lhs), .dictionary(let rhs)): return lhs == rhs
        default: return false
        }
    }
}
