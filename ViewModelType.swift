import Foundation
import Combine

// MARK: - ViewModelType Protocol
// =============================================================================
// Standard protocol for all ViewModels in tools-automation submodules
// Provides consistent input/output transformation pattern
// =============================================================================

/// Protocol defining the standard ViewModel pattern.
/// Conforming types should define Input and Output types
/// and implement the transform function.
protocol ViewModelType: ObservableObject {
    associatedtype Input
    associatedtype Output
    
    /// Transform input events into output state
    func transform(input: Input) -> Output
}

// MARK: - Base ViewModel
// =============================================================================

/// Base class providing common ViewModel functionality
class BaseViewModel<I, O>: ViewModelType {
    typealias Input = I
    typealias Output = O
    
    /// Subscription storage
    var cancellables = Set<AnyCancellable>()
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error state
    @Published var error: Error?
    
    /// Override in subclasses
    func transform(input: I) -> O {
        fatalError("Subclasses must override transform(input:)")
    }
    
    /// Convenience for handling async operations
    func performAsync<T>(
        _ operation: @escaping () async throws -> T,
        onSuccess: @escaping (T) -> Void,
        onError: ((Error) -> Void)? = nil
    ) {
        isLoading = true
        error = nil
        
        Task { @MainActor [weak self] in
            do {
                let result = try await operation()
                self?.isLoading = false
                onSuccess(result)
            } catch {
                self?.isLoading = false
                self?.error = error
                onError?(error)
            }
        }
    }
}

// MARK: - Example Usage
// =============================================================================

/*
Example ViewModel implementation:

final class TransactionViewModel: BaseViewModel<TransactionViewModel.Input, TransactionViewModel.Output> {
    
    struct Input {
        let refresh: AnyPublisher<Void, Never>
        let searchText: AnyPublisher<String, Never>
    }
    
    struct Output {
        let transactions: AnyPublisher<[Transaction], Never>
        let isLoading: AnyPublisher<Bool, Never>
    }
    
    @Published private(set) var transactions: [Transaction] = []
    
    private let service: TransactionServiceProtocol
    
    init(service: TransactionServiceProtocol = TransactionService()) {
        self.service = service
        super.init()
    }
    
    override func transform(input: Input) -> Output {
        // Handle refresh
        input.refresh
            .sink { [weak self] in
                self?.fetchTransactions()
            }
            .store(in: &cancellables)
        
        // Handle search
        input.searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.filterTransactions(text)
            }
            .store(in: &cancellables)
        
        return Output(
            transactions: $transactions.eraseToAnyPublisher(),
            isLoading: $isLoading.eraseToAnyPublisher()
        )
    }
    
    private func fetchTransactions() {
        performAsync(
            { try await self.service.fetchAll() },
            onSuccess: { [weak self] in self?.transactions = $0 }
        )
    }
}
*/

// MARK: - Observable State Wrapper
// =============================================================================

/// Property wrapper for observable state in ViewModels
@propertyWrapper
struct ViewState<Value> {
    private var value: Value
    private let subject = CurrentValueSubject<Value, Never>
    
    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            subject.send(newValue)
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
        self.subject = CurrentValueSubject(wrappedValue)
    }
}

// MARK: - Dependency Injection
// =============================================================================

/// Simple dependency container for ViewModel dependencies
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    /// Register a dependency factory
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[String(describing: type)] = factory
    }
    
    /// Resolve a dependency
    func resolve<T>(_ type: T.Type) -> T {
        guard let factory = factories[String(describing: type)] else {
            fatalError("No registration found for type: \(type)")
        }
        guard let instance = factory() as? T else {
            fatalError("Factory returned wrong type for: \(type)")
        }
        return instance
    }
    
    /// Check if type is registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        factories[String(describing: type)] != nil
    }
}

/// Property wrapper for dependency injection
@propertyWrapper
struct Injected<T> {
    private var dependency: T?
    
    var wrappedValue: T {
        mutating get {
            if dependency == nil {
                dependency = DependencyContainer.shared.resolve(T.self)
            }
            return dependency!
        }
    }
    
    init() {}
}
