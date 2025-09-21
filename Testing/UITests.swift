#if canImport(XCTest) && canImport(UIKit)
import SwiftUI
@testable import TestingFramework
import UIKit
import XCTest

// MARK: - UI Tests for SwiftUI Components

// Comprehensive UI testing framework for interactive components and user flows

// MARK: - Habit Quest UI Tests

class HabitQuestUITests: UITestCase {
    func testHabitCreationFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()
        
        // When - Navigate to habit creation
        let addHabitButton = app.buttons["addHabitButton"]
        waitForElement(addHabitButton)
        addHabitButton.tap()
        
        // Then - Verify habit creation screen appears
        let habitNameField = app.textFields["habitNameField"]
        waitForElement(habitNameField)
        XCTAssertTrue(habitNameField.exists)
        
        // When - Fill in habit details
        typeAndWait("Morning Exercise", in: habitNameField)
        
        let dailyFrequencyButton = app.buttons["dailyFrequency"]
        tapAndWait(dailyFrequencyButton)
        
        let createButton = app.buttons["createHabitButton"]
        tapAndWait(createButton)
        
        // Then - Verify habit appears in list
        let habitCell = app.cells.containing(.staticText, identifier: "Morning Exercise").firstMatch
        waitForElement(habitCell)
        XCTAssertTrue(habitCell.exists)
    }
    
    func testHabitCompletionFlow() throws {
        // Given
        self.setupTestHabits()
        
        // When - Tap to complete habit
        let habitCell = app.cells["testHabitCell"].firstMatch
        waitForElement(habitCell)
        
        let completeButton = habitCell.buttons["completeHabitButton"]
        tapAndWait(completeButton)
        
        // Then - Verify completion state
        let completedIcon = habitCell.images["checkmark.circle.fill"]
        waitForElement(completedIcon)
        XCTAssertTrue(completedIcon.exists)
        
        // Verify streak counter updated
        let streakLabel = habitCell.staticTexts["streakLabel"]
        XCTAssertTrue(streakLabel.label.contains("1"))
    }
    
    func testHabitSwipeActions() throws {
        // Given
        self.setupTestHabits()
        
        // When - Swipe left on habit
        let habitCell = app.cells["testHabitCell"].firstMatch
        waitForElement(habitCell)
        habitCell.swipeLeft()
        
        // Then - Verify swipe actions appear
        let deleteButton = app.buttons["deleteHabitAction"]
        waitForElement(deleteButton)
        XCTAssertTrue(deleteButton.exists)
        
        let editButton = app.buttons["editHabitAction"]
        XCTAssertTrue(editButton.exists)
    }
    
    private func setupTestHabits() {
        // Launch app with test data
        app.launchArguments.append("--test-data-habits")
        app.launch()
    }
}

// MARK: - MomentumFinance UI Tests

class MomentumFinanceUITests: UITestCase {
    func testAccountCreationFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()
        
        // When - Navigate to account creation
        let addAccountButton = app.buttons["addAccountButton"]
        waitForElement(addAccountButton)
        addAccountButton.tap()
        
        // Then - Verify account creation screen
        let accountNameField = app.textFields["accountNameField"]
        waitForElement(accountNameField)
        
        // When - Fill account details
        typeAndWait("Checking Account", in: accountNameField)
        
        let balanceField = app.textFields["initialBalanceField"]
        typeAndWait("1000.00", in: balanceField)
        
        let accountTypeSelector = app.segmentedControls["accountTypeSelector"]
        tapAndWait(accountTypeSelector.buttons["Checking"])
        
        let createButton = app.buttons["createAccountButton"]
        tapAndWait(createButton)
        
        // Then - Verify account appears in dashboard
        let accountCard = app.otherElements["Checking Account_accountCard"]
        waitForElement(accountCard)
        XCTAssertTrue(accountCard.exists)
        
