// Tasker/Tasker/SettingsManager.swift
import Cocoa

class SettingsManager {
    static func showSettingsDialog() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Settings"
        alert.informativeText = "Modify your application settings below."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let formView = NSStackView(frame: NSRect(x: 0, y: 0, width: 350, height: 100))
        formView.orientation = .vertical
        formView.spacing = 10

        let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: nil, action: nil)
        launchAtLoginCheckbox.state = UserDefaults.standard.bool(forKey: "launchAtLogin") ? .on : .off

        let persistTasksCheckbox = NSButton(checkboxWithTitle: "Persist Tasks", target: nil, action: nil)
        persistTasksCheckbox.state = UserDefaults.standard.bool(forKey: "persistTasks") ? .on : .off

        formView.addArrangedSubview(launchAtLoginCheckbox)
        formView.addArrangedSubview(persistTasksCheckbox)

        alert.accessoryView = formView

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            UserDefaults.standard.set(launchAtLoginCheckbox.state == .on, forKey: "launchAtLogin")
            UserDefaults.standard.set(persistTasksCheckbox.state == .on, forKey: "persistTasks")
        }
            print("Settings saved: Launch at Login = \(launchAtLoginCheckbox.state == .on), Persist Tasks = \(persistTasksCheckbox.state == .on)")
    }
}
