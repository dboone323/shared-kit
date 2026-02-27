#if canImport(SwiftData)
import Foundation
import SwiftData

@Model
public class ExpenseCategory {
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var budgetAmount: Double

    @Relationship(deleteRule: .cascade, inverse: \FinancialTransaction.category)
    public var transactions: [FinancialTransaction]?

    public init(name: String, iconName: String, colorHex: String, budgetAmount: Double) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.budgetAmount = budgetAmount
    }
}

#endif
