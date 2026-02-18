import Combine
import Foundation

@available(iOS 13.0, macOS 10.15, *)
@MainActor
public class AICoordinator {
    public static let shared = AICoordinator()

    @Published public var availableFeatures: Set<AIFeature> = []

    private init() {}
}

public enum AIFeature: String, Hashable, Codable, Sendable {
    case predictiveText
    case smartScheduling
    case automatedReview
    case codeAnalysis
}
