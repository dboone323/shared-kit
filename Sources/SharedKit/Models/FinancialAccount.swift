#if canImport(SwiftData)
import Foundation
import SharedKitCore
import SwiftData

@Model
public class FinancialAccount {
    public var id: UUID
    public var name: String
    public var balance: Double
    public var iconName: String
    public var accountType: AccountType
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FinancialTransaction.account)
    public var transactions: [FinancialTransaction]?

    public init(
        id: UUID = UUID(),
        name: String,
        balance: Double,
        iconName: String = "bank",
        accountType: AccountType = .checking,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.balance = balance
        self.iconName = iconName
        self.accountType = accountType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

#endif
