# shared-kit

Swift Package providing shared architecture, utilities, and testing support for Quantum projects.

## Overview

Extracted from the Quantum-workspace monorepo with full git history on November 4, 2025. This package consolidates reusable Swift code for macOS, iOS, tvOS, watchOS, and visionOS platforms.

## Products

### SharedKit
Main library containing:
- **SharedArchitecture**: Base protocols, MVVM patterns, `BaseViewModel`
- **Utilities**: Helper functions, extensions, common utilities

### SharedTestSupport
Testing utilities and mocks for consumer apps.

## Requirements

- Swift 6.0+
- iOS 18.0+ / macOS 15.0+ / tvOS 18.0+ / watchOS 11.0+ / visionOS 2.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dboone323/shared-kit", exact: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages
2. Enter: `https://github.com/dboone323/shared-kit`
3. Dependency Rule: **Exact Version** `1.0.0`
4. Add to your target

## Usage

```swift
import SharedKit

// Use BaseViewModel protocol
@MainActor
class MyViewModel: BaseViewModel {
    typealias State = MyState
    typealias Action = MyAction
    
    @Published var state: MyState
    @Published var isLoading: Bool = false
    
    func handle(_ action: MyAction) {
        // Handle actions
    }
}
```

## Architecture Principles

1. **Data models NEVER import SwiftUI** - Keep them in `SharedTypes/`
2. **Avoid Codable in complex models** - Prevents circular dependencies
3. **Sendable for thread safety** - Prefer over complex async patterns
4. **Specific naming over generic** - Avoid "Dashboard", "Manager"

## Development

```bash
# Build
swift build

# Test
swift test

# Format (if tools available)
swiftformat .
swiftlint --strict
```

## Versioning

This package follows [Semantic Versioning 2.0.0](https://semver.org/):
- **MAJOR**: Breaking API changes
- **MINOR**: Backward-compatible features
- **PATCH**: Backward-compatible fixes

Apps pin to **exact versions** to ensure stability.

## Migration Notice

Extracted from [Quantum-workspace monorepo](https://github.com/dboone323/Quantum-workspace) (archived).

## License

See LICENSE file in repository.

## Contact

- Owner: @dboone323
- Issues: https://github.com/dboone323/shared-kit/issues
