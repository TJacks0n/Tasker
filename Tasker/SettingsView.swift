import SwiftUI

struct SettingsView: View {
    // Use @AppStorage to automatically save/load from UserDefaults
    @AppStorage("launchAtLogin") private var launchAtLoginEnabled = false
    @AppStorage("persistTasks") private var persistTasksEnabled = true // Assuming default is true
    // Add state for other settings later

    var body: some View {
        // Use Form for standard settings layout
        Form {
            // Section for General Settings
            Section("General") {
                Toggle("Launch Tasker at login", isOn: $launchAtLoginEnabled)
                    .onChange(of: launchAtLoginEnabled) { _, newValue in
                        // Add logic to enable/disable launch agent here
                        print("Launch at login toggled: \(newValue)")
                    }
                    .accessibilityIdentifier("launchAtLoginToggle")

                Toggle("Save tasks between launches", isOn: $persistTasksEnabled)
                    .onChange(of: persistTasksEnabled) { _, newValue in
                        // This might influence TaskViewModel's save/load behavior
                        print("Persist tasks toggled: \(newValue)")
                    }
                    .accessibilityIdentifier("persistTasksToggle")
            }

            // Section for Customization
            Section("Customization") {
                Button("Customize Keyboard Shortcuts") {
                    // Add action to open shortcut customization UI (complex)
                    print("Customize shortcuts button clicked")
                }
                .accessibilityIdentifier("customizeShortcutsButton")

                // Add Appearance settings controls here (e.g., Picker for light/dark/system)
                Text("Appearance settings placeholder")
            }

            // Section for Updates
            Section("Updates") {
                Button("Check for Updates") {
                    // Add action to trigger update check (e.g., using Sparkle)
                    print("Check for updates button clicked")
                }
                .accessibilityIdentifier("checkForUpdatesButton")
            }
        }
        .padding() // Add padding around the Form
        .frame(minWidth: 300, idealWidth: 400, minHeight: 250, idealHeight: 300) // Set window size constraints
        // *** Update the navigation title to match the window title ***
        .navigationTitle("Tasker Preferences") // Changed from "Tasker Settings"
        .accessibilityIdentifier("settingsView")
    }
}

// Preview provider for Xcode Previews
#Preview {
    SettingsView()
}
