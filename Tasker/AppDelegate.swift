import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    // Keep the ViewModel instance accessible
    var taskViewModel = TaskViewModel()
    private var cancellables = Set<AnyCancellable>()
    // Keep a reference to the hosting controller for resizing
    private var hostingController: NSHostingController<TaskListView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to prevent Dock icon and main menu
        // You might prefer the Info.plist 'Application is agent (UIElement)' = YES setting
        NSApp.setActivationPolicy(.accessory)

        // Use the AppDelegate's viewModel instance
        let contentView = TaskListView(viewModel: taskViewModel)

        popover = NSPopover()
        // Store the hosting controller
        hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "menuBarIcon")
            button.image?.isTemplate = true
            // Set the action for the button
            button.action = #selector(togglePopover(_:))
            // *** Add this line to handle right-clicks ***
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Observe task changes to update popover size using the stored hostingController
        taskViewModel.$tasks
            .sink { [weak self] _ in
                // Ensure hostingController is available before calling update
                if let hc = self?.hostingController {
                    self?.updatePopoverSize(for: hc)
                }
            }
            .store(in: &cancellables)

        // Perform initial size update after launch
        DispatchQueue.main.async { [weak self] in
            if let hc = self?.hostingController {
                self?.updatePopoverSize(for: hc)
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        // *** Check if the event was a right-click ***
        if NSApp.currentEvent?.type == .rightMouseUp {
            // Create and show the context menu
            if let button = statusItem.button {
                let menu = createContextMenu()
                statusItem.menu = menu // Assign the menu temporarily
                // Programmatically click the button to show the menu immediately
                button.performClick(nil)
                // Important: Reset the menu after it's shown so left-click works for the popover
                // Use async to ensure it happens after the menu action is processed
                DispatchQueue.main.async { [weak self] in
                    self?.statusItem.menu = nil
                }
            }
        } else {
            // *** Handle left-click (toggle popover) ***
            if popover.isShown {
                popover.performClose(sender)
            } else if let button = statusItem.button {
                // Ensure size is correct before showing
                if let hc = hostingController {
                    updatePopoverSize(for: hc)
                }
                // Show popover below the status bar item
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Make the popover's content view active
                popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }

    // *** Function to create the context menu ***
    func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Tasker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        // Add other menu items here if needed
        return menu
    }

    // *** Keep your existing updatePopoverSize function ***
    private func updatePopoverSize(for hostingController: NSHostingController<TaskListView>) {
        guard let popover = popover else { return }

        DispatchQueue.main.async {
            // Calculate the height dynamically based on the content
            let contentSize = hostingController.view.intrinsicContentSize
            let screenHeight = NSScreen.main?.visibleFrame.height ?? 700
            let maxHeight = screenHeight - 50 // Leave space for the menu bar
            // Ensure minimum height if needed, e.g., when list is empty
            let calculatedHeight = max(contentSize.height, 50) // Example minimum height
            let newHeight = min(calculatedHeight, maxHeight)

            // Animate the size change if desired
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1 // Short duration for responsiveness
                context.allowsImplicitAnimation = true
                popover.contentSize = NSSize(width: 300, height: newHeight)
            }, completionHandler: nil)
        }
    }
}

// Optional helper extension
extension AppDelegate {
    static var shared: AppDelegate? {
        return NSApplication.shared.delegate as? AppDelegate
    }
}
