// Tasker/Tasker/SettingsWindowController.swift
import Cocoa
import SwiftUI

/// Manages the NSWindow that displays the SwiftUI SettingsView.
class SettingsWindowController: NSWindowController, NSWindowDelegate {

    /// Convenience initializer to set up the window with the SettingsView.
    /// - Parameter settingsView: The SwiftUI view to host in the window.
    convenience init(settingsView: SettingsView) {
        // Create an NSHostingController. The SettingsView defines its own frame.
        let hostingController = NSHostingController(rootView: settingsView)

        // Create the NSWindow using the hosting controller.
        // Let the window adopt default appearance and sizing behavior.
        let window = NSWindow(contentViewController: hostingController)

        // Configure basic window properties.
        window.title = "Settings" // Set title (matches SettingsView.navigationTitle)
        window.styleMask = [.titled, .closable] // Standard window controls
        window.level = .normal // Standard window level
        window.center() // Center on screen
        window.setAccessibilityIdentifier("settingsWindow") // For UI testing

        // Call the designated initializer of NSWindowController.
        self.init(window: window)
        window.delegate = self // Set the delegate.
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        // Additional setup after window loads.
    }

    /// Brings the settings window to the front and makes it key.
    func showAndActivate() {
        guard let window = self.window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
