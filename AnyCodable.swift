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
        case let .string(stringValue):
            try container.encode(stringValue)
        case let .int(intValue):
            try container.encode(intValue)
        case let .double(doubleValue):
            try container.encode(doubleValue)
        case let .bool(boolValue):
            try container.encode(boolValue)
        case let .array(arrayValue):
            try container.encode(arrayValue)
        case let .dictionary(dictValue):
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
        if case let .string(value) = value { return value }
        return nil
    }

    public func asInt() -> Int? {
        if case let .int(value) = value { return value }
        return nil
    }

    public func asDouble() -> Double? {
        if case let .double(value) = value { return value }
        return nil
    }

    public func asBool() -> Bool? {
        if case let .bool(value) = value { return value }
        return nil
    }

    public func asArray() -> [AnyCodable]? {
        if case let .array(value) = value { return value }
        return nil
    }

    public func asDictionary() -> [String: AnyCodable]? {
        if case let .dictionary(value) = value { return value }
        return nil
    }
}

// MARK: - Convenience Initializers

public extension AnyCodable {
    static func string(_ value: String) -> AnyCodable {
        AnyCodable(value)
    }

    static func int(_ value: Int) -> AnyCodable {
        AnyCodable(value)
    }

    static func double(_ value: Double) -> AnyCodable {
        AnyCodable(value)
    }

    static func bool(_ value: Bool) -> AnyCodable {
        AnyCodable(value)
    }

    static func array(_ value: [any Sendable]) -> AnyCodable {
        AnyCodable(value)
    }

    static func dictionary(_ value: [String: any Sendable]) -> AnyCodable {
        AnyCodable(value)
    }
}

// MARK: - CustomStringConvertible

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case let .string(value): return "\"\(value)\""
        case let .int(value): return "\(value)"
        case let .double(value): return "\(value)"
        case let .bool(value): return "\(value)"
        case let .array(value): return "\(value)"
        case let .dictionary(value): return "\(value)"
        }
    }
}

// MARK: - Equatable

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (.string(lhs), .string(rhs)): return lhs == rhs
        case let (.int(lhs), .int(rhs)): return lhs == rhs
        case let (.double(lhs), .double(rhs)): return lhs == rhs
        case let (.bool(lhs), .bool(rhs)): return lhs == rhs
        case let (.array(lhs), .array(rhs)): return lhs == rhs
        case let (.dictionary(lhs), .dictionary(rhs)): return lhs == rhs
        default: return false
        }
    }
}
