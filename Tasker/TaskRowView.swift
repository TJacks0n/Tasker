import SwiftUI

/// Represents a single row displaying a task in the list.
/// Allows toggling completion status, deleting the task, and editing the task title.
struct TaskRowView: View {
    /// A binding to the `Task` object this row represents.
    /// Changes made here (like completion status or title) will reflect in the source.
    @Binding var task: Task
    /// State variable to track whether the mouse pointer is hovering over the row.
    /// Used to conditionally show the delete button.
    @State private var isHovering = false
    /// State variable to track if the task title is currently being edited.
    @State private var isEditing = false
    /// Controls the focus state of the edit text field.
    @FocusState private var isTextFieldFocused: Bool
    /// The view model containing the business logic for task operations (toggle, delete).
    var viewModel: TaskViewModel
    /// Access global settings for font size, etc.
    @EnvironmentObject var settings: SettingsManager

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
                        .stroke(task.isCompleted ? AppStyle.accentColor : AppStyle.secondaryTextColor, lineWidth: 2)
                        // Fill color changes based on completion status.
                        .fill(task.isCompleted ? AppStyle.accentColor.opacity(0.2) : AppStyle.secondaryTextColor.opacity(0.2))
                }
                .frame(width: 12, height: 12) // Fixed size for the checkbox.
                .contentShape(Rectangle()) // Ensures the tap area covers the frame.
            }
            .buttonStyle(PlainButtonStyle()) // Removes default button styling for a cleaner look.
            .accessibilityIdentifier("taskRowCheckbox_\(task.id)")
            
            // MARK: - Task Title / Edit Field
            if isEditing {
                TextField("Edit task", text: $task.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: settings.fontSize))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(AppStyle.accentColor.opacity(0.1))
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit { // Triggered on Enter/Return key
                        endEditing()
                    }
                    // Detect when focus is lost from the text field
                    .onChange(of: isTextFieldFocused) { oldValue, newValue in
                        // End editing if the text field is no longer focused
                        if !newValue {
                            endEditing()
                        }
                    }
                    .accessibilityIdentifier("taskRowEditField_\(task.id)")

            } else {
                Text(task.title)
                    .font(.system(size: settings.fontSize))
                    // Apply strikethrough effect if the task is completed.
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? AppStyle.secondaryTextColor : .primary)
                    .accessibilityIdentifier("taskRowTitle_\(task.id)")
                    // Allow double-click to edit
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
            }

            Spacer() // Pushes the delete button to the far right.

            // MARK: - Delete Button (Conditional)
            // Only show the delete button when the mouse is hovering over the row.
            if isHovering {
                Button {
                    // Action to delete the task via the view model.
                    viewModel.deleteTask(task: task)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppStyle.secondaryTextColor)
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
        .padding(.horizontal, AppStyle.rowPadding)
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
    
    /// Switches the view to editing mode and focuses the text field.
    private func startEditing() {
        isEditing = true
        // Delay focusing slightly to ensure the TextField is rendered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isTextFieldFocused = true
        }
    }

    /// Switches the view out of editing mode.
    private func endEditing() {
        // Trim whitespace from the edited title before saving
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        // If trimming results in an empty title, consider deleting or reverting (optional)
        // For now, just exit edit mode. An empty title might be valid.
        isEditing = false
    }
}
