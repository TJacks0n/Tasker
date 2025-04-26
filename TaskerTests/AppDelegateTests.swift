import XCTest
@testable import Tasker // Make sure your app target is importable

class AppDelegateTests: XCTestCase {

    var appDelegate: AppDelegate!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Note: Initializing AppDelegate directly might not fully set up
        // UI elements like statusItem or popover as they depend on NSApplication state.
        appDelegate = AppDelegate()
        // Manually initialize the view model if needed for calculations
        appDelegate.taskViewModel = TaskViewModel()
    }

    override func tearDownWithError() throws {
        appDelegate = nil
        try super.tearDownWithError()
    }

    // MARK: - Popover Size Calculation Tests
    
    func testCalculatePopoverSize_ZeroTasks() {
        // Given
        let taskCount = 0
        let expectedBaseHeight = appDelegate.inputAreaHeight + appDelegate.dividerHeight + appDelegate.dividerHeight + appDelegate.footerHeight
        let expectedHeight = expectedBaseHeight + appDelegate.emptyStateHeight
        let expectedSize = NSSize(width: appDelegate.desiredWidth, height: max(expectedHeight, 110)) // Check against min height

        // When
        let calculatedSize = appDelegate.calculatePopoverSize(taskCount: taskCount)

        // Then
        XCTAssertEqual(calculatedSize.width, expectedSize.width, "Width should match desiredWidth.")
        XCTAssertEqual(calculatedSize.height, expectedSize.height, "Height calculation for zero tasks is incorrect.")
    }

    func testCalculatePopoverSize_FewTasks() {
        // Given
        let taskCount = 3
        let expectedBaseHeight = appDelegate.inputAreaHeight + appDelegate.dividerHeight + appDelegate.dividerHeight + appDelegate.footerHeight
        let expectedListHeight = appDelegate.listTopPadding + (CGFloat(taskCount) * appDelegate.taskRowHeight)
        let expectedHeight = expectedBaseHeight + expectedListHeight
        let expectedSize = NSSize(width: appDelegate.desiredWidth, height: max(expectedHeight, 110)) // Check against min height

        // When
        let calculatedSize = appDelegate.calculatePopoverSize(taskCount: taskCount)

        // Then
        XCTAssertEqual(calculatedSize.width, expectedSize.width, "Width should match desiredWidth.")
        XCTAssertEqual(calculatedSize.height, expectedSize.height, "Height calculation for few tasks is incorrect.")
    }

    func testCalculatePopoverSize_ManyTasks_ClampsToMaxHeight() {
        // Given
        // Calculate a task count that *should* exceed the max height based on screen size
        // This requires assumptions about screen height or mocking NSScreen, which is complex.
        // We'll use a very large number to likely trigger clamping.
        let taskCount = 1000
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 700 // Use fallback
        let expectedMaxHeight = screenHeight - 50
        let expectedSize = NSSize(width: appDelegate.desiredWidth, height: expectedMaxHeight)

        // When
        let calculatedSize = appDelegate.calculatePopoverSize(taskCount: taskCount)

        // Then
        XCTAssertEqual(calculatedSize.width, expectedSize.width, "Width should match desiredWidth.")
        // We test that the calculated height does not exceed the expected max height.
        // Direct equality might be fragile due to screen size variations, <= is safer.
        XCTAssertLessThanOrEqual(calculatedSize.height, expectedMaxHeight, "Height should be clamped to the maximum allowed height.")
        // Also check it didn't go below min height (unlikely here, but good practice)
        XCTAssertGreaterThanOrEqual(calculatedSize.height, 110, "Height should not be less than the minimum height.")
    }

    // Note: Testing applicationDidFinishLaunching, togglePopover, showAboutPanel,
    // and updatePopoverSize effectively in unit tests is difficult due to their
    // reliance on NSApplication, UI elements, and asynchronous operations.
    // These often require mocking frameworks or UI testing.
}
