import SharedKitCore
import XCTest

@testable import SharedKit

@available(macOS 12.0, iOS 15.0, *)
final class SecurityFrameworkTests: XCTestCase {
    func testEmailValidation() async throws {
        let framework = SharedKitCore.SecurityFramework.shared

        try await framework.validate(input: "test@example.com", type: .email)

        do {
            try await framework.validate(input: "not-an-email", type: .email)
            XCTFail("Expected invalid email validation to throw")
        } catch let error as ValidationError {
            guard case .invalidEmail = error else {
                XCTFail("Unexpected validation error: \(error)")
                return
            }
        }
    }

    func testIdentifierValidation() async throws {
        let framework = SharedKitCore.SecurityFramework.shared

        try await framework.validate(input: "valid_id_123", type: .identifier)

        do {
            try await framework.validate(input: "invalid-id!", type: .identifier)
            XCTFail("Expected invalid identifier validation to throw")
        } catch {}
    }

    func testSanitization() async {
        let framework = SharedKitCore.SecurityFramework.shared
        let raw = "Hello\0World'"
        let sanitized = await framework.sanitize(raw)
        XCTAssertEqual(sanitized, "HelloWorld''")
    }

    func testRBAC() async throws {
        let framework = SharedKitCore.SecurityFramework.shared
        let admin = UserContext(id: "1", role: .admin)
        let viewer = UserContext(id: "2", role: .viewer)

        try await framework.checkPermission(user: admin, action: .delete)
        try await framework.checkPermission(user: viewer, action: .read)

        do {
            try await framework.checkPermission(user: viewer, action: .write)
            XCTFail("Viewer should not be able to write")
        } catch {}
    }

    func testEncryptionCycle() async throws {
        let framework = SharedKitCore.SecurityFramework.shared
        let secret = Data("My Secret Data".utf8)

        let encrypted = try await framework.encrypt(secret)
        XCTAssertNotEqual(secret, encrypted)

        let decrypted = try await framework.decrypt(encrypted)
        XCTAssertEqual(secret, decrypted)
    }
}
