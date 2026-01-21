// swift-tools-version: 5.9
import Foundation
import SharedKit

@main
struct RAGVerifier {
    static func main() async {
        print("🚀 Starting RAG Verification...")

        do {
            // 1. Initialize Components
            let store = PostgresVectorStore.shared
            try await store.connect()
            print("✅ DB Connected")

            let embeddingService = CoreMLEmbeddingService.shared

            // 2. Inject Knowledge (Simulating "Learning")
            let fact = "The health monitor agent is located at /app/agents/smart_agent_health_monitor.sh"
            print("🧠 Learning fact: \(fact)")
            let vector = try await embeddingService.embed(fact)
            try await store.save(content: fact, vector: vector)
            print("✅ Fact saved to Postgres Vector DB")

            // 3. Test Retrieval via Aggregator
            let agent = AggregatorAgent.shared
            // We ask a question that requires knowledge + tool use
            let query = "Run the health monitor check please."

            let response = try await agent.process(query: query)
            print("\n🤖 Final Response:\n\(response)")

            print("✅ Verification Complete")
            exit(0)
        } catch {
            print("❌ Error: \(String(reflecting: error))")
            exit(1)
        }
    }
}
