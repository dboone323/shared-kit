import XCTest

@testable import SharedKit

final class SharedKitIntegrationTests: XCTestCase {

    @MainActor
    func testEncryptedNetworkTransmission() async throws {
        // 1. Setup Security
        let crypto = CryptoManager()

        // 2. Setup Mock Network
        let conf = URLSessionConfiguration.ephemeral
        conf.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: conf)

        // Mock response
        let secretResponse = "Top Secret AI Response"
        let encryptedResponse = try await crypto.encrypt(secretResponse.data(using: .utf8)!)

        // Note: In a real scenario, the server would return encrypted data.
        // Here we simulate the server returning data that we (client) can decrypt.
        // Since CryptoManager uses a symmetric key (locally generated for this test),
        // we can confirm that we can encrypt payload, send it, receive it (mocked), and decrypt.

        let responseJSON = """
            {
                "response": "\(encryptedResponse.base64EncodedString())",
                "done": true
            }
            """

        MockURLProtocol.requestHandler = { request in
            // Verify request contains expected data (conceptually)
            return (
                HTTPURLResponse(
                    url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
                responseJSON.data(using: .utf8)!
            )
        }

        let client = OllamaClient(
            config: OllamaConfig(baseURL: "http://localhost:11434"), session: session)

        // 3. Encrypt Request Payload
        let prompt = "My Secret Prompt"
        // Skipping validation as 'My Secret Prompt' contains spaces which might fail identifier validation
        let encryptedPrompt = try await crypto.encrypt(prompt.data(using: .utf8)!)

        // 4. Send Request (we send base64 of encrypted)
        // We are passing the encrypted string as the prompt to the client
        let result = try await client.generate(
            model: "secure-model", prompt: encryptedPrompt.base64EncodedString())

        // 5. Decrypt Response
        // The mock returned our pre-encrypted 'secretResponse' as the result string
        // The client.generate returns string.
        guard let responseData = Data(base64Encoded: result) else {
            XCTFail("Response was not base64")
            return
        }

        let decrypted = try await crypto.decrypt(responseData)
        let decryptedString = String(data: decrypted, encoding: .utf8)
        XCTAssertEqual(decryptedString, secretResponse)
    }
}
