import XCTest

final class TaskRowViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting"]
        app.launch()

        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5), "Status bar item not found.")

        let newTaskField = app.textFields["newTaskTextField"]

        // Only click if the field isn't already present and hittable
        if !newTaskField.isHittable { // isHittable implies exists
            statusItem.click()
            // Increased delay significantly after click for popover animation/setup
            Thread.sleep(forTimeInterval: 2.5) // Increased from 1.5
            // Wait longer for the text field to appear
            XCTAssertTrue(newTaskField.waitForExistence(timeout: 10), "New task text field did not appear after clicking status item.") // Increased from 7
            // Explicitly wait/check for hittable *after* existence
            XCTAssertTrue(newTaskField.waitForHittable(timeout: 5), "New task text field did not become hittable.") // Added explicit hittable check with timeout
        }

        // Add a small pause before clearing to ensure UI is settled
        Thread.sleep(forTimeInterval: 0.5)
        clearAllTasks() // Ensure this helper is robust
    }

    override func tearDownWithError() throws {
        let statusItem = app.statusItems.firstMatch
        let newTaskField = app.textFields["newTaskTextField"]
        // Check if hittable as a proxy for being open
        if statusItem.exists && newTaskField.isHittable {
             statusItem.click()
             // Wait briefly for close animation
             Thread.sleep(forTimeInterval: 0.5) // Use Thread.sleep
        }

        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    // Helper to add a task via the UI
    func addTask(title: String) {
        let inputTextField = app.textFields["newTaskTextField"]
        // Use the hittable check with timeout directly
        XCTAssertTrue(inputTextField.waitForHittable(timeout: 5), "New task text field not hittable for adding task.")

        inputTextField.click()
        // Clear existing text if any before typing
        if let stringValue = inputTextField.value as? String, !stringValue.isEmpty {
             inputTextField.typeKey("a", modifierFlags: .command)
             inputTextField.typeKey(.delete, modifierFlags: [])
        }
        inputTextField.typeText(title + "\n") // Use \n to simulate pressing Enter

        // Pause to allow UI update after adding task
        Thread.sleep(forTimeInterval: 1.0) // Use Thread.sleep
    }

    // Helper to clear tasks, handling the alert
    func clearAllTasks() {
        // Find any task row based on identifier prefix to see if clearing is needed
        let anyTaskRow = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'taskRow_'")).firstMatch
        if !anyTaskRow.waitForExistence(timeout: 1) {
             print("No task rows found, skipping clear.")
             return // No tasks to clear
        }

        // Attempt to clear completed first (might not exist if no tasks are completed)
        let clearCompletedButton = app.buttons["clearCompletedButton"].firstMatch
        if clearCompletedButton.waitForHittable(timeout: 2) { // Wait for hittable
            clearCompletedButton.click()
            Thread.sleep(forTimeInterval: 0.5) // Use Thread.sleep for pause
        }

        // Now attempt to clear all remaining tasks
        let clearAllButton = app.buttons["clearAllButton"].firstMatch
        if clearAllButton.waitForHittable(timeout: 2) { // Wait for hittable
            clearAllButton.click()
            // Handle the confirmation alert
            let alert = app.alerts["Clear All Tasks?"] // Use title if no identifier
            XCTAssertTrue(alert.waitForExistence(timeout: 3), "Clear All confirmation alert did not appear.") // Increased timeout
            let clearAlertButton = alert.buttons["Clear All"] // Match the destructive button title
            XCTAssertTrue(clearAlertButton.waitForHittable(timeout: 2), "Clear All button in alert not hittable.") // Wait for hittable
            clearAlertButton.click()
            // Pause after clearing all
            Thread.sleep(forTimeInterval: 1.0) // Use Thread.sleep
        } else if !clearAllButton.exists {
             print("Clear All button not found (perhaps no tasks remained after clearing completed).")
        } else {
             print("Clear All button exists but is not hittable.")
             // XCTFail("Clear All button was not hittable.") // Uncomment to fail if this state is invalid
        }
    }

    // Helper function to find a task row element containing specific text
    func findTaskRow(containingText text: String) -> XCUIElement {
        let taskTextElement = app.staticTexts[text]
        XCTAssertTrue(taskTextElement.waitForExistence(timeout: 7), "Static text '\(text)' not found anywhere in the app.")

        let taskRowIdentifierPredicate = NSPredicate(format: "identifier BEGINSWITH 'taskRow_'")
        // Search within descendants of the popover window if possible, otherwise fallback to app
        // Note: Finding the popover reliably might need an identifier on its view/window in AppDelegate
        let searchBase = app.windows.matching(identifier: "TaskerPopoverWindow").firstMatch // Assuming identifier is set
        let containerQuery = (searchBase.exists ? searchBase : app).descendants(matching: .any)
                                        .matching(taskRowIdentifierPredicate)

        // Iterate through potential rows to find the one containing the text
        for i in 0..<containerQuery.count {
            let potentialRow = containerQuery.element(boundBy: i)
            if potentialRow.staticTexts[text].exists {
                 XCTAssertTrue(potentialRow.isHittable, "Found task row for '\(text)' but it's not hittable.")
                 return potentialRow // Return the first hittable row containing the text
            }
        }

        // If loop completes without returning, the text wasn't found in any identified row
        XCTFail("Could not find a hittable task row container with identifier prefix 'taskRow_' containing the text '\(text)'.")
        return app.otherElements["FallbackElementOnError"] // Return a dummy element to satisfy compiler, test will fail above
    }

    func testToggleTaskCompletion() throws {
        let taskTitle = "My Test Task - Toggle \(UUID().uuidString)"
        addTask(title: taskTitle)
        let taskRow = findTaskRow(containingText: taskTitle)

        let checkbox = taskRow.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'taskRowCheckbox_'")).firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 2), "Checkbox within row for '\(taskTitle)' not found.")

        let taskText = taskRow.staticTexts[taskTitle]
        XCTAssertTrue(taskText.exists, "Task title static text not found within the identified row.")

        XCTAssertTrue(checkbox.waitForHittable(timeout: 2), "Checkbox is not hittable before first click.")
        checkbox.click()
        Thread.sleep(forTimeInterval: 1.0)

        // Re-find the row and checkbox after potential UI update
        let taskRowAfterComplete = findTaskRow(containingText: taskTitle)
        let checkboxAfterComplete = taskRowAfterComplete.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'taskRowCheckbox_'")).firstMatch
        XCTAssertTrue(checkboxAfterComplete.waitForHittable(timeout: 2), "Checkbox is not hittable before second click.")
        checkboxAfterComplete.click()
        Thread.sleep(forTimeInterval: 1.0)

        // Verify row still exists
        let taskRowAfterUncomplete = findTaskRow(containingText: taskTitle)
        XCTAssertTrue(taskRowAfterUncomplete.exists, "Task row disappeared after un-completion.")
    }

    func testDeleteTask() throws {
        let taskTitle = "My Test Task - Delete \(UUID().uuidString)"
        addTask(title: taskTitle)
        let taskRow = findTaskRow(containingText: taskTitle)

        XCTAssertTrue(taskRow.isHittable, "Task row is not hittable for hover.")
        taskRow.hover()
        // Increase pause after hover significantly
        Thread.sleep(forTimeInterval: 2.0) // Increased from 1.5

        // Re-check if taskRow is still valid/hittable after hover/sleep
        XCTAssertTrue(taskRow.isHittable, "Task row became unhittable after hover.")

        let deleteButton = taskRow.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'taskRowDeleteButton_'")).firstMatch
        // Increase wait time for the delete button significantly
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 7), "Delete button within row for '\(taskTitle)' did not appear after hover.") // Increased from 5
        XCTAssertTrue(deleteButton.waitForHittable(timeout: 3), "Delete button did not become hittable.") // Added hittable check

        deleteButton.click()

        // Verify the row is gone
        let taskTextElement = app.staticTexts[taskTitle]
        let existsPredicate = NSPredicate(format: "exists == false") // Corrected predicate
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: taskTextElement)
        wait(for: [expectation], timeout: 5) // Increased timeout
    }

    func testEditTask() throws {
        let initialTaskTitle = "My Test Task - Edit Initial \(UUID().uuidString)"
        let editedTaskTitle = "My Test Task - Edited \(UUID().uuidString)"

        addTask(title: initialTaskTitle)

        // Find the row and the static text element
        let taskRow = findTaskRow(containingText: initialTaskTitle)
        let taskStaticText = taskRow.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'taskRowTitle_'")).firstMatch
        XCTAssertTrue(taskStaticText.waitForExistence(timeout: 3), "Task title static text not found.")
        XCTAssertTrue(taskStaticText.isHittable, "Task title static text is not hittable for double click.")

        // Double click to enter edit mode
        taskStaticText.doubleClick()
        Thread.sleep(forTimeInterval: 0.5) // Allow time for TextField to appear

        // Find the edit text field
        let editTextField = taskRow.textFields.matching(NSPredicate(format: "identifier BEGINSWITH 'taskRowEditField_'")).firstMatch
        XCTAssertTrue(editTextField.waitForExistence(timeout: 3), "Edit text field did not appear after double click.")
        XCTAssertTrue(editTextField.waitForHittable(timeout: 2), "Edit text field is not hittable.")

        // Clear existing text and type the new title, then press Enter
        editTextField.click() // Ensure focus
        // Select all and delete existing text
        editTextField.typeKey("a", modifierFlags: .command)
        editTextField.typeKey(.delete, modifierFlags: [])
        editTextField.typeText(editedTaskTitle + "\n") // Type new title and submit with newline

        // Wait for edit field to disappear and static text to update
        let editFieldDisappearedPredicate = NSPredicate(format: "exists == false")
        let editFieldExpectation = XCTNSPredicateExpectation(predicate: editFieldDisappearedPredicate, object: editTextField)

        let updatedStaticText = app.staticTexts[editedTaskTitle] // Query for the new text
        let updatedTextAppearedPredicate = NSPredicate(format: "exists == true")
        let updatedTextExpectation = XCTNSPredicateExpectation(predicate: updatedTextAppearedPredicate, object: updatedStaticText)

        wait(for: [editFieldExpectation, updatedTextExpectation], timeout: 5)

        // Final verification: Ensure the row now contains the edited text
        let finalTaskRow = findTaskRow(containingText: editedTaskTitle)
        XCTAssertTrue(finalTaskRow.exists, "Task row with edited title '\(editedTaskTitle)' not found.")
        XCTAssertFalse(app.staticTexts[initialTaskTitle].exists, "Task row with initial title '\(initialTaskTitle)' still exists.")
    }

    // MARK: - Helper Extension for Hittable Check with Timeout -
}

extension XCUIElement {
    /// Waits for the element to become hittable within a specified timeout.
    /// - Parameter timeout: The maximum time to wait.
    /// - Returns: `true` if the element becomes hittable within the timeout, `false` otherwise.
    func waitForHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
