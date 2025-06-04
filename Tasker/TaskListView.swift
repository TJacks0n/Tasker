// TaskListView.swift
import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

// Define a UTI for dragging tasks
extension UTType {
    static let taskItem = UTType(exportedAs: "com.github.TJacks0n.Tasker")
}

// 1. Task Data Model
struct Task: Identifiable, Equatable, Codable {
    var id: UUID // Must be var and set manually for Codable to decode
    var title: String
    var isCompleted: Bool = false

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isCompleted == rhs.isCompleted
    }
}

// 2. Task View Model
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var newTaskTitle: String = ""

    /// Adds a new task to the list if the title is not empty.
    func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let newTask = Task(title: trimmedTitle)
        tasks.append(newTask)
        newTaskTitle = ""
    }

    /// Deletes a task from the list.
    func deleteTask(task: Task) {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.id == task.id }
        }
    }

    /// Toggles the completion status of a task.
    func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                tasks[index].isCompleted.toggle()
            }
        }
    }

    /// Removes all completed tasks from the list.
    func removeCompletedTasks() {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.isCompleted }
        }
    }

    /// Clears all tasks from the list.
    func clearList() {
        withAnimation(.interpolatingSpring(stiffness: 80, damping: 7)) {
            tasks.removeAll()
        }
    }

    /// Moves a task to a new position in the list.
    func moveTask(sourceID: UUID, targetID: UUID, moveAbove: Bool) {
        guard let sourceIndex = tasks.firstIndex(where: { $0.id == sourceID }),
              let targetIndex = tasks.firstIndex(where: { $0.id == targetID }) else { return }
        if sourceIndex == targetIndex { return }
        let destinationIndex = moveAbove ? targetIndex : targetIndex + 1
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destinationIndex)
        }
    }
}

// 3. Main Task List View (UI Layout)
struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingClearAlert = false
    @State private var draggedTask: Task?
    @State private var dropTargetInfo: (id: UUID, above: Bool)? = nil
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // --- Input Area ---
            AddTaskView(viewModel: viewModel)
                .environmentObject(settings)
                .padding(.horizontal, settings.rowPadding)
                .padding(.top, settings.rowPadding)
                .padding(.bottom, settings.rowPadding / 2)

            Divider().padding(.horizontal, settings.rowPadding)

            // --- Task List Area ---
            if viewModel.tasks.isEmpty {
                Text("No tasks yet!")
                    .foregroundColor(AppStyle.secondaryTextColor)
                    .font(.system(size: settings.fontSize))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: settings.emptyStateHeight)
                    .frame(minHeight: settings.emptyStateHeight)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach($viewModel.tasks) { $task in
                            VStack(spacing: 0) {
                                // Drop indicator ABOVE
                                Rectangle()
                                    .fill(dropTargetInfo?.id == task.id && dropTargetInfo?.above == true ? settings.accentColor : .clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, settings.rowPadding / 2)

                                // Task row
                                TaskRowView(task: $task, viewModel: viewModel)
                                    .padding(.vertical, settings.rowPadding / 2)
                                    .transition(.scale.combined(with: .opacity))
                                    .onDrag {
                                        self.draggedTask = task
                                        self.dropTargetInfo = nil
                                        return NSItemProvider(object: task.id.uuidString as NSString)
                                    } preview: {
                                        TaskRowView(task: $task, viewModel: viewModel)
                                            .frame(width: settings.listWidth)
                                            .background(AppStyle.backgroundColor)
                                    }
                                    .onDrop(of: [UTType.taskItem, .plainText],
                                            delegate: TaskDropDelegate(
                                                item: task,
                                                tasks: $viewModel.tasks,
                                                draggedItem: $draggedTask,
                                                dropTargetInfo: $dropTargetInfo,
                                                viewModel: viewModel
                                            ))

                                // Drop indicator BELOW
                                Rectangle()
                                    .fill(dropTargetInfo?.id == task.id && dropTargetInfo?.above == false ? settings.accentColor : .clear)
                                    .frame(height: 2)
                                    .padding(.horizontal, settings.rowPadding / 2)
                            }
                        }
                    }
                    .padding(.top, settings.rowPadding)
                }
                .frame(maxHeight: .infinity)
                .scrollContentBackground(.hidden)
            }

            Divider().padding(.horizontal, settings.rowPadding)
            HStack {
                Button("Clear Completed") {
                    viewModel.removeCompletedTasks()
                }
                .font(.system(size: settings.fontSize))
                .padding(.vertical, settings.buttonVerticalPadding)
                .padding(.horizontal, settings.buttonHorizontalPadding)
                .disabled(viewModel.tasks.filter { $0.isCompleted }.isEmpty)
                .accessibilityIdentifier("clearCompletedButton")

                Spacer()

                Button("Clear All") {
                    showingClearAlert = true
                }
                .font(.system(size: settings.fontSize))
                .padding(.vertical, settings.buttonVerticalPadding)
                .padding(.horizontal, settings.buttonHorizontalPadding)
                .disabled(viewModel.tasks.isEmpty)
                .foregroundColor(AppStyle.destructiveColor)
                .accessibilityIdentifier("clearAllButton")
            }
            .padding(.vertical, settings.rowPadding)
            .padding(.horizontal, settings.rowPadding)
        }
        .background(AppStyle.backgroundColor)
        .frame(width: settings.listWidth)
        .font(.system(size: settings.fontSize)) // <-- Apply global font size to all content
        .alert("Clear All Tasks?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                viewModel.clearList()
            }
        } message: {
            Text("Are you sure you want to remove all tasks? This cannot be undone.")
        }
        .onDrop(of: [UTType.taskItem, .plainText], isTargeted: nil) { providers in
            DispatchQueue.main.async {
                self.dropTargetInfo = nil
                self.draggedTask = nil
            }
            return true
        }
    }
}

