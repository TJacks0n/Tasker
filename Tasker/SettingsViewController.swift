//
//  SettingsViewController.swift
//  Tasker
//
//  Created by Thomas Jackson on 28/05/2025.
//

import Cocoa

class SettingsViewController: NSViewController {
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
}
