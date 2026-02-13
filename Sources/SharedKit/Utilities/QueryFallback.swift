import Foundation

// Global fallback for @Query so sources compile when SwiftData's attribute macros
// aren't available or recognized by the toolchain. This intentionally provides a
// simple in-memory wrapper that preserves the expected source-level API.

@propertyWrapper
public struct Query<Value> {
    private var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get { self.value }
        set { self.value = newValue }
    }

    public var projectedValue: Query<Value> { self }
}
