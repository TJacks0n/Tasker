import SwiftUI

/// The main entry point for the Tasker application.
/// This defines the application structure and lifecycle.
@main // Marks this struct as the application's entry point.
struct TaskMenuBarApp: App {
    /// Connects to the `AppDelegate` class to handle application-level events,
    /// particularly for managing the menu bar item and its behavior,
    /// which are not fully managed by the standard SwiftUI `App` lifecycle for menu bar apps.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Defines the scenes that make up the application's user interface.
    var body: some Scene {
        /// Uses the `Settings` scene builder. In a menu bar application context,
        /// this is often used to define the app's presence without creating a main window.
        Settings {
            /// An `EmptyView` is provided within the `Settings` scene.
            /// This prevents SwiftUI from automatically creating a default window
            /// when the application launches, which is the desired behavior for a
            /// menu bar-only application. The actual UI is managed by the `AppDelegate`
            /// via an `NSStatusItem`.
            EmptyView()
        }
    }
}
