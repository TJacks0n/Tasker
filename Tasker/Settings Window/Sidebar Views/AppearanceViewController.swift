import Cocoa

class AppearanceViewController: NSViewController {
    private let themeDropdown = NSPopUpButton()
    private let colorButtonsStack = NSStackView()
    private let colorLabel = NSTextField(labelWithString: "")
    private var selectedAccentColor: NSColor?
    private let colorNames = ["Blue", "Red", "Green", "Yellow", "System", "Custom"]
    private var colorLabelCenterConstraint: NSLayoutConstraint?

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
        accentColorRow.distribution = .fill
        accentColorRow.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(accentColorRow)

        let accentColorLabel = NSTextField(labelWithString: "Accent Color")
        accentColorLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        accentColorLabel.alignment = .left
        accentColorLabel.translatesAutoresizingMaskIntoConstraints = false
        accentColorRow.addArrangedSubview(accentColorLabel)
        accentColorLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true

        // Add flexible spacer to push buttons to the right
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        accentColorRow.addArrangedSubview(spacer)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Color buttons stack
        colorButtonsStack.orientation = .horizontal
        colorButtonsStack.spacing = 15
        colorButtonsStack.alignment = .centerY
        colorButtonsStack.distribution = .equalSpacing
        colorButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        accentColorRow.addArrangedSubview(colorButtonsStack)
        colorButtonsStack.setContentHuggingPriority(.required, for: .horizontal)
        colorButtonsStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let colors: [NSColor] = [
            .systemBlue, .systemRed, .systemGreen, .systemYellow, .controlAccentColor, .controlBackgroundColor
        ]
        let actions: [Selector?] = [
            #selector(colorButtonPressed(_:)),
            #selector(colorButtonPressed(_:)),
            #selector(colorButtonPressed(_:)),
            #selector(colorButtonPressed(_:)),
            #selector(colorButtonPressed(_:)),
            #selector(openColorPicker)
        ]

        for (i, color) in colors.enumerated() {
            let button = ColorButton(color: color)
            button.action = actions[i]
            button.target = self
            button.tag = i
            button.widthAnchor.constraint(equalToConstant: 18).isActive = true
            button.heightAnchor.constraint(equalToConstant: 18).isActive = true
            colorButtonsStack.addArrangedSubview(button)
        }

        // Single label for color name
        colorLabel.font = NSFont.systemFont(ofSize: 9)
        colorLabel.alignment = .center
        colorLabel.isEditable = false
        colorLabel.isBordered = false
        colorLabel.backgroundColor = .clear
        colorLabel.alphaValue = 0.0
        colorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(colorLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 20),

            themeRow.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            themeRow.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            themeRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),

            accentColorRow.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            accentColorRow.topAnchor.constraint(equalTo: themeRow.bottomAnchor, constant: 20),
            accentColorRow.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),

            colorButtonsStack.heightAnchor.constraint(equalToConstant: 18),

            colorLabel.topAnchor.constraint(equalTo: accentColorRow.bottomAnchor, constant: 6),
            colorLabel.widthAnchor.constraint(equalToConstant: 50),
            self.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 350)
        ])

        // Initial constraint: center label under the first button
        if let firstButton = colorButtonsStack.arrangedSubviews.first {
            colorLabelCenterConstraint = colorLabel.centerXAnchor.constraint(equalTo: firstButton.centerXAnchor)
            colorLabelCenterConstraint?.isActive = true
        }
    }

    @objc private func colorButtonPressed(_ sender: ColorButton) {
        for (i, view) in colorButtonsStack.arrangedSubviews.enumerated() {
            if let button = view as? ColorButton {
                button.isSelected = (button == sender)
                if button == sender {
                    colorLabel.stringValue = colorNames[i]
                    colorLabel.alphaValue = 1.0
                    moveLabel(under: button)
                }
            }
        }
        if let backgroundColor = sender.layer?.backgroundColor {
            selectedAccentColor = NSColor(cgColor: backgroundColor)
            applyAccentColor()
        }
    }

    private func moveLabel(under button: NSView) {
        colorLabelCenterConstraint?.isActive = false
        colorLabelCenterConstraint = colorLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor)
        colorLabelCenterConstraint?.isActive = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            self.view.layoutSubtreeIfNeeded()
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

        if let popup = actionView as? NSPopUpButton {
            popup.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        }

        return row
    }

    private func applyAccentColor() {
        guard let color = selectedAccentColor else { return }
        NotificationCenter.default.post(name: .accentColorChanged, object: color)
    }

    @objc private func openColorPicker(_ sender: ColorButton) {
        let colorPanel = NSColorPanel.shared
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(customColorSelected(_:)))
        colorPanel.orderFront(nil)
        // Show label for "Custom"
        for (i, view) in colorButtonsStack.arrangedSubviews.enumerated() {
            if let button = view as? ColorButton {
                button.isSelected = (button == sender)
                if button == sender {
                    colorLabel.stringValue = colorNames[i]
                    colorLabel.alphaValue = 1.0
                    moveLabel(under: button)
                }
            }
        }
    }

    @objc private func customColorSelected(_ sender: NSColorPanel) {
        let selectedColor = sender.color
        selectedAccentColor = selectedColor
        applyAccentColor()
        // Highlight "Custom" button and update label
        if let customButton = colorButtonsStack.arrangedSubviews.last as? ColorButton {
            customButton.layer?.backgroundColor = selectedColor.cgColor
            for (i, view) in colorButtonsStack.arrangedSubviews.enumerated() {
                if let button = view as? ColorButton {
                    button.isSelected = (button == customButton)
                    if button == customButton {
                        colorLabel.stringValue = colorNames[i]
                        colorLabel.alphaValue = 1.0
                        moveLabel(under: button)
                    }
                }
            }
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
