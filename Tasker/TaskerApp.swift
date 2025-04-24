//
//  TaskerApp.swift
//  Tasker
//
//  Created by Thomas Jackson on 24/04/2025.
//

import SwiftUI

@main
struct TaskMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We don't want a visible window for a menu bar app
        Settings {
            EmptyView() // Or any other view that doesn't present a window
        }
    }
}
