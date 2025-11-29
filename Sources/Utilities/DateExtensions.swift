//
// DateExtensions.swift
// SharedKit
//
// Common date manipulation utilities
//

import Foundation

public extension Date {
    /// Returns an ISO8601 string representation of the date
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    /// Returns a user-friendly string (e.g., "Today", "Yesterday", "Nov 29")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns the start of the day
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns the end of the day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
}
