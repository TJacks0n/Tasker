//  SettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 28/05/2025.
//

import SwiftUI
import AppKit

// Enum for the different settings categories
enum SettingsCategory: String, CaseIterable, Identifiable {
    case general, startup, appearance, behavior, data

    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: return "General"
        case .startup: return "Startup"
        case .appearance: return "Appearance"
        case .behavior: return "Behavior"
        case .data: return "Data"
        }
    }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .startup: return "arrow.up.circle"
        case .appearance: return "paintbrush"
        case .behavior: return "slider.horizontal.3"
        case .data: return "tray.full"
        }
    }
}

// Custom button style for category selection
struct CategoryButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color
    @EnvironmentObject var settings: SettingsManager

    func makeBody(configuration: Configuration) -> some View {
        CategoryButton(
            configuration: configuration,
            isSelected: isSelected,
            accentColor: accentColor
        )
        .environmentObject(settings)
    }

    // Inner view for button appearance and interaction
    private struct CategoryButton: View {
        let configuration: Configuration
        let isSelected: Bool
        let accentColor: Color
        @State private var isHovered = false
        @EnvironmentObject var settings: SettingsManager

        // Scale effect for hover/press animation
        var scale: CGFloat {
            if configuration.isPressed {
                return 0.97
            } else if isHovered {
                return 1.07
            } else {
                return 1.0
            }
        }

        // Background color based on selection and interaction state
        var backgroundColor: Color {
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
                    return AppStyle.secondaryTextColor.opacity(0.18)
                } else if isHovered {
                    return AppStyle.secondaryTextColor.opacity(0.10)
                } else {
                    return Color.clear
                }
            }
        }

        var body: some View {
            configuration.label
                .foregroundColor(isSelected ? accentColor : AppStyle.secondaryTextColor)
                .padding(.vertical, settings.buttonVerticalPadding)
                .padding(.horizontal, settings.buttonHorizontalPadding * 0.7)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(backgroundColor)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
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

// Main settings view container
struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var selection: SettingsCategory = .general
    @Environment(\.colorScheme) private var systemColorScheme

    // Helper to resolve the effective color scheme based on user selection
    private var effectiveColorScheme: ColorScheme {
        switch settings.theme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    // Dynamically calculate button width based on label size and dynamic padding
    private var buttonWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: settings.fontSize * 0.85, weight: .medium)
        let maxLabelWidth = SettingsCategory.allCases
            .map { $0.title.size(withAttributes: [.font: font]).width }
            .max() ?? 60
        let iconWidth: CGFloat = 2
        let horizontalPadding = settings.buttonHorizontalPadding * 1.0
        return maxLabelWidth + iconWidth + horizontalPadding
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height:5)
            // --- Category selection bar ---
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(SettingsCategory.allCases) { category in
                        Button(action: { selection = category }) {
                            VStack(spacing: 2) {
                                Image(systemName: category.icon)
                                    .font(.system(size: settings.fontSize, weight: .semibold))
                                Text(category.title)
                                    .font(.system(size: settings.fontSize * 0.85, weight: .medium))
                            }
                            .frame(width: buttonWidth)
                        }
                        .buttonStyle(CategoryButtonStyle(isSelected: selection == category, accentColor: settings.accentColor))
                        .environmentObject(settings)
                    }
                }
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 6)

            Divider().frame(height: AppStyle.dividerHeight)

            // --- Main content area for selected settings category ---
            Group {
                switch selection {
                case .general:
                    GeneralSettingsView()
                case .startup:
                    StartupSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .behavior:
                    BehaviorSettingsView()
                case .data:
                    DataSettingsView()
                }
            }
            .padding()
        }
        .font(.system(size: settings.fontSize))
        .preferredColorScheme(settings.theme == .system ? nil : effectiveColorScheme)
        // Do NOT set a background here; let AppDelegate/window control it.
        // .background(Color.clear) // Optional: can be omitted, as clear is default
        .frame(width: 500, height: 300) // Or your preferred size
    }
}

// Helper extension to measure string width for button sizing
fileprivate extension String {
    func size(withAttributes attrs: [NSAttributedString.Key: Any]) -> CGSize {
        (self as NSString).size(withAttributes: attrs)
    }
}
