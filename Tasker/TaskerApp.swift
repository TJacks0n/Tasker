// Tasker/Tasker/TaskerApp.swift
import SwiftUI

/// The main entry point for the Tasker application.
/// This defines the application structure and lifecycle.
@main // Marks this struct as the application's entry point.
struct TaskMenuBarApp: App {
    /// Connects to the `AppDelegate` class to handle application-level events,
    /// particularly for managing the menu bar item and its behavior,
    /// which are not fully managed by the standard SwiftUI `App` lifecycle for menu bar apps.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Provide a minimal Settings scene to conform to the App protocol.
    // The actual settings window presentation is handled manually
    // by the AppDelegate and SettingsWindowController.
    var body: some Scene {
        Settings {
            // EmptyView() or your SettingsView() can be placed here,
            // but it won't be used automatically if AppDelegate handles presentation.
            // Using EmptyView is minimal.
            EmptyView()
        }
    }
}
