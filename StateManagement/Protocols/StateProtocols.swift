//
//  StateProtocols.swift
//  Shared State Management System
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Foundation

// MARK: - Import Required Types from Service Layer

// These types are imported from our service protocols

public enum ProjectType: String, CaseIterable {
    case habitQuest = "habit_quest"
    case momentumFinance = "momentum_finance"
    case plannerApp = "planner_app"
    case codingReviewer = "coding_reviewer"
    case avoidObstaclesGame = "avoid_obstacles_game"

    public var displayName: String {
        switch self {
        case .habitQuest: "HabitQuest"
        case .momentumFinance: "MomentumFinance"
        case .plannerApp: "PlannerApp"
        case .codingReviewer: "CodingReviewer"
        case .avoidObstaclesGame: "AvoidObstaclesGame"
        }
    }
}

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
