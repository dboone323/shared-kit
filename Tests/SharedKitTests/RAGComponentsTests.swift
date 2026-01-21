@testable import SharedKit
import XCTest

@available(macOS 12.0, *)
final class CoreMLEmbeddingServiceTests: XCTestCase {
    var embeddingService: CoreMLEmbeddingService!
    
    override func setUp() async throws {
        embeddingService = CoreMLEmbeddingService.shared
    }
    
    // MARK: - Basic Embedding Tests
    
    func testEmbedReturnsNonEmptyVector() async throws {
        let text = "Hello, this is a test sentence."
        let vector = try await embeddingService.embed(text)
        
        XCTAssertFalse(vector.isEmpty, "Embedding vector should not be empty")
        XCTAssertEqual(vector.count, 512, "Expected 512-dimensional vector from NLEmbedding")
    }
    
    func testEmbedDifferentTextsProduceDifferentVectors() async throws {
        let text1 = "The quick brown fox jumps over the lazy dog."
        let text2 = "Machine learning is transforming software development."
        
        let vector1 = try await embeddingService.embed(text1)
        let vector2 = try await embeddingService.embed(text2)
        
        XCTAssertNotEqual(vector1, vector2, "Different texts should produce different embeddings")
    }
    
    func testEmbedSimilarTextsProduceSimilarVectors() async throws {
        let text1 = "Docker containers are great for deployment."
        let text2 = "Docker containers are excellent for deploying applications."
        
        let vector1 = try await embeddingService.embed(text1)
        let vector2 = try await embeddingService.embed(text2)
        
        // Calculate cosine similarity
        let similarity = cosineSimilarity(vector1, vector2)
        XCTAssertGreaterThan(similarity, 0.7, "Similar texts should have high cosine similarity")
    }
    
    func testEmbedEmptyStringProducesVector() async throws {
        let text = ""
        let vector = try await embeddingService.embed(text)
        
        // Should still return a vector (may be zeros or default)
        XCTAssertEqual(vector.count, 512, "Even empty string should produce 512-d vector")
    }
    
    func testEmbedLongTextProducesVector() async throws {
        let longText = String(repeating: "This is a test sentence. ", count: 100)
        let vector = try await embeddingService.embed(longText)
        
        XCTAssertEqual(vector.count, 512, "Long text should produce 512-d vector")
        XCTAssertFalse(vector.allSatisfy { $0 == 0 }, "Vector should not be all zeros")
    }
    
    // MARK: - Helper Functions
    
    private func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        
        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }
}

// MARK: - Conversation Message Tests

final class ConversationMessageTests: XCTestCase {
    func testConversationMessageCreation() {
        let message = ConversationMessage(role: "user", content: "Hello")
        
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Hello")
        XCTAssertNotNil(message.timestamp)
    }
    
    func testConversationMessageTimestampIsRecent() {
        let before = Date()
        let message = ConversationMessage(role: "assistant", content: "Hi there!")
        let after = Date()
        
        XCTAssertGreaterThanOrEqual(message.timestamp, before)
        XCTAssertLessThanOrEqual(message.timestamp, after)
    }
}

// MARK: - AggregatorAgent Tests (Mocked)

@available(macOS 12.0, *)
@MainActor
final class AggregatorAgentTests: XCTestCase {
    func testAgentSingletonExists() {
        let agent1 = AggregatorAgent.shared
        let agent2 = AggregatorAgent.shared
        
        XCTAssertTrue(agent1 === agent2, "AggregatorAgent should be a singleton")
    }
    
    func testClearHistoryEmptiesConversation() {
        let agent = AggregatorAgent.shared
        agent.clearHistory()
        
        XCTAssertTrue(agent.conversationHistory.isEmpty, "History should be empty after clear")
    }
}
