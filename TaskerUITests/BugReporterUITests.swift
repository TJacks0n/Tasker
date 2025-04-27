import XCTest

// MARK: - Bug Reporter UI Tests

class BugReporterUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }

    /// Helper to open the bug report menu item
    private func openBugReportMenu() {
        let statusBarItem = app.statusItems.firstMatch
        // Reduced timeout
        XCTAssertTrue(statusBarItem.waitForExistence(timeout: 3), "Status bar item should exist")
        statusBarItem.rightClick()

        let reportMenuItem = app.menuItems["reportBugButton"]
        // Reduced timeout
        XCTAssertTrue(reportMenuItem.waitForExistence(timeout: 1), "Report Bug menu item should exist")
        reportMenuItem.click()

        // Wait for the bug report dialog to appear or become active
        let bugReportDialog = app.dialogs["Report a Bug"]
        let dialogExistsPredicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: dialogExistsPredicate, object: bugReportDialog)
        wait(for: [expectation], timeout: 5)
    }

    /// Tests the flow of successfully submitting a bug report.
    func testBugReportSubmission_Success() throws {
        openBugReportMenu()

        let reportDialog = app.dialogs["Report a Bug"]
        // Reduced timeout
        XCTAssertTrue(reportDialog.waitForExistence(timeout: 5), "Bug report dialog should appear")

        let descriptionTextView = reportDialog.textViews["bugDescriptionTextView"]
        XCTAssertTrue(descriptionTextView.exists)
        let submitButton = reportDialog.buttons["Send Report"]
        XCTAssertTrue(submitButton.exists)

        let testDescription = "UI Test: This is a test bug report."
        descriptionTextView.click()
        descriptionTextView.typeText(testDescription)
        submitButton.click()

        let successDialog = app.dialogs["Report Sent"]
        // Reduced timeout (still needs network time)
        XCTAssertTrue(successDialog.waitForExistence(timeout: 10), "Success alert dialog ('Report Sent') should appear")
        XCTAssertTrue(successDialog.staticTexts["Thank you! Your bug report has been submitted successfully."].exists)
        successDialog.buttons["OK"].click()

        let successDialogDisappearedPredicate = NSPredicate(format: "exists == false")
        // Reduced timeout
        let expectationSuccess = XCTNSPredicateExpectation(predicate: successDialogDisappearedPredicate, object: successDialog)
        wait(for: [expectationSuccess], timeout: 2)
    }

    /// Tests cancelling the bug report dialog.
    func testBugReportCancellation() throws {
        openBugReportMenu()

        let reportDialog = app.dialogs["Report a Bug"]
        // Reduced timeout
        XCTAssertTrue(reportDialog.waitForExistence(timeout: 5), "Bug report dialog should appear")

        let cancelButton = reportDialog.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.click()

        let reportDialogDisappearedPredicate = NSPredicate(format: "exists == false")
        // Reduced timeout
        let expectation = XCTNSPredicateExpectation(predicate: reportDialogDisappearedPredicate, object: reportDialog)
        wait(for: [expectation], timeout: 2)

        XCTAssertFalse(app.dialogs["Report Sent"].exists)
        XCTAssertFalse(app.dialogs["Error"].exists) // Check using the explicit identifier
    }
}
