//
//  AccentColorTextField.swift
//  Tasker
//
//  Created by Thomas Jackson on 24/05/2025.
//

import SwiftUI

struct AccentColorTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.textColor = NSColor.labelColor
        textField.focusRingType = .none
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.commit)
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        setInsertionPointColorIfPossible(for: nsView)
    }

    /// Tries to set the insertion point color. If the field editor is not available yet, retries after a short delay.
    private func setInsertionPointColorIfPossible(for textField: NSTextField) {
        guard let editor = textField.window?.fieldEditor(false, for: textField) as? NSTextView else {
            // Retry after a short delay if the field editor is not ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let window = textField.window {
                    _ = window.makeFirstResponder(textField)
                }
                setInsertionPointColorIfPossible(for: textField)
            }
            return
        }
        editor.insertionPointColor = AppStyle.accentNSColor
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: AccentColorTextField

        init(_ parent: AccentColorTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        @objc func commit() {
            parent.onCommit?()
        }
    }
}
