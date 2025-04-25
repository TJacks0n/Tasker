import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var taskViewModel = TaskViewModel()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        //NSApp.setActivationPolicy(.accessory)

        let contentView = TaskListView(viewModel: taskViewModel)

        popover = NSPopover()
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "menuBarIcon")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:)) // Correct: togglePopover is now a class member
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create the menu
        menu = NSMenu()
        // Add About item
        menu.addItem(NSMenuItem(title: "About Tasker", action: #selector(showAboutPanel(_:)), keyEquivalent: "")) // Correct: showAboutPanel is now a class member
        menu.addItem(NSMenuItem.separator()) // Optional separator
        menu.addItem(NSMenuItem(title: "Quit Tasker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        taskViewModel.$tasks
            .sink { [weak self] _ in
                // Correct: updatePopoverSize is now a class member
                self?.updatePopoverSize(for: hostingController)
            }
            .store(in: &cancellables)

        // ADD this block to hide the Dock icon after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Adjust delay as needed (e.g., 0.5 seconds)
            NSApp.setActivationPolicy(.accessory)
        }
    } // <<< --- ADD THIS CLOSING BRACE for applicationDidFinishLaunching

    @objc func togglePopover(_ sender: AnyObject?) { // Correct: Now a class member
        guard let button = statusItem.button else { return }
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            if popover.isShown {
                popover.performClose(sender)
            }
            // Ensure the app is active before showing the menu,
            // otherwise the About panel might not become key.
            NSApp.activate(ignoringOtherApps: true)
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        } else { // Left mouse up
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }

    // Action for the "About Tasker" menu item
    @objc func showAboutPanel(_ sender: Any?) { // Correct: Now a class member
         // Close popover if open before showing About panel
        if popover.isShown {
            popover.performClose(sender)
        }
        // Show the standard About panel
        // Ensure your Info.plist has values for Application Name, Version, and Copyright
        NSApp.orderFrontStandardAboutPanel(
            options: [
                NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                    string: "https://github.com/TJacks0n/Tasker", // Optional: Load from RTF if needed
                    attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
                    ]
                ),
                NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Copyright © 2025 TJacks0n" // Update copyright
            ]
        )
        // Make sure the About panel comes to the front
        NSApp.activate(ignoringOtherApps: true)
    }


    private func updatePopoverSize(for hostingController: NSHostingController<TaskListView>) { // Correct: Now a class member
        guard let popover = popover else { return }

        DispatchQueue.main.async {
            let contentSize = hostingController.view.intrinsicContentSize
            let screenHeight = NSScreen.main?.visibleFrame.height ?? 700
            let maxHeight = screenHeight - 50
            let newHeight = min(contentSize.height, maxHeight)
            popover.contentSize = NSSize(width: 300, height: newHeight)
        }
    }
} // <<< --- This is the closing brace for the AppDelegate class
