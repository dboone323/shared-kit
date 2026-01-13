//
// AccessibilityLabels.swift
// Shared accessibility utilities for all iOS projects.
//
// Step 27: Accessibility labels for all interactive elements.
//

import SwiftUI

// MARK: - Accessibility Helpers

/// View modifier for consistent accessibility labeling.
struct AccessibleButtonModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    init(label: String, hint: String? = nil, traits: AccessibilityTraits = .isButton) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    /// Adds accessibility label and hint for buttons.
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        modifier(AccessibleButtonModifier(label: label, hint: hint))
    }
    
    /// Adds accessibility for toggle controls.
    func accessibleToggle(_ label: String, isOn: Bool) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityHint("Double tap to toggle")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Adds accessibility for progress indicators.
    func accessibleProgress(_ label: String, progress: Double) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(progress * 100)) percent")
    }
    
    /// Adds accessibility for images.
    func accessibleImage(_ description: String) -> some View {
        self
            .accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }
    
    /// Hides decorative elements from accessibility.
    func accessibilityDecorative() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Common Accessibility Labels

enum AccessibilityLabels {
    
    // Navigation
    static let backButton = "Go back"
    static let closeButton = "Close"
    static let menuButton = "Open menu"
    static let settingsButton = "Open settings"
    
    // Actions
    static let addButton = "Add new item"
    static let deleteButton = "Delete"
    static let editButton = "Edit"
    static let saveButton = "Save changes"
    static let cancelButton = "Cancel"
    
    // Status
    static let loading = "Loading content"
    static let refreshing = "Refreshing content"
    static let error = "Error occurred"
    static let success = "Action completed successfully"
    
    // Tasks (PlannerApp)
    static func taskItem(title: String, isComplete: Bool) -> String {
        isComplete ? "\(title), completed" : "\(title), not completed"
    }
    
    static func taskPriority(_ priority: String) -> String {
        "\(priority) priority"
    }
    
    // Habits (HabitQuest)
    static func habitItem(name: String, isComplete: Bool, streak: Int) -> String {
        var description = name
        if isComplete {
            description += ", completed today"
        } else {
            description += ", not completed"
        }
        if streak > 0 {
            description += ", \(streak) day streak"
        }
        return description
    }
    
    static func streakCount(_ count: Int) -> String {
        count == 1 ? "1 day streak" : "\(count) day streak"
    }
    
    // Finance (MomentumFinance)
    static func transactionAmount(_ amount: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    static func accountBalance(_ balance: Double) -> String {
        "Account balance: \(transactionAmount(balance))"
    }
    
    // Game (AvoidObstaclesGame)
    static func gameScore(_ score: Int) -> String {
        "Score: \(score) points"
    }
    
    static func gameLevel(_ level: Int) -> String {
        "Level \(level)"
    }
    
    static let pauseGame = "Pause game"
    static let resumeGame = "Resume game"
    static let restartGame = "Restart game"
}

// MARK: - VoiceOver Announcements

struct AccessibilityAnnouncer {
    
    /// Announces a message to VoiceOver users.
    static func announce(_ message: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .announcement, argument: message)
        #endif
    }
    
    /// Announces screen change.
    static func screenChanged(_ screenName: String) {
        #if os(iOS)
        UIAccessibility.post(notification: .screenChanged, argument: screenName)
        #endif
    }
    
    /// Announces layout change.
    static func layoutChanged(_ element: Any? = nil) {
        #if os(iOS)
        UIAccessibility.post(notification: .layoutChanged, argument: element)
        #endif
    }
}

#if os(iOS)
import UIKit
#endif
