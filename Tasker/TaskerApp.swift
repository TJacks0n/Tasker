import SwiftUI

@main
struct TaskMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(SettingsManager.shared) // Inject here
        }
    }
}
