// In TaskListView.swift
import SwiftUI
import Combine
import AppKit // Needed for NSApplication
import UniformTypeIdentifiers // <<< Import for UTIs

// Define a UTI for dragging tasks
extension UTType {
    static let taskItem = UTType(exportedAs: "com.github.TJacks0n.Tasker") // Replace with your identifier
}

// 1. Task Data Model
/// Represents a single task item in the list.
///
/// Conforms to `Identifiable` for use in SwiftUI lists, `Equatable` for comparisons (e.g., finding index),
/// and `Codable` for potential persistence (saving/loading).
struct Task: Identifiable, Equatable, Codable {
    /// A unique identifier for the task, automatically generated.
    let id = UUID()
    /// The text content or description of the task.
    var title: String
    /// A Boolean value indicating whether the task has been completed. Defaults to `false`.
    var isCompleted: Bool = false

    /// Compares two `Task` instances for equality based on their `id`, `title`, and `isCompleted` status.
    /// - Parameters:
    ///   - lhs: The left-hand side `Task` to compare.
    ///   - rhs: The right-hand side `Task` to compare.
    /// - Returns: `true` if the tasks have the same `id`, `title`, and `isCompleted` status; otherwise, `false`.
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isCompleted == rhs.isCompleted
    }
}

// 2. Task View Model
/// Manages the state and logic for the list of tasks.
///
/// This class conforms to `ObservableObject` to allow SwiftUI views to react to changes
/// in the task list (`tasks`) or the new task input (`newTaskTitle`).
class TaskViewModel: ObservableObject {
    /// The array of `Task` items currently being managed. Marked with `@Published` so
    /// SwiftUI views observing this view model will automatically update when the array changes.
    @Published var tasks: [Task] = []
    /// The string bound to the text field used for adding new tasks. Marked with `@Published`
    /// to enable two-way binding with the input field.
    @Published var newTaskTitle: String = ""

    /// Adds a new task to the list based on the current `newTaskTitle`.
    ///
    /// If `newTaskTitle` is empty, the function does nothing. Otherwise, it creates a new `Task`,
    /// appends it to the `tasks` array with an animation, and clears `newTaskTitle`.
    func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return } // Don't add empty tasks

        let newTask = Task(title: trimmedTitle)
        tasks.append(newTask)
        newTaskTitle = "" // <-- Add this line to clear the input field
    }

    /// Deletes a specific task from the list.
    /// - Parameter task: The `Task` instance to remove.
    ///
    /// Removes the task matching the provided `task.id` from the `tasks` array with an animation.
    func deleteTask(task: Task) {
        // Animate the removal of the task.
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.id == task.id }
        }
    }

    /// Toggles the completion status (`isCompleted`) of a specific task.
    /// - Parameter task: The `Task` whose completion status should be toggled.
    ///
    /// Finds the task by its `id` and flips its `isCompleted` boolean value with an animation.
    func toggleTaskCompletion(task: Task) {
        // Find the index of the task to toggle.
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Animate the change in completion status.
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                tasks[index].isCompleted.toggle()
            }
        }
    }

    /// Removes all tasks marked as completed (`isCompleted == true`) from the list.
    ///
    /// Filters the `tasks` array, keeping only the tasks that are not completed, with an animation.
    func removeCompletedTasks() {
        // Animate the removal of completed tasks.
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.isCompleted }
        }
    }

    /// Removes all tasks from the list, regardless of their completion status.
    ///
    /// This typically does not require animation if the containing view (e.g., popover) handles resizing.
    func clearList() {
        tasks.removeAll()
    }

    /// Moves a task from a source position to a target position within the list.
    /// Used for drag-and-drop reordering.
    /// - Parameters:
    ///   - sourceID: The `UUID` of the task being moved.
    ///   - targetID: The `UUID` of the task relative to which the source task is being dropped.
    ///   - moveAbove: A Boolean indicating whether the source task should be placed above (`true`)
    ///                or below (`false`) the target task.
    ///
    /// Calculates the correct source and destination indices and uses `tasks.move`
    /// to reorder the array with an animation.
    func moveTask(sourceID: UUID, targetID: UUID, moveAbove: Bool) {
            // Find the indices of the source (dragged) and target (drop) tasks.
            guard let sourceIndex = tasks.firstIndex(where: { $0.id == sourceID }),
                  let targetIndex = tasks.firstIndex(where: { $0.id == targetID }) else {
                print("Error: Could not find source or target index for move.")
                return
            }

            // Prevent moving an item onto itself.
            if sourceIndex == targetIndex { return }

            // Determine the offset for the `tasks.move` function.
            // If dropping *above* the target, the destination offset is the target's index.
            // If dropping *below* the target, the destination offset is the target's index + 1.
            let destinationIndex = moveAbove ? targetIndex : targetIndex + 1

            // Perform the move operation with animation.
            // `tasks.move` handles the index adjustments internally.
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                 tasks.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destinationIndex)
            }
        }
}


