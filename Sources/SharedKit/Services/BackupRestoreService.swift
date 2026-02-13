import Foundation

public struct BackupArtifact: Sendable, Codable, Equatable {
    public let createdAt: Date
    public let fileURL: URL

    public init(createdAt: Date = Date(), fileURL: URL) {
        self.createdAt = createdAt
        self.fileURL = fileURL
    }
}

public actor BackupRestoreService {
    public static let shared = BackupRestoreService()

    public init() {}

    public func createBackup(data: Data, destinationDirectory: URL, filePrefix: String) throws -> BackupArtifact {
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let filename = "\(filePrefix)-\(Int(Date().timeIntervalSince1970)).backup"
        let targetURL = destinationDirectory.appendingPathComponent(filename)
        try data.write(to: targetURL, options: .atomic)
        return BackupArtifact(fileURL: targetURL)
    }

    public func restoreBackup(from artifact: BackupArtifact) throws -> Data {
        try Data(contentsOf: artifact.fileURL)
    }
}
