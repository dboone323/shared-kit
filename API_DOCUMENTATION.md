# Shared-Kit API Documentation

**Version**: 2.0 (With Production Enhancements)  
**Last Updated**: 2026-01-15

---

## Quick Start

```swift
import SharedKit

// Initialize OllamaClient with enhancements
let client = OllamaClient()

// Generate with automatic retry & health tracking
let response = try await client.generate(
    model: "llama2",
    prompt: "Explain async/await"
)
```

---

## Core Components

### OllamaClient

**Purpose**: LLM interaction with production reliability features

**Enhancements**:

- ✅ Connection pooling (reuses URLSessions)
- ✅ Exponential backoff retry
- ✅ Health-based model selection
- ✅ Automatic failover

**Basic Usage**:

```swift
let client = OllamaClient()

// Generate text
let response = try await client.generate(
    model: "llama2",
    prompt: "Your prompt here",
    temperature: 0.7
)
```

**With Custom Configuration**:

```swift
let client = OllamaClient(
    baseURL: "http://localhost:11434",
    timeout: 60
)
```

**Key Methods**:

- `generate(model:prompt:systemPrompt:temperature:)` - Generate text with retry
- `chat(model:messages:temperature:)` - Chat with conversation history
- `listModels()` - Get available models

---

### AggregatorAgent

**Purpose**: Multi-tool agent orchestration with learning

**Enhancements**:

- ✅ Context window optimization (4096 tokens)
- ✅ Tool result caching (5min TTL)
- ✅ Parallel tool execution
- ✅ Learning from outcomes

**Usage**:

```swift
let agent = AggregatorAgent.shared

// Process query with all enhancements
let result = try await agent.process(query: "Check system status")
```

**Key Features**:

- Automatic planning
- Tool selection & execution
- Result caching
- Learning & recommendations

---

### Enhancement Modules

#### OllamaEnhancements

**RetryConfig**:

```swift
let config = RetryConfig(
    maxRetries: 3,
    baseDelay: 1.0,
    maxDelay: 30.0,
    jitter: true
)

let delay = config.delay(for: attempt)  // With exponential backoff
```

**ModelHealthTracker**:

```swift
let tracker = ModelHealthTracker()

// Record outcomes
await tracker.recordSuccess(for: "llama2")
await tracker.recordFailure(for: "llama2")

// Check health
let isHealthy = await tracker.isHealthy("llama2")
let best = await tracker.healthiestModel(from: ["llama2", "mistral"])
```

**OllamaConnectionPool**:

```swift
let pool = OllamaConnectionPool.shared

// Automatic session reuse
let session = pool.session(for: "llama2")
```

#### AgentEnhancements

**ContextWindowManager**:

```swift
let manager = ContextWindowManager(maxTokens: 4096)

// Optimize messages
let optimized = manager.optimizeMessages(allMessages)

// Summarize old messages
let summary = try await manager.summarize(oldMessages)
```

**ToolResultCache**:

```swift
let cache = ToolResultCache()

// Cache results
await cache.set("result", for: "tool:params")

// Retrieve cached
let cached = await cache.get(for: "tool:params")
```

**ToolExecutionCoordinator**:

```swift
let coordinator = ToolExecutionCoordinator()

// Execute in parallel
let tools: [@Sendable () async throws -> String] = [
    { try await tool1() },
    { try await tool2() }
]
let results = try await coordinator.executeParallel(tools: tools)

// Execute with timeout
let result = try await coordinator.executeWithTimeout(
    seconds: 30,
    block: { try await longRunningTool() }
)
```

**ToolLearningSystem**:

```swift
let learning = ToolLearningSystem()

// Record outcomes
await learning.recordOutcome(tool: "status", success: true)

// Get recommendations
let rate = await learning.successRate(for: "status")
let best = await learning.recommendTool(from: ["status", "logs", "metrics"])
```

#### VectorStoreEnhancements

**VectorBatchOperation**:

```swift
let batch = VectorBatchOperation(
    contents: ["doc1", "doc2", "doc3"],
    vectors: [vector1, vector2, vector3],
    metadata: [meta1, meta2, meta3]
)

try await batch.execute(on: vectorStore)
```

**VectorStoreMetrics**:

```swift
let metrics = VectorStoreMetrics()

await metrics.recordQuery(duration: 0.5, resultCount: 10)
let avgTime = await metrics.averageQueryTime()
let cacheHitRate = await metrics.cacheHitRate()
```

---

## Best Practices

### Error Handling

```swift
do {
    let response = try await client.generate(
        model: "llama2",
        prompt: "Your prompt"
    )
} catch OllamaError.modelNotFound(let model) {
    print("Model not available: \(model)")
} catch OllamaError.connectionFailed {
    print("Cannot connect to Ollama server")
} catch {
    print("Unknown error: \(error)")
}
```

### Performance Optimization

```swift
// Use connection pooling automatically
// Sessions are reused per model

// Enable caching
let agent = AggregatorAgent.shared
// Cache is automatic with 5-min TTL

// Parallel execution for independent operations
let coordinator = ToolExecutionCoordinator()
let results = try await coordinator.executeParallel(tools: independentTools)
```

### Logging

```swift
// Use SecureLogger instead of print()
SecureLogger.info("Processing request", category: .ai)
SecureLogger.error("Failed to connect", category: .network)
```

---

## Configuration

### Environment Variables

```bash
# Ollama connection
export OLLAMA_BASE_URL="http://localhost:11434"

# PostgreSQL for vector store
export POSTGRES_HOST="localhost"
export POSTGRES_PORT="5432"
export POSTGRES_USER="user"
export POSTGRES_PASSWORD="password"
export POSTGRES_DB="vectordb"
```

### Fallback Models

```swift
// Configure in OllamaClient initialization
let config = OllamaConfig(
    baseURL: "http://localhost:11434",
    fallbackModels: ["mistral", "llama2", "codellama"],
    enableCaching: true
)
```

---

## Testing

### Unit Tests

```swift
import XCTest
@testable import SharedKit

class MyTests: XCTestCase {
    func testRetryConfig() {
        let config = RetryConfig(maxRetries: 3)
        XCTAssertEqual(config.maxRetries, 3)
    }
}
```

### Integration Tests

See `Tests/SharedKitTests/*IntegrationTests.swift` for examples.

---

## Performance Metrics

**Expected Improvements**:

- Connection pooling: ~50ms saved per request
- Tool caching: ~500ms saved per cached call
- Health tracking: <0.1ms overhead
- Parallel execution: 2-3x faster for independent tools

---

## Migration Guide

### From Version 1.0

**Before**:

```swift
let client = OllamaClient()
let response = try await client.generate(model: "llama2", prompt: "...")
```

**After** (No changes required!):

```swift
let client = OllamaClient()
// Automatically gets retry, health tracking, pooling
let response = try await client.generate(model: "llama2", prompt: "...")
```

All enhancements are backward compatible.

---

## Troubleshooting

### Connection Issues

```swift
// Verify Ollama is running
// Check baseURL configuration
// Review firewall settings
```

### Performance Issues

```swift
// Check connection pool stats
// Verify cache hit rates
// Review retry configurations
```

### Memory Issues

```swift
// Monitor cache sizes
// Adjust context window limits
// Review batch operation sizes
```

---

## Support

- **Documentation**: See ENHANCEMENTS.md
- **Deployment**: See production_deployment.md
- **Issues**: Check error logs with SecureLogger

---

**API Status**: ✅ Stable  
**Production Ready**: ✅ Yes  
**Test Coverage**: 25+ tests
