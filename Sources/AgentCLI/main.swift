import Foundation
import SharedKit

private enum AgentCLIError: LocalizedError {
    case missingValue(flag: String)
    case invalidCommand(String)
    case backupVerificationFailed

    var errorDescription: String? {
        switch self {
        case .missingValue(let flag):
            return "Missing value for \(flag)."
        case .invalidCommand(let command):
            return "Unsupported command: \(command)"
        case .backupVerificationFailed:
            return "Backup round-trip verification failed."
        }
    }
}

/// CLI for validating SharedKit service health and platform security/runtime settings.
@available(macOS 14.0, *)
@main
struct AgentCLI {
    static func main() async {
        let tool = AgentCLITool()
        do {
            try await tool.run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}

@available(macOS 14.0, *)
private struct AgentCLITool {
    func run(arguments: [String]) async throws {
        guard let command = arguments.first else {
            printHelp()
            return
        }

        switch command {
        case "help", "--help", "-h":
            printHelp()
        case "status":
            try await printServiceStatus()
        case "flags":
            try await printPlatformFlags()
        case "pin":
            try await updateCertificatePolicy(arguments: Array(arguments.dropFirst()))
        case "backup-check":
            try await runBackupRoundTrip(arguments: Array(arguments.dropFirst()))
        default:
            throw AgentCLIError.invalidCommand(command)
        }
    }

    private func printHelp() {
        print(
            """
            AgentCLI commands:
              status
                Initialize services and print health state.
              flags
                Print feature flags for each supported platform.
              pin --host <hostname> --fingerprint <sha256>
                Add/update a pinned certificate entry for a host.
              backup-check --payload <text> [--prefix <name>]
                Create and restore a backup, then verify payload integrity.
            """
        )
    }

    private func printServiceStatus() async throws {
        try await ServiceManager.shared.initializeServices()
        let statuses = await ServiceManager.shared.getServicesHealthStatus()
        if statuses.isEmpty {
            print("No registered services were found.")
            return
        }

        for (service, status) in statuses.sorted(by: { $0.key < $1.key }) {
            print("\(service): \(statusLabel(status))")
        }
    }

    private func printPlatformFlags() async throws {
        for platform in SupportedPlatform.allCases {
            let flags = await PlatformFeatureRegistry.shared.flags(for: platform)
            print(
                """
                \(platform.rawValue):
                  widgets=\(flags.widgetsEnabled)
                  siriShortcuts=\(flags.siriShortcutsEnabled)
                  coreML=\(flags.coreMLEnabled)
                  arkit=\(flags.arkitEnabled)
                  cloudKitSharing=\(flags.cloudKitSharingEnabled)
                  healthKit=\(flags.healthKitEnabled)
                  homeKit=\(flags.homeKitEnabled)
                  callKit=\(flags.callKitEnabled)
                  carPlay=\(flags.carPlayEnabled)
                """
            )
        }
    }

    private func updateCertificatePolicy(arguments: [String]) async throws {
        let host = try requiredValue(for: "--host", in: arguments)
        let fingerprint = try requiredValue(for: "--fingerprint", in: arguments)

        var policy = await CertificatePinningPolicyStore.shared.currentPolicy()
        let newPin = PinnedCertificate(host: host, sha256Fingerprint: fingerprint)

        if let existingIndex = policy.pinnedCertificates.firstIndex(where: {
            $0.host.caseInsensitiveCompare(host) == .orderedSame
        }) {
            policy.pinnedCertificates[existingIndex] = newPin
        } else {
            policy.pinnedCertificates.append(newPin)
        }
        await CertificatePinningPolicyStore.shared.updatePolicy(policy)

        print("Pinned certificate policy updated for host: \(host)")
    }

    private func runBackupRoundTrip(arguments: [String]) async throws {
        let payload = try requiredValue(for: "--payload", in: arguments)
        let prefix = value(for: "--prefix", in: arguments) ?? "agentcli"

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "agentcli-backups",
            isDirectory: true
        )
        let artifact = try await BackupRestoreService.shared.createBackup(
            data: Data(payload.utf8),
            destinationDirectory: directory,
            filePrefix: prefix
        )
        let restoredData = try await BackupRestoreService.shared.restoreBackup(from: artifact)
        guard restoredData == Data(payload.utf8) else {
            throw AgentCLIError.backupVerificationFailed
        }

        print("Backup verification succeeded: \(artifact.fileURL.path)")
    }

    private func statusLabel(_ status: ServiceHealthStatus) -> String {
        switch status {
        case .healthy:
            return "healthy"
        case .degraded(let reason):
            return "degraded (\(reason))"
        case .unhealthy(let error):
            return "unhealthy (\(error.localizedDescription))"
        }
    }

    private func requiredValue(for flag: String, in arguments: [String]) throws -> String {
        guard let value = value(for: flag, in: arguments), !value.isEmpty else {
            throw AgentCLIError.missingValue(flag: flag)
        }
        return value
    }

    private func value(for flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else {
            return nil
        }
        return arguments[valueIndex]
    }
}
