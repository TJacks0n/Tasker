//
//  AppearanceSettingsView.swift
//  Tasker
//
//  Created by Thomas Jackson on 30/05/2025.
//

import SwiftUI

struct AccentColorPickerView: View {
    @ObservedObject var settings = SettingsManager.shared
    let colors: [Color] = [.yellow, .blue, .green, .orange, .pink, .purple]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(colors, id: \.self) { color in
                Button(action: {
                    settings.accentColor = color
                }) {
                    ZStack {
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                        // Inner circle for selection indicator
                        if settings.accentColor == color {
                            Circle()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 10, height: 10)
                                .shadow(radius: 1)
                                .animation(nil, value: settings.accentColor)
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(settings.accentColor == color ? 0.8 : 0.2), lineWidth: 3)
                            .animation(nil, value: settings.accentColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}