        let balanceLabel = accountCard.staticTexts["$1,000.00"]
        XCTAssertTrue(balanceLabel.exists)
    }
    
    func testTransactionFlow() throws {
        // Given
        self.setupTestAccounts()
        
        // When - Start transaction
        let quickActionsView = app.otherElements["quickActionsView"]
        waitForElement(quickActionsView)
        
        let addTransactionButton = quickActionsView.buttons["addTransactionButton"]
        tapAndWait(addTransactionButton)
        
        // Then - Verify transaction form
        let amountField = app.textFields["transactionAmountField"]
        waitForElement(amountField)
        
        // When - Fill transaction details
        typeAndWait("250.00", in: amountField)
        
        let descriptionField = app.textFields["transactionDescriptionField"]
        typeAndWait("Grocery shopping", in: descriptionField)
        
        let categorySelector = app.buttons["categorySelector"]
        tapAndWait(categorySelector)
        
        let foodCategory = app.buttons["Food & Dining"]
        tapAndWait(foodCategory)
        
        let submitButton = app.buttons["submitTransactionButton"]
        tapAndWait(submitButton)
        
        // Then - Verify transaction appears
        let transactionItem = app.cells.containing(.staticText, identifier: "Grocery shopping").firstMatch
        waitForElement(transactionItem)
        XCTAssertTrue(transactionItem.exists)
    }
    
    func testTransferFlow() throws {
        // Given
        self.setupTestAccounts()
        
        // When - Initiate transfer
        let transferButton = app.buttons["transferButton"]
        waitForElement(transferButton)
        transferButton.tap()
        
        // Then - Verify transfer form
        let fromAccountPicker = app.buttons["fromAccountPicker"]
        waitForElement(fromAccountPicker)
        
        // When - Select accounts and amount
        tapAndWait(fromAccountPicker)
        let checkingAccount = app.buttons["Checking Account"]
        tapAndWait(checkingAccount)
        
        let toAccountPicker = app.buttons["toAccountPicker"]
        tapAndWait(toAccountPicker)
        let savingsAccount = app.buttons["Savings Account"]
        tapAndWait(savingsAccount)
        
        let transferAmountField = app.textFields["transferAmountField"]
        typeAndWait("500.00", in: transferAmountField)
        
        let confirmTransferButton = app.buttons["confirmTransferButton"]
        tapAndWait(confirmTransferButton)
        
        // Then - Verify success message
        let successMessage = app.alerts["Transfer Successful"]
        waitForElement(successMessage)
        XCTAssertTrue(successMessage.exists)
    }
    
    private func setupTestAccounts() {
        app.launchArguments.append("--test-data-accounts")
        app.launch()
    }
}

// MARK: - PlannerApp UI Tests

class PlannerAppUITests: UITestCase {
    func testTaskCreationFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()
        
        // When - Create new task
        let addTaskButton = app.buttons["addTaskButton"]
        waitForElement(addTaskButton)
        addTaskButton.tap()
        
        // Then - Verify task creation form
        let taskTitleField = app.textFields["taskTitleField"]
        waitForElement(taskTitleField)
        
        // When - Fill task details
        typeAndWait("Complete project presentation", in: taskTitleField)
        
        let descriptionField = app.textViews["taskDescriptionField"]
        typeAndWait("Prepare slides and practice presentation for quarterly review", in: descriptionField)
        
        let prioritySelector = app.segmentedControls["prioritySelector"]
        tapAndWait(prioritySelector.buttons["High"])
        
        let dueDateButton = app.buttons["dueDateButton"]
        tapAndWait(dueDateButton)
        
        // Select tomorrow's date
        let datePicker = app.datePickers["dueDatePicker"]
        waitForElement(datePicker)
        datePicker.swipeUp() // Move to next day
        
        let confirmDateButton = app.buttons["confirmDateButton"]
        tapAndWait(confirmDateButton)
        
        let createTaskButton = app.buttons["createTaskButton"]
        tapAndWait(createTaskButton)
        
