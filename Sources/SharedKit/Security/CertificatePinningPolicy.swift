import Foundation

public struct PinnedCertificate: Sendable, Codable, Equatable {
    public let host: String
    public let sha256Fingerprint: String

    public init(host: String, sha256Fingerprint: String) {
        self.host = host
        self.sha256Fingerprint = sha256Fingerprint
    }
}

public struct CertificatePinningPolicy: Sendable, Codable, Equatable {
    public var enforcePinning: Bool
    public var pinnedCertificates: [PinnedCertificate]

    public init(enforcePinning: Bool = true, pinnedCertificates: [PinnedCertificate] = []) {
        self.enforcePinning = enforcePinning
        self.pinnedCertificates = pinnedCertificates
    }

    public func fingerprint(for host: String) -> String? {
        pinnedCertificates.first { $0.host.caseInsensitiveCompare(host) == .orderedSame }?.sha256Fingerprint
    }
}

public actor CertificatePinningPolicyStore {
    public static let shared = CertificatePinningPolicyStore()

    private var policy = CertificatePinningPolicy()

    public init() {}

    public func updatePolicy(_ policy: CertificatePinningPolicy) {
        self.policy = policy
    }

    public func currentPolicy() -> CertificatePinningPolicy {
        policy
    }
}
