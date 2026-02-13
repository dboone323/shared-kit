import Foundation
import SharedKit

private enum VerificationError: LocalizedError {
    case unhealthyService(name: String, details: String)
    case backupRoundTripFailed
    case pinningLookupFailed
    case featureFlagRoundTripFailed

    var errorDescription: String? {
        switch self {
        case .unhealthyService(let name, let details):
            return "Service '\(name)' is not healthy: \(details)"
        case .backupRoundTripFailed:
            return "Backup round-trip validation failed."
        case .pinningLookupFailed:
            return "Certificate pinning lookup failed after policy update."
        case .featureFlagRoundTripFailed:
            return "Platform feature flag round-trip validation failed."
        }
    }
}

/// Runtime Assurance Gateway verifier for SharedKit service/security foundations.
@available(macOS 14.0, *)
@main
struct RAGVerifier {
    static func main() async {
        do {
            try await RuntimeAssuranceVerifier().run()
            print("RAG verification completed successfully.")
            exit(0)
        } catch {
            fputs("RAG verification failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}

@available(macOS 14.0, *)
private struct RuntimeAssuranceVerifier {
    func run() async throws {
        try await verifyServiceHealth()
        try await verifyFeatureRegistryRoundTrip()
        try await verifyCertificatePinningRoundTrip()
        try await verifyBackupRestoreRoundTrip()
    }

    private func verifyServiceHealth() async throws {
        try await ServiceManager.shared.initializeServices()
        let statuses = await ServiceManager.shared.getServicesHealthStatus()
        for (service, status) in statuses {
            switch status {
            case .healthy:
                continue
            case .degraded(let reason):
                throw VerificationError.unhealthyService(name: service, details: "degraded: \(reason)")
            case .unhealthy(let error):
                throw VerificationError.unhealthyService(
                    name: service,
                    details: "unhealthy: \(error.localizedDescription)"
                )
            }
        }
    }

    private func verifyFeatureRegistryRoundTrip() async throws {
        let baseline = PlatformFeatureFlags(
            widgetsEnabled: true,
            siriShortcutsEnabled: true,
            coreMLEnabled: true,
            arkitEnabled: false,
            cloudKitSharingEnabled: true,
            healthKitEnabled: false,
            homeKitEnabled: false,
            callKitEnabled: false,
            carPlayEnabled: false
        )
        await PlatformFeatureRegistry.shared.setFlags(baseline, for: .macOS)
        let roundTrip = await PlatformFeatureRegistry.shared.flags(for: .macOS)
        guard roundTrip == baseline else {
            throw VerificationError.featureFlagRoundTripFailed
        }
    }

    private func verifyCertificatePinningRoundTrip() async throws {
        let host = "api.example.com"
        let fingerprint = "sha256-test-fingerprint"
        let pin = PinnedCertificate(host: host, sha256Fingerprint: fingerprint)
        let policy = CertificatePinningPolicy(enforcePinning: true, pinnedCertificates: [pin])
        await CertificatePinningPolicyStore.shared.updatePolicy(policy)

        let current = await CertificatePinningPolicyStore.shared.currentPolicy()
        guard current.fingerprint(for: host) == fingerprint else {
            throw VerificationError.pinningLookupFailed
        }
    }

    private func verifyBackupRestoreRoundTrip() async throws {
        let payload = Data("shared-kit-rag-verifier-payload".utf8)
        let backupDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "rag-verifier-backups",
            isDirectory: true
        )

        let artifact = try await BackupRestoreService.shared.createBackup(
            data: payload,
            destinationDirectory: backupDirectory,
            filePrefix: "rag-verify"
        )
        let restored = try await BackupRestoreService.shared.restoreBackup(from: artifact)

        guard restored == payload else {
            throw VerificationError.backupRoundTripFailed
        }
    }
}
