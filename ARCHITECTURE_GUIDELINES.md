# Swift Architecture Guidelines
## Best Practices for iOS/macOS Development in tools-automation

This document outlines the architectural patterns and best practices for Swift development in the tools-automation submodules (CodingReviewer, HabitQuest, MomentumFinance, PlannerApp, AvoidObstaclesGame).

---

## 1. Architecture Pattern: MVVM

We standardize on **Model-View-ViewModel (MVVM)** for all SwiftUI projects.

### ViewModelType Protocol

```swift
/// Standard protocol for all ViewModels
protocol ViewModelType: ObservableObject {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
```

### Example Implementation

```swift
final class TransactionViewModel: ViewModelType {
    struct Input {
        let refresh: AnyPublisher<Void, Never>
        let searchText: AnyPublisher<String, Never>
    }
    
    struct Output {
        let transactions: AnyPublisher<[Transaction], Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<Error?, Never>
    }
    
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func transform(input: Input) -> Output {
        // Implementation
    }
}
```

---

## 2. Dependency Injection

Use a simple DI container for testability.

```swift
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    private var factories: [String: () -> Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[String(describing: type)] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        guard let factory = factories[String(describing: type)] else {
            fatalError("No registration for \(type)")
        }
        return factory() as! T
    }
}
```

---

## 3. Memory Management

### Weak Self in Closures

Always use `[weak self]` in async closures to prevent retain cycles:

```swift
// ✅ Correct
networkService.fetch { [weak self] result in
    guard let self = self else { return }
    self.handleResult(result)
}

// ❌ Incorrect - potential retain cycle
networkService.fetch { result in
    self.handleResult(result)
}
```

### Combine Subscriptions

Use a subscription manager:

```swift
class SubscriptionBag {
    private var cancellables = Set<AnyCancellable>()
    
    func store(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }
    
    func cancel() {
        cancellables.removeAll()
    }
}
```

---

## 4. Error Handling

### Result Type

Use `Result` for explicit error handling:

```swift
func fetchData() async -> Result<Data, NetworkError> {
    do {
        let data = try await networkService.fetch()
        return .success(data)
    } catch {
        return .failure(.networkError(error))
    }
}
```

### Error Protocol

Define domain-specific errors:

```swift
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingFailed: return "Failed to decode response"
        case .serverError(let code): return "Server error: \(code)"
        }
    }
}
```

---

## 5. Testing Guidelines

### XCTest Structure

```swift
final class ViewModelTests: XCTestCase {
    var sut: MyViewModel!
    var mockService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockService = MockNetworkService()
        sut = MyViewModel(service: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    func test_whenFetchCalled_thenDataLoaded() async {
        // Arrange
        mockService.stubbedResult = .success(testData)
        
        // Act
        await sut.fetch()
        
        // Assert
        XCTAssertEqual(sut.items.count, 3)
    }
}
```

---

## 6. Code Style

We use SwiftLint and SwiftFormat. Key rules:

- **Line length**: 120 characters max
- **Indentation**: 4 spaces
- **Trailing commas**: Required in multiline arrays/dicts
- **Self**: Only required when necessary
- **Access control**: Explicit for public API

---

## 7. File Organization

```
Feature/
├── Models/
│   └── FeatureModel.swift
├── Views/
│   ├── FeatureView.swift
│   └── Components/
│       └── FeatureRow.swift
├── ViewModels/
│   └── FeatureViewModel.swift
└── Services/
    └── FeatureService.swift
```

---

## 8. SwiftUI Best Practices

### State Management

```swift
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        // Use viewModel
    }
}
```

### Preview Providers

```swift
#Preview {
    ContentView()
        .environmentObject(MockDependencies())
}
```

---

*Last updated: 2024-12-21*
