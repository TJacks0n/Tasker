//  AppStyle.swift
//  Tasker
//
//  Created by Thomas Jackson on 23/05/2025.
//

import SwiftUI

struct AppStyle {
    // Only keep static constants that never change
    static let dividerHeight: CGFloat = 1
    static let secondaryTextColor: Color = Color.secondary
    static let destructiveColor: Color = .red
    static let backgroundColor: Color = .clear
}

// Move all dynamic style properties to SettingsManager
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    @Published var fontSize: CGFloat = 13
    @Published var colorScheme: ColorScheme = .light
    @Published var theme: AppTheme = .system
    @Published var accentColor: Color = .yellow

    // Dynamic style properties
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

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}
