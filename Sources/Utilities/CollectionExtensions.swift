//
// CollectionExtensions.swift
// SharedKit
//
// Common collection utilities
//

import Foundation

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    /// Returns true if the collection is not empty
    var isNotEmpty: Bool {
        !isEmpty
    }
}

public extension Array {
    /// Splits the array into chunks of the specified size
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
