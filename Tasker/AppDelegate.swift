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
    private var hostingController: NSHostingController<AnyView>?
    /// Handles bug reporting presentation and logic.
    private let bugReporter = BugReporter()

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // --- Setup the main content view and hosting controller ---
        let contentView = TaskListView(viewModel: taskViewModel)
            .environmentObject(SettingsManager.shared)
        let initialSize = calculatePopoverSize(taskCount: taskViewModel.tasks.count)
        self.hostingController = NSHostingController(rootView: AnyView(contentView))
        self.hostingController?.view.frame.size = initialSize
        self.hostingController?.view.wantsLayer = true
        self.hostingController?.view.layer?.backgroundColor = NSColor.clear.cgColor

        // --- Setup the popover ---
        popover = NSPopover()
        popover.contentSize = initialSize
        popover.contentViewController = hostingController
        popover.contentViewController?.view.setAccessibilityIdentifier("TaskerPopoverWindow")
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .vibrantDark)
        
        // --- Setup the status item (menu bar icon) ---
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "menuBarIcon")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // --- Setup the right-click context menu ---
        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Tasker", action: #selector(showAboutPanel(_:)), keyEquivalent: ""))

        // *** Create the Report Bug menu item and set its identifier ***
        let reportBugMenuItem = NSMenuItem(title: "Report Bug...", action: #selector(showBugReportDialog(_:)), keyEquivalent: "")
        reportBugMenuItem.setAccessibilityIdentifier("reportBugButton") // Match UI test identifier
        menu.addItem(reportBugMenuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Tasker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // --- Observe changes to the task list and update popover size accordingly ---
        taskViewModel.$tasks
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] tasks in
                guard let self = self else { return }
                self.updatePopoverSize(taskCount: tasks.count, animate: true)
            }
            .store(in: &cancellables)

        // --- Observe changes to font size and update popover size dynamically ---
        SettingsManager.shared.$fontSize
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updatePopoverSize(taskCount: self.taskViewModel.tasks.count, animate: true)
            }
            .store(in: &cancellables)

        // --- Set activation policy after a short delay (for menu bar app behavior) ---
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
            if popover.isShown {
                popover.performClose(sender)
            }
            NSApp.activate(ignoringOtherApps: true)
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        } else { // Left-click
            if popover.isShown {
                popover.performClose(sender)
            } else {
                updatePopoverSize(taskCount: taskViewModel.tasks.count, animate: false)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    /// Displays the standard "About" panel for the application.
    @objc func showAboutPanel(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        }

        let creditsURL = URL(string: "https://github.com/TJacks0n/Tasker")
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildString = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
        let versionAndBuildString = "\(versionString) (\(buildString))"

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(
            options: [
                .credits: NSAttributedString(
                    string: "https://github.com/TJacks0n/Tasker",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                        .link: creditsURL as Any
                    ]
                ),
                .applicationVersion: versionAndBuildString,
                .version: "",
                .applicationName: "Tasker",
                NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "Copyright © 2025 TJacks0n"
            ]
        )
    }

    /// Action method called by the menu item. Delegates to the BugReporter.
    @objc func showBugReportDialog(_ sender: Any?) {
        // Close the main popover if it's open.
        if popover.isShown {
            popover.performClose(sender)
        }
        // Call the method on the BugReporter instance
        bugReporter.showReportBugDialog()
    }

    // MARK: - Popover Size Calculation & Update

    /// Calculates the appropriate popover size based on the number of tasks and current style settings.
    func calculatePopoverSize(taskCount: Int) -> NSSize {
        let inputAreaHeight = AppStyle.inputAreaHeight
        let dividerHeight = AppStyle.dividerHeight
        let listTopPadding = AppStyle.rowPadding
        let taskRowHeight = AppStyle.taskRowHeight
        let rowVerticalPadding = AppStyle.rowPadding / 2
        let footerHeight = AppStyle.footerHeight
        let emptyStateHeight = AppStyle.emptyStateHeight
        let desiredWidth = AppStyle.listWidth

        let baseHeight = inputAreaHeight + dividerHeight + dividerHeight + footerHeight

        // Add extra height for 1-5+ tasks for better visual balance
        let extraHeightForFewTasks: CGFloat
        switch taskCount {
        case 1, 2:
            extraHeightForFewTasks = taskRowHeight + AppStyle.rowPadding
        case 3:
            extraHeightForFewTasks = AppStyle.rowPadding * 1.5
        case 4...:
            extraHeightForFewTasks = AppStyle.rowPadding * 2.2
        default:
            extraHeightForFewTasks = 0
        }

        let calculatedHeight: CGFloat
        if taskCount == 0 {
            calculatedHeight = baseHeight + emptyStateHeight
        } else {
            let visibleTaskCount = min(taskCount, 5)
            let listHeight = listTopPadding + (CGFloat(visibleTaskCount) * (taskRowHeight + rowVerticalPadding * 2))
            calculatedHeight = baseHeight + listHeight + extraHeightForFewTasks
        }

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 700
        let maxHeight = screenHeight - 50
        let finalHeight = min(calculatedHeight, maxHeight)
        let minHeight: CGFloat = 110
        let clampedHeight = max(finalHeight, minHeight)

        return NSSize(width: desiredWidth, height: clampedHeight)
    }

    /// Updates the popover size, optionally animating the change.
    private func updatePopoverSize(taskCount: Int, animate: Bool = true) {
        guard let popover = popover, let hc = hostingController else { return }

        let newSize = calculatePopoverSize(taskCount: taskCount)
        hc.view.frame.size = newSize

        if popover.contentSize != newSize {
            if animate && popover.isShown {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.15
                    context.allowsImplicitAnimation = true
                    popover.contentSize = newSize
                }, completionHandler: nil)
            } else {
                popover.contentSize = newSize
            }
        }
    }
}
