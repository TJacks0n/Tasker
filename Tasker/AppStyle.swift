//
//  AppStyle.swift
//  Tasker
//
//  Created by Thomas Jackson on 23/05/2025.
//

import SwiftUI

struct AppStyle {
    // Padding and sizing
    static var rowPadding: CGFloat { SettingsManager.shared.fontSize * 0.7 }
    static var defaultFontSize: CGFloat { 13 }
    static var listWidth: CGFloat { SettingsManager.shared.fontSize * 24 }
    static var inputAreaHeight: CGFloat { SettingsManager.shared.fontSize * 2.7 }
    static var dividerHeight: CGFloat { 1 }
    static var taskRowHeight: CGFloat { SettingsManager.shared.fontSize * 1.7 }
    static var footerHeight: CGFloat { SettingsManager.shared.fontSize * 2.5 }
    static var emptyStateHeight: CGFloat { SettingsManager.shared.fontSize * 4 }
    static var buttonVerticalPadding: CGFloat { SettingsManager.shared.fontSize * 0.40 }
    static var buttonHorizontalPadding: CGFloat { SettingsManager.shared.fontSize * 0.7 }

    // Colors
    static let backgroundColor: Color = .clear
    static let accentColor: Color = .green
    static let secondaryTextColor: Color = Color.secondary
    static let destructiveColor: Color = .red

    // AppKit-compatible accent color for cursor, etc.
    static var accentNSColor: NSColor {
        // If you use asset colors, use the asset name here.
        // Otherwise, match the SwiftUI color as closely as possible.
        NSColor(AppStyle.accentColor)
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    @Published var fontSize: CGFloat = AppStyle.defaultFontSize
    @Published var colorScheme: ColorScheme = .light
    @Published var theme: AppTheme = .system
    // Add more settings as needed

    private init() {}
}
