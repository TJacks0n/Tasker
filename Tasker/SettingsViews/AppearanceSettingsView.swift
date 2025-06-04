//  AppearanceSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI
import AppKit

// Notification for font size commit (used to trigger window resize)
extension Notification.Name {
    static let settingsFontSizeDidCommit = Notification.Name("settingsFontSizeDidCommit")
}

// Custom button style for accent color selection (unchanged)
struct AccentColorButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        AccentColorButton(
            configuration: configuration,
            isSelected: isSelected,
            accentColor: accentColor
        )
    }

    private struct AccentColorButton: View {
        let configuration: Configuration
        let isSelected: Bool
        let accentColor: Color
        @State private var isHovered = false

        var scale: CGFloat {
            if configuration.isPressed { return 0.97 }
            else if isHovered { return 1.07 }
            else { return 1.0 }
        }

        var highlightColor: Color {
            if isSelected {
                if configuration.isPressed { return accentColor.opacity(0.35) }
                else if isHovered { return accentColor.opacity(0.22) }
                else { return accentColor.opacity(0.15) }
            } else {
                if configuration.isPressed { return Color.secondary.opacity(0.18) }
                else if isHovered { return Color.secondary.opacity(0.10) }
                else { return Color.clear }
            }
        }

        var body: some View {
            configuration.label
                .background(Circle().fill(highlightColor))
                .scaleEffect(scale)
                .animation(
                    configuration.isPressed
                        ? .easeInOut(duration: 0.10)
                        : isHovered
                            ? .interpolatingSpring(stiffness: 350, damping: 12)
                            : .spring(response: 0.25, dampingFraction: 0.7),
                    value: scale
                )
                .onHover { hovering in
                    withAnimation(.interpolatingSpring(stiffness: 350, damping: 12)) {
                        isHovered = hovering
                    }
                }
        }
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var showCustomColorPicker = false
    @State private var customColor: Color? = nil
    @State private var pendingFontSize: CGFloat = 13
    @State private var isEditingSlider = false

    // Preset accent colors
    let presetColors: [Color] = [.yellow, .blue, .green, .pink, .orange, .purple]

    // --- Dynamic sizing based on font size ---
    private var buttonDiameter: CGFloat { settings.fontSize * 2.1 }
    private var innerCircleDiameter: CGFloat { settings.fontSize * 0.7 }
    private var eyedropperIconSize: CGFloat { settings.fontSize * 0.92 }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // --- App Size Section ---
            VStack(alignment: .leading, spacing: 10) {
                Text("App Size")
                    .font(.system(size: settings.fontSize, weight: .bold))
                HStack {
                    // Slider for font size, only commits on drag end
                    Slider(
                        value: $pendingFontSize,
                        in: 11...20,
                        step: 1,
                        onEditingChanged: { editing in
                            isEditingSlider = editing
                            if !editing {
                                settings.fontSize = pendingFontSize
                                NotificationCenter.default.post(name: .settingsFontSizeDidCommit, object: nil)
                            }
                        }
                    )
                    .frame(width: 160)
                    Text("\(Int(pendingFontSize)) pt")
                        .font(.system(size: settings.fontSize * 0.85))
                        .foregroundColor(.secondary)
                }
                Text("Adjusts font and window size for the whole app.")
                    .font(.system(size: settings.fontSize * 0.8))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)

            // --- Accent Color Section ---
            VStack(alignment: .leading, spacing: 10) {
                Text("Accent Color")
                    .font(.system(size: settings.fontSize, weight: .bold))
                HStack(spacing: 12) {
                    // Preset color buttons
                    ForEach(presetColors, id: \.self) { color in
                        Button(action: {
                            withAnimation(.interpolatingSpring(stiffness: 350, damping: 12)) {
                                settings.accentColor = color
                                customColor = nil
                            }
                        }) {
                            ZStack {
                                // Outer color circle, diameter scales with font size
                                Circle()
                                    .fill(color)
                                    .frame(width: buttonDiameter, height: buttonDiameter)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                Color.primary.opacity(settings.accentColor == color && customColor == nil ? 0.7 : 0.15),
                                                lineWidth: settings.accentColor == color && customColor == nil ? 3 : 1
                                            )
                                    )
                                // Inner white dot if selected, also scales
                                if settings.accentColor == color && customColor == nil {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: innerCircleDiameter, height: innerCircleDiameter)
                                        .shadow(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
                                }
                            }
                        }
                        .buttonStyle(AccentColorButtonStyle(
                            isSelected: settings.accentColor == color && customColor == nil,
                            accentColor: color
                        ))
                    }
                    // Custom color picker button, also scales
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 12)) {
                            showCustomColorPicker = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(customColor ?? Color.gray)
                                .frame(width: buttonDiameter, height: buttonDiameter)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            Color.primary.opacity(customColor != nil ? 0.7 : 0.15),
                                            lineWidth: customColor != nil ? 3 : 1
                                        )
                                )
                            Image(systemName: "eyedropper.full")
                                .font(.system(size: eyedropperIconSize, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(AccentColorButtonStyle(
                        isSelected: customColor != nil,
                        accentColor: settings.accentColor
                    ))
                    .accessibilityLabel("Custom Color")
                }
            }
            .padding()
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)

            Spacer()
        }
        .font(.system(size: settings.fontSize))
        .padding()
        .onAppear { pendingFontSize = settings.fontSize }
        // Show custom color picker sheet
        .sheet(isPresented: $showCustomColorPicker) {
            CustomColorPickerSheet(
                currentColor: customColor ?? settings.accentColor,
                onSet: { newColor in
                    settings.accentColor = newColor
                    customColor = newColor
                    showCustomColorPicker = false
                },
                onCancel: { showCustomColorPicker = false }
            )
            .environmentObject(settings)
        }
    }
}
