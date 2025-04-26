import SwiftUI

/// Represents a single row displaying a task in the list.
/// Allows toggling completion status and deleting the task.
struct TaskRowView: View {
    /// A binding to the `Task` object this row represents.
    /// Changes made here (like completion status) will reflect in the source.
    @Binding var task: Task
    /// State variable to track whether the mouse pointer is hovering over the row.
    /// Used to conditionally show the delete button.
    @State private var isHovering = false
    /// The view model containing the business logic for task operations (toggle, delete).
    var viewModel: TaskViewModel

    var body: some View {
        HStack {
            // MARK: - Checkbox Button
            Button {
                // Action to toggle the task's completion status via the view model.
                viewModel.toggleTaskCompletion(task: task)
            } label: {
                // Custom checkbox appearance.
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        // Border color changes based on completion status.
                        .stroke(task.isCompleted ? Color.accentColor : Color.secondary, lineWidth: 2)
                        // Fill color changes based on completion status.
                        .fill(task.isCompleted ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.2))
                }
                .frame(width: 12, height: 12) // Fixed size for the checkbox.
                .contentShape(Rectangle()) // Ensures the tap area covers the frame.
            }
            .buttonStyle(PlainButtonStyle()) // Removes default button styling for a cleaner look.
            .accessibilityIdentifier("taskRowCheckbox_\(task.id)")
            
            // MARK: - Task Title
            Text(task.title)
                // Apply strikethrough effect if the task is completed.
                .strikethrough(task.isCompleted)
                .accessibilityIdentifier("taskRowTitle_\(task.id)")

            Spacer() // Pushes the delete button to the far right.

            // MARK: - Delete Button (Conditional)
            // Only show the delete button when the mouse is hovering over the row.
            if isHovering {
                Button {
                    // Action to delete the task via the view model.
                    viewModel.deleteTask(task: task)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray) // Style the delete icon.
                }
                .buttonStyle(PlainButtonStyle()) // Removes default button styling.
                // Apply a fade transition when the button appears/disappears.
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                .accessibilityIdentifier("taskRowDeleteButton_\(task.id)")
            }
        }
        // Ensure the HStack takes the full available width.
        .frame(maxWidth: .infinity, alignment: .leading)
        // Add horizontal padding to the row content.
        .padding(.horizontal)
        // Make the entire HStack area responsive to hover events.
        .contentShape(Rectangle())
        // Detect hover state changes.
        .onHover { hovering in
            // Animate the change in hover state for a smoother appearance/disappearance
            // of the delete button.
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .contain) // Group elements for accessibility
        .accessibilityIdentifier("taskRow_\(task.id)")
    }
}
