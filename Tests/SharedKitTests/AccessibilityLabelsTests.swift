//
// AccessibilityLabelsTests.swift
// SharedKitTests
//

@testable import SharedKit
import XCTest

final class AccessibilityLabelsTests: XCTestCase {
    // MARK: - Navigation Labels

    func testBackButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.backButton, "Go back")
    }

    func testCloseButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.closeButton, "Close")
    }

    func testMenuButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.menuButton, "Open menu")
    }

    func testSettingsButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.settingsButton, "Open settings")
    }

    // MARK: - Action Labels

    func testAddButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.addButton, "Add new item")
    }

    func testDeleteButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.deleteButton, "Delete")
    }

    func testEditButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.editButton, "Edit")
    }

    func testSaveButtonLabel() {
        XCTAssertEqual(AccessibilityLabels.saveButton, "Save changes")
    }

    // MARK: - Status Labels

    func testLoadingLabel() {
        XCTAssertEqual(AccessibilityLabels.loading, "Loading content")
    }

    func testErrorLabel() {
        XCTAssertEqual(AccessibilityLabels.error, "Error occurred")
    }

    // MARK: - Task Labels

    func testTaskItemCompleted() {
        let label = AccessibilityLabels.taskItem(title: "Buy groceries", isComplete: true)
        XCTAssertTrue(label.contains("completed"))
        XCTAssertTrue(label.contains("Buy groceries"))
    }

    func testTaskItemNotCompleted() {
        let label = AccessibilityLabels.taskItem(title: "Buy groceries", isComplete: false)
        XCTAssertTrue(label.contains("not completed"))
    }

    func testTaskPriority() {
        let label = AccessibilityLabels.taskPriority("high")
        XCTAssertEqual(label, "high priority")
    }

    // MARK: - Habit Labels

    func testHabitItemWithStreak() {
        let label = AccessibilityLabels.habitItem(name: "Exercise", isComplete: true, streak: 5)
        XCTAssertTrue(label.contains("Exercise"))
        XCTAssertTrue(label.contains("completed today"))
        XCTAssertTrue(label.contains("5 day streak"))
    }

    func testStreakCountSingular() {
        let label = AccessibilityLabels.streakCount(1)
        XCTAssertEqual(label, "1 day streak")
    }

    func testStreakCountPlural() {
        let label = AccessibilityLabels.streakCount(7)
        XCTAssertEqual(label, "7 day streak")
    }

    // MARK: - Game Labels

    func testGameScore() {
        let label = AccessibilityLabels.gameScore(150)
        XCTAssertEqual(label, "Score: 150 points")
    }

    func testGameLevel() {
        let label = AccessibilityLabels.gameLevel(3)
        XCTAssertEqual(label, "Level 3")
    }

    func testPauseGameLabel() {
        XCTAssertEqual(AccessibilityLabels.pauseGame, "Pause game")
    }

    func testRestartGameLabel() {
        XCTAssertEqual(AccessibilityLabels.restartGame, "Restart game")
    }
}
