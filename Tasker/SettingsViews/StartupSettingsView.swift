//
//  StartupSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI

/// Startup settings view, now including the custom-styled "Launch at Login" checkbox.
struct StartupSettingsView: View {
    @EnvironmentObject var settings: SettingsManager
    @StateObject private var launchAtLogin = LaunchAtLoginManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // --- Launch at Login Section ---
            VStack(alignment: .leading, spacing: 10) {
                Text("Launch settings")
                    .font(.system(size: settings.fontSize, weight: .bold))
                HStack {
                    RoundedCheckbox(
                        isOn: $launchAtLogin.isEnabled,
                        accentColor: settings.accentColor,
                        size: settings.fontSize * 1.2,
                        disabled: !isLaunchAtLoginSupported
                    )
                    .onChange(of: launchAtLogin.isEnabled) { _, newValue in
                        launchAtLogin.setEnabled(newValue)
                    }
                    Text("Launch Tasker at Login")
                        .font(.system(size: settings.fontSize * 0.95))
                        .foregroundColor(.primary)
                }
                .disabled(!isLaunchAtLoginSupported)
                Text("Start Tasker automatically when you log in to your Mac.")
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

    /// Checks if Launch at Login is supported on this macOS version.
    private var isLaunchAtLoginSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }
}
