import Foundation

#if canImport(Combine)
@_exported import Combine
#else
/// Minimal compatibility shims for Combine features used in the project.
/// This file provides no-op implementations of ObservableObject and @Published
/// when Combine is not available (e.g., on Linux with standard toolchains).

public protocol ObservableObject: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

public extension ObservableObject {
    var objectWillChange: ObservableObjectPublisher {
        ObservableObjectPublisher()
    }
}

public struct ObservableObjectPublisher {
    public init() {}
    public func send() {}
}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public var projectedValue: Published<Value> {
        self
    }
}
#endif
