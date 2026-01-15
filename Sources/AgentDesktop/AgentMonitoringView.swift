import SwiftUI
import SharedKit

@available(macOS 14.0, *)
struct AgentMonitoringView: View {
    @State private var systemMetrics: SystemMetrics = SystemMetrics()
    @State private var toolStats: [ToolStat] = []
    @State private var recentActivity: [ActivityLog] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundStyle(.purple)
                Text("System Monitoring")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    Task { await refreshMetrics() }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // System Health
                    GroupBox("System Health") {
                        VStack(alignment: .leading, spacing: 12) {
                            MetricRow(
                                icon: "server.rack",
                                label: "Database",
                                value: systemMetrics.databaseStatus,
                                color: systemMetrics.databaseStatus == "Connected" ? .green : .red
                            )
                            MetricRow(
                                icon: "brain",
                                label: "LLM",
                                value: systemMetrics.llmStatus,
                                color: systemMetrics.llmStatus == "Ready" ? .green : .orange
                            )
                            MetricRow(
                                icon: "doc.text.magnifyingglass",
                                label: "Vector Store",
                                value: "\(systemMetrics.embeddingsCount) embeddings",
                                color: .blue
                            )
                        }
                    }
                    
                    // Tool Usage Stats
                    GroupBox("Tool Usage (Last 24h)") {
                        if toolStats.isEmpty {
                            Text("No tool executions yet")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(spacing: 8) {
                                ForEach(toolStats) { stat in
                                    HStack {
                                        Image(systemName: "wrench.and.screwdriver.fill")
                                            .foregroundStyle(.purple)
                                        Text(stat.toolName)
                                            .font(.body)
                                        Spacer()
                                        Text("\(stat.callCount) calls")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(Int(stat.successRate * 100))%")
                                            .font(.caption.bold())
                                            .foregroundStyle(stat.successRate > 0.8 ? .green : .orange)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Recent Activity
                    GroupBox("Recent Activity") {
                        if recentActivity.isEmpty {
                            Text("No recent activity")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(recentActivity.prefix(10)) { activity in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(activity.level.color)
                                            .frame(width: 6, height: 6)
                                        Text(activity.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(activity.message)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .task {
            await refreshMetrics()
        }
    }
    
    private func refreshMetrics() async {
        // Simulate fetching metrics
        // In production, query actual system state
        systemMetrics = SystemMetrics(
            databaseStatus: "Connected",
            llmStatus: "Ready",
            embeddingsCount: 42
        )
        
        toolStats = [
            ToolStat(toolName: "status", callCount: 15, successRate: 1.0),
            ToolStat(toolName: "logs", callCount: 8, successRate: 0.95),
            ToolStat(toolName: "deploy", callCount: 3, successRate: 0.67)
        ]
        
        recentActivity = [
            ActivityLog(level: .info, message: "Processed query: Check system status"),
            ActivityLog(level: .success, message: "Tool execution: status completed"),
            ActivityLog(level: .warning, message: "Retry attempt 2/3 for logs command"),
            ActivityLog(level: .info, message: "Learned new fact about API endpoint")
        ]
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }
}

struct SystemMetrics {
    var databaseStatus: String = "Unknown"
    var llmStatus: String = "Unknown"
    var embeddingsCount: Int = 0
}

struct ToolStat: Identifiable {
    let id = UUID()
    let toolName: String
    let callCount: Int
    let successRate: Double
}

struct ActivityLog: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let level: Level
    let message: String
    
    enum Level {
        case info, success, warning, error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
}
