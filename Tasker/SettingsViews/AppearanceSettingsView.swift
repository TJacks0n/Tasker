//
//  AppearanceSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color:")
                .font(.headline)
            AccentColorPickerView()
            // Add more appearance settings here
            Spacer()
        }
        .padding()
    }
}