// 3. Main Task List View (UI Layout)
/// The primary SwiftUI view that displays the list of tasks, input field, and control buttons.
struct TaskListView: View {
    /// The view model containing the task data and logic. Observed for changes.
    @ObservedObject var viewModel: TaskViewModel
    /// State variable to control the presentation of the "Clear All" confirmation alert.
    @State private var showingClearAlert = false
    /// State variable to hold the `Task` currently being dragged (if any).
    @State private var draggedTask: Task?
    /// State variable to track the potential drop target task's ID and whether the drop
    /// is intended for above or below that task. Used for visual feedback.
    @State private var dropTargetInfo: (id: UUID, above: Bool)? = nil

    var body: some View {
        // Main vertical stack for the entire view content.
        VStack(alignment: .leading, spacing: 0) {
            // --- Input Area ---
            // View containing the text field and button for adding new tasks.
            AddTaskView(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)

            // Visual separator below the input area.
            Divider().padding(.horizontal)

            // --- Task List Area ---
            // Conditionally display either the task list or an empty state message.
            if viewModel.tasks.isEmpty {
                 // Message shown when there are no tasks.
                 Text("No tasks yet!")
                     .foregroundColor(.secondary)
                     .padding()
                     .frame(maxWidth: .infinity, alignment: .center)
                     .frame(height: 60) // Ensure empty state has some height
                     .frame(minHeight: 60) // Explicit min height
             } else {
                 // Scrollable container for the list of tasks.
                 ScrollView {
                     // Lazily loads task rows as they become visible.
                     LazyVStack(spacing: 0) {
                         // Iterate over the tasks in the view model.
                         ForEach($viewModel.tasks) { $task in
                             // Vertical stack for each task row and its associated drop indicators.
                             VStack(spacing: 0) {
                                 // --- Drop indicator ABOVE the task row ---
                                 // Visible only when dragging over the top half of the row.
                                 Rectangle()
                                     .fill(dropTargetInfo?.id == task.id && dropTargetInfo?.above == true ? Color.accentColor : Color.clear)
                                     .frame(height: 2)
                                     .padding(.horizontal, 5) // Indent slightly

                                 // The view representing a single task row.
                                 TaskRowView(task: $task, viewModel: viewModel)
                                     .padding(.vertical, 2) // Add slight vertical padding around row
                                     // --- Drag Source ---
                                     // Makes the TaskRowView draggable.
                                     .onDrag {
                                         self.draggedTask = task // Store the task being dragged.
                                         self.dropTargetInfo = nil // Clear drop target when starting a new drag.
                                         // Provide the task's ID as the draggable data.
                                         return NSItemProvider(object: task.id.uuidString as NSString)
                                     } preview: {
                                         // Optional: Custom view shown while dragging.
                                         TaskRowView(task: $task, viewModel: viewModel)
                                             .frame(width: 280) // Match list width approx
                                             .background(.background) // Use a background for preview
                                     }
                                     // --- Drop Target ---
                                     // Makes the TaskRowView accept drops.
                                     .onDrop(of: [UTType.taskItem, .plainText], // Accepts custom task type or plain text UUID.
                                             delegate: TaskDropDelegate( // Uses a delegate to handle drop logic.
                                                 item: task, // The task associated with this drop target.
                                                 tasks: $viewModel.tasks, // Binding to the tasks array.
                                                 draggedItem: $draggedTask, // Binding to the currently dragged task.
                                                 dropTargetInfo: $dropTargetInfo, // Binding to the drop target state.
                                                 viewModel: viewModel // Reference to the view model for moving tasks.
                                             ))

                                 // --- Drop indicator BELOW the task row ---
                                 // Visible only when dragging over the bottom half of the row.
                                 Rectangle()
                                     .fill(dropTargetInfo?.id == task.id && dropTargetInfo?.above == false ? Color.accentColor : Color.clear)
                                     .frame(height: 2)
                                     .padding(.horizontal, 5) // Indent slightly
                             }
                         }
                     }
                     .padding(.top, 5) // Padding above the list content
                 }
                 .frame(maxHeight: .infinity) // Allow scrollview to take available space
                 .scrollContentBackground(.hidden) // Make ScrollView background transparent if needed
             }

            // --- Footer Area ---
            // Visual separator above the footer buttons.
            Divider().padding(.horizontal)
            // Horizontal stack for the action buttons at the bottom.
            HStack {
                // Button to remove all completed tasks.
                Button("Clear Completed") {
                    viewModel.removeCompletedTasks()
                }
                // Disabled if there are no completed tasks.
                .disabled(viewModel.tasks.filter { $0.isCompleted }.isEmpty)
                .accessibilityIdentifier("clearCompletedButton")

                Spacer() // Pushes buttons to opposite ends.

                // Button to remove all tasks.
                Button("Clear All") {
                    showingClearAlert = true // Shows the confirmation alert.
                }
                // Disabled if the task list is empty.
                .disabled(viewModel.tasks.isEmpty)
                .foregroundColor(.red) // Indicates a potentially destructive action.
                .accessibilityIdentifier("clearAllButton")
            }
            .padding(.vertical, 10)
            .padding(.horizontal)
        }
        .background(Color(nsColor: .windowBackgroundColor)) // Set the background for the entire view.
        .frame(width: 300) // Define a fixed width for the view.
        // --- Alert ---
        // Confirmation dialog for the "Clear All" action.
        .alert("Clear All Tasks?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { } // Dismisses the alert.
            Button("Clear All", role: .destructive) { // Performs the clear action.
                viewModel.clearList()
            }
        } message: {
            Text("Are you sure you want to remove all tasks? This cannot be undone.")
        }
        // --- Global Drop Target ---
        // Handles drops that occur outside of any specific TaskRowView within the VStack.
        .onDrop(of: [UTType.taskItem, .plainText], isTargeted: nil) { providers in
             print("Dropped outside valid area")
             // Clear drag/drop state if the drop doesn't land on a valid row target.
             DispatchQueue.main.async {
                 self.dropTargetInfo = nil
                 self.draggedTask = nil
             }
             // Indicate that the drop was handled (by clearing state), preventing propagation.
             return true
         }
    }
}