// 4. Add Task Input View
struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @FocusState private var isInputActive: Bool
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        HStack {
            AccentColorTextField(text: $viewModel.newTaskTitle, onCommit: addTask)
                .frame(height: settings.fontSize + 6)
                .font(.system(size: settings.fontSize))
                .focused($isInputActive)
                .onSubmit(addTask)
                .accessibilityIdentifier("newTaskTextField")
            Button(action: addTask) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: settings.fontSize))
                    .foregroundColor(settings.accentColor)
                    .padding(.vertical, settings.buttonVerticalPadding)
                    .padding(.horizontal, settings.buttonHorizontalPadding)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.newTaskTitle.isEmpty)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputActive = true
            }
        }
    }

    /// Adds a new task using the current input.
    func addTask() {
        let trimmedTitle = viewModel.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let newTask = Task(title: trimmedTitle)
        withAnimation(.interpolatingSpring(stiffness: 80, damping: 7)) {
            viewModel.tasks.append(newTask)
        }
        viewModel.newTaskTitle = ""
    }
}

// 5. Drop Delegate Helper Struct
struct TaskDropDelegate: DropDelegate {
    let item: Task
    @Binding var tasks: [Task]
    @Binding var draggedItem: Task?
    @Binding var dropTargetInfo: (id: UUID, above: Bool)?
    var viewModel: TaskViewModel

    /// Called when the drop location is updated.
    func dropUpdated(info: DropInfo) -> DropProposal? {
        let dropLocation = info.location
        let isAbove = dropLocation.y < 10
        DispatchQueue.main.async {
            self.dropTargetInfo = (item.id, isAbove)
        }
        return DropProposal(operation: .move)
    }

    /// Called when the drag leaves the drop target.
    func dropExited(info: DropInfo) {
        DispatchQueue.main.async {
            if self.dropTargetInfo?.id == item.id {
                self.dropTargetInfo = nil
            }
        }
    }

    /// Handles the drop action.
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem,
              let currentTargetInfo = self.dropTargetInfo,
              currentTargetInfo.id == item.id else {
            self.dropTargetInfo = nil
            self.draggedItem = nil
            return false
        }
        if draggedItem.id != item.id {
            viewModel.moveTask(sourceID: draggedItem.id, targetID: item.id, moveAbove: currentTargetInfo.above)
        }
        self.dropTargetInfo = nil
        self.draggedItem = nil
        return true
    }
}
