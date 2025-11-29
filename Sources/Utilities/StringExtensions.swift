//
// StringExtensions.swift
// SharedKit
//
// Common string manipulation utilities
//

import Foundation

public extension String {
    /// Returns true if the string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Returns true if the string is not empty and contains non-whitespace characters
    var isNotBlank: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Truncates the string to the specified length and adds an ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}
