//  TaskerSwiftUIMenu.swift
//  Tasker
//
//  Created by Thomas Jackson on 2025-05-23.
//

import SwiftUI

/// The menu shown when right-clicking the menu bar icon.
/// Uses global font size and accent color from SettingsManager.
struct TaskerSwiftUIMenu: View {
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject var settings: SettingsManager

    // Store the event monitor so it can be removed
    @State private var eventMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuButton(
                title: "About Tasker",
                shortcut: "⌘ I",
                action: { NSApp.orderFrontStandardAboutPanel(nil) }
            )
            MenuButton(
                title: "Settings...",
                shortcut: "⌘ ,",
                action: { openSettings() }
            )
            Divider().padding(.vertical, 2)
            MenuButton(
                title: "Report Bug",
                shortcut: "⌘ ⇧ B",
                action: { BugReporter().showReportBugDialog() }
            )
            Divider().padding(.vertical, 2)
            MenuButton(
                title: "Quit Tasker",
                shortcut: "⌘ Q",
                action: { NSApp.terminate(nil) }
            )
        }
        .frame(width: 170)
        .padding(4)
        .font(.system(size: settings.fontSize)) // Use global font size
        .onAppear {
            // Register keyDown event monitor for menu shortcuts
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // About Tasker: Cmd+I
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "i" {
                    NSApp.orderFrontStandardAboutPanel(nil)
                    return nil
                }
                // Settings: Cmd+,
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "," {
                    openSettings()
                    return nil
                }
                // Report Bug: Shift+Cmd+B
                if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers?.lowercased() == "b" {
                    BugReporter().showReportBugDialog()
                    return nil
                }
                // Quit: Cmd+Q
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
                    NSApp.terminate(nil)
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            // Remove event monitor to prevent leaks
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
}

/// A single menu button row, styled with global font and accent color.
struct MenuButton: View {
    let title: String
    let shortcut: String?
    var isDestructive: Bool = false
    let action: () -> Void

    @State private var isHovering = false
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .foregroundColor(AppStyle.secondaryTextColor)
                        .font(.system(size: settings.fontSize - 1, weight: .regular, design: .monospaced))
                }
            }
            .font(.system(size: settings.fontSize))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? settings.accentColor.opacity(0.32) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
