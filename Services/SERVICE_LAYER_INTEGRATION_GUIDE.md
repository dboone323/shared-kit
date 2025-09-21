# Service Layer Architecture Integration Guide

## Overview
This guide provides comprehensive instructions for integrating the new Service Layer Architecture across all projects in the Quantum workspace. The service layer implements dependency injection, protocol-based architecture, and centralized business logic management.

## Architecture Components

### Core Service Layer Files

#### 1. ServiceProtocols.swift
**Location**: `/Shared/Services/ServiceProtocols.swift`
**Purpose**: Defines all service protocols and supporting models
**Key Components**:
- `ServiceProtocol` - Base protocol for all services
- `DataServiceProtocol` - Generic CRUD operations
- `AnalyticsServiceProtocol` - Analytics and tracking
- `HabitServiceProtocol` - Habit-specific business logic
- `FinancialServiceProtocol` - Financial business logic
- `PlannerServiceProtocol` - Task/goal management
- `CrossProjectServiceProtocol` - Inter-project integration

#### 2. DependencyContainer.swift
**Location**: `/Shared/Services/DependencyContainer.swift`
**Purpose**: Dependency injection container and service management
**Key Components**:
- `DependencyContainer` - Main DI container
- `@Injected` property wrapper - Automatic dependency injection
- `ServiceManager` - Service lifecycle management
- Default service implementations

## Service Architecture Patterns

### Dependency Injection
The service layer uses a comprehensive dependency injection system:

```swift
// Register services
DependencyContainer.shared.register(MyHabitService(), for: HabitServiceProtocol.self)

// Use @Injected property wrapper
class HabitViewController {
    @Injected private var habitService: HabitServiceProtocol
    
    func createHabit() {
        // Service automatically injected
        habitService.createHabit(...)
    }
}
```

### Protocol-Based Architecture
All business logic is defined through protocols:

```swift
// Define business logic protocols
protocol HabitServiceProtocol: ServiceProtocol {
    func createHabit(_ habit: EnhancedHabit) async throws -> EnhancedHabit
    func logHabitCompletion(...) async throws -> EnhancedHabitLog
}

// Implement concrete services
class ProductionHabitService: HabitServiceProtocol {
    // Implementation with real business logic
}

class MockHabitService: HabitServiceProtocol {
    // Mock implementation for testing
}
```

## Service Implementation Guide

### 1. Creating Custom Services

#### Step 1: Define Service Protocol
```swift
protocol MyBusinessServiceProtocol: ServiceProtocol {
    func performBusinessLogic() async throws -> Result
}
```

#### Step 2: Implement Service
```swift
final class MyBusinessService: MyBusinessServiceProtocol {
    let serviceId = "my_business_service"
    let version = "1.0.0"
    
    func initialize() async throws {
        // Setup resources
    }
    
    func cleanup() async {
        // Cleanup resources
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        // Return health status
        return .healthy
    }
    
    func performBusinessLogic() async throws -> Result {
        // Business logic implementation
    }
}
```

#### Step 3: Register Service
```swift
// Register in dependency container
DependencyContainer.shared.register(
    MyBusinessService(), 
    for: MyBusinessServiceProtocol.self
)
```

### 2. Using Services in Applications

#### Option 1: Property Wrapper (Recommended)
```swift
class MyViewController: UIViewController {
    @Injected private var habitService: HabitServiceProtocol
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Services are automatically available
        Task {
            await analyticsService.track(event: "screen_view", properties: nil, userId: nil)
        }
    }
}
```

#### Option 2: Service Locator
```swift
class MyManager {
    private let habitService: HabitServiceProtocol
    
    init() throws {
        self.habitService = try ServiceLocator.get(HabitServiceProtocol.self)
    }
}
```

#### Option 3: Direct Resolution
```swift
class MyComponent {
    func performAction() async {
        guard let service = DependencyContainer.shared.resolve(HabitServiceProtocol.self) else {
            return
        }
        // Use service
    }
}
```

## Project Integration Steps

### For HabitQuest

1. **Service Integration**:
```swift
// In AppDelegate or App.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Register HabitQuest-specific services
    DependencyContainer.shared.register(
        HabitQuestHabitService(), 
        for: HabitServiceProtocol.self
    )
    
    // Initialize services
    Task {
        try await ServiceManager.shared.initializeServices()
    }
    
    return true
}
```

2. **Use in ViewControllers**:
```swift
class HabitListViewController: UIViewController {
    @Injected private var habitService: HabitServiceProtocol
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    func loadHabits() async {
        await analyticsService.track(event: "habits_loaded", properties: nil, userId: getCurrentUserId())
        // Load habits using service
    }
}
```

### For MomentumFinance

1. **Service Registration**:
```swift
// Register financial services
DependencyContainer.shared.register(
    MomentumFinancialService(), 
    for: FinancialServiceProtocol.self
)
```

2. **Integration Example**:
```swift
class TransactionViewController: UIViewController {
    @Injected private var financialService: FinancialServiceProtocol
    
    func createTransaction(_ transaction: EnhancedFinancialTransaction) async {
        do {
            let createdTransaction = try await financialService.createTransaction(transaction)
            // Handle successful creation
        } catch {
            // Handle error
        }
    }
}
```

### For PlannerApp

1. **Service Setup**:
```swift
DependencyContainer.shared.register(
    PlannerTaskService(), 
    for: PlannerServiceProtocol.self
)
```

