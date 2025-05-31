//  AppearanceSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI
import AppKit

// Custom button style for accent color selection, matching CategoryButtonStyle
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
            if configuration.isPressed {
                return 0.97
            } else if isHovered {
                return 1.07
            } else {
                return 1.0
            }
        }

        var highlightColor: Color {
            if isSelected {
                if configuration.isPressed {
                    return accentColor.opacity(0.35)
                } else if isHovered {
                    return accentColor.opacity(0.22)
                } else {
                    return accentColor.opacity(0.15)
                }
            } else {
                if configuration.isPressed {
                    return Color.secondary.opacity(0.18)
                } else if isHovered {
                    return Color.secondary.opacity(0.10)
                } else {
                    return Color.clear
                }
            }
        }

        var body: some View {
            configuration.label
                .background(
                    Circle()
                        .fill(highlightColor)
                )
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

    // Preset accent colors
    let presetColors: [Color] = [.yellow, .blue, .green, .pink, .orange, .purple]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color:")
                .font(.headline)
            HStack(spacing: 12) {
                // Preset accent color buttons
                ForEach(presetColors, id: \.self) { color in
                    Button(action: {
                        withAnimation(.interpolatingSpring(stiffness: 350, damping: 12)) {
                            settings.accentColor = color
                            customColor = nil
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            Color.primary.opacity(settings.accentColor == color && customColor == nil ? 0.7 : 0.15),
                                            lineWidth: settings.accentColor == color && customColor == nil ? 3 : 1
                                        )
                                )
                            // Center circle: white if selected, invisible otherwise
                            if settings.accentColor == color && customColor == nil {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 9, height: 9)
                                    .shadow(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
                            }
                        }
                    }
                    .buttonStyle(AccentColorButtonStyle(
                        isSelected: settings.accentColor == color && customColor == nil,
                        accentColor: color
                    ))
                }
                // Custom Color button: no center circle
                Button(action: {
                    withAnimation(.interpolatingSpring(stiffness: 350, damping: 12)) {
                        showCustomColorPicker = true
                    }
                }) {
                    ZStack {
                        // Outer circle: always shows last custom color, or gray if none picked yet
                        Circle()
                            .fill(customColor ?? Color.gray)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        Color.primary.opacity(customColor != nil ? 0.7 : 0.15),
                                        lineWidth: customColor != nil ? 3 : 1
                                    )
                            )
                        Image(systemName: "eyedropper.full")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                .buttonStyle(AccentColorButtonStyle(
                    isSelected: customColor != nil,
                    accentColor: settings.accentColor
                ))
                .accessibilityLabel("Custom Color")
            }
            Spacer()
        }
        .padding()
        // Custom Color Picker Sheet
        .sheet(isPresented: $showCustomColorPicker) {
            CustomColorPickerSheet(
                currentColor: customColor ?? settings.accentColor,
                onSet: { newColor in
                    settings.accentColor = newColor
                    customColor = newColor // Only update customColor when a custom color is picked
                    showCustomColorPicker = false
                },
                onCancel: {
                    showCustomColorPicker = false
                }
            )
            .environmentObject(settings)
        }
    }
}
