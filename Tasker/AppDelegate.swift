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
    private var settingsCancellable: AnyCancellable?

    // Track the currently selected settings category for dynamic window height
    private var currentSettingsCategory: SettingsCategory = .general

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

        // Observe fontSize changes to resize settings window
        settingsCancellable = SettingsManager.shared.$fontSize
            .sink { [weak self] _ in
                self?.resizeSettingsWindow()
            }

        // Observe font size commit notification to always resize settings window
        NotificationCenter.default.addObserver(
            forName: .settingsFontSizeDidCommit,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resizeSettingsWindow()
        }

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
            let menuView = TaskerSwiftUIMenu(onShowSettings: { [weak self] in
                self?.menuPopover?.performClose(nil)
                self?.showSettingsWindow()
            })
            .environmentObject(SettingsManager.shared)
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

    /// Shows the settings window with a glass/blurred background and dynamic sizing.
    /// The window height now adapts to the selected settings category.
    @objc func showSettingsWindow(_ sender: Any? = nil) {
        NSApp.activate(ignoringOtherApps: true)
        let settings = SettingsManager.shared

        // --- Calculate dynamic width based on widest category button and minimum width ---
        let minWidth: CGFloat = 400
        let buttonBarWidth = SettingsCategory.allCases
            .map { category in
                let font = NSFont.systemFont(ofSize: settings.fontSize * 0.85, weight: .medium)
                let labelWidth = category.title.size(withAttributes: [.font: font]).width
                return labelWidth + settings.fontSize * 2.5 // icon + padding
            }
            .reduce(0, +) + CGFloat(SettingsCategory.allCases.count - 1) * 8 + 48 // spacing + side padding
        let contentWidth = max(settings.listWidth, buttonBarWidth, minWidth) + 60

        // --- Use per-category base height ---
        let baseHeight: CGFloat = currentSettingsCategory.preferredHeight
        let extraPerPoint: CGFloat = 8
        let windowHeight = baseHeight + max(0, (settings.fontSize - 13)) * extraPerPoint
        let windowSize = NSSize(width: contentWidth, height: windowHeight)

        if settingsWindow == nil {
            // 1. Create the blur background view
            let blurView = NSVisualEffectView(frame: NSRect(origin: .zero, size: windowSize))
            blurView.blendingMode = .behindWindow
            blurView.material = .sidebar
            blurView.state = .active
            blurView.autoresizingMask = [.width, .height]

            // 2. Create the SwiftUI settings view, passing a closure to update the category
            let settingsView = SettingsView(onCategoryChange: { [weak self] category in
                self?.currentSettingsCategory = category
                self?.resizeSettingsWindow()
            })
            .environmentObject(SettingsManager.shared)
            let hostingController = NSHostingController(rootView: settingsView)
            hostingController.view.frame = blurView.bounds
            hostingController.view.autoresizingMask = [.width, .height]
            hostingController.view.wantsLayer = false

            // 3. Add SwiftUI view to blur view
            blurView.addSubview(hostingController.view)

            // 4. Create the window with the blur view as contentView
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: windowSize),
                                  styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                                  backing: .buffered,
                                  defer: false)
            window.contentView = blurView
            window.title = "Tasker Settings"
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = true
            window.isOpaque = false
            window.backgroundColor = .clear
            window.center()

            settingsWindow = window
        }
        resizeSettingsWindow()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    /// Resizes the settings window to match the current font size, width, and selected category.
    func resizeSettingsWindow() {
        guard let window = settingsWindow else { return }
        let settings = SettingsManager.shared

        let minWidth: CGFloat = 400
        let buttonBarWidth = SettingsCategory.allCases
            .map { category in
                let font = NSFont.systemFont(ofSize: settings.fontSize * 0.85, weight: .medium)
                let labelWidth = category.title.size(withAttributes: [.font: font]).width
                return labelWidth + settings.fontSize * 2.5
            }
            .reduce(0, +) + CGFloat(SettingsCategory.allCases.count - 1) * 8 + 48
        let contentWidth = max(settings.listWidth, buttonBarWidth, minWidth) + 60

        // Use the preferred height for the current category
        let baseHeight: CGFloat = currentSettingsCategory.preferredHeight
        let extraPerPoint: CGFloat = 8
        let windowHeight = baseHeight + max(0, (settings.fontSize - 13)) * extraPerPoint
        let newSize = NSSize(width: contentWidth, height: windowHeight)

        // Use a custom timing function for a "bouncy" feel (overshoot)
        let bounceTiming = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.55
            context.timingFunction = bounceTiming
            window.animator().setContentSize(newSize)
            // Do NOT animate blurView or hostingView frames—let autoresizing handle it
        }, completionHandler: nil)
    }

    // MARK: - Popover Size Calculation & Update

    /// Calculates the popover size based on the number of tasks and current settings.
    func calculatePopoverSize(taskCount: Int) -> NSSize {
        let settings = SettingsManager.shared
        let inputAreaHeight = settings.inputAreaHeight
        let dividerHeight = AppStyle.dividerHeight
        let listTopPadding = settings.rowPadding
        let taskRowHeight = settings.taskRowHeight
        let rowVerticalPadding = settings.rowPadding / 2
        let footerHeight = settings.footerHeight
        let emptyStateHeight = settings.emptyStateHeight
        let desiredWidth = settings.listWidth

        let baseHeight = inputAreaHeight + dividerHeight + dividerHeight + footerHeight

        let extraHeightForFewTasks: CGFloat
        switch taskCount {
        case 1, 2:
            extraHeightForFewTasks = taskRowHeight + settings.rowPadding
        case 3:
            extraHeightForFewTasks = settings.rowPadding * 1.5
        case 4...:
            extraHeightForFewTasks = settings.rowPadding * 2.2
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

    /// Updates the popover size, animating if requested.
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
