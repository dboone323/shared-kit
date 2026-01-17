#if canImport(CoreML) && canImport(NaturalLanguage)
    import Foundation
    import NaturalLanguage
    import CoreML

    /// A service that generates vector embeddings for text using Apple's On-Device Foundation Models (NaturalLanguage).
    @available(macOS 10.15, iOS 13.0, *)
    public final class CoreMLEmbeddingService: Sendable {

        public static let shared = CoreMLEmbeddingService()

        private init() {}

        /// Generates a vector embedding for the given text using the system's default sentence embedding model.
        /// - Parameter text: The input string to embed.
        /// - Returns: An array of Doubles representing the vector embedding.
        public func embed(_ text: String) async throws -> [Double] {
            return try await withCheckedThrowingContinuation { continuation in
                // Use the NLEmbedding for sentence embedding (available since macOS 10.15/iOS 13)
                // Note: In newer OS versions (macOS 14+), this uses the improved Transformer-based models automatically.
                guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
                    continuation.resume(throwing: EmbeddingError.modelUnavailable)
                    return
                }

                if let vector = embedding.vector(for: text) {
                    continuation.resume(returning: vector)
                } else {
                    continuation.resume(throwing: EmbeddingError.embeddingFailed)
                }
            }
        }

        /// Batch processes multiple strings for embedding.
        public func embedBatch(_ texts: [String]) async throws -> [[Double]] {
            var results: [[Double]] = []
            for text in texts {
                let vector = try await embed(text)
                results.append(vector)
            }
            return results
        }
    }

    public enum EmbeddingError: Error {
        case modelUnavailable
        case embeddingFailed
    }
#endif
