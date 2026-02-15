=== CLEANUP PLAN ===

## Current State
- Total files in SharedKit:      208
- Speculative/sci-fi files: 123 (59%)
- Practical files: ~85 (41%)

## Action Plan
1. Remove all speculative files from Sources/SharedKit/
2. Move practical files to proper directories
3. Simplify SharedKitCore to minimal common types
4. Update Package.swift to reflect clean structure
5. Test build and verify momentum-finance still works
