//
// OllamaTypesTests.swift
// SharedKitTests
//

import XCTest
@testable import SharedKit

final class OllamaTypesTests: XCTestCase {
    
    // MARK: - Generate Request Tests
    
    func testGenerateRequestEncoding() throws {
        let request = OllamaGenerateRequest(
            model: "llama2",
            prompt: "Hello, world!",
            stream: false
        )
        
        let data = try JSONEncoder().encode(request)
        XCTAssertNotNil(data)
    }
    
    func testGenerateRequestDefaults() {
        let request = OllamaGenerateRequest(
            model: "llama2",
            prompt: "Test"
        )
        
        XCTAssertEqual(request.model, "llama2")
        XCTAssertEqual(request.prompt, "Test")
    }
    
    // MARK: - Chat Message Tests
    
    func testChatMessageEncoding() throws {
        let message = OllamaChatMessage(
            role: "user",
            content: "Hello"
        )
        
        let data = try JSONEncoder().encode(message)
        XCTAssertNotNil(data)
    }
    
    func testChatMessageRoles() {
        let roles = ["system", "user", "assistant"]
        for role in roles {
            let message = OllamaChatMessage(role: role, content: "test")
            XCTAssertEqual(message.role, role)
        }
    }
    
    // MARK: - Chat Request Tests
    
    func testChatRequestEncoding() throws {
        let message = OllamaChatMessage(role: "user", content: "Hello")
        let request = OllamaChatRequest(
            model: "llama2",
            messages: [message],
            stream: false
        )
        
        let data = try JSONEncoder().encode(request)
        XCTAssertNotNil(data)
    }
    
    func testChatRequestMultipleMessages() {
        let messages = [
            OllamaChatMessage(role: "system", content: "You are helpful"),
            OllamaChatMessage(role: "user", content: "Hello")
        ]
        let request = OllamaChatRequest(
            model: "llama2",
            messages: messages,
            stream: false
        )
        
        XCTAssertEqual(request.messages.count, 2)
    }
    
    // MARK: - Response Decoding Tests
    
    func testGenerateResponseDecoding() throws {
        let json = """
        {
            "model": "llama2",
            "response": "Hello!",
            "done": true
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(OllamaGenerateResponse.self, from: json)
        XCTAssertEqual(response.model, "llama2")
        XCTAssertEqual(response.response, "Hello!")
        XCTAssertTrue(response.done)
    }
    
    func testPartialResponseDecoding() throws {
        let json = """
        {
            "model": "llama2",
            "response": "Hello",
            "done": false
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(OllamaGenerateResponse.self, from: json)
        XCTAssertFalse(response.done)
    }
}
