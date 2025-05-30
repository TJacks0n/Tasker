import Cocoa
import SwiftUI
import Combine

/// Handles application-level events and manages the menu bar item (status item) and its associated popovers.
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var taskViewModel = TaskViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var hostingController: NSHostingController<AnyView>?
    private let bugReporter = BugReporter()
    private var settingsWindow: NSWindow?
    private var menuPopover: NSPopover?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup the main content view and hosting controller for the left-click popover
        let contentView = TaskListView(viewModel: taskViewModel)
            .environmentObject(SettingsManager.shared)
        let initialSize = calculatePopoverSize(taskCount: taskViewModel.tasks.count)
        self.hostingController = NSHostingController(rootView: AnyView(contentView))
        self.hostingController?.view.frame.size = initialSize
        self.hostingController?.view.wantsLayer = true
        self.hostingController?.view.layer?.backgroundColor = NSColor.clear.cgColor

        // Setup the left-click popover
        popover = NSPopover()
        popover.contentSize = initialSize
        popover.contentViewController = hostingController
        popover.contentViewController?.view.setAccessibilityIdentifier("TaskerPopoverWindow")
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .vibrantDark)

        // Setup the status item (menu bar icon)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "menuBarIcon")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Observe changes to the task list and update popover size accordingly
        taskViewModel.$tasks
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] tasks in
                guard let self = self else { return }
                self.updatePopoverSize(taskCount: tasks.count, animate: true)
            }
            .store(in: &cancellables)

        // Observe changes to font size and update popover size dynamically
        SettingsManager.shared.$fontSize
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updatePopoverSize(taskCount: self.taskViewModel.tasks.count, animate: true)
            }
            .store(in: &cancellables)

        // Set activation policy after a short delay (for menu bar app behavior)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.setActivationPolicy(.accessory)
        }

        // Register Cmd + , shortcut for settings
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.characters == "," {
                self?.showSettingsWindow()
                return nil
            }
            return event
        }
    }

    // MARK: - Actions

    /// Toggles the popover's visibility or shows the SwiftUI menu popover on right-click.
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Close any open popovers
            if popover.isShown {
                popover.performClose(sender)
            }
            if menuPopover?.isShown == true {
                menuPopover?.performClose(sender)
                return
            }
            // Show SwiftUI menu popover for right-click
            let menuView = TaskerSwiftUIMenu()
            let hostingController = NSHostingController(rootView: menuView)
            let popover = NSPopover()
            popover.contentViewController = hostingController
            popover.behavior = .transient
            popover.appearance = NSAppearance(named: .vibrantDark)
            self.menuPopover = popover
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        } else { // Left-click
            if menuPopover?.isShown == true {
                menuPopover?.performClose(sender)
            }
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
        if menuPopover?.isShown == true {
            menuPopover?.performClose(sender)
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
        if popover.isShown {
            popover.performClose(sender)
        }
        if menuPopover?.isShown == true {
            menuPopover?.performClose(sender)
        }
        bugReporter.showReportBugDialog()
    }

    /// Shows the settings window for all supported macOS versions.
    @objc func showSettingsWindow(_ sender: Any? = nil) {
        NSApp.activate(ignoringOtherApps: true)
        if settingsWindow == nil {
            // Inject SettingsManager.shared as environment object for live updates
            let settingsView = SettingsView()
                .environmentObject(SettingsManager.shared)
            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Tasker Settings"
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.setContentSize(NSSize(width: 500, height: 320))
            window.center()
            // Set window background to AppStyle (clear)
            window.isOpaque = false
            window.backgroundColor = NSColor.clear
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
            // Ensure the NSHostingController's view is also clear to allow frosted effect
            hostingController.view.wantsLayer = true
            hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Popover Size Calculation & Update

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

    private func updatePopoverSize(taskCount: Int, animate: Bool = true) {
        guard let popover = popover, let hc = hostingController else { return }

        let newSize = calculatePopoverSize(taskCount: taskCount)
        hc.view.frame.size = newSize

        if popover.contentSize != newSize {
            if animate && popover.isShown {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.35
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    context.allowsImplicitAnimation = true
                    popover.contentSize = newSize
                }, completionHandler: nil)
            } else {
                popover.contentSize = newSize
            }
        }
    }
}
