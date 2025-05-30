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

    func makeBody(configuration: Configuration) -> some View {
        CategoryButton(
            configuration: configuration,
            isSelected: isSelected
        )
    }

    // Inner view for button appearance and interaction
    private struct CategoryButton: View {
        let configuration: Configuration
        let isSelected: Bool
        @State private var isHovered = false

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
                    return AppStyle.accentColor.opacity(0.35)
                } else if isHovered {
                    return AppStyle.accentColor.opacity(0.22)
                } else {
                    return AppStyle.accentColor.opacity(0.15)
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
                .foregroundColor(isSelected ? AppStyle.accentColor : .secondary)
                .padding(.vertical, AppStyle.buttonVerticalPadding)
                .padding(.horizontal, AppStyle.buttonHorizontalPadding * 0.7)
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

// Main settings view
struct SettingsView: View {
    @State private var selection: SettingsCategory = .general

    // Dynamically calculate button width based on label size
    private var buttonWidth: CGFloat {
        let font = NSFont.systemFont(ofSize: AppStyle.defaultFontSize * 0.85, weight: .medium)
        let maxLabelWidth = SettingsCategory.allCases
            .map { $0.title.size(withAttributes: [.font: font]).width }
            .max() ?? 60
        let iconWidth: CGFloat = 2
        let horizontalPadding = AppStyle.buttonHorizontalPadding * 1.0
        return maxLabelWidth + iconWidth + horizontalPadding
    }

    var body: some View {
        ZStack {
            // --- Semi-transparent background using controlBackgroundColor ---
            // This matches the NSTextView translucency style.
            Color(NSColor.controlBackgroundColor.withAlphaComponent(0.7))
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Category selection bar
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(SettingsCategory.allCases) { category in
                            Button(action: { selection = category }) {
                                VStack(spacing: 2) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: AppStyle.defaultFontSize, weight: .semibold))
                                    Text(category.title)
                                        .font(.system(size: AppStyle.defaultFontSize * 0.85, weight: .medium))
                                }
                                .frame(width: buttonWidth)
                            }
                            .buttonStyle(CategoryButtonStyle(isSelected: selection == category))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 0)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(Color.clear)

                Divider()

                // Main content area for selected settings category
                ZStack {
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 500, height: 320)
    }
}

// Helper extension to measure string width for button sizing
fileprivate extension String {
    func size(withAttributes attrs: [NSAttributedString.Key: Any]) -> CGSize {
        (self as NSString).size(withAttributes: attrs)
    }
}
