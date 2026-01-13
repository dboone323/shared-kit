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
    
    func testNestedDictionary() throws {
        let nested: [String: Any] = [
            "string": "test",
            "number": 123,
            "array": [1, 2, 3],
            "nested": ["a": "b"]
        ]
        let value = AnyCodable(nested)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertNotNil(decoded.value as? [String: Any])
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
