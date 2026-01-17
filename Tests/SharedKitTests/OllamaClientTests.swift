//
// OllamaClientTests.swift
// SharedKitTests
//

import XCTest

@testable import SharedKit

@MainActor
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

    // MARK: - Mock Network Tests

    func testGenerateWithMock() async throws {
        // Setup Protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        // Setup Mock Response
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.path.hasSuffix("/api/generate") else {
                throw URLError(.badURL)
            }

            let responseJSON = """
                {
                    "model": "llama2",
                    "created_at": "2024-01-01T00:00:00Z",
                    "response": "Mocked response",
                    "done": true
                }
                """
            let data = responseJSON.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let client = OllamaClient(session: session)
        // Bypass connection check for this specific unit test or mock the connection check endpoint too
        // The client init calls initializeConnection which calls /api/tags
        // We should handle that mock too or wait?
        // Actually initializeConnection is async Task, might not finish before we call generate.
        // But generate calls selectOptimalModel which calls listModels -> performs request
        // So we need to mock /api/tags as well for any robust test.

        MockURLProtocol.requestHandler = { request in
            guard let url = request.url else { throw URLError(.badURL) }

            if url.path.hasSuffix("/api/tags") {
                let tagsJSON = """
                    { "models": [ { "name": "llama2" } ] }
                    """
                return (
                    HTTPURLResponse(
                        url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    tagsJSON.data(using: .utf8)!
                )
            }

            if url.path.hasSuffix("/api/generate") {
                let responseJSON = """
                    {
                        "model": "llama2",
                        "created_at": "2024-01-01T00:00:00Z",
                        "response": "Mocked response",
                        "done": true
                    }
                    """
                return (
                    HTTPURLResponse(
                        url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                    responseJSON.data(using: .utf8)!
                )
            }

            throw URLError(.badURL)
        }

        let result = try await client.generate(model: "llama2", prompt: "Test", useCache: false)
        XCTAssertEqual(result, "Mocked response")
    }
}
