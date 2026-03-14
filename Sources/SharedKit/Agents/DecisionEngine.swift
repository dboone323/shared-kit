import Foundation
import SharedKitCore

/// A rule-based engine for making autonomous decisions in Swift 2026 apps.
public final class DecisionEngine: Sendable {
    public struct Rule: Sendable {
        public let name: String
        public let condition: String
        public let action: String
        public let params: [String: AnyCodable]?

        public init(
            name: String, condition: String, action: String, params: [String: AnyCodable]? = nil
        ) {
            self.name = name
            self.condition = condition
            self.action = action
            self.params = params
        }
    }

    public struct ProposedAction: Identifiable, Sendable {
        public let id = UUID()
        public let action: String
        public let reason: String
        public let params: [String: AnyCodable]?
    }

    private let rules: [Rule]
    private let ollamaClient: OllamaClient?

    public init(rules: [Rule], ollamaClient: OllamaClient? = nil) {
        self.rules = rules
        self.ollamaClient = ollamaClient
    }

    /// Evaluate current state against rules and return proposed actions.
    /// Uses LLM for complex conditions if available.
    public func evaluate(metrics: [String: Any]) async -> [ProposedAction] {
        var actions: [ProposedAction] = []

        for rule in rules {
            let isSatisfied = await evaluateCondition(rule.condition, metrics: metrics)
            if isSatisfied {
                actions.append(
                    ProposedAction(
                        action: rule.action,
                        reason: "Condition '\(rule.condition)' satisfied",
                        params: rule.params
                    )
                )
            }
        }

        return actions
    }

    private func evaluateCondition(_ condition: String, metrics: [String: Any]) async -> Bool {
        // First try simple symbolic evaluation
        if let result = evaluateSimpleCondition(condition, metrics: metrics) {
            return result
        }

        // Fallback to LLM if symbolic evaluation fails and client is available
        guard let client = ollamaClient else { return false }

        let context = metrics.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let prompt = """
        Evaluate the following condition based on the provided metrics.
        Metrics: \(context)
        Condition: \(condition)

        Return ONLY 'TRUE' or 'FALSE'.
        """

        do {
            let response = try await client.generate(
                model: nil,
                prompt: prompt,
                temperature: 0.0,
                maxTokens: 10
            )
            return response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().contains("TRUE")
        } catch {
            return false
        }
    }

    private func evaluateSimpleCondition(_ condition: String, metrics: [String: Any]) -> Bool? {
        // Supported format: "metric_name > value" or "metric_name == true"
        let parts = condition.components(separatedBy: " ")
        if parts.count == 1 {
            if let metricValue = metrics[condition] as? Bool {
                return metricValue
            }
            return nil // Needs LLM or unknown
        }

        if parts.count == 3 {
            let metricName = parts[0]
            let `operator` = parts[1]
            let valueString = parts[2]

            guard let metricValue = metrics[metricName] else { return nil }

            switch `operator` {
            case ">":
                if let mValue = metricValue as? Double, let cValue = Double(valueString) {
                    return mValue > cValue
                }
                if let mValue = metricValue as? Int, let cValue = Int(valueString) {
                    return mValue > cValue
                }
            case "<":
                if let mValue = metricValue as? Double, let cValue = Double(valueString) {
                    return mValue < cValue
                }
                if let mValue = metricValue as? Int, let cValue = Int(valueString) {
                    return mValue < cValue
                }
            case "==":
                if let mValue = metricValue as? String {
                    return mValue == valueString
                }
                if let mValue = metricValue as? Bool {
                    return mValue == (valueString.lowercased() == "true")
                }
                if let mValue = metricValue as? Double, let cValue = Double(valueString) {
                    return mValue == cValue
                }
                if let mValue = metricValue as? Int, let cValue = Int(valueString) {
                    return mValue == cValue
                }
            default:
                break
            }
        }

        return nil // Fallback to LLM
    }
}
