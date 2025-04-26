import Cocoa
import SwiftUI
import Combine

/// Handles application-level events and manages the menu bar item (status item) and its associated popover.
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// The popover window that displays the main task list UI.
    var popover: NSPopover!
    /// The item displayed in the system menu bar.
    var statusItem: NSStatusItem!
    /// The context menu shown on right-clicking the status item.
    var menu: NSMenu!
    /// The shared view model managing the task data and logic.
    var taskViewModel = TaskViewModel()
    /// Stores Combine subscriptions to manage their lifecycle.
    private var cancellables = Set<AnyCancellable>()
    /// Hosts the SwiftUI `TaskListView` within the AppKit popover.
    private var hostingController: NSHostingController<TaskListView>?

    // MARK: - UI Constants (Estimated Heights for Popover Sizing)

    /// Estimated height of the task input area.
    let inputAreaHeight: CGFloat = 45
    /// Height of divider lines.
    let dividerHeight: CGFloat = 1
    /// Padding above the task list.
    let listTopPadding: CGFloat = 5
    /// Estimated height of a single task row.
    let taskRowHeight: CGFloat = 21
    /// Estimated height of the footer area (clear buttons).
    let footerHeight: CGFloat = 40
    /// Height of the view shown when the task list is empty.
    let emptyStateHeight: CGFloat = 60
    /// Fixed width for the popover.
    let desiredWidth: CGFloat = 300

    // MARK: - Application Lifecycle

    /// Called when the application finishes launching. Sets up the menu bar item, popover, and initial state.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view and inject the view model.
        // IMPORTANT: For transparency, modify TaskListView to have a .background modifier
        // e.g., .background(Color.black.opacity(0.7)) or .background(.ultraThinMaterial)
        let contentView = TaskListView(viewModel: taskViewModel)
        // Calculate the initial size needed for the popover.
        let initialSize = calculatePopoverSize(taskCount: taskViewModel.tasks.count)

        // Create a hosting controller to embed the SwiftUI view.
        self.hostingController = NSHostingController(rootView: contentView)
        self.hostingController?.view.frame.size = initialSize // Set initial frame size
        // Make the hosting view layer-backed and clear for transparency pass-through
        self.hostingController?.view.wantsLayer = true
        self.hostingController?.view.layer?.backgroundColor = NSColor.clear.cgColor

        // Configure the popover.
        popover = NSPopover()
        popover.contentSize = initialSize
        popover.contentViewController = hostingController
        popover.contentViewController?.view.setAccessibilityIdentifier("TaskerPopoverWindow")
        popover.behavior = .transient // Close popover when clicking outside
        // Set the appearance to allow the background to show through if needed
        popover.appearance = NSAppearance(named: .vibrantDark) // Or another appropriate appearance

        // Configure the status bar item.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "menuBarIcon") // Set the icon
            button.image?.isTemplate = true // Allows the icon to adapt to light/dark mode
            button.action = #selector(togglePopover(_:)) // Action for clicks
            button.sendAction(on: [.leftMouseUp, .rightMouseUp]) // Trigger action on both clicks
        }

        // Configure the right-click menu.
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Tasker", action: #selector(showAboutPanel(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Tasker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // Subscribe to changes in the task list to update popover size dynamically.
        taskViewModel.$tasks
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main) // Wait briefly for rapid changes to settle
            .sink { [weak self] tasks in
                guard let self = self else { return }
                // Update popover size when tasks change, with animation.
                self.updatePopoverSize(taskCount: tasks.count, animate: true)
            }
            .store(in: &cancellables) // Store subscription

        // Set the activation policy to .accessory after a short delay.
        // This hides the Dock icon and makes it a background/menu bar app.
        // The delay helps ensure initial setup completes smoothly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Actions

    /// Toggles the popover's visibility or shows the context menu based on the click type.
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click: Close popover if open, then show the context menu.
            if popover.isShown {
                popover.performClose(sender)
            }
            // Temporarily activate the app to ensure the menu appears correctly.
            NSApp.activate(ignoringOtherApps: true)
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        } else { // Left-click
            if popover.isShown {
                // If popover is visible, close it.
                popover.performClose(sender)
            } else {
                // If popover is hidden, update its size and show it.
                updatePopoverSize(taskCount: taskViewModel.tasks.count, animate: false) // Ensure size is correct before showing
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                // Make the popover the key window to allow immediate interaction (e.g., text input)
                // without fully activating the application globally.
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    /// Displays the standard "About" panel for the application.
    @objc func showAboutPanel(_ sender: Any?) {
        // Close the main popover if it's open.
        if popover.isShown {
            popover.performClose(sender)
        }

        // Prepare information for the About panel.
        let creditsURL = URL(string: "https://github.com/TJacks0n/Tasker")
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildString = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        let versionAndBuildString = "\(versionString) (\(buildString))" // e.g., "1.1 (15)"

        // Temporarily activate the app to show the panel.
        NSApp.activate(ignoringOtherApps: true)
        // Order the standard About panel to the front with custom options.
        NSApp.orderFrontStandardAboutPanel(
            options: [
                // Display clickable credits link.
                .credits: NSAttributedString(
                    string: "https://github.com/TJacks0n/Tasker",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                        .link: creditsURL as Any
                    ]
                ),
                // Display combined version and build number.
                .applicationVersion: versionAndBuildString,
                // Clear the default separate version field.
                .version: "",
                // Set the application name.
                .applicationName: "Tasker",
                // Set the copyright information.
                NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Copyright © 2025 TJacks0n"
            ]
        )
    }

    // MARK: - Popover Size Calculation & Update

    /// Calculates the appropriate height for the popover based on the number of tasks.
    /// - Parameter taskCount: The current number of tasks.
    /// - Returns: An `NSSize` with the desired width and calculated height.
    func calculatePopoverSize(taskCount: Int) -> NSSize {
        var calculatedHeight: CGFloat = 0
        // Base height includes input area, dividers, and footer.
        let baseHeight = inputAreaHeight + dividerHeight + dividerHeight + footerHeight

        if taskCount == 0 {
            // If no tasks, add the height of the empty state view.
            calculatedHeight = baseHeight + emptyStateHeight
        } else {
            // If tasks exist, calculate list height based on row count and padding.
            let listHeight = listTopPadding + (CGFloat(taskCount) * taskRowHeight)
            calculatedHeight = baseHeight + listHeight
        }

        // Ensure the popover doesn't exceed the screen height minus some margin.
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 700 // Default fallback height
        let maxHeight = screenHeight - 50 // Max allowed height
        let finalHeight = min(calculatedHeight, maxHeight) // Clamp to max height

        // Ensure the popover has a minimum reasonable height.
        let minHeight: CGFloat = 110
        let clampedHeight = max(finalHeight, minHeight) // Clamp to min height

        return NSSize(width: desiredWidth, height: clampedHeight)
    }

    /// Updates the popover's content size, optionally animating the change.
    /// - Parameters:
    ///   - taskCount: The current number of tasks used for size calculation.
    ///   - animate: Whether to animate the size change (default is true).
    private func updatePopoverSize(taskCount: Int, animate: Bool = true) {
        guard let popover = popover, let hc = hostingController else { return }

        // Calculate the new required size.
        let newSize = calculatePopoverSize(taskCount: taskCount)

        // Update the hosting controller's view frame size first.
        // This is important for the SwiftUI layout to adapt correctly *before* the popover resizes.
        hc.view.frame.size = newSize

        // Only resize the popover if the size actually changed.
        if popover.contentSize != newSize {
            if animate && popover.isShown {
                // Animate the popover size change if requested and visible.
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.15 // Short animation duration
                    context.allowsImplicitAnimation = true // Allow smooth animation
                    popover.contentSize = newSize
                }, completionHandler: nil)
            } else {
                // Apply the size change immediately if not animating or not shown.
                popover.contentSize = newSize
            }
        }
    }
}
