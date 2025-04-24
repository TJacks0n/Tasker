//
//  TaskListView.swift
//  Tasker
//
//  Created by Thomas Jackson on 24/04/2025.
//
import SwiftUI
import Combine

struct Task: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var newTaskTitle: String = ""

    func addTask() {
        guard !newTaskTitle.isEmpty else {
            print("Task title is empty. Task not added.")
            return
        }
        let newTask = Task(title: newTaskTitle)
        tasks.append(newTask)
        print("Task added: \(newTask.title)")
        DispatchQueue.main.async {
            self.newTaskTitle = "" // Clear the title immediately to prevent duplicate commits
        }
        schedulePopoverSizeUpdate()
    }

    func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            schedulePopoverSizeUpdate()
        }
    }

    func removeCompletedTasks() {
        tasks.removeAll { $0.isCompleted }
        schedulePopoverSizeUpdate()
    }

    private var appDelegate: AppDelegate? {
        NSApplication.shared.delegate as? AppDelegate
    }

    private func schedulePopoverSizeUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.updatePopoverSize()
        }
    }

    func updatePopoverSize() {
        guard let popover = appDelegate?.popover else { return }

        let baseHeight: CGFloat = 70
        let rowHeight: CGFloat = 30
        let newHeight = baseHeight + CGFloat(tasks.count) * rowHeight + 20
        let maxHeight: CGFloat = 700
        popover.contentSize = NSSize(width: 300, height: min(newHeight, maxHeight))
    }
    
    func clearList() {
        tasks.removeAll()
        schedulePopoverSizeUpdate()
    }

    init() {
        $tasks
            .dropFirst()
            .sink { [weak self] _ in
                self?.schedulePopoverSizeUpdate()
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel

    var body: some View {
        VStack {
            TextField("Add New Task", text: $viewModel.newTaskTitle, onCommit: {
                viewModel.addTask()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            VStack(spacing: 10) {
                ForEach(viewModel.tasks) { task in
                    HStack {
                        Button(action: {
                            viewModel.toggleTaskCompletion(task: task)
                        }) {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(task.title)
                            .strikethrough(task.isCompleted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            HStack {
                Button("Remove Completed Tasks") {
                    viewModel.removeCompletedTasks()
                }
                .padding()

                Button("Clear List") {
                    viewModel.clearList()
                }
                .padding()
            }
        }
        .frame(width: 300)
    }
}
