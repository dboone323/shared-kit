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

    public init(rules: [Rule]) {
        self.rules = rules
    }

    /// Evaluate current state against rules and return proposed actions
    public func evaluate(metrics: [String: Any]) -> [ProposedAction] {
        var actions: [ProposedAction] = []

        for rule in rules where evaluateCondition(rule.condition, metrics: metrics) {
            actions.append(
                ProposedAction(
                    action: rule.action,
                    reason: "Rule '\(rule.name)' satisfied",
                    params: rule.params
                )
            )
        }

        return actions
    }

    private func evaluateCondition(_ condition: String, metrics: [String: Any]) -> Bool {
        // Supported format: "metric_name > value" or "metric_name == true"
        let parts = condition.components(separatedBy: " ")
        if parts.count == 1 {
            if let metricValue = metrics[condition] as? Bool {
                return metricValue
            }
            return false
        }

        if parts.count == 3 {
            let metricName = parts[0]
            let `operator` = parts[1]
            let valueString = parts[2]

            guard let metricValue = metrics[metricName] else { return false }

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

        return false
    }
}
