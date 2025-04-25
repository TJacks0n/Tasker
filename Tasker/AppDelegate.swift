// In AppDelegate.swift
import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var taskViewModel = TaskViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var hostingController: NSHostingController<TaskListView>?

    // --- Estimated Heights ---
    let inputAreaHeight: CGFloat = 45
    let dividerHeight: CGFloat = 1
    let listTopPadding: CGFloat = 5 // Padding above the LazyVStack
    let taskRowHeight: CGFloat = 21 // Adjusted height per row
    let footerHeight: CGFloat = 40 // Adjusted footer height
    let emptyStateHeight: CGFloat = 60
    let desiredWidth: CGFloat = 300
    // --- End Estimated Heights ---


    func applicationDidFinishLaunching(_ notification: Notification) {
        // NSApp.setActivationPolicy(.accessory) // <<< REMOVE this immediate call

        let contentView = TaskListView(viewModel: taskViewModel)
        let initialSize = calculatePopoverSize(taskCount: taskViewModel.tasks.count)

        self.hostingController = NSHostingController(rootView: contentView)
        self.hostingController?.view.frame.size = initialSize
        self.hostingController?.view.layer?.backgroundColor = NSColor.clear.cgColor

        popover = NSPopover()
        popover.contentSize = initialSize
        popover.contentViewController = hostingController
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "menuBarIcon")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About Tasker", action: #selector(showAboutPanel(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Tasker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        taskViewModel.$tasks
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] tasks in
                guard let self = self else { return }
                self.updatePopoverSize(taskCount: tasks.count, animate: true)
            }
            .store(in: &cancellables)

        // <<< Schedule hiding the Dock icon after a delay (e.g., 2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() +  1.0) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            if popover.isShown {
                popover.performClose(sender)
            }
            // Activate briefly to show menu even in accessory mode
            NSApp.activate(ignoringOtherApps: true)
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        } else { // Left mouse up
            if popover.isShown {
                popover.performClose(sender)
            } else {
                updatePopoverSize(taskCount: taskViewModel.tasks.count, animate: false)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                // Make the popover window key without activating the app globally
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    @objc func showAboutPanel(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        }
        let creditsURL = URL(string: "https://github.com/TJacks0n/Tasker")

        // Get Version and Build numbers
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let buildString = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1" // kCFBundleVersionKey is "CFBundleVersion"
        let versionAndBuildString = "\(versionString) (\(buildString))" // Combine them

        // Activate briefly to show the About panel
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(
                    options: [
                        .credits: NSAttributedString(
                            string: "https://github.com/TJacks0n/Tasker", // Display text
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

    // Calculate size based on task count and estimated heights
    private func calculatePopoverSize(taskCount: Int) -> NSSize {
        var calculatedHeight: CGFloat = 0
        let baseHeight = inputAreaHeight + dividerHeight + dividerHeight + footerHeight

        if taskCount == 0 {
            calculatedHeight = baseHeight + emptyStateHeight
        } else {
            let listHeight = listTopPadding + (CGFloat(taskCount) * taskRowHeight)
            calculatedHeight = baseHeight + listHeight
        }

        let screenHeight = NSScreen.main?.visibleFrame.height ?? 700
        let maxHeight = screenHeight - 50
        let finalHeight = min(calculatedHeight, maxHeight)
        let minHeight: CGFloat = 110
        let clampedHeight = max(finalHeight, minHeight)

        return NSSize(width: desiredWidth, height: clampedHeight)
    }


    // Update popover size using the calculation method
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
