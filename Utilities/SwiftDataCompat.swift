// Minimal compatibility shims for SwiftData features used in the project.
// This file provides a no-op @Query property wrapper when SwiftData is not available
// so sources that annotate with @Query still compile on platforms/toolchains
// that don't provide SwiftData. It intentionally mimics the surface of the
// real property wrapper but implements a safe in-memory fallback.

import Foundation

// If SwiftData is available in the SDK, re-export it so other source files in the
// same compilation unit can use @Query without adding explicit `import SwiftData`.
// If SwiftData is not available, provide a minimal fallback Query property wrapper.
#if canImport(SwiftData)
    @_exported import SwiftData
#else

    /// A minimal, source-compatible fallback for the SwiftData @Query property wrapper.
    /// It stores a value in an ordinary stored property and exposes a projectedValue
    /// to remain compatible with simple usages.
    @propertyWrapper
    public struct Query<Value> {
        private var value: Value

        public init(wrappedValue: Value) {
            self.value = wrappedValue
        }

        public var wrappedValue: Value {
            get { value }
            set { value = newValue }
        }

        public var projectedValue: Query<Value> { self }
    }

#endif
