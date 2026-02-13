import Foundation

// MARK: - Financial Utilities

/// Format currency amount with optional currency code
public func formatCurrency(_ amount: Double, code: String? = nil) -> String {
    let currencyCode = code ?? Locale.current.currency?.identifier ?? "USD"
    return amount.formatted(.currency(code: currencyCode))
}

/// Format date in short format
public func formatDateShort(_ date: Date) -> String {
    date.formatted(date: .abbreviated, time: .omitted)
}

/// Format month in abbreviated format
public func formatMonthAbbrev(_ date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated))
}
