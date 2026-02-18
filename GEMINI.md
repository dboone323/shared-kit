# SharedKit: Agentic Grounding (Feb 2026)

## Purpose

SharedKit is the foundational library for all AI agents and protocol standards in this ecosystem. It provides the core abstractions for `BaseAgent`, `AgentResult`, and AI service protocols.

## Core Objectives

1. **Protocol Standard**: Maintain strict adherence to Codable and Sendable protocols for all AI exchange models.
2. **Safety First**: Ensure all agentic results support the `requiresApproval` HITL (Human-in-the-Loop) flag.
3. **Strict Concurrency**: Every component must be Swift 6.2 thread-safe.

## Agent Instructions

- **Design Pattern**: Always use the "Result Object" pattern for agent outputs.
- **Testing**: Prioritize `Swift Testing` over legacy `XCTest`.
- **Optimization**: Use `Static Member Lookup` where possible for service configurations.

## Constraints

- No third-party dependencies unless explicitly listed in `Package.swift`.
- Maintain 100% compatibility with Xcode 26.3 and Python 3.13 orchestration.
