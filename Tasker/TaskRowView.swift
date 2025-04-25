//
//  TaskRowView.swift
//  Tasker
//
//  Created by Thomas Jackson on 25/04/2025.
//

import SwiftUI

struct TaskRowView: View {
    @Binding var task: Task
    @State private var isHovering = false // State to track hover
    var viewModel: TaskViewModel // Pass the view model for actions

    var body: some View {
        HStack {
            // Checkbox Button
            Button(action: {
                viewModel.toggleTaskCompletion(task: task)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(task.isCompleted ? Color.accentColor : Color.secondary, lineWidth: 2)
                        .fill(task.isCompleted ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.2))
                }
                .frame(width: 12, height: 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Task Title
            Text(task.title)
                .strikethrough(task.isCompleted)

            Spacer() // Pushes delete button to the right

            // Delete Button (conditionally visible)
            if isHovering {
                Button {
                    viewModel.deleteTask(task: task)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray) // Style the button
                }
                .buttonStyle(PlainButtonStyle()) // Use plain style to avoid default button appearance
                .transition(.opacity.animation(.easeInOut(duration: 0.1))) // Fade in/out
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .contentShape(Rectangle()) // Ensure the whole HStack detects hover
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { // Animate hover state change
                isHovering = hovering
            }
        }
    }
}