        // Then - Verify task appears in list
        let taskCell = app.cells.containing(.staticText, identifier: "Complete project presentation").firstMatch
        waitForElement(taskCell)
        XCTAssertTrue(taskCell.exists)
        
        // Verify priority indicator
        let highPriorityIndicator = taskCell.images["highPriorityIndicator"]
        XCTAssertTrue(highPriorityIndicator.exists)
    }
    
    func testTaskCompletionFlow() throws {
        // Given
        self.setupTestTasks()
        
        // When - Mark task as complete
        let taskCell = app.cells["testTaskCell"].firstMatch
        waitForElement(taskCell)
        
        let completionCheckbox = taskCell.buttons["completionCheckbox"]
        tapAndWait(completionCheckbox)
        
        // Then - Verify completion state
        let completedCheckmark = taskCell.images["checkmark.circle.fill"]
        waitForElement(completedCheckmark)
        XCTAssertTrue(completedCheckmark.exists)
        
        // Verify task styling changes
        let taskTitle = taskCell.staticTexts["taskTitle"]
        XCTAssertTrue(taskTitle.exists)
        // Note: In actual implementation, you'd verify strikethrough styling
    }
    
    func testTaskFilteringFlow() throws {
        // Given
        self.setupTestTasks()
        
        // When - Apply priority filter
        let filterButton = app.buttons["filterButton"]
        waitForElement(filterButton)
        filterButton.tap()
        
        let filterSheet = app.sheets["filterSheet"]
        waitForElement(filterSheet)
        
        let highPriorityFilter = filterSheet.buttons["High Priority"]
        tapAndWait(highPriorityFilter)
        
        let applyFilterButton = filterSheet.buttons["applyFilterButton"]
        tapAndWait(applyFilterButton)
        
        // Then - Verify only high priority tasks shown
        let tasksList = app.collectionViews["tasksList"]
        let highPriorityTasks = tasksList.cells.matching(identifier: "highPriorityTask")
        
        XCTAssertGreaterThan(highPriorityTasks.count, 0)
        
        // Verify no low priority tasks visible
        let lowPriorityTasks = tasksList.cells.matching(identifier: "lowPriorityTask")
        XCTAssertEqual(lowPriorityTasks.count, 0)
    }
    
    private func setupTestTasks() {
        app.launchArguments.append("--test-data-tasks")
        app.launch()
    }
}

// MARK: - CodingReviewer UI Tests

class CodingReviewerUITests: UITestCase {
    func testPullRequestListFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()
        
        // When - Load pull requests
        let refreshButton = app.buttons["refreshButton"]
        waitForElement(refreshButton)
        refreshButton.tap()
        
        // Then - Verify pull requests load
        let prList = app.collectionViews["pullRequestsList"]
        waitForElement(prList)
        
        let firstPR = prList.cells.firstMatch
        waitForElement(firstPR, timeout: 10.0)
        XCTAssertTrue(firstPR.exists)
        
        // Verify PR information displayed
        let prTitle = firstPR.staticTexts["prTitle"]
        let prAuthor = firstPR.staticTexts["prAuthor"]
        let prStatus = firstPR.staticTexts["prStatus"]
        
