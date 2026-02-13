import Foundation
import SwiftData

@Model
public class FinancialTransaction {
    public var id: String
    public var name: String
    public var amount: Double
    public var date: Date
    public var isReconciled: Bool
    public var notes: String
    public var isRecurring: Bool

    @Relationship
    public var category: ExpenseCategory?

    @Relationship
    public var account: FinancialAccount?

    public init(
        name: String, amount: Double, date: Date, isReconciled: Bool = false, notes: String = "",
        isRecurring: Bool = false
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.amount = amount
        self.date = date
        self.isReconciled = isReconciled
        self.notes = notes
        self.isRecurring = isRecurring
    }
}
