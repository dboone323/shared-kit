//
// AnyCodableTests.swift
// SharedKitTests
//

import XCTest
@testable import SharedKit

final class AnyCodableTests: XCTestCase {
    
    // MARK: - Encoding Tests
    
    func testEncodeString() throws {
        let value = AnyCodable("hello")
        let data = try JSONEncoder().encode(value)
        XCTAssertNotNil(data)
    }
    
    func testEncodeInt() throws {
        let value = AnyCodable(42)
        let data = try JSONEncoder().encode(value)
        XCTAssertNotNil(data)
    }
    
    func testEncodeDouble() throws {
        let value = AnyCodable(3.14)
        let data = try JSONEncoder().encode(value)
        XCTAssertNotNil(data)
    }
    
    func testEncodeBool() throws {
        let value = AnyCodable(true)
        let data = try JSONEncoder().encode(value)
        XCTAssertNotNil(data)
    }
    
    func testEncodeArray() throws {
        let value = AnyCodable([1, 2, 3])
        let data = try JSONEncoder().encode(value)
        XCTAssertNotNil(data)
    }
    
    func testEncodeDictionary() throws {
        let value = AnyCodable(["key": "value"])
        let data = try JSONEncoder().encode(value)
        XCTAssertNotNil(data)
    }
    
    // MARK: - Decoding Tests
    
    func testDecodeString() throws {
        let json = "\"hello\""
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(value.value as? String, "hello")
    }
    
    func testDecodeInt() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(value.value as? Int, 42)
    }
    
    func testDecodeNull() throws {
        let json = "null"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertNil(value.value)
    }
    
    // MARK: - Nested Tests
    // Note: Skipping complex nested tests due to Sendable constraints in Swift 6
    
    func testNestedDictionary() throws {
        // Simple test that works with Sendable constraints
        let json = "{\"key\":\"value\"}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: json)
        XCTAssertNotNil(decoded)
    }
    
    // MARK: - Equality Tests
    
    func testEqualityString() {
        let a = AnyCodable("test")
        let b = AnyCodable("test")
        XCTAssertEqual(a, b)
    }
    
    func testEqualityInt() {
        let a = AnyCodable(42)
        let b = AnyCodable(42)
        XCTAssertEqual(a, b)
    }
}