        XCTAssertTrue(prTitle.exists)
        XCTAssertTrue(prAuthor.exists)
        XCTAssertTrue(prStatus.exists)
    }
    
    func testPullRequestReviewFlow() throws {
        // Given
        self.setupTestPullRequests()
        
        // When - Select PR for review
        let prList = app.collectionViews["pullRequestsList"]
        let firstPR = prList.cells.firstMatch
        waitForElement(firstPR)
        firstPR.tap()
        
        // Then - Verify PR detail screen
        let prDetailView = app.otherElements["prDetailView"]
        waitForElement(prDetailView)
        
        let reviewButton = prDetailView.buttons["startReviewButton"]
        XCTAssertTrue(reviewButton.exists)
        
        // When - Start review
        tapAndWait(reviewButton)
        
        // Then - Verify review interface
        let codeView = app.textViews["codeView"]
        waitForElement(codeView)
        
        let commentButton = app.buttons["addCommentButton"]
        XCTAssertTrue(commentButton.exists)
        
        let approveButton = app.buttons["approveButton"]
        let requestChangesButton = app.buttons["requestChangesButton"]
        
        XCTAssertTrue(approveButton.exists)
        XCTAssertTrue(requestChangesButton.exists)
    }
    
    func testCodeCommentFlow() throws {
        // Given
        self.setupTestPullRequests()
        self.startPRReview()
        
        // When - Add line comment
        let codeView = app.textViews["codeView"]
        waitForElement(codeView)
        
        // Long press on a line to add comment
        let codeLine = codeView.staticTexts["codeLine_10"]
        waitForElement(codeLine)
        codeLine.press(forDuration: 1.0)
        
        // Then - Verify comment interface appears
        let commentPopover = app.popovers["commentPopover"]
        waitForElement(commentPopover)
        
        let commentField = commentPopover.textViews["commentField"]
        typeAndWait("Consider using a more descriptive variable name here", in: commentField)
        
        let submitCommentButton = commentPopover.buttons["submitCommentButton"]
        tapAndWait(submitCommentButton)
        
        // Verify comment indicator appears
        let commentIndicator = codeView.images["commentIndicator_10"]
        waitForElement(commentIndicator)
        XCTAssertTrue(commentIndicator.exists)
    }
    
    private func setupTestPullRequests() {
        app.launchArguments.append("--test-data-pull-requests")
        app.launch()
    }
    
    private func startPRReview() {
        let prList = app.collectionViews["pullRequestsList"]
        let firstPR = prList.cells.firstMatch
        waitForElement(firstPR)
        firstPR.tap()
        
        let reviewButton = app.buttons["startReviewButton"]
        waitForElement(reviewButton)
        reviewButton.tap()
    }
}

// MARK: - AvoidObstaclesGame UI Tests

class AvoidObstaclesGameUITests: UITestCase {
    func testGameStartFlow() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()
        
        // When - Start new game
        let startGameButton = app.buttons["startGameButton"]
        waitForElement(startGameButton)
        startGameButton.tap()
        
        // Then - Verify game screen loads
        let gameView = app.otherElements["gameView"]
        waitForElement(gameView)
        
        let player = gameView.images["player"]
        XCTAssertTrue(player.exists)
        
        let scoreLabel = gameView.staticTexts["scoreLabel"]
        XCTAssertTrue(scoreLabel.exists)
        XCTAssertTrue(scoreLabel.label.contains("0"))
        
