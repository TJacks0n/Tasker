//  GeneralSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI

/// General settings for Tasker.
/// Add controls for general app preferences here.
struct GeneralSettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // --- Add Task Position Section ---
            VStack(alignment: .leading, spacing: 10) {
                Text("Add Task Position")
                    .font(.system(size: settings.fontSize, weight: .bold))
                // Use the custom accent-colored selector for Top/Bottom
                AddTaskPositionSelector(selection: $settings.addTaskPosition)
                    .environmentObject(settings)
                Text("Choose whether new tasks appear at the top or bottom of your list.")
                    .font(.system(size: settings.fontSize * 0.8))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)

            Spacer()
        }
        .font(.system(size: settings.fontSize))
        .padding()
    }
}
