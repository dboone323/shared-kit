import SharedKit
import SwiftUI

@available(macOS 14.0, *)
@main
struct AgentDesktopApp: App {
    @StateObject private var viewModel = AgentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 600)

        // Menu bar extra
        MenuBarExtra("Agent", systemImage: "brain.head.profile") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

@available(macOS 14.0, *)
@MainActor
class AgentViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var statusMessage: String = "Ready"

    private var agent: AggregatorAgent {
        AggregatorAgent.shared
    }

    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = inputText
        inputText = ""

        messages.append(ChatMessage(role: .user, content: userMessage))
        isProcessing = true
        statusMessage = "Thinking..."

        do {
            let response = try await agent.process(query: userMessage)
            messages.append(ChatMessage(role: .assistant, content: response))
            statusMessage = "Ready"
        } catch {
            messages.append(ChatMessage(role: .error, content: "Error: \(error.localizedDescription)"))
            statusMessage = "Error occurred"
        }

        isProcessing = false
    }

    func clearChat() {
        messages = []
        agent.clearHistory()
    }

    func learnFact(_ fact: String) async {
        do {
            try await agent.learn(fact: fact)
            statusMessage = "Learned new fact!"
        } catch {
            statusMessage = "Failed to learn: \(error.localizedDescription)"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()

    enum Role {
        case user
        case assistant
        case error
    }
}

@available(macOS 14.0, *)
struct ContentView: View {
    @EnvironmentObject var viewModel: AgentViewModel
    @State private var learnText: String = ""
    @State private var showLearnSheet: Bool = false
    @State private var showExportSheet: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundStyle(.purple)
                Text("Agent Intelligence")
                    .font(.headline)
                Spacer()

                Button(action: { exportConversation() }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .help("Export conversation")
                .keyboardShortcut("e", modifiers: .command)

                Button(action: { showLearnSheet.toggle() }) {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .help("Teach the agent a new fact (⌘N)")
                .keyboardShortcut("n", modifiers: .command)

                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .help("Clear chat (⌘⌫)")
                .keyboardShortcut(.delete, modifiers: .command)
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundStyle(.purple.opacity(0.3))
                            Text("Ask me anything about your Docker system")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Try these:")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                ForEach(["Check system status", "Show logs", "What's running?"],
                                        id: \.self)
                                { example in
                                    Button(action: {
                                        viewModel.inputText = example
                                        Task { await viewModel.sendMessage() }
                                    }) {
                                        Text("• \(example)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            HStack {
                TextField("Ask the agent...", text: $viewModel.inputText)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(.textBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .onSubmit {
                        Task { await viewModel.sendMessage() }
                    }
                    .disabled(viewModel.isProcessing)

                Button(action: {
                    Task { await viewModel.sendMessage() }
                }) {
                    Image(systemName: viewModel.isProcessing ? "hourglass" : "paperplane.fill")
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing || viewModel.inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
            .background(.ultraThinMaterial)

            // Status bar
            HStack {
                Circle()
                    .fill(viewModel.isProcessing ? .orange : .green)
                    .frame(width: 8, height: 8)
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.messages.count) messages")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(Color(.windowBackgroundColor))
        }
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showLearnSheet) {
            LearnFactSheet(learnText: $learnText) { fact in
                Task { await viewModel.learnFact(fact) }
            }
        }
        .alert("Export Conversation", isPresented: $showExportSheet) {
            Button("OK") {}
        } message: {
            Text("Conversation exported to clipboard!")
        }
    }

    private func exportConversation() {
        let text = viewModel.messages.map { message in
            let role = message.role == .user ? "You" : "Agent"
            let timestamp = message.timestamp.formatted(date: .abbreviated, time: .shortened)
            return "[\(timestamp)] \(role): \(message.content)"
        }.joined(separator: "\n\n")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        viewModel.statusMessage = "Exported \(viewModel.messages.count) messages"
        showExportSheet = true
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding(10)
                    .background(backgroundColor)
                    .foregroundStyle(foregroundColor)
                    .cornerRadius(12)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if message.role != .user { Spacer() }
        }
    }

    var backgroundColor: Color {
        switch message.role {
        case .user: return .purple
        case .assistant: return Color(.controlBackgroundColor)
        case .error: return .red.opacity(0.2)
        }
    }

    var foregroundColor: Color {
        switch message.role {
        case .user: return .white
        case .assistant, .error: return .primary
        }
    }
}

struct LearnFactSheet: View {
    @Binding var learnText: String
    @Environment(\.dismiss) var dismiss
    let onLearn: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Teach the Agent")
                .font(.headline)

            Text("Enter a fact for the agent to remember:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: $learnText)
                .frame(height: 100)
                .border(Color.gray.opacity(0.3))

            HStack {
                Button("Cancel") { dismiss() }
                Button("Learn") {
                    onLearn(learnText)
                    learnText = ""
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(learnText.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
    }
}

@available(macOS 14.0, *)
struct MenuBarView: View {
    @EnvironmentObject var viewModel: AgentViewModel
    @State private var quickInput: String = ""
    @State private var showQuickActions: Bool = false
    @State private var recentQueries: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(statusColor)
                Text("Agent Intelligence")
                    .font(.headline)
                Spacer()
                StatusIndicator(status: viewModel.statusMessage, isProcessing: viewModel.isProcessing)
            }

            Divider()

            // Quick query with suggestions
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Quick query...", text: $quickInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            Task {
                                addToRecentQueries(quickInput)
                                viewModel.inputText = quickInput
                                await viewModel.sendMessage()
                                quickInput = ""
                            }
                        }
                    Button(action: { showQuickActions.toggle() }) {
                        Image(systemName: "list.bullet")
                    }
                    .buttonStyle(.borderless)
                    .help("Quick Actions")
                }

                // Recent queries
                if !recentQueries.isEmpty && quickInput.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recent:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(recentQueries.prefix(3), id: \.self) { query in
                            Button(action: {
                                quickInput = query
                            }) {
                                Text("• \(query)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Quick Actions Panel
            if showQuickActions {
                QuickActionsPanel(viewModel: viewModel)
            }

            // Latest response preview
            if let lastResponse = viewModel.messages.last(where: { $0.role == .assistant }) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Latest Response")
                                .font(.caption.bold())
                            Spacer()
                            Text(lastResponse.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(lastResponse.content.prefix(150))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }

            Divider()

            // System health summary
            HStack(spacing: 12) {
                HealthBadge(label: "DB", status: .healthy)
                HealthBadge(label: "LLM", status: .healthy)
                HealthBadge(label: "Tools", status: .healthy)
            }
            .font(.caption2)

            Divider()

            Button("Open Full App") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderedProminent)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(width: 320)
    }

    private var statusColor: Color {
        if viewModel.isProcessing {
            return .orange
        }
        return .green
    }

    private func addToRecentQueries(_ query: String) {
        guard !query.isEmpty else { return }
        if let index = recentQueries.firstIndex(of: query) {
            recentQueries.remove(at: index)
        }
        recentQueries.insert(query, at: 0)
        if recentQueries.count > 5 {
            recentQueries.removeLast()
        }
    }
}

struct StatusIndicator: View {
    let status: String
    let isProcessing: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isProcessing ? .orange : .green)
                .frame(width: 6, height: 6)
            Text(status)
                .font(.caption2)
        }
    }
}

struct HealthBadge: View {
    let label: String
    let status: HealthStatus

    enum HealthStatus {
        case healthy, warning, error
        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(status.color)
                .frame(width: 4, height: 4)
            Text(label)
        }
    }
}

struct QuickActionsPanel: View {
    @ObservedObject var viewModel: AgentViewModel

    let actions = [
        ("Status Check", "arrow.clockwise", "Check the system status"),
        ("View Logs", "doc.text", "Show me the logs"),
        ("Deploy", "arrow.up.circle", "Deploy core services"),
        ("Backup", "externaldrive", "Create a database backup"),
    ]

    var body: some View {
        GroupBox("Quick Actions") {
            VStack(spacing: 6) {
                ForEach(actions, id: \.0) { action in
                    Button(action: {
                        viewModel.inputText = action.2
                        Task { await viewModel.sendMessage() }
                    }) {
                        HStack {
                            Image(systemName: action.1)
                                .frame(width: 16)
                            Text(action.0)
                                .font(.caption)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
