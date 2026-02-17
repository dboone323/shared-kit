# AI Context & Architecture Guide

## Project Overview

This repository is part of the **Momentum Ecosystem**, a suite of iOS applications and developer tools built with Swift and Python.

### Repositories

- **momentum-finance**: Personal finance tracker (Swift/SwiftUI).
- **habitquest**: Gamified habit tracker (Swift/SwiftUI/SpriteKit).
- **planner-app**: Task management (Swift/SwiftUI/CoreData).
- **avoid-obstacles-game**: SpriteKit game (Swift).
- **coding-reviewer**: iOS code review tool (Swift).
- **shared-kit**: Shared UI components and utilities (Swift Package).
- **tools-automation**: DevOps, CI/CD, and AI Agents (Python/Bash).

## Technology Stack

- **iOS**: Swift 6, SwiftUI, Combine, CoreData, SwiftData.
- **Scripting**: Python 3.11+, Bash.
- **CI/CD**: GitHub Actions.
- **AI**: Ollama (local), Groq/Gemini (cloud).

## Architecture Patterns (iOS)

- **MVVM**: Model-View-ViewModel is the standard pattern.
- **Coordinator**: Flow controllers for navigation (where applicable).
- **Repository Pattern**: Data access abstraction.
- **Dependency Injection**: Via init or EnvironmentObject.

## Code Style

- **Swift**: Enforced by `SwiftLint`.
    - 4-space indentation.
    - Trailing closures preferred.
    - Explicit `self` in closures.
- **Python**: Enforced by `Flake8` / `Black`.
    - Type hints required for new code.
    - Docstrings (Google style) for all functions.

## AI Agent Guidelines

1. **Context First**: Read `AI_CONTEXT.md` (this file) and `README.md` before making changes.
2. **Atomic Changes**: Keep PRs focused on single tasks.
3. **Safety**: Do not commit secrets/tokens.
4. **Testing**: Run tests after changes (`xcodebuild test` or `pytest`).
5. **Documentation**: Update docs if behavior changes.

## Key Directories

- `.github/workflows`: CI/CD definitions.
- `scripts/`: Automation scripts.
- `docs/`: Documentation.
- `src/` or `App/`: Source code.

## Troubleshooting

- **Build Failures**: Check `logs/build.log`.
- **Lint Errors**: Run `swiftlint --fix` or `black .`.
- **Pre-commit**: Run `pre-commit run --all-files` to check locally.
