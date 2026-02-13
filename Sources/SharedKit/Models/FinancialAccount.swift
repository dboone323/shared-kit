import Foundation
import SwiftData

@Model
public class FinancialAccount {
    public var name: String
    public var balance: Double
    public var iconName: String
    // accountType might be an enum, assume String for now or simple enum if likely reused
    // run_tests.swift used enum AccountType. Let's make it simple for now or usage in details view "Text(transaction.account?.name ...)" implies name is key.

    @Relationship(deleteRule: .cascade, inverse: \FinancialTransaction.account)
    public var transactions: [FinancialTransaction]?

    public init(name: String, balance: Double, iconName: String = "bank") {
        self.name = name
        self.balance = balance
        self.iconName = iconName
    }
}
