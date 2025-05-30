//
//  SettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 28/05/2025.
//

import SwiftUI

/// The settings view for the app.
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared

    var body: some View {
        Form {
            Stepper("Font Size: \(Int(settings.fontSize))", value: $settings.fontSize, in: 10...30)
        }
        .padding()
        .frame(width: 350)
    }
}
