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
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false

        // Create the sidebar
        sidebarViewController = SidebarViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 150
        sidebarItem.maximumThickness = 150
        sidebarItem.canCollapse = false
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

        // Set up Auto Layout
        NSLayoutConstraint.activate([
            // Split view constraints
            splitViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}

class SidebarViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    private var tableView: NSTableView!
    private var searchField: NSSearchField!
    private let categories = ["General", "Appearance", "Startup", "Behaviour", "Data"]
    var onSelectionChange: ((String) -> Void)?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create the search field
        searchField = NSSearchField(frame: .zero)
        searchField.placeholderString = "Search"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(searchFieldChanged(_:))
        self.view.addSubview(searchField)

        // Create the table view
        let scrollView = NSScrollView(frame: self.view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        tableView = NSTableView()
        tableView.headerView = nil // Remove the header
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CategoryColumn")))
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        // Set up Auto Layout
        NSLayoutConstraint.activate([
            // Search field constraints
            searchField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            searchField.heightAnchor.constraint(equalToConstant: 30),

            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    @objc private func searchFieldChanged(_ sender: NSSearchField) {
        let searchText = sender.stringValue.lowercased()
        // Filter categories based on search text (if needed)
        // TODO - Add search logic once other settings features implemented.
        print("Search text: \(searchText)")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return categories.count
    }
    
    private let categoryIcons: [NSImage?] = [
        NSImage(systemSymbolName: "gear", accessibilityDescription: nil), // Cog icon for "General"
        NSImage(systemSymbolName: "paintbrush", accessibilityDescription: nil),
        NSImage(systemSymbolName: "power", accessibilityDescription: nil),
        NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil),
        NSImage(systemSymbolName: "tray", accessibilityDescription: nil)
    ]

    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30 // Adjust the height to add spacing between rows
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // Create a horizontal container view
        let container = NSView()

        // Create the icon view
        let icon = NSImageView()
        icon.image = categoryIcons[row] // Use the corresponding icon
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyDown
        container.addSubview(icon)

        // Create the text label
        let label = NSTextField(labelWithString: categories[row])
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        // Set up Auto Layout
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 5),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 5),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -5)
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
