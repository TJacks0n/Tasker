//
//  AccentSearchField.swift
//  Tasker
//
//  Created by Thomas Jackson on 21/05/2025.
//

import Cocoa

class AccentSearchField: NSSearchField {
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLayer()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        self.wantsLayer = true
        self.focusRingType = .none
        self.layer?.cornerRadius = 6
        self.layer?.borderWidth = 0
        NotificationCenter.default.addObserver(self, selector: #selector(updateOutline), name: NSWindow.didBecomeKeyNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateOutline), name: NSWindow.didResignKeyNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateOutline), name: NSControl.textDidBeginEditingNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(updateOutline), name: NSControl.textDidEndEditingNotification, object: self)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        updateOutline()
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        updateOutline()
        return result
    }

    // This ensures the outline is removed as soon as focus leaves the field
    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        updateOutline()
    }

    @objc private func updateOutline() {
        let isEditing = (window?.firstResponder == currentEditor())
        self.layer?.borderColor = isEditing ? AccentColorManager.shared.accentColor.cgColor : nil
        self.layer?.borderWidth = isEditing ? 2 : 0
    }
}
