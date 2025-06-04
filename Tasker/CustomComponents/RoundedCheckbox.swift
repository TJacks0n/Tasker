//
//  RoundedCheckbox.swift
//  Tasker
//
//  Created by Thomas Jackson on 04/06/2025.
//

import SwiftUI

struct RoundedCheckbox: View {
    @Binding var isOn: Bool
    var accentColor: Color
    var size: CGFloat = 22
    var disabled: Bool = false

    @State private var isHovered = false
    @State private var isPressed = false

    // Even more subtle scale for hover/press animation
    private var scale: CGFloat {
        if isPressed { return 0.995 }
        else if isHovered { return 1.005 }
        else { return 1.0 }
    }

    // Slightly lighter highlight color for hover/press
    private var highlightColor: Color {
        if isPressed { return accentColor.opacity(0.13) }
        else if isHovered { return accentColor.opacity(0.07) }
        else { return Color.clear }
    }

    var body: some View {
        Button(action: { if !disabled { isOn.toggle() } }) {
            ZStack {
                // Smaller highlight ring
                if isHovered || isPressed {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(highlightColor)
                        .frame(width: size + 2, height: size + 2)
                        .transition(.opacity)
                }
                // Checkbox background
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isOn ? accentColor : Color.secondary, lineWidth: 2)
                    .fill(isOn ? accentColor.opacity(0.2) : Color.secondary.opacity(0.2))
                // Checkmark
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.6, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
            .opacity(disabled ? 0.5 : 1.0)
            .scaleEffect(scale)
            .animation(
                isPressed
                    ? .easeInOut(duration: 0.10)
                    : isHovered
                        ? .interpolatingSpring(stiffness: 320, damping: 14)
                        : .spring(response: 0.25, dampingFraction: 0.7),
                value: scale
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Checked" : "Unchecked")
        .disabled(disabled)
        .onHover { hovering in
            withAnimation(.interpolatingSpring(stiffness: 320, damping: 14)) {
                isHovered = hovering
            }
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.10)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.10)) { isPressed = false }
        }
    }
}

// Helper modifier for press state tracking
private extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

private struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}
