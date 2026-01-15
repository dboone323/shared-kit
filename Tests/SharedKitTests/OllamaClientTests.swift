//
// OllamaClientTests.swift
// SharedKitTests
//

import XCTest
@testable import SharedKit

final class OllamaClientTests: XCTestCase {
    
    // MARK: - Configuration Tests
    // Note: OllamaConfig uses OllamaConfig struct, not OllamaClientConfig
    
    func testDefaultConfig() {
        let config = OllamaConfig.default
        XCTAssertEqual(config.baseURL, "http://127.0.0.1:11434")
        XCTAssertFalse(config.defaultModel.isEmpty)
    }
    
    func testCodeGenerationConfig() {
        let config = OllamaConfig.codeGeneration
        XCTAssertEqual(config.defaultModel, "codellama")
        XCTAssertEqual(config.temperature, 0.2)
    }
    
    // MARK: - Response Parsing Tests
    
    func testGenerateResponseParsing() throws {
        let json = """
        {
            "model": "llama2",
            "created_at": "2024-01-01T00:00:00Z",
            "response": "Hello there!",
            "done": true
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(OllamaGenerateResponse.self, from: json)
        XCTAssertEqual(response.model, "llama2")
        XCTAssertEqual(response.response, "Hello there!")
        XCTAssertTrue(response.done)
    }
    
    func testOllamaMessageCreation() {
        let message = OllamaMessage(role: "user", content: "Hello")
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello")
    }
    
    // MARK: - Error Tests
    
    func testOllamaErrorDescriptions() {
        XCTAssertNotNil(OllamaError.serverNotRunning.errorDescription)
        XCTAssertNotNil(OllamaError.modelNotAvailable("test").errorDescription)
        XCTAssertNotNil(OllamaError.networkTimeout.errorDescription)
    }
}

