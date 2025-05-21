//
//  AccentTableView.swift
//  Tasker
//
//  Created by Thomas Jackson on 21/05/2025.
//

import Cocoa

class AccentTableView: NSTableView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.selectionHighlightStyle = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.selectionHighlightStyle = .none
    }
}
