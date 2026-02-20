# Apple Platforms (Swift 6.2) Best Practices (Feb 2026)

- Use strict concurrency (`Sendable`, Actors).
- Use `Swift Testing` instead of `XCTest`.
- Avoid third-party dependencies unless strictly necessary (must be listed in Package.swift).
- All AI agent results must support the `requiresApproval` HITL flag.
- Prioritize high-performance execution.
