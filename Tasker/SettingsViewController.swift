import Cocoa

class AccentSidebarRowView: NSTableRowView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        NotificationCenter.default.addObserver(self, selector: #selector(accentColorChanged), name: .accentColorChanged, object: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(accentColorChanged), name: .accentColorChanged, object: nil)
    }

    @objc private func accentColorChanged() {
        self.needsDisplay = true
    }

    override func drawSelection(in dirtyRect: NSRect) {
        if isSelected {
            var accent = AccentColorManager.shared.accentColor
            if let deviceRGB = accent.usingColorSpace(.deviceRGB) {
                accent = deviceRGB
            }
            let rect = bounds.insetBy(dx: 2, dy: 4)
            let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
            accent.setFill()
            path.fill()
        }
    }
}

class ClickThroughView: NSView {
    override func mouseDown(with event: NSEvent) {
        self.window?.makeFirstResponder(nil)
        super.mouseDown(with: event)
    }
}

class SettingsViewController: NSViewController {
    private var splitViewController: NSSplitViewController!
    private var sidebarViewController: SidebarViewController!
    private var contentViewController: ContentViewController!

    override func loadView() {
        self.view = ClickThroughView(frame: NSRect(x: 0, y: 0, width: 300, height: 250))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        splitViewController = NSSplitViewController()
        splitViewController.splitView.isVertical = true
        splitViewController.view.translatesAutoresizingMaskIntoConstraints = false

        sidebarViewController = SidebarViewController()
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebarItem.minimumThickness = 150
        sidebarItem.maximumThickness = 150
        sidebarItem.canCollapse = false
        splitViewController.addSplitViewItem(sidebarItem)

        contentViewController = ContentViewController()
        let contentItem = NSSplitViewItem(viewController: contentViewController)
        splitViewController.addSplitViewItem(contentItem)

        self.addChild(splitViewController)
        self.view.addSubview(splitViewController.view)

        sidebarViewController.onSelectionChange = { [weak self] selectedItem in
            guard let self = self else { return }
            self.contentViewController.updateContent(for: selectedItem)
        }

        NSLayoutConstraint.activate([
            splitViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            splitViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            splitViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            splitViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}

class SidebarViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    private var tableView: AccentTableView!
    private var searchField: AccentSearchField!
    private let categories = ["General", "Appearance", "Startup", "Behaviour", "Data"]
    var onSelectionChange: ((String) -> Void)?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchField = AccentSearchField(frame: .zero)
        searchField.placeholderString = "Search"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(searchFieldChanged(_:))
        self.view.addSubview(searchField)

        NotificationCenter.default.addObserver(forName: .accentColorChanged, object: nil, queue: .main) { [weak self] _ in
            self?.searchField.needsDisplay = true
            self?.tableView.reloadData()
            self?.tableView.enumerateAvailableRowViews { rowView, _ in
                rowView.needsDisplay = true
            }
        }

        let scrollView = NSScrollView(frame: self.view.bounds)
        scrollView.autoresizingMask = [.width, .height]
        tableView = AccentTableView()
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CategoryColumn")))
        scrollView.documentView = tableView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            searchField.heightAnchor.constraint(equalToConstant: 30),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    @objc private func searchFieldChanged(_ sender: NSSearchField) {
        let searchText = sender.stringValue.lowercased()
        print("Search text: \(searchText)")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return categories.count
    }

    private let categoryIcons: [NSImage?] = [
        NSImage(systemSymbolName: "gear", accessibilityDescription: nil),
        NSImage(systemSymbolName: "paintbrush", accessibilityDescription: nil),
        NSImage(systemSymbolName: "power", accessibilityDescription: nil),
        NSImage(systemSymbolName: "figure.walk", accessibilityDescription: nil),
        NSImage(systemSymbolName: "tray", accessibilityDescription: nil)
    ]

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return AccentSidebarRowView()
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let container = NSView()
        container.wantsLayer = true

        let isSelected = tableView.selectedRowIndexes.contains(row)

        let icon = NSImageView()
        icon.image = categoryIcons[row]
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyDown
        icon.contentTintColor = isSelected ? .white : .labelColor
        container.addSubview(icon)

        let label = NSTextField(labelWithString: categories[row])
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .clear
        label.drawsBackground = false
        label.textColor = isSelected ? .white : .labelColor
        container.addSubview(label)

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
        tableView.setNeedsDisplay(tableView.visibleRect)
    }
}

class ContentViewController: NSViewController {
    private var currentViewController: NSViewController?

    override func loadView() {
        self.view = NSView()
    }

    func updateContent(for category: String) {
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()

        switch category {
        case "General":
            currentViewController = GeneralViewController()
        case "Appearance":
            currentViewController = AppearanceViewController()
        case "Startup":
            currentViewController = StartupViewController()
        case "Behaviour":
            currentViewController = BehaviourViewController()
        case "Data":
            currentViewController = DataViewController()
        default:
            currentViewController = nil
        }

        if let newViewController = currentViewController {
            self.addChild(newViewController)
            self.view.addSubview(newViewController.view)
            newViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                newViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                newViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                newViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                newViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.view.layoutSubtreeIfNeeded()
                newViewController.view.layoutSubtreeIfNeeded()
                let contentSize = newViewController.view.fittingSize
                if let window = self.view.window {
                    let minWidth = contentSize.width + 170
                    let minHeight = max(contentSize.height, 250)
                    window.setContentSize(NSSize(width: minWidth, height: minHeight))
                    window.minSize = NSSize(width: minWidth, height: minHeight)
                }
            }
        }
    }
}
