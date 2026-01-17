import XCTest

@testable import SharedKit

@available(macOS 12.0, iOS 15.0, *)
final class SecurityFrameworkTests: XCTestCase {

    // MARK: - Input Validation

    func testEmailValidation() async throws {
        let framework = SecurityFramework()

        // Valid
        try await framework.validate(input: "test@example.com", type: .email)

        // Invalid
        do {
            try await framework.validate(input: "not-an-email", type: .email)
            XCTFail("Should detect invalid email")
        } catch let error as ValidationError {
            if case .invalidFormat = error {} else { XCTFail("Wrong error type") }
        } catch {
            XCTFail("Wrong error type")
        }
    }

    func testIdentifierValidation() async throws {
        let framework = SecurityFramework()

        try await framework.validate(input: "valid_id_123", type: .identifier)

        do {
            try await framework.validate(input: "invalid-id!", type: .identifier)  // - and ! not allowed in regex ^[a-zA-Z0-9_]+$
            XCTFail("Should detect invalid identifier")
        } catch {}
    }

    func testSanitization() async {
        let framework = SecurityFramework()
        let raw = "Hello\0World'"
        let sanitized = await framework.sanitize(raw)
        XCTAssertEqual(sanitized, "HelloWorld''")  // null removed, quote escaped
    }

    // MARK: - RBAC

    func testRBAC() async throws {
        let framework = SecurityFramework()
        let admin = UserContext(id: "1", role: .admin)
        let viewer = UserContext(id: "2", role: .viewer)

        // Admin can do anything
        try await framework.checkPermission(user: admin, action: .delete)

        // Viewer can read
        try await framework.checkPermission(user: viewer, action: .read)

        // Viewer cannot write
        do {
            try await framework.checkPermission(user: viewer, action: .write)
            XCTFail("Viewer should not write")
        } catch {}
    }

    // MARK: - Encryption

    func testEncryptionCycle() async throws {
        let framework = SecurityFramework()
        let secret = "My Secret Data".data(using: .utf8)!

        let encrypted = try await framework.encrypt(secret)
        XCTAssertNotEqual(secret, encrypted)

        let decrypted = try await framework.decrypt(encrypted)
        XCTAssertEqual(secret, decrypted)
    }
}
