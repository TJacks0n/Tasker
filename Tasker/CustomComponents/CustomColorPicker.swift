import SwiftUI

struct CustomColorPickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State var currentColor: Color
    let onSet: (Color) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Pick a Custom Accent Color")
                .font(.headline)
            ColorWheelView(selectedColor: $currentColor)
                .frame(width: 220, height: 220)
            HStack {
                Button("Cancel") {
                    onCancel()
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
                Button("Set") {
                    onSet(currentColor)
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 300)
    }
}

struct ColorWheelView: View {
    @Binding var selectedColor: Color
    @State private var dragLocation: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            ZStack {
                // Draw the color wheel
                ColorWheelShape()
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let color = colorAt(point: value.location, in: CGSize(width: size, height: size))
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedColor = color
                                    dragLocation = value.location
                                }
                            }
                    )
                // Selection indicator
                SelectionIndicator(
                    color: selectedColor,
                    wheelSize: size
                )
                // Show selected color in the center
                Circle()
                    .fill(selectedColor)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 2))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Returns the color at a given point in the color wheel.
    private func colorAt(point: CGPoint, in size: CGSize) -> Color {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radius = sqrt(dx*dx + dy*dy)
        let maxRadius = min(size.width, size.height) / 2

        guard radius <= maxRadius else { return selectedColor }

        let angle = atan2(dy, dx)
        let hue = (angle < 0 ? angle + 2 * .pi : angle) / (2 * .pi)
        let saturation = min(radius / maxRadius, 1.0)
        let brightness: CGFloat = 1.0

        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))
    }
}

/// Draws a smooth color wheel using AngularGradient.
struct ColorWheelShape: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: stride(from: 0.0, to: 1.0, by: 0.01).map {
                            Color(hue: $0, saturation: 1, brightness: 1)
                        }),
                        center: .center
                    )
                )
                .frame(width: size, height: size)
        }
    }
}

/// Draws an animated indicator at the selected color's position on the wheel.
struct SelectionIndicator: View {
    let color: Color
    let wheelSize: CGFloat

    // Extract hue and saturation from the Color
    private func getHSB(_ color: Color) -> (hue: Double, saturation: Double) {
        #if canImport(AppKit)
        var nsColor = NSColor(color)
        nsColor = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        return (Double(hue), Double(sat))
        #else
        return (0, 0)
        #endif
    }

    var body: some View {
        let (hue, saturation) = getHSB(color)
        let radius = (wheelSize / 2) * saturation
        let angle = Angle(degrees: hue * 360)
        let center = CGPoint(x: wheelSize / 2, y: wheelSize / 2)
        let indicatorSize: CGFloat = 22

        // Calculate indicator position
        let x = center.x + CGFloat(cos(angle.radians)) * radius
        let y = center.y + CGFloat(sin(angle.radians)) * radius

        return Circle()
            .strokeBorder(Color.white, lineWidth: 3)
            .background(Circle().fill(Color.black.opacity(0.5)))
            .frame(width: indicatorSize, height: indicatorSize)
            .position(x: x, y: y)
            .shadow(color: .black.opacity(0.25), radius: 3)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: x + y)
    }
}
