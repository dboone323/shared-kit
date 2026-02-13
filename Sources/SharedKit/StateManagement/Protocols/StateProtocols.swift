//
//  StateProtocols.swift
//  Shared State Management System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation

// MARK: - State Management Protocols

// Re-export types from service protocols for state management
public protocol EnhancedHabitProtocol {
    var id: UUID { get }
    var name: String { get set }
}

public protocol EnhancedHabitLogProtocol {
    var id: UUID { get }
    var habitId: UUID { get set }
}

public protocol HabitAchievementProtocol {
    var id: UUID { get }
    var habitId: UUID { get set }
}

public protocol EnhancedFinancialTransactionProtocol {
    var id: UUID { get }
    var amount: Double { get set }
}

public protocol EnhancedTaskProtocol {
    var id: UUID { get }
    var title: String { get set }
}
