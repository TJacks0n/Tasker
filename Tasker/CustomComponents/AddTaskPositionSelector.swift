//  AddTaskPositionSelector.swift
//  Tasker
//
//  Created by Thomas Jackson on 04/06/2025.
//

import SwiftUI

/// Selector for choosing where new tasks are added (top or bottom of the list).
struct AddTaskPositionSelector: View {
    @Binding var selection: AddTaskPosition
    @EnvironmentObject var settings: SettingsManager
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 16) {
            ForEach(AddTaskPosition.allCases) { position in
                AddTaskPositionButton(
                    position: position,
                    isSelected: selection == position,
                    accentColor: settings.accentColor,
                    fontSize: settings.fontSize,
                    horizontalPadding: settings.buttonHorizontalPadding,
                    onSelect: {
                        withAnimation(.interpolatingSpring(stiffness: 220, damping: 18)) {
                            selection = position
                        }
                    },
                    selectionNamespace: selectionNamespace
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Button for a single add-task position option (top or bottom).
private struct AddTaskPositionButton: View {
    let position: AddTaskPosition
    let isSelected: Bool
    let accentColor: Color
    let fontSize: CGFloat
    let horizontalPadding: CGFloat
    let onSelect: () -> Void
    var selectionNamespace: Namespace.ID

    @State private var isHovered = false

    // Consistent height and min width for both states
    private let buttonHeight: CGFloat = 28
    private let minButtonWidth: CGFloat = 64

    /// Returns the display text for each position.
    private var positionText: String {
        switch position {
        case .top: return "Top"
        case .bottom: return "Bottom"
        }
    }

    /// Highlight color for hover/selection states.
    var highlightColor: Color {
        if isSelected {
            isHovered ? accentColor.opacity(0.22) : accentColor.opacity(0.15)
        } else {
            isHovered ? Color.secondary.opacity(0.13) : Color.clear
        }
    }

    /// Scale effect for hover animation.
    var scale: CGFloat {
        isHovered ? 1.07 : 1.0
    }

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor)
                        .matchedGeometryEffect(id: "selectorBackground", in: selectionNamespace)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(highlightColor)
                }
                // Use positionText instead of rawValue (which is now Int)
                Text(positionText)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: buttonHeight)
            .frame(minWidth: minButtonWidth)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(scale)
            .animation(
                isHovered
                    ? .interpolatingSpring(stiffness: 220, damping: 18)
                    : .spring(response: 0.25, dampingFraction: 0.7),
                value: scale
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 18)) {
                isHovered = hovering
            }
        }
    }
}
