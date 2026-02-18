# Xcode 26.3 Intelligence: SharedKit Hints

## Architecture Oversight

This project is a pure Swift Package. AI Agents should focus on `Sources/SharedKit` for implementation and `Tests/SharedKitTests` for verification.

## Intelligence Integration

- **Index Priority**: `Sources/SharedKit/Agents/BaseAgent.swift` is the root of all agent definitions.
- **Service Root**: `Sources/SharedKit/Protocols/AIServiceProtocols.swift` defines all service exchange formats.
- **Explicit Modules**: This project uses explicit module builds. Do not manually modify build settings; use `Package.swift` or centralized `.xcconfig`.

## Optimization Hints

- Use `@testable import SharedKit` in all test targets.
- Leverage `Testing` framework macros (`@Suite`, `@Test`, `#expect`).
