import Foundation
import SwiftUI

// MARK: - Shared View Model Protocol

/// Protocol for standardized MVVM pattern across all projects
/// Supports both ObservableObject and @Observable patterns for maximum compatibility
@MainActor
public protocol BaseViewModel: AnyObject {
    associatedtype State
    associatedtype Action

    var state: State { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }

    func handle(_ action: Action) async
    func resetError()
    func validateState() -> Bool
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

    func setError(_ message: String) {
        errorMessage = message
    }

    func validateState() -> Bool {
        // Default implementation - override in subclasses for specific validation
        true
    }

    /// Convenience method for synchronous actions
    func handle(_ action: Action) {
        Task {
            await handle(action)
        }
    }
}

// MARK: - ObservableObject Extension for BaseViewModel

// Removed problematic extension - state changes should trigger naturally through @Published properties

// MARK: - Enhanced Base View Model Classes

/// Base class for list view models with standardized functionality
@MainActor
class BaseListViewModel<StateType, ActionType>: ObservableObject {
    typealias State = StateType
    typealias Action = ActionType

    @Published var state: State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    init(initialState: State) {
        self.state = initialState
    }

    func handle(_ action: Action) async {
        // Override in subclasses
        fatalError("Subclasses must implement handle(_:)")
    }

    func loadData() async {
        // Override in subclasses
    }

    func refresh() async {
        await loadData()
    }

    func search(query: String) async {
        searchText = query
        // Override in subclasses for custom search logic
    }

    var filteredItems: [Any] {
        // Override in subclasses
        []
    }
}

/// Base class for form view models with validation
@MainActor
class BaseFormViewModel<StateType, ActionType>: ObservableObject {
    typealias State = StateType
    typealias Action = ActionType

    @Published var state: State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isValid = false

    init(initialState: State) {
        self.state = initialState
        validate()
    }

    func handle(_ action: Action) async {
        // Override in subclasses
        fatalError("Subclasses must implement handle(_:)")
    }

    func validate() {
        isValid = validateState()
    }

    func validateState() -> Bool {
        // Override in subclasses
        true
    }

    func save() async throws {
        // Override in subclasses
        fatalError("Subclasses must implement save()")
    }

    func reset() {
        // Override in subclasses to reset form state
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

        self.metrics.append(metric)
        return result
    }
}

// MARK: - Storage Protocol

/// Shared storage interface
protocol StorageService {
    func store(_ object: some Codable, key: String) throws
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
        Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay)?.addingTimeInterval(-1)
            ?? self
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
            Array(self[$0..<Swift.min($0 + size, count)])
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

    /// Converts a color string to SwiftUI Color with fallback
    var toColor: Color {
        switch self.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "gray", "grey": return .gray
        case "black": return .black
        case "white": return .white
        case "primary": return .primary
        case "secondary": return .secondary
        case "accent": return .accentColor
        default: return .blue  // Default fallback color
        }
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialize a Color from a hex string
    /// - Parameter hex: Hex color string (with or without # prefix)
    /// - Returns: Color instance from hex value
    ///
    /// Supports:
    /// - RGB (12-bit): "FFF"
    /// - RGB (24-bit): "FFFFFF"
    /// - ARGB (32-bit): "FFFFFFFF"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Create gradient colors for modern effects
    static func gradient(from startColor: Color, to endColor: Color) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Glass morphism effect
    var glassMorphism: some View {
        opacity(0.7)
            .background(.ultraThinMaterial)
    }
}

// MARK: - View Extensions

extension View {
    /// Platform-specific optimizations for iOS
    @ViewBuilder
    func platformOptimizations() -> some View {
        #if os(iOS)
            self.tint(.blue)
        #elseif os(macOS)
            self.preferredColorScheme(.light)
                .tint(.indigo)
        #else
            self
        #endif
    }

    /// Apply glass morphism effect
    func glassMorphismEffect() -> some View {
        self.opacity(0.7)
            .background(.ultraThinMaterial)
    }

    /// Conditional modifier application
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
