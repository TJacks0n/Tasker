// Tasker/Tasker/SettingsManager.swift
import Cocoa

class SettingsManager {
    private static var settingsWindow: NSWindow?

    static func showSettingsDialog() {
        if settingsWindow == nil {
            let settingsViewController = SettingsViewController()
            settingsWindow = NSWindow(
                contentViewController: settingsViewController
            )
            settingsWindow?.title = "Settings"
            settingsWindow?.setContentSize(NSSize(width: 500, height: 250))
            settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.isReleasedWhenClosed = false
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
