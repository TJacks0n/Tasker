import Cocoa

class AppearanceViewController: NSViewController {
    private let themeDropdown = NSPopUpButton()
    private let colorButtonsStack = NSStackView()
    private var selectedAccentColor: NSColor?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Title label
        let titleLabel = NSTextField(labelWithString: "Appearance Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(titleLabel)

        // Theme row
        let themeRow = createRow(labelText: "Theme", actionView: themeDropdown)
        themeDropdown.addItems(withTitles: ["System", "Light", "Dark"])
        themeDropdown.target = self
        themeDropdown.action = #selector(themeChanged(_:))
        themeDropdown.translatesAutoresizingMaskIntoConstraints = false
        themeDropdown.heightAnchor.constraint(equalToConstant: 25).isActive = true
        self.view.addSubview(themeRow)

        // Accent color row
        let accentColorRow = NSStackView()
        accentColorRow.orientation = .horizontal
        accentColorRow.spacing = 10
        accentColorRow.alignment = .top
        accentColorRow.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(accentColorRow)

        let accentColorLabel = NSTextField(labelWithString: "Accent Color")
        accentColorLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        accentColorLabel.alignment = .left
        accentColorLabel.translatesAutoresizingMaskIntoConstraints = false
        accentColorRow.addArrangedSubview(accentColorLabel)
        accentColorLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true

        // Color buttons stack
        colorButtonsStack.orientation = .horizontal
        colorButtonsStack.spacing = 15
        colorButtonsStack.alignment = .top
        colorButtonsStack.distribution = .fill
        colorButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        accentColorRow.addArrangedSubview(colorButtonsStack)

        let colors: [(NSColor, String, Selector?)] = [
            (.systemBlue, "Blue", #selector(colorButtonPressed(_:))),
            (.systemRed, "Red", #selector(colorButtonPressed(_:))),
            (.systemGreen, "Green", #selector(colorButtonPressed(_:))),
            (.systemYellow, "Yellow", #selector(colorButtonPressed(_:))),
            (.controlAccentColor, "System", #selector(colorButtonPressed(_:))),
            (.controlBackgroundColor, "Custom", #selector(openColorPicker))
        ]

        for (color, labelText, action) in colors {
            let container = NSStackView()
            container.orientation = .vertical
            container.alignment = .centerX
            container.spacing = 2
            container.translatesAutoresizingMaskIntoConstraints = false

            let button = ColorButton(color: color)
            button.action = action
            button.target = self
            button.widthAnchor.constraint(equalToConstant: 18).isActive = true
            button.heightAnchor.constraint(equalToConstant: 18).isActive = true
            container.addArrangedSubview(button)

            let label = NSTextField(labelWithString: labelText)
            label.font = NSFont.systemFont(ofSize: 9)
            label.alignment = .center
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            label.isHidden = true
            label.lineBreakMode = .byClipping
            label.setContentHuggingPriority(.required, for: .horizontal)
            container.addArrangedSubview(label)

            colorButtonsStack.addArrangedSubview(container)
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),

            themeRow.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            themeRow.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            themeRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),

            accentColorRow.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            accentColorRow.topAnchor.constraint(equalTo: themeRow.bottomAnchor, constant: 20),
            accentColorRow.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20),
            self.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 350)
        ])
    }

    @objc private func colorButtonPressed(_ sender: ColorButton) {
        for view in colorButtonsStack.arrangedSubviews {
            if let container = view as? NSStackView,
               let button = container.arrangedSubviews.first as? ColorButton,
               let label = container.arrangedSubviews.last as? NSTextField {
                button.isSelected = false
                label.isHidden = true
            }
        }
        if let container = sender.superview as? NSStackView,
           let label = container.arrangedSubviews.last as? NSTextField {
            sender.isSelected = true
            label.isHidden = false
        }
        if let backgroundColor = sender.layer?.backgroundColor {
            selectedAccentColor = NSColor(cgColor: backgroundColor)
            applyAccentColor()
        }
    }

    private func createRow(labelText: String, actionView: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: labelText)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false

        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 10
        row.alignment = .centerY
        row.distribution = .fill
        row.translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(label)
        row.addArrangedSubview(actionView)
        label.widthAnchor.constraint(equalToConstant: 100).isActive = true

        // Do NOT set any width constraint on the popup
        if let popup = actionView as? NSPopUpButton {
            popup.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }

        return row
    }

    private func applyAccentColor() {
        guard let color = selectedAccentColor else { return }
        NotificationCenter.default.post(name: .accentColorChanged, object: color)
    }

    @objc private func openColorPicker() {
        let colorPanel = NSColorPanel.shared
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(customColorSelected(_:)))
        colorPanel.orderFront(nil)
    }

    @objc private func customColorSelected(_ sender: NSColorPanel) {
        let selectedColor = sender.color
        selectedAccentColor = selectedColor
        applyAccentColor()
        for view in colorButtonsStack.arrangedSubviews {
            if let container = view as? NSStackView,
               let button = container.arrangedSubviews.first as? ColorButton,
               let label = container.arrangedSubviews.last as? NSTextField {
                button.isSelected = false
                label.isHidden = true
            }
        }
        if let customContainer = colorButtonsStack.arrangedSubviews.last as? NSStackView,
           let customButton = customContainer.arrangedSubviews.first as? ColorButton,
           let customLabel = customContainer.arrangedSubviews.last as? NSTextField {
            customButton.layer?.backgroundColor = selectedColor.cgColor
            customButton.isSelected = true
            customLabel.isHidden = false
        }
    }

    @objc private func themeChanged(_ sender: NSPopUpButton) {
        switch sender.titleOfSelectedItem {
        case "System":
            NSApp.appearance = nil
        case "Light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "Dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            break
        }
    }
}

class ColorButton: NSButton {
    private let selectionIndicator: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = NSColor.white.cgColor
        layer.cornerRadius = 2
        layer.isHidden = true
        return layer
    }()

    var isSelected: Bool = false {
        didSet {
            selectionIndicator.isHidden = !isSelected
        }
    }

    init(color: NSColor) {
        super.init(frame: .zero)
        self.title = ""
        self.wantsLayer = true
        self.layer?.backgroundColor = color.cgColor
        self.layer?.cornerRadius = 4
        self.layer?.borderWidth = 1
        self.layer?.borderColor = NSColor.separatorColor.cgColor
        self.isBordered = false
        self.translatesAutoresizingMaskIntoConstraints = false

        self.layer?.addSublayer(selectionIndicator)
        selectionIndicator.frame = CGRect(x: 5, y: 5, width: 8, height: 8)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Notification.Name {
    static let accentColorChanged = Notification.Name("accentColorChanged")
}
