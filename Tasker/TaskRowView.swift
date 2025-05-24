import SwiftUI

/// Represents a single row displaying a task in the list.
/// Allows toggling completion status, deleting the task, and editing the task title.
struct TaskRowView: View {
    /// A binding to the `Task` object this row represents.
    @Binding var task: Task
    /// State variable to track whether the mouse pointer is hovering over the row.
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
                // Toggle the task's completion status via the view model.
                viewModel.toggleTaskCompletion(task: task)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(task.isCompleted ? AppStyle.accentColor : AppStyle.secondaryTextColor, lineWidth: 2)
                        .fill(task.isCompleted ? AppStyle.accentColor.opacity(0.2) : AppStyle.secondaryTextColor.opacity(0.2))
                }
                .frame(width: settings.fontSize * 0.92, height: settings.fontSize * 0.92)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("taskRowCheckbox_\(task.id)")

            // MARK: - Task Title / Edit Field
            if isEditing {
                // Show editable text field when editing
                AccentColorTextField(text: $task.title)
                    .frame(height: settings.fontSize + 6)
                    .font(.system(size: settings.fontSize))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(AppStyle.accentColor.opacity(0.1))
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit { endEditing() }
                    .onChange(of: isTextFieldFocused) { oldValue, newValue in
                        if !newValue { endEditing() }
                    }
                    .accessibilityIdentifier("taskRowEditField_\(task.id)")
            } else {
                // Show static text when not editing
                Text(task.title)
                    .font(.system(size: settings.fontSize))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? AppStyle.secondaryTextColor : .primary)
                    .accessibilityIdentifier("taskRowTitle_\(task.id)")
                    .onTapGesture(count: 2) { startEditing() }
            }

            Spacer()

            // MARK: - Delete Button (Conditional)
            // Only show the delete button when hovering and not editing
            if isHovering && !isEditing {
                Button {
                    viewModel.deleteTask(task: task)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: settings.fontSize * 0.92))
                        .foregroundColor(AppStyle.secondaryTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity.animation(.easeInOut(duration: 0.1)))
                .accessibilityIdentifier("taskRowDeleteButton_\(task.id)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppStyle.rowPadding)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taskRow_\(task.id)")
    }

    /// Switches the view to editing mode and focuses the text field.
    private func startEditing() {
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isTextFieldFocused = true
        }
    }

    /// Switches the view out of editing mode.
    private func endEditing() {
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditing = false
    }
}