2. **Task Management**:
```swift
class TaskViewController: UIViewController {
    @Injected private var plannerService: PlannerServiceProtocol
    
    func createTask(_ task: EnhancedTask) async {
        do {
            let optimizedTask = try await plannerService.createTask(task)
            // Update UI with optimized task
        } catch {
            // Handle error
        }
    }
}
```

### For CodingReviewer

1. **Custom Service Protocol**:
```swift
protocol CodeReviewServiceProtocol: ServiceProtocol {
    func analyzeCode(_ code: String) async throws -> CodeAnalysis
    func trackReviewProgress(_ reviewId: UUID) async throws
}
```

2. **Service Implementation**:
```swift
class CodeReviewService: CodeReviewServiceProtocol {
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    func analyzeCode(_ code: String) async throws -> CodeAnalysis {
        await analyticsService.track(event: "code_analyzed", properties: ["lines": code.components(separatedBy: .newlines).count], userId: nil)
        // Analysis logic
    }
}
```

### For AvoidObstaclesGame

1. **Game Analytics**:
```swift
class GameManager {
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    func playerScored(_ score: Int) async {
        await analyticsService.track(event: "player_scored", properties: ["score": score], userId: getPlayerId())
    }
}
```

## Advanced Service Features

### 1. Cross-Project Integration

```swift
class UnifiedDashboard {
    @Injected private var crossProjectService: CrossProjectServiceProtocol
    
    func loadUnifiedInsights() async {
        do {
            let insights = try await crossProjectService.getUnifiedUserInsights(for: getCurrentUserId())
            // Display unified data from all projects
        } catch {
            // Handle error
        }
    }
}
```

### 2. Service Health Monitoring

```swift
class HealthDashboard {
    func checkSystemHealth() async {
        let healthStatuses = await ServiceManager.shared.getServicesHealthStatus()
        
        for (serviceId, status) in healthStatuses {
            switch status {
            case .healthy:
                print("✅ \(serviceId) is healthy")
            case .degraded(let reason):
                print("⚠️ \(serviceId) is degraded: \(reason)")
            case .unhealthy(let error):
                print("❌ \(serviceId) is unhealthy: \(error)")
            }
        }
    }
}
```

### 3. Analytics Integration

```swift
class BaseViewController: UIViewController {
    @Injected private var analyticsService: AnalyticsServiceProtocol
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task {
            await analyticsService.trackUserAction(UserAction(
                action: "screen_view",
                context: String(describing: type(of: self)),
                userId: getCurrentUserId(),
                metadata: ["timestamp": Date().timeIntervalSince1970]
            ))
        }
    }
}
```

## Testing with Service Layer

### 1. Mock Services for Testing

```swift
class MockHabitService: HabitServiceProtocol {
    let serviceId = "mock_habit_service"
    let version = "1.0.0"
    
    var mockHabits: [EnhancedHabit] = []
    
    func initialize() async throws {}
    func cleanup() async {}
    func healthCheck() async -> ServiceHealthStatus { return .healthy }
    
    func createHabit(_ habit: EnhancedHabit) async throws -> EnhancedHabit {
        mockHabits.append(habit)
        return habit
    }
    
    // Implement other methods with mock behavior
}
```

### 2. Test Setup

```swift
class HabitServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        // Replace production service with mock
        DependencyContainer.shared.register(
            MockHabitService(), 
            for: HabitServiceProtocol.self
        )
    }
    
    override func tearDown() {
        DependencyContainer.shared.clear()
        super.tearDown()
    }
    
    func testHabitCreation() async throws {
        let service: HabitServiceProtocol = try ServiceLocator.get(HabitServiceProtocol.self)
        // Test with mock service
    }
}
```

## Performance Considerations

### 1. Service Lifecycle
- Services are initialized once and reused
- Use singleton pattern for stateless services
- Implement proper cleanup to prevent memory leaks

### 2. Async Operations
- All service operations are async for better performance
- Use Task groups for concurrent operations
- Implement timeout handling for long-running operations

### 3. Error Handling
- Services throw specific error types
- Implement retry logic for transient failures
- Log errors for debugging and monitoring

## Best Practices

1. **Service Boundaries**: Keep services focused on specific business domains
2. **Protocol First**: Always define protocols before implementations
3. **Dependency Injection**: Use DI for better testability and flexibility
4. **Error Handling**: Implement comprehensive error handling
5. **Async/Await**: Use modern async patterns throughout
6. **Testing**: Create mock implementations for all services
7. **Monitoring**: Implement health checks and analytics
8. **Documentation**: Document service contracts and expected behaviors

## Migration Notes

When migrating existing code to use the service layer:

1. **Identify Business Logic**: Extract business logic from view controllers
2. **Create Service Protocols**: Define clear service contracts
3. **Implement Services**: Create production implementations
4. **Register Services**: Set up dependency injection
5. **Update Consumers**: Use @Injected or ServiceLocator
6. **Add Testing**: Create mock services and tests
7. **Monitor**: Implement health checks and analytics

## Support and Troubleshooting

### Common Issues

1. **Service Not Found**: Ensure service is registered in DependencyContainer
2. **Circular Dependencies**: Check service dependencies and initialization order
3. **Memory Leaks**: Implement proper cleanup in service lifecycle
4. **Performance Issues**: Use profiling tools to identify bottlenecks

### Debugging Tips

1. **Health Checks**: Use ServiceManager to check service health
2. **Logging**: Enable debug logging for service operations
3. **Analytics**: Use analytics service to track service usage
4. **Testing**: Use mock services to isolate issues

For additional support, refer to:
- Service protocol documentation
- Individual service implementation guides
- Project-specific integration examples
- Error handling best practices