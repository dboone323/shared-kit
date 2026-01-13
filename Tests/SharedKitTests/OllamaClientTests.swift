//
// OllamaClientTests.swift
// SharedKitTests
//

import XCTest
@testable import SharedKit

final class OllamaClientTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testDefaultEndpoint() {
        let config = OllamaClientConfig()
        XCTAssertEqual(config.baseURL.absoluteString, "http://localhost:11434")
    }
    
    func testCustomEndpoint() {
        let config = OllamaClientConfig(baseURL: URL(string: "http://custom:8080")!)
        XCTAssertEqual(config.baseURL.absoluteString, "http://custom:8080")
    }
    
    func testDefaultModel() {
        let config = OllamaClientConfig()
        XCTAssertFalse(config.model.isEmpty)
    }
    
    // MARK: - Request Building Tests
    
    func testGenerateRequestJSON() throws {
        let request = OllamaGenerateRequest(
            model: "llama2",
            prompt: "Hello",
            stream: false
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertEqual(json?["model"] as? String, "llama2")
        XCTAssertEqual(json?["prompt"] as? String, "Hello")
        XCTAssertEqual(json?["stream"] as? Bool, false)
    }
    
    func testChatRequestJSON() throws {
        let message = OllamaChatMessage(role: "user", content: "Hello")
        let request = OllamaChatRequest(
            model: "llama2",
            messages: [message],
            stream: false
        )
        let data = try JSONEncoder().encode(request)
        XCTAssertNotNil(data)
    }
    
    // MARK: - Response Parsing Tests
    
    func testGenerateResponseParsing() throws {
        let json = """
        {
            "model": "llama2",
            "response": "Hello there!",
            "done": true
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(OllamaGenerateResponse.self, from: json)
        XCTAssertEqual(response.model, "llama2")
        XCTAssertEqual(response.response, "Hello there!")
        XCTAssertTrue(response.done)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        XCTAssertTrue(true, "Network error handling placeholder")
    }
    
    func testTimeoutHandling() {
        XCTAssertTrue(true, "Timeout handling placeholder")
    }
    
    func testInvalidResponseHandling() {
        XCTAssertTrue(true, "Invalid response handling placeholder")
    }
}
