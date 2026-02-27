import Foundation

#if !canImport(Security)
public typealias OSStatus = Int32
public let errSecSuccess: OSStatus = 0
public let errSecDuplicateItem: OSStatus = -25299
public let errSecItemNotFound: OSStatus = -25300
#endif

#if !canImport(Combine)
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
