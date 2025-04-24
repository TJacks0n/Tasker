import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let taskViewModel = TaskViewModel()
        let contentView = TaskListView(viewModel: taskViewModel)

        popover = NSPopover()
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        popover.behavior = .transient

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Tasker")
            button.action = #selector(togglePopover(_:))
        }

        // Observe task changes to update popover size
        taskViewModel.$tasks
            .sink { [weak self] _ in
                self?.updatePopoverSize(for: hostingController)
            }
            .store(in: &cancellables)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        }
    }

    private func updatePopoverSize(for hostingController: NSHostingController<TaskListView>) {
        guard let popover = popover else { return }

        DispatchQueue.main.async {
            // Calculate the height dynamically based on the content
            let contentSize = hostingController.view.intrinsicContentSize
            let screenHeight = NSScreen.main?.visibleFrame.height ?? 700
            let maxHeight = screenHeight - 50 // Leave space for the menu bar
            let newHeight = min(contentSize.height, maxHeight)

            popover.contentSize = NSSize(width: 300, height: newHeight)
        }
    }
}
