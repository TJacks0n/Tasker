// Tasker/Tasker/SettingsManager.swift
import Cocoa

class SettingsManager {
    private static var settingsWindow: NSWindow?

    // In SettingsManager.swift
    static func showSettingsDialog() {
        if settingsWindow == nil {
            let settingsViewController = SettingsViewController()
            settingsWindow = NSWindow(
                contentViewController: settingsViewController
            )
            settingsWindow?.title = "Settings"
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.isReleasedWhenClosed = false
            
            // Set a large enough fixed size for all views
            settingsWindow?.setContentSize(NSSize(width: 450, height: 250))
            settingsWindow?.minSize = NSSize(width: 300, height: 250)
            
            // Disable window resizing to prevent constraint issues
            settingsWindow?.styleMask.remove(.resizable)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
