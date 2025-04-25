//
//  TaskListView.swift
//  Tasker
//
//  Created by Thomas Jackson on 24/04/2025.
//
import SwiftUI
import Combine
import AppKit

struct Task: Identifiable, Equatable { // Add Equatable
    let id = UUID()
    var title: String
    var isCompleted: Bool = false

    // Add the Equatable requirement implementation
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isCompleted == rhs.isCompleted
    }
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
        // Use a spring animation
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.append(newTask)
        }
        print("Task added: \(newTask.title)")
        DispatchQueue.main.async {
            self.newTaskTitle = ""
        }
        schedulePopoverSizeUpdate()
    }
    
    // Add this method inside TaskViewModel class
    func deleteTask(task: Task) {
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.id == task.id }
        }
        schedulePopoverSizeUpdate()
    }

    func toggleTaskCompletion(task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            // Use a spring animation
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                tasks[index].isCompleted.toggle()
            }
            schedulePopoverSizeUpdate()
        }
    }

    func removeCompletedTasks() {
        // Use spring animation again
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            tasks.removeAll { $0.isCompleted }
        }
        schedulePopoverSizeUpdate()
    }

    func clearList() {
        // Remove the withAnimation block here
        tasks.removeAll()
        // Rely on the popover size update animation
        schedulePopoverSizeUpdate()
    }
    
    private var appDelegate: AppDelegate? {
        NSApplication.shared.delegate as? AppDelegate
    }

     func schedulePopoverSizeUpdate() {
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
        let finalSize = NSSize(width: 300, height: min(newHeight, maxHeight))

        // Animate the popover's size change by setting the property directly
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2 // Adjust duration as needed
            context.allowsImplicitAnimation = true // This enables the animation
            // Set the contentSize directly
            popover.contentSize = finalSize
        }, completionHandler: nil)
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
            .padding(.horizontal)
            .padding(.top, 10)

            Divider()
                .padding(.vertical, 2)

            // Use ScrollView for potentially long lists
            ScrollView {
                VStack(spacing: 10) {
                    // Use TaskRowView in ForEach
                    ForEach($viewModel.tasks) { $task in
                        TaskRowView(task: $task, viewModel: viewModel)
                    }
                    // Apply animation to the container of rows
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: viewModel.tasks)
                }
                .padding(.top, 5) // Add some padding above the list
            }
            .frame(maxHeight: .infinity, alignment: .top) // Allow ScrollView to take available space


            HStack {
                Button("Remove Completed") {
                    viewModel.removeCompletedTasks()
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary) // Keep secondary tint or change as needed
                .padding(.leading)

                Spacer()

                Button("Clear List") {
                    viewModel.clearList()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .padding(.trailing)
            }
            .padding(.top, 5)
             .padding(.bottom, 10)
             .padding(.horizontal)
        }
        .frame(width: 300) // Keep the overall frame
    }
}
