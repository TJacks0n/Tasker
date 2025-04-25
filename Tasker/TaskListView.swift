// In TaskListView.swift
import SwiftUI
import Combine
import AppKit // Needed for NSApplication
import UniformTypeIdentifiers // <<< Import for UTIs

// Define a UTI for dragging tasks
extension UTType {
    static let taskItem = UTType(exportedAs: "com.github.TJacks0n.Tasker") // Replace with your identifier
}

// 1. Task Data Model ... (remains the same)
struct Task: Identifiable, Equatable, Codable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isCompleted == rhs.isCompleted
    }
}


// 2. Task View Model ... (remains the same)
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var newTaskTitle: String = ""

    // --- Persistence (Optional: Add load/save logic if needed) ---
    // init() { loadTasks() }
    // func saveTasks() { /* ... */ }
    // func loadTasks() { /* ... */ }
    // --- End Persistence ---

    func addTask() {
        guard !newTaskTitle.isEmpty else { return }
        let newTask = Task(title: newTaskTitle)
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.append(newTask)
        }
        DispatchQueue.main.async { // Clear title after adding
            self.newTaskTitle = ""
        }
        // saveTasks() // Optional: Save after adding
    }

    func deleteTask(task: Task) {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.id == task.id }
        }
        // saveTasks() // Optional: Save after deleting
    }

    func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                tasks[index].isCompleted.toggle()
            }
            // saveTasks() // Optional: Save after toggling
        }
    }

    func removeCompletedTasks() {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.isCompleted }
        }
        // saveTasks() // Optional: Save after removing completed
    }

    func clearList() {
        // No animation needed here if AppDelegate handles size animation
        tasks.removeAll()
        // saveTasks() // Optional: Save after clearing
    }

    // Function to handle moving tasks (used by onDrop)
    func moveTask(sourceTaskID: UUID, destinationTaskID: UUID) {
        guard let sourceIndex = tasks.firstIndex(where: { $0.id == sourceTaskID }),
              let destinationIndex = tasks.firstIndex(where: { $0.id == destinationTaskID }) else {
            print("Error: Could not find source or destination index for move.")
            return
        }

        // Don't move if source and destination are the same
        if sourceIndex == destinationIndex { return }

        // Perform the move
        tasks.move(fromOffsets: IndexSet(integer: sourceIndex), toOffset: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex)
        // saveTasks() // Optional: Save after moving
    }
}


// 3. Main Task List View (UI Layout)
struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingClearAlert = false
    @State private var draggedTask: Task?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // --- Input Area ---
            AddTaskView(viewModel: viewModel)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)

            Divider().padding(.horizontal)

            // --- Spacer Above Task List ---
            Spacer() // <<< Re-add Spacer here

            // --- Task List Area ---
            if viewModel.tasks.isEmpty {
                 Text("No tasks yet!")
                     .foregroundColor(.secondary)
                     .padding()
                     .frame(maxWidth: .infinity, alignment: .center)
                     .frame(height: 60) // Match emptyStateHeight
             } else {
                 ScrollView {
                     LazyVStack(spacing: 0) {
                         ForEach($viewModel.tasks) { $task in
                             TaskRowView(task: $task, viewModel: viewModel)
                                 .padding(.bottom, 5)
                                 .onDrag {
                                     self.draggedTask = task
                                     return NSItemProvider(item: task.id.uuidString as NSSecureCoding, typeIdentifier: UTType.taskItem.identifier)
                                 }
                                 .onDrop(of: [UTType.taskItem.identifier, UTType.plainText.identifier],
                                         delegate: TaskDropDelegate(
                                             item: task,
                                             tasks: $viewModel.tasks,
                                             draggedItem: $draggedTask,
                                             viewModel: viewModel
                                         ))
                         }
                     }
                     .padding(.top, 5) // Match listTopPadding
                 }
                 .frame(maxHeight: .infinity) // <<< Re-add maxHeight modifier
             }

            // --- Spacer Below Task List ---
            Spacer() // <<< Re-add Spacer here

            // --- Footer Area ---
            Divider().padding(.horizontal)
            HStack {
                Button("Clear Completed") {
                    viewModel.removeCompletedTasks()
                }
                .disabled(viewModel.tasks.filter { $0.isCompleted }.isEmpty)

                Spacer()

                Button("Clear All") {
                    showingClearAlert = true
                }
                .disabled(viewModel.tasks.isEmpty)
                .foregroundColor(.red)
            }
            .padding(.vertical, 10) // Keep reduced vertical padding
            .padding(.horizontal)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(width: 300) // Match desiredWidth
        .alert("Clear All Tasks?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                viewModel.clearList()
            }
        } message: {
            Text("Are you sure you want to remove all tasks? This cannot be undone.")
        }
    }
}


// 4. Add Task Input View ... (remains the same)
struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @FocusState private var isInputActive: Bool // To manage focus

    var body: some View {
        HStack {
            TextField("Add a new task...", text: $viewModel.newTaskTitle)
                .textFieldStyle(.plain) // Use plain style for seamless look
                .focused($isInputActive) // Bind focus state
                .onSubmit(addTask) // Add task on Enter/Return key

            Button(action: addTask) {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(PlainButtonStyle()) // Remove default button chrome
            .disabled(viewModel.newTaskTitle.isEmpty) // Disable if text field is empty
        }
        .onAppear {
             // Set focus to the text field when the view appears
             // Delay might be needed depending on popover presentation timing
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                 isInputActive = true
             }
         }
    }

    private func addTask() {
        viewModel.addTask()
        // Keep focus after adding:
        // isInputActive = true
    }
}


// 5. Drop Delegate Helper Struct
struct TaskDropDelegate: DropDelegate {
    let item: Task // The item this delegate instance is associated with
    @Binding var tasks: [Task]
    @Binding var draggedItem: Task?
    var viewModel: TaskViewModel // Reference to call moveTask

    // Action when drop is performed
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = self.draggedItem else {
            print("Drop failed: No dragged item found.")
            return false
        }

        // Ensure we are not dropping onto itself
        if draggedItem.id != item.id {
            print("Moving task \(draggedItem.title) to position of \(item.title)")
            viewModel.moveTask(sourceTaskID: draggedItem.id, destinationTaskID: item.id)
        }

        self.draggedItem = nil // Clear the dragged item state
        return true
    }

    // Optional: Provide visual feedback during drag (e.g., insertion line)
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Indicate that this view can handle the drop operation (move)
        return DropProposal(operation: .move)
    }

    // Optional: Validate if the drop is allowed here
    func validateDrop(info: DropInfo) -> Bool {
        // Ensure the dragged item is of the expected type
        return info.hasItemsConforming(to: [.taskItem, .plainText])
    }
}


// 6. Preview ... (remains the same)
#Preview {
    let previewViewModel = TaskViewModel()
    previewViewModel.tasks = [
        Task(title: "Sample Task 1", isCompleted: false),
        Task(title: "Sample Task 2", isCompleted: true),
        Task(title: "Sample Task 3", isCompleted: false)
    ]
    return TaskListView(viewModel: previewViewModel)
        .frame(width: 300)
}
