import Foundation
import SwiftUI

// MARK: - Shared View Model Protocol

/// Protocol for standardized MVVM pattern across all projects
@MainActor
protocol BaseViewModel: ObservableObject {
    associatedtype State
    associatedtype Action

    var state: State { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }

    func handle(_ action: Action)
    func resetError()
}

extension BaseViewModel {
    func resetError() {
        errorMessage = nil
    }

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func setError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - Shared Data Service Protocol

/// Protocol for standardized data services across projects
protocol DataService {
    associatedtype DataType

    func fetch() async throws -> [DataType]
    func save(_ item: DataType) async throws
    func delete(_ item: DataType) async throws
    func update(_ item: DataType) async throws
}

// MARK: - Common View States

enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var data: T? {
        if case let .loaded(data) = self { return data }
        return nil
    }

    var error: Error? {
        if case let .error(error) = self { return error }
        return nil
    }
}

// MARK: - Analytics Protocol

/// Shared analytics protocol for consistent tracking across projects
protocol AnalyticsTrackable {
    var eventName: String { get }
    var parameters: [String: Any] { get }
}

protocol AnalyticsService {
    func track<T: AnalyticsTrackable>(_ event: T)
    func setUserProperty(_ value: String, forName name: String)
    func incrementUserProperty(_ property: String, by value: Int)
}

// MARK: - Networking Protocol

/// Shared networking infrastructure
protocol NetworkService {
    func request<T: Codable>(_ endpoint: NetworkEndpoint) async throws -> T
    func upload<T: Codable>(_ data: Data, to endpoint: NetworkEndpoint) async throws -> T
}

struct NetworkEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryParameters: [String: String]

    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }
}

// MARK: - Error Handling

/// Standardized error types across projects
enum AppError: LocalizedError {
    case networkError(String)
    case dataError(String)
    case validationError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case let .networkError(message):
            return "Network Error: \(message)"
        case let .dataError(message):
            return "Data Error: \(message)"
        case let .validationError(message):
            return "Validation Error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Common UI Components Base Classes

/// Base for list view models
@MainActor
class BaseListViewModel<T>: ObservableObject {
    @Published var items: [T] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    var filteredItems: [T] {
        items // Override in subclasses for filtering logic
    }

    func loadItems() async {
        // Override in subclasses
    }

    func refresh() async {
        await loadItems()
    }
}

/// Base for form view models
@MainActor
class BaseFormViewModel<T>: ObservableObject {
    @Published var item: T
    @Published var isValid = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    init(item: T) {
        self.item = item
    }

    func validate() -> Bool {
        // Override in subclasses
        true
    }

    func save() async throws {
        // Override in subclasses
    }
}

// MARK: - Performance Monitoring

/// Shared performance monitoring
@MainActor
class PerformanceMonitor: ObservableObject {
    @Published var metrics: [PerformanceMetric] = []

    struct PerformanceMetric {
        let name: String
        let duration: TimeInterval
        let timestamp: Date
        let additionalInfo: [String: Any]
    }

    func measureAsync<T>(
        operation: String,
        task: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        let result = try await task()
        let duration = Date().timeIntervalSince(startTime)

        let metric = PerformanceMetric(
            name: operation,
            duration: duration,
            timestamp: startTime,
            additionalInfo: [:]
        )

        metrics.append(metric)
        return result
    }
}

// MARK: - Storage Protocol

/// Shared storage interface
protocol StorageService {
    func store<T: Codable>(_ object: T, key: String) throws
    func retrieve<T: Codable>(_ type: T.Type, key: String) throws -> T?
    func remove(key: String) throws
    func clear() throws
}

// MARK: - Validation Utilities

enum ValidationUtilities {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    static func isValidCurrency(_ amount: String) -> Bool {
        let currencyRegex = "^\\d{1,10}(\\.\\d{1,2})?$"
        let currencyPredicate = NSPredicate(format: "SELF MATCHES %@", currencyRegex)
        return currencyPredicate.evaluate(with: amount)
    }

    static func isNotEmpty(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Date Utilities

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }

    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
    }

    func isInSameWeek(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .weekOfYear)
    }

    func isInSameMonth(as date: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: date, toGranularity: .month)
    }
}

// MARK: - Currency Formatting

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    var percentageFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self * 100)%"
    }
}

// MARK: - Color Extensions

extension Color {
    static let primaryAccent = Color.blue
    static let secondaryAccent = Color.gray
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red

    // Platform-agnostic background colors
    static let backgroundPrimary = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let backgroundSecondary = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let textPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let textSecondary = Color(red: 0.42, green: 0.42, blue: 0.42)
}

// MARK: - Array Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - String Extensions

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValidEmail: Bool {
        ValidationUtilities.isValidEmail(self)
    }

    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }
}
