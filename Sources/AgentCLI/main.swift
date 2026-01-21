import Foundation
import SharedKit

/// A simple CLI interface to interact with the AggregatorAgent.
@available(macOS 12.0, *)
@main
struct AgentCLI {
    static func main() async {
        print("""
        ╔═══════════════════════════════════════════════════════════════╗
        ║              🤖 Agent Intelligence CLI v1.0                  ║
        ║    Powered by RAG + Local LLM (qwen2.5-coder) + Docker       ║
        ╚═══════════════════════════════════════════════════════════════╝

        Try commands like:
         • "Check the system status"
         • "Show me the logs"
         • "What's running?"
         • "Fix any issues"
         • "Start the core services"

        Type 'exit' or 'quit' to leave.
        """)

        let agent = AggregatorAgent.shared

        while true {
            print("\n💬 You: ", terminator: "")
            guard let input = readLine(), !input.isEmpty else {
                continue
            }

            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmed == "exit" || trimmed == "quit" || trimmed == "q" {
                print("\n👋 Goodbye!")
                break
            }

            do {
                print("\n⏳ Processing...\n")
                let response = try await agent.process(query: input)
                print("\n🤖 Agent Response:\n")
                print("───────────────────────────────────────────────────────────────")
                print(response)
                print("───────────────────────────────────────────────────────────────")
            } catch {
                print("\n❌ Error: \(error.localizedDescription)")
            }
        }
    }
}
