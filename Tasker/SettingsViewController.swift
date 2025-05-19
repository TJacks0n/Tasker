//
//  SettingsViewController.swift
//  Tasker
//
//  Created by Thomas Jackson on 19/05/2025.
//

import Cocoa

class SettingsViewController: NSViewController {
    private var splitViewController: NSSplitViewController!
    private var sidebarViewController: SidebarViewController!
    private var contentViewController: ContentViewController!

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 250))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the split view controller
        splitViewController = NSSplitViewController()
        splitViewController.splitView.isVertical = true
        splitViewController.view.frame = self.view.bounds
        splitViewController.view.autoresizingMask = [.width, .height]

        // Create the sidebar
        sidebarViewController = SidebarViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 125
        sidebarItem.maximumThickness = 125 // Fixed size
        sidebarItem.canCollapse = false // Prevent collapsing
        splitViewController.addSplitViewItem(sidebarItem)

        // Create the content area
        contentViewController = ContentViewController()
        let contentItem = NSSplitViewItem(viewController: contentViewController)
        splitViewController.addSplitViewItem(contentItem)

        // Add the split view controller to the main view
        self.addChild(splitViewController)
        self.view.addSubview(splitViewController.view)

        // Handle the sidebar selection
        sidebarViewController.onSelectionChange = { [weak self] selectedItem in
            guard let self = self else { return }
            self.contentViewController.updateContent(for: selectedItem)
        }
    }
}

class SidebarViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    private var tableView: NSTableView!
    private let categories = ["General", "Appearance", "Startup", "Behavior", "Data"]
    var onSelectionChange: ((String) -> Void)?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the table view
        let scrollView = NSScrollView(frame: self.view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        tableView = NSTableView()
        tableView.headerView = nil // Remove the header
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CategoryColumn")))
        scrollView.documentView = tableView
        self.view.addSubview(scrollView)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return categories.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = NSTextField(labelWithString: categories[row])
        cell.font = NSFont.systemFont(ofSize: 13)
        cell.alignment = .left // Align text to the left horizontally
        cell.translatesAutoresizingMaskIntoConstraints = false

        // Create a container view to center the text vertically
        let container = NSView()
        container.addSubview(cell)

        NSLayoutConstraint.activate([
            cell.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10), // Add padding to the left
            cell.centerYAnchor.constraint(equalTo: container.centerYAnchor) // Center vertically
        ])

        return container
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            onSelectionChange?(categories[selectedRow])
        }
    }
}

class ContentViewController: NSViewController {
    private var contentLabel: NSTextField!

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a placeholder label
        contentLabel = NSTextField(labelWithString: "Select a category from the sidebar")
        contentLabel.font = NSFont.systemFont(ofSize: 15)
        contentLabel.alignment = .center
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            contentLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            contentLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
    }

    func updateContent(for category: String) {
        contentLabel.stringValue = "Selected category: \(category)"
    }
}