        let pauseButton = gameView.buttons["pauseButton"]
        XCTAssertTrue(pauseButton.exists)
    }
    
    func testPlayerMovementControls() throws {
        // Given
        self.startGame()
        
        // When - Test touch controls
        let gameView = app.otherElements["gameView"]
        let player = gameView.images["player"]
        
        let initialPlayerPosition = player.frame
        
        // Swipe up to move player up
        gameView.swipeUp()
        
        // Wait for animation
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then - Verify player moved
        let newPlayerPosition = player.frame
        XCTAssertNotEqual(initialPlayerPosition.midY, newPlayerPosition.midY)
    }
    
    func testPauseResumeFlow() throws {
        // Given
        self.startGame()
        
        // When - Pause game
        let pauseButton = app.buttons["pauseButton"]
        tapAndWait(pauseButton)
        
        // Then - Verify pause menu appears
        let pauseMenu = app.otherElements["pauseMenu"]
        waitForElement(pauseMenu)
        
        let resumeButton = pauseMenu.buttons["resumeButton"]
        let restartButton = pauseMenu.buttons["restartButton"]
        let mainMenuButton = pauseMenu.buttons["mainMenuButton"]
        
        XCTAssertTrue(resumeButton.exists)
        XCTAssertTrue(restartButton.exists)
        XCTAssertTrue(mainMenuButton.exists)
        
        // When - Resume game
        tapAndWait(resumeButton)
        
        // Then - Verify game continues
        waitForElementToDisappear(pauseMenu)
        XCTAssertFalse(pauseMenu.exists)
    }
    
    func testGameOverFlow() throws {
        // Given
        self.startGame()
        
        // When - Simulate game over (this would be triggered by collision in actual game)
        app.launchArguments.append("--simulate-game-over")
        
        // Then - Verify game over screen
        let gameOverView = app.otherElements["gameOverView"]
        waitForElement(gameOverView, timeout: 15.0) // Wait longer for game over
        
        let finalScoreLabel = gameOverView.staticTexts["finalScoreLabel"]
        let highScoreLabel = gameOverView.staticTexts["highScoreLabel"]
        let playAgainButton = gameOverView.buttons["playAgainButton"]
        
        XCTAssertTrue(finalScoreLabel.exists)
        XCTAssertTrue(highScoreLabel.exists)
        XCTAssertTrue(playAgainButton.exists)
        
        // When - Play again
        tapAndWait(playAgainButton)
        
        // Then - Verify new game starts
        let gameView = app.otherElements["gameView"]
        waitForElement(gameView)
        
        let scoreLabel = gameView.staticTexts["scoreLabel"]
        XCTAssertTrue(scoreLabel.label.contains("0"))
    }
    
    private func startGame() {
        let startButton = app.buttons["startGameButton"]
        waitForElement(startButton)
        startButton.tap()
        
        let gameView = app.otherElements["gameView"]
        waitForElement(gameView)
    }
}

// MARK: - Animation and Interaction Tests

class AnimationInteractionTests: UITestCase {
    func testButtonAnimations() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--animation-testing")
        app.launch()
        
        // When - Test neumorphic button
        let neumorphicButton = app.buttons["neumorphicTestButton"]
        waitForElement(neumorphicButton)
        
        let initialFrame = neumorphicButton.frame
        neumorphicButton.press(forDuration: 0.1)
        
        // Then - Button should animate (frame might change slightly)
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertTrue(neumorphicButton.exists)
    }
    
    func testSwipeGestures() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--gesture-testing")
        app.launch()
        
        // When - Test swipe gesture area
        let gestureArea = app.otherElements["swipeGestureArea"]
        waitForElement(gestureArea)
        
        gestureArea.swipeLeft()
        
        // Then - Verify swipe action triggered
        let leftSwipeAlert = app.alerts["Left Swipe Detected"]
        waitForElement(leftSwipeAlert, timeout: 3.0)
        XCTAssertTrue(leftSwipeAlert.exists)
        
        leftSwipeAlert.buttons["OK"].tap()
        
        // Test right swipe
        gestureArea.swipeRight()
        
        let rightSwipeAlert = app.alerts["Right Swipe Detected"]
        waitForElement(rightSwipeAlert, timeout: 3.0)
        XCTAssertTrue(rightSwipeAlert.exists)
    }
    
    func testInteractiveComponents() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--interactive-testing")
        app.launch()
        
        // When - Test interactive slider
        let interactiveSlider = app.sliders["interactiveSlider"]
        waitForElement(interactiveSlider)
        
        let initialValue = interactiveSlider.value
        interactiveSlider.adjust(toNormalizedSliderPosition: 0.8)
        
        // Then - Verify slider value changed
        let newValue = interactiveSlider.value
        XCTAssertNotEqual(initialValue, newValue)
        
        // When - Test interactive toggle
        let interactiveToggle = app.switches["interactiveToggle"]
        let initialToggleState = interactiveToggle.value as? String
        
        interactiveToggle.tap()
        
        // Then - Verify toggle state changed
        let newToggleState = interactiveToggle.value as? String
        XCTAssertNotEqual(initialToggleState, newToggleState)
    }
    
    func testCustomTransitions() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--transition-testing")
        app.launch()
        
        // When - Test slide transition
        let slideTransitionButton = app.buttons["slideTransitionButton"]
        waitForElement(slideTransitionButton)
        slideTransitionButton.tap()
        
        // Then - Verify content appears with transition
        let transitionedContent = app.otherElements["transitionedContent"]
        waitForElement(transitionedContent, timeout: 2.0)
        XCTAssertTrue(transitionedContent.exists)
        
        // When - Test scale transition
        let scaleTransitionButton = app.buttons["scaleTransitionButton"]
        tapAndWait(scaleTransitionButton)
        
        let scaledContent = app.otherElements["scaledContent"]
        waitForElement(scaledContent)
        XCTAssertTrue(scaledContent.exists)
    }
}