// 4. Add Task Input View
/// A view component containing a text field and a button for adding new tasks.
struct AddTaskView: View {
    /// The view model that manages the task list and the new task title.
    @ObservedObject var viewModel: TaskViewModel
    /// Controls the focus state of the text field. True when the field is focused.
    @FocusState private var isInputActive: Bool

    var body: some View {
        // Horizontal stack for the text field and add button.
        HStack {
            // Text field for entering the new task title.
            TextField("Add a new task...", text: $viewModel.newTaskTitle)
                .textFieldStyle(.plain) // Use plain style for a seamless look within the list context.
                .focused($isInputActive) // Bind the focus state to the isInputActive property.
                .onSubmit(addTask) // Call addTask when the user presses Enter/Return.
                .accessibilityIdentifier("newTaskTextField")

            // Button to trigger adding the task.
            Button(action: addTask) {
                Image(systemName: "plus.circle.fill") // Standard SF Symbol for adding.
            }
            .buttonStyle(PlainButtonStyle()) // Remove default button styling for a cleaner look.
            .disabled(viewModel.newTaskTitle.isEmpty) // Disable the button if the text field is empty.
        }
        .onAppear {
             // Set focus to the text field automatically when the view appears.
             // A slight delay might be necessary depending on view presentation timing (e.g., in a popover).
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 isInputActive = true
             }
         }
    }

    /// Helper function called when the add button is tapped or the text field is submitted.
    /// It delegates the actual task addition logic to the view model.
    private func addTask() {
        viewModel.addTask()
        // Optional: Uncomment the line below if you want the text field to remain focused after adding a task.
        //isInputActive = true
    }
}

