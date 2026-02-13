import CryptoKit
import Foundation

public enum EncryptedFileStoreError: Error {
    case invalidCiphertext
    case missingData
}

public actor EncryptedFileStore {
    public static let shared = EncryptedFileStore()

    private var symmetricKey: SymmetricKey

    public init() {
        symmetricKey = SymmetricKey(size: .bits256)
    }

    public func updateKey(_ key: SymmetricKey) {
        symmetricKey = key
    }

    public func save(_ data: Data, to url: URL) throws {
        let sealed = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealed.combined else {
            throw EncryptedFileStoreError.invalidCiphertext
        }
        try combined.write(to: url, options: .atomic)
    }

    public func load(from url: URL) throws -> Data {
        let encrypted = try Data(contentsOf: url)
        let sealed = try AES.GCM.SealedBox(combined: encrypted)
        return try AES.GCM.open(sealed, using: symmetricKey)
    }
}
