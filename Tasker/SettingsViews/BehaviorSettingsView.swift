//
//  BehaviorSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI

struct BehaviorSettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // --- Task Persistence Section ---
            VStack(alignment: .leading, spacing: 10) {
                Text("Task Persistence")
                    .font(.system(size: settings.fontSize, weight: .bold))
                HStack {
                    Toggle(isOn: $settings.retainTasksOnClose) {
                        Text("Retain tasks when Tasker is closed")
                            .font(.system(size: settings.fontSize * 0.95))
                            .foregroundColor(.primary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: settings.accentColor))
                }
                Text("If enabled, your tasks will be saved and restored when you reopen Tasker.")
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
