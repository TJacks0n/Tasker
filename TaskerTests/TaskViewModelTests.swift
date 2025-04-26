import XCTest
@testable import Tasker

class TaskViewModelTests: XCTestCase {

    var viewModel: TaskViewModel!

    // Set up a fresh view model before each test
    override func setUp() {
        super.setUp()
        viewModel = TaskViewModel()
    }

    // Clean up after each test
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // Test adding a task with a non-empty title
    func testAddTask_WithNonEmptyTitle_AddsTaskAndClearsTitle() {
        // Given
        viewModel.newTaskTitle = "Test Task 1"
        let initialCount = viewModel.tasks.count

        // When
        viewModel.addTask()

        // Then
        XCTAssertEqual(viewModel.tasks.count, initialCount + 1, "Task count should increase by 1.")
        XCTAssertEqual(viewModel.tasks.last?.title, "Test Task 1", "The last task should have the correct title.")
        XCTAssertTrue(viewModel.newTaskTitle.isEmpty, "newTaskTitle should be cleared after adding.")
    }

    // Test adding a task with an empty title
    func testAddTask_WithEmptyTitle_DoesNotAddTask() {
        // Given
        viewModel.newTaskTitle = ""
        let initialCount = viewModel.tasks.count

        // When
        viewModel.addTask()

        // Then
        XCTAssertEqual(viewModel.tasks.count, initialCount, "Task count should not change when title is empty.")
    }

    // Test deleting a specific task
    func testDeleteTask_RemovesCorrectTask() {
        // Given
        let task1 = Task(title: "Task to Delete")
        let task2 = Task(title: "Task to Keep")
        viewModel.tasks = [task1, task2]
        let initialCount = viewModel.tasks.count

        // When
        viewModel.deleteTask(task: task1)

        // Then
        XCTAssertEqual(viewModel.tasks.count, initialCount - 1, "Task count should decrease by 1.")
        XCTAssertFalse(viewModel.tasks.contains(where: { $0.id == task1.id }), "Deleted task should be removed.")
        XCTAssertTrue(viewModel.tasks.contains(where: { $0.id == task2.id }), "Other tasks should remain.")
    }

    // Test toggling the completion status of a task
    func testToggleTaskCompletion_FlipsIsCompleted() {
        // Given
        let task = Task(title: "Task to Toggle", isCompleted: false)
        viewModel.tasks = [task]

        // When
        viewModel.toggleTaskCompletion(task: task)

        // Then
        XCTAssertTrue(viewModel.tasks.first?.isCompleted ?? false, "Task should be marked as completed.")

        // When toggled again
        viewModel.toggleTaskCompletion(task: viewModel.tasks.first!) // Use the updated task from the array

        // Then
        XCTAssertFalse(viewModel.tasks.first?.isCompleted ?? true, "Task should be marked as not completed.")
    }

    // Test removing only completed tasks
    func testRemoveCompletedTasks_RemovesOnlyCompleted() {
        // Given
        let task1 = Task(title: "Incomplete", isCompleted: false)
        let task2 = Task(title: "Completed", isCompleted: true)
        let task3 = Task(title: "Another Incomplete", isCompleted: false)
        viewModel.tasks = [task1, task2, task3]

        // When
        viewModel.removeCompletedTasks()

        // Then
        XCTAssertEqual(viewModel.tasks.count, 2, "Only incomplete tasks should remain.")
        XCTAssertTrue(viewModel.tasks.contains(where: { $0.id == task1.id }))
        XCTAssertFalse(viewModel.tasks.contains(where: { $0.id == task2.id }))
        XCTAssertTrue(viewModel.tasks.contains(where: { $0.id == task3.id }))
    }

    // Test clearing all tasks
    func testClearList_RemovesAllTasks() {
        // Given
        viewModel.tasks = [Task(title: "Task 1"), Task(title: "Task 2")]

        // When
        viewModel.clearList()

        // Then
        XCTAssertTrue(viewModel.tasks.isEmpty, "Task list should be empty after clearing.")
    }

    // Test moving a task above another task
    func testMoveTask_ReordersTasksCorrectly_MoveAbove() {
        // Given
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")
        let task3 = Task(title: "Task 3")
        viewModel.tasks = [task1, task2, task3] // Initial order: 1, 2, 3

        // When: Move task 3 above task 2
        viewModel.moveTask(sourceID: task3.id, targetID: task2.id, moveAbove: true)

        // Then: Expected order: 1, 3, 2
        XCTAssertEqual(viewModel.tasks.map { $0.id }, [task1.id, task3.id, task2.id], "Tasks should be reordered correctly (move above).")
    }

    // Test moving a task below another task
    func testMoveTask_ReordersTasksCorrectly_MoveBelow() {
        // Given
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")
        let task3 = Task(title: "Task 3")
        viewModel.tasks = [task1, task2, task3] // Initial order: 1, 2, 3

        // When: Move task 1 below task 2
        viewModel.moveTask(sourceID: task1.id, targetID: task2.id, moveAbove: false)

        // Then: Expected order: 2, 1, 3
        XCTAssertEqual(viewModel.tasks.map { $0.id }, [task2.id, task1.id, task3.id], "Tasks should be reordered correctly (move below).")
    }

    // Test moving with invalid source ID
    func testMoveTask_WithInvalidSourceID_DoesNothing() {
        // Given
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")
        viewModel.tasks = [task1, task2]
        let initialOrder = viewModel.tasks.map { $0.id }
        let invalidSourceID = UUID() // A random, non-existent ID

        // When
        viewModel.moveTask(sourceID: invalidSourceID, targetID: task2.id, moveAbove: true)

        // Then
        XCTAssertEqual(viewModel.tasks.map { $0.id }, initialOrder, "Task order should not change with invalid source ID.")
    }

    // Test moving with invalid target ID
    func testMoveTask_WithInvalidTargetID_DoesNothing() {
        // Given
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")
        viewModel.tasks = [task1, task2]
        let initialOrder = viewModel.tasks.map { $0.id }
        let invalidTargetID = UUID() // A random, non-existent ID

        // When
        viewModel.moveTask(sourceID: task1.id, targetID: invalidTargetID, moveAbove: true)

        // Then
        XCTAssertEqual(viewModel.tasks.map { $0.id }, initialOrder, "Task order should not change with invalid target ID.")
    }

    // Test moving a task onto itself
    func testMoveTask_SourceEqualsTarget_DoesNothing() {
        // Given
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")
        viewModel.tasks = [task1, task2]
        let initialOrder = viewModel.tasks.map { $0.id }

        // When: Attempt to move task1 relative to itself
        viewModel.moveTask(sourceID: task1.id, targetID: task1.id, moveAbove: true)

        // Then
        XCTAssertEqual(viewModel.tasks.map { $0.id }, initialOrder, "Task order should not change when source equals target.")
    }
}
