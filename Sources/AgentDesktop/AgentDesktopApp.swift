import SharedKit
import SwiftUI

@available(macOS 14.0, *)
@main
struct AgentDesktopApp: App {
    @StateObject private var viewModel = AgentDesktopViewModel()

    var body: some Scene {
        WindowGroup("Agent Desktop") {
            AgentDashboardView()
                .environmentObject(viewModel)
        }
        .defaultSize(width: 760, height: 620)
    }
}

@available(macOS 14.0, *)
@MainActor
final class AgentDesktopViewModel: ObservableObject {
    @Published private(set) var serviceStatuses: [ServiceStatusItem] = []
    @Published private(set) var platformFlags: [PlatformFlagsItem] = []
    @Published private(set) var lastRefreshDate: Date?
    @Published private(set) var isRefreshing = false
    @Published var errorMessage: String?

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await ServiceManager.shared.initializeServices()
            let statuses = await ServiceManager.shared.getServicesHealthStatus()
            let serviceItems = statuses.map { key, value in
                ServiceStatusItem(
                    serviceName: key,
                    summary: self.summary(for: value),
                    status: value
                )
            }
            .sorted(by: { $0.serviceName < $1.serviceName })

            var flagItems: [PlatformFlagsItem] = []
            for platform in SupportedPlatform.allCases {
                let flags = await PlatformFeatureRegistry.shared.flags(for: platform)
                flagItems.append(PlatformFlagsItem(platform: platform, flags: flags))
            }
            flagItems.sort(by: { $0.platform.rawValue < $1.platform.rawValue })

            serviceStatuses = serviceItems
            platformFlags = flagItems
            lastRefreshDate = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func summary(for status: ServiceHealthStatus) -> String {
        switch status {
        case .healthy:
            return "Healthy"
        case .degraded(let reason):
            return "Degraded: \(reason)"
        case .unhealthy(let error):
            return "Unhealthy: \(error.localizedDescription)"
        }
    }
}

@available(macOS 14.0, *)
private struct AgentDashboardView: View {
    @EnvironmentObject private var viewModel: AgentDesktopViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Runtime Overview")
                    .font(.title2.bold())
                Spacer()
                if let lastRefreshDate = viewModel.lastRefreshDate {
                    Text(lastRefreshDate, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Refresh") {
                    Task { await viewModel.refresh() }
                }
                .disabled(viewModel.isRefreshing)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            GroupBox("Service Health") {
                if viewModel.serviceStatuses.isEmpty {
                    Text("No registered services.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.serviceStatuses) { item in
                            HStack(alignment: .firstTextBaseline) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.serviceName)
                                    .font(.body.monospaced())
                                Spacer()
                                Text(item.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            GroupBox("Platform Feature Flags") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.platformFlags) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.platform.rawValue)
                                .font(.headline)
                            Text(item.summaryLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(20)
        .task {
            await viewModel.refresh()
        }
    }
}

@available(macOS 14.0, *)
struct ServiceStatusItem: Identifiable {
    let id = UUID()
    let serviceName: String
    let summary: String
    let status: ServiceHealthStatus

    var color: Color {
        switch status {
        case .healthy:
            return .green
        case .degraded:
            return .orange
        case .unhealthy:
            return .red
        }
    }
}

@available(macOS 14.0, *)
struct PlatformFlagsItem: Identifiable {
    let id = UUID()
    let platform: SupportedPlatform
    let flags: PlatformFeatureFlags

    var summaryLine: String {
        [
            flagText("widgets", flags.widgetsEnabled),
            flagText("siri", flags.siriShortcutsEnabled),
            flagText("coreML", flags.coreMLEnabled),
            flagText("arkit", flags.arkitEnabled),
            flagText("cloudKit", flags.cloudKitSharingEnabled),
            flagText("healthKit", flags.healthKitEnabled),
            flagText("homeKit", flags.homeKitEnabled),
            flagText("callKit", flags.callKitEnabled),
            flagText("carPlay", flags.carPlayEnabled),
        ]
        .joined(separator: " | ")
    }

    private func flagText(_ key: String, _ enabled: Bool) -> String {
        "\(key)=\(enabled ? "on" : "off")"
    }
}
