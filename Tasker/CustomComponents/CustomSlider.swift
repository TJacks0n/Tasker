//
//  CustomSlider.swift
//  Tasker
//
//  Created by Thomas Jackson on 04/06/2025.
//

import SwiftUI

/// A custom slider view for macOS that shows visible increments (dots) inside the slider bar.
struct AccentSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    var onEditingChanged: ((Bool) -> Void)? = nil
    @EnvironmentObject var settings: SettingsManager

    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let steps = Int((range.upperBound - range.lowerBound) / step)
            let percent = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbRadius: CGFloat = 8
            let dotSize: CGFloat = 4

            // Thumb center X: goes from 0 to width
            let thumbX = percent * width

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 4)
                    .frame(maxHeight: .infinity, alignment: .center)

                // Step dots inside the bar
                ForEach(0...steps, id: \.self) { i in
                    let x = CGFloat(i) / CGFloat(steps) * width
                    let isFilled = x <= thumbX + 0.5
                    Circle()
                        .fill(isFilled ? settings.accentColor : Color.secondary.opacity(0.45))
                        .frame(width: dotSize, height: dotSize)
                        .position(x: x, y: 12)
                }

                // Fill track (fix: no minimum width)
                Capsule()
                    .fill(settings.accentColor)
                    .frame(width: percent * width, height: 4)
                    .frame(maxHeight: .infinity, alignment: .center)

                // Thumb
                Circle()
                    .fill(settings.accentColor)
                    .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                    .shadow(color: .black.opacity(0.10), radius: 1, x: 0, y: 1)
                    .position(x: thumbX, y: 12)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let x = min(max(0, gesture.location.x), width)
                                let percent = x / width
                                let rawValue = range.lowerBound + percent * (range.upperBound - range.lowerBound)
                                let newValue = (rawValue / step).rounded() * step
                                value = min(max(range.lowerBound, newValue), range.upperBound)
                                onEditingChanged?(true)
                            }
                            .onEnded { _ in
                                onEditingChanged?(false)
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}