// 5. Drop Delegate Helper Struct
/// Implements the `DropDelegate` protocol to handle drag-and-drop operations for `Task` items
/// within the `TaskListView`. Each `TaskRowView` gets an instance of this delegate.
struct TaskDropDelegate: DropDelegate {
    /// The specific `Task` item associated with the view this delegate instance is attached to.
    /// This represents the potential drop target.
    let item: Task
    /// A binding to the array of `Task` objects in the `TaskViewModel`. Allows the delegate
    /// to modify the task order upon a successful drop.
    @Binding var tasks: [Task]
    /// A binding to the optional `Task` that is currently being dragged. This state is shared
    /// across all drop delegates in the list. `nil` if no drag is in progress.
    @Binding var draggedItem: Task?
    /// A binding to the shared state that tracks which task (`id`) is the current drop target
    /// and whether the drop indicator should appear above (`true`) or below (`false`) it.
    /// `nil` if the cursor is not over a valid drop target area.
    @Binding var dropTargetInfo: (id: UUID, above: Bool)?
    /// A reference to the `TaskViewModel` to call the `moveTask` function for reordering.
    var viewModel: TaskViewModel

    /// Called repeatedly while a dragged item is over the delegate's view.
    /// Determines the drop position (above/below the `item`) based on the cursor's location
    /// and updates the shared `dropTargetInfo` state to provide visual feedback (the drop indicator line).
    /// - Parameter info: Contains information about the drag operation, including cursor location.
    /// - Returns: A `DropProposal` indicating the type of operation allowed (in this case, `.move`).
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Determine if the drop location is in the top or bottom half of the row's frame.
        let dropLocation = info.location
        // Approximation: Assume drop is above if y-coordinate is less than a threshold (e.g., 10).
        // A more precise method might involve GeometryReader in the TaskRowView.
        let isAbove = dropLocation.y < 10 // Adjust this threshold based on row padding/height.

        // Update the shared state on the main thread for UI updates.
        DispatchQueue.main.async {
            self.dropTargetInfo = (item.id, isAbove)
        }

        // Propose a 'move' operation.
        return DropProposal(operation: .move)
    }

    /// Called when the dragged item exits the bounds of the delegate's view.
    /// Clears the `dropTargetInfo` if it was previously set for this specific `item`.
    /// - Parameter info: Contains information about the drag operation.
    func dropExited(info: DropInfo) {
        // If the cursor is leaving *this* item's area, clear its target status.
        DispatchQueue.main.async {
            if self.dropTargetInfo?.id == item.id {
                self.dropTargetInfo = nil
            }
        }
    }

    /// Called when the user releases the dragged item over the delegate's view.
    /// Performs the actual reordering of the task list.
    /// - Parameter info: Contains information about the drop operation.
    /// - Returns: `true` if the drop was successfully handled, `false` otherwise.
    func performDrop(info: DropInfo) -> Bool {
        // Ensure there is a dragged item and the drop target info matches this item.
        guard let draggedItem = self.draggedItem,
              let currentTargetInfo = self.dropTargetInfo,
              currentTargetInfo.id == item.id else {
            print("Drop failed: No dragged item or target info mismatch.")
            // Clear potentially stale state on failure.
            self.dropTargetInfo = nil
            self.draggedItem = nil
            return false
        }

        // Prevent dropping an item onto itself (though moveTask also checks).
        if draggedItem.id != item.id {
            print("Moving task \(draggedItem.title) \(currentTargetInfo.above ? "above" : "below") \(item.title)")
            // Call the view model's function to move the task, using the 'above' flag from the state.
            viewModel.moveTask(sourceID: draggedItem.id, targetID: item.id, moveAbove: currentTargetInfo.above)
        }

        // Clear the drag/drop states after a successful or self-drop.
        self.dropTargetInfo = nil
        self.draggedItem = nil
        return true
    }

    /// Called first to determine if the delegate's view can accept the drop.
    /// Checks if the dragged item conforms to the expected `UTType.taskItem`.
    /// - Parameter info: Contains information about the drag operation, including the item types.
    /// - Returns: `true` if the dragged item is a valid `Task`, `false` otherwise.
    func validateDrop(info: DropInfo) -> Bool {
        // Allow the drop only if the dragged item conforms to our custom task UTI.
        return info.hasItemsConforming(to: [UTType.taskItem])
    }
}

// 6. Preview
#Preview {
    // Create a view model instance specifically for the preview
    let previewViewModel = TaskViewModel()
    // Populate with sample data for the preview
    previewViewModel.tasks = [
        Task(title: "Review Code", isCompleted: false),
        Task(title: "Implement Feature X", isCompleted: true),
        Task(title: "Write Unit Tests", isCompleted: false),
        Task(title: "Deploy to Staging", isCompleted: false)
    ]
    // Return the view, passing the preview view model
    return TaskListView(viewModel: previewViewModel)
        .frame(width: 300) // Apply the expected frame for accurate layout
}
