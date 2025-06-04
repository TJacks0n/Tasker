//  AppStyle.swift
//  Tasker
//
//  Created by Thomas Jackson on 23/05/2025.
//

import SwiftUI

// MARK: - App-wide static style constants
struct AppStyle {
    static let dividerHeight: CGFloat = 1
    static let secondaryTextColor: Color = Color.secondary
    static let destructiveColor: Color = .red
    static let backgroundColor: Color = .clear
}

// MARK: - Add task position enum
/// Controls where new tasks are inserted in the list.
enum AddTaskPosition: String, CaseIterable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"
    var id: String { rawValue }
}

// MARK: - App theme enum
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    var id: String { rawValue }
}

// MARK: - Global settings manager (singleton)
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // --- Appearance ---
    @Published var fontSize: CGFloat = 13
    @Published var colorScheme: ColorScheme = .light
    @Published var theme: AppTheme = .system
    @Published var accentColor: Color = Color(hex: "#6D72C3") // Default accent color

    // --- Task list behavior ---
    @Published var addTaskPosition: AddTaskPosition = .top

    // --- Startup/task persistence ---
    /// If true, tasks are saved and restored when the app is closed and reopened.
    @Published var retainTasksOnClose: Bool = true

    // --- Dynamic style properties (computed from font size) ---
    var rowPadding: CGFloat { fontSize * 0.7 }
    var listWidth: CGFloat { fontSize * 24 }
    var inputAreaHeight: CGFloat { fontSize * 2.7 }
    var taskRowHeight: CGFloat { fontSize * 1.7 }
    var footerHeight: CGFloat { fontSize * 2.5 }
    var emptyStateHeight: CGFloat { fontSize * 4 }
    var buttonVerticalPadding: CGFloat { fontSize * 0.40 }
    var buttonHorizontalPadding: CGFloat { fontSize * 0.7 }

    // AppKit-compatible accent color
    var accentNSColor: NSColor { NSColor(accentColor) }

    private init() {}
}

// MARK: - Color extension for hex initialization
extension Color {
    /// Initialize a Color from a hex string (e.g. "#6D72C3")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