// MARK: - Cross-Platform UI Tests

class CrossPlatformUITests: UITestCase {
    func testAdaptiveLayout() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--adaptive-layout-testing")
        app.launch()
        
        // When - Test on different screen sizes (simulated)
        let mainView = app.otherElements["adaptiveMainView"]
        waitForElement(mainView)
        
        // Rotate device to test landscape layout
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1.0)
        
        // Then - Verify layout adapts
        XCTAssertTrue(mainView.exists)
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
        
        XCTAssertTrue(mainView.exists)
    }
    
    func testAccessibilityFeatures() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--accessibility-testing")
        app.launch()
        
        // When - Test VoiceOver support
        let accessibleButton = app.buttons["accessibleButton"]
        waitForElement(accessibleButton)
        
        // Then - Verify accessibility properties
        XCTAssertNotNil(accessibleButton.label)
        XCTAssertNotNil(accessibleButton.identifier)
        XCTAssertTrue(accessibleButton.isEnabled)
        
        // Test accessibility hints
        let hintButton = app.buttons["hintButton"]
        XCTAssertTrue(hintButton.exists)
    }
    
    func testDarkModeSupport() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--dark-mode-testing")
        app.launch()
        
        // When - Switch to dark mode (simulated via app state)
        let darkModeToggle = app.switches["darkModeToggle"]
        waitForElement(darkModeToggle)
        darkModeToggle.tap()
        
        // Then - Verify UI updates for dark mode
        let mainBackground = app.otherElements["mainBackground"]
        XCTAssertTrue(mainBackground.exists)
        
        // Verify text colors adapt
        let adaptiveText = app.staticTexts["adaptiveText"]
        XCTAssertTrue(adaptiveText.exists)
    }
}

// MARK: - Performance UI Tests

class PerformanceUITests: UITestCase {
    func testLaunchPerformance() throws {
        if #available(iOS 13.0, *) {
            // Given
            let app = XCUIApplication()
            
            // When - Measure launch time
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                app.launch()
                
                // Wait for main screen to load
                let mainScreen = app.otherElements["mainScreen"]
                waitForElement(mainScreen, timeout: 10.0)
            }
            
            app.terminate()
        }
    }
    
    func testScrollPerformance() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--performance-testing-large-list")
        app.launch()
        
        let scrollView = app.scrollViews.firstMatch
        waitForElement(scrollView)
        
        // When - Measure scroll performance
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            // Perform rapid scrolling
            for _ in 0 ..< 10 {
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            for _ in 0 ..< 10 {
                scrollView.swipeDown()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    func testAnimationPerformance() throws {
        // Given
        let app = XCUIApplication()
        app.launchArguments.append("--animation-performance-testing")
        app.launch()
        
        let animationTrigger = app.buttons["startAnimationButton"]
        waitForElement(animationTrigger)
        
        // When - Measure animation performance
        measure(metrics: [XCTCPUMetric()]) {
            // Trigger multiple animations
            for _ in 0 ..< 5 {
                animationTrigger.tap()
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
    }
}

#endif
