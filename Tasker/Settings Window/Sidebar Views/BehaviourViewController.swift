//
//  BehaviourViewController.swift
//  Tasker
//
//  Created by Thomas Jackson on 19/05/2025.
//

import Cocoa

class BehaviourViewController: NSViewController {
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 400))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = NSTextField(labelWithString: "Behaviour Settings")
        label.font = NSFont.systemFont(ofSize: 15)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
    }
}
