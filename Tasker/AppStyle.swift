//  AppStyle.swift
//  Tasker
//
//  Created by Thomas Jackson on 23/05/2025.
//

import SwiftUI
import Combine

// MARK: - App-wide static style constants
struct AppStyle {
    static let dividerHeight: CGFloat = 1
    static let secondaryTextColor: Color = Color.secondary
    static let destructiveColor: Color = .red
    static let backgroundColor: Color = .clear
}

// MARK: - Add task position enum (now Int-backed for robust persistence)
/// Controls where new tasks are inserted in the list.
/// Uses Int raw values for robust file storage: 0 = top, 1 = bottom.
enum AddTaskPosition: Int, CaseIterable, Identifiable, Codable {
    case top = 0
    case bottom = 1
    var id: Int { rawValue }
}

// MARK: - App theme enum
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark
    var id: String { rawValue }
}

// MARK: - Codable struct for all settings
/// Stores all user settings for persistence.
/// fontSize is Double for Codable compatibility.
/// addTaskPosition is Int (0 = top, 1 = bottom) for robust loading.
struct AppSettings: Codable {
    var fontSize: Double
    var colorScheme: String
    var theme: String
    var accentColorHex: String
    var addTaskPosition: Int
    var retainTasksOnClose: Bool
}

// MARK: - Global settings manager (singleton) with file-based persistence
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // --- Appearance ---
    @Published var fontSize: CGFloat = 13
    @Published var colorScheme: ColorScheme = .light
    @Published var theme: AppTheme = .system
    @Published var accentColor: Color = Color(hex: "#6D72C3")

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

    // Store the actual hex string for persistence
    private var _accentColorHex: String = "#6D72C3"
    var accentColorHex: String {
        get { _accentColorHex }
        set { _accentColorHex = newValue }
    }

    private var cancellables = Set<AnyCancellable>()
    private let settingsFileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("Tasker", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("settings.json")
    }()

    // Prevents saving while loading from disk
    private var isLoading = false

    // MARK: - Initialization with file loading
    private init() {
        loadSettings()

        // Observe all @Published properties and save on change
        $fontSize.sink { [weak self] _ in self?.saveSettingsIfNeeded() }.store(in: &cancellables)
        $colorScheme.sink { [weak self] _ in self?.saveSettingsIfNeeded() }.store(in: &cancellables)
        $theme.sink { [weak self] _ in self?.saveSettingsIfNeeded() }.store(in: &cancellables)
        $accentColor.sink { [weak self] color in
            guard let self = self else { return }
            self.accentColorHex = color.toHex() ?? "#6D72C3"
            self.saveSettingsIfNeeded()
        }.store(in: &cancellables)
        $addTaskPosition.sink { [weak self] _ in self?.saveSettingsIfNeeded() }.store(in: &cancellables)
        $retainTasksOnClose.sink { [weak self] _ in self?.saveSettingsIfNeeded() }.store(in: &cancellables)
    }

    // MARK: - Load settings from file
    private func loadSettings() {
        isLoading = true
        print("Loading settings from: \(settingsFileURL.path)")
        guard let data = try? Data(contentsOf: settingsFileURL),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            print("No settings file found or failed to decode.")
            isLoading = false
            return
        }
        print("Loaded settings: \(decoded)")
        fontSize = CGFloat(decoded.fontSize) // Convert Double to CGFloat
        colorScheme = (decoded.colorScheme == "dark") ? .dark : .light
        theme = AppTheme(rawValue: decoded.theme) ?? .system
        accentColor = Color(hex: decoded.accentColorHex)
        accentColorHex = decoded.accentColorHex
        // Robustly load addTaskPosition as Int (0 = top, 1 = bottom)
        addTaskPosition = AddTaskPosition(rawValue: decoded.addTaskPosition) ?? .top
        retainTasksOnClose = decoded.retainTasksOnClose
        isLoading = false
    }

    // Only save if not loading from disk
    private func saveSettingsIfNeeded() {
        if isLoading { return }
        saveSettings()
    }

    // MARK: - Save settings to file
    private func saveSettings() {
        let settings = AppSettings(
            fontSize: Double(fontSize), // Convert CGFloat to Double
            colorScheme: colorScheme == .dark ? "dark" : "light",
            theme: theme.rawValue,
            accentColorHex: accentColorHex,
            addTaskPosition: addTaskPosition.rawValue, // Save as Int
            retainTasksOnClose: retainTasksOnClose
        )
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: settingsFileURL)
            print("Saved settings to: \(settingsFileURL.path)")
        }
    }
}

// MARK: - Color extension for hex initialization and conversion
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

    /// Convert Color to hex string (for persistence)
    func toHex() -> String? {
        #if os(macOS)
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return nil }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return nil
        #endif
    }
}
