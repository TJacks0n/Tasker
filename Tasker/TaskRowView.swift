import SwiftUI

/// Represents a single row displaying a task in the list.
/// Allows toggling completion status, deleting the task, and editing the task title.
struct TaskRowView: View {
    @Binding var task: Task
    @State private var isHovering = false
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool
    var viewModel: TaskViewModel
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        HStack {
            // MARK: - Checkbox Button
            Button {
                viewModel.toggleTaskCompletion(task: task)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(task.isCompleted ? settings.accentColor : AppStyle.secondaryTextColor, lineWidth: 2)
                        .fill(task.isCompleted ? settings.accentColor.opacity(0.2) : AppStyle.secondaryTextColor.opacity(0.2))
                }
                .frame(width: settings.fontSize * 0.92, height: settings.fontSize * 0.92)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("taskRowCheckbox_\(task.id)")

            // MARK: - Task Title / Edit Field
            if isEditing {
                AccentColorTextField(text: $task.title)
                    .frame(height: settings.fontSize + 6)
                    .font(.system(size: settings.fontSize))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(settings.accentColor.opacity(0.1))
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit { endEditing() }
                    .onChange(of: isTextFieldFocused) { oldValue, newValue in
                        if !newValue { endEditing() }
                    }
                    .accessibilityIdentifier("taskRowEditField_\(task.id)")
                Button(action: { endEditing() }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: settings.fontSize * 0.92))
                        .foregroundColor(settings.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("taskRowEditConfirmButton_\(task.id)")
            } else {
                Text(task.title)
                    .font(.system(size: settings.fontSize))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? AppStyle.secondaryTextColor : .primary)
                    .accessibilityIdentifier("taskRowTitle_\(task.id)")
                    .onTapGesture(count: 2) { startEditing() }
            }

            Spacer()

            // MARK: - Delete Button (Conditional)
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
        .padding(.horizontal, settings.rowPadding)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taskRow_\(task.id)")
    }

    private func startEditing() {
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isTextFieldFocused = true
        }
    }

    private func endEditing() {
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
            isEditing = false
        }
    }
}
