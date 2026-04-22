import SwiftUI

enum LockinMotion {
    static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let soft = Animation.spring(response: 0.45, dampingFraction: 0.78)
    static let bouncy = Animation.spring(response: 0.55, dampingFraction: 0.62)
    static let lazy = Animation.spring(response: 0.8, dampingFraction: 0.85)
    static let cardTap = Animation.spring(response: 0.22, dampingFraction: 0.75)
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var opacity: Double = 0.92

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(LockinMotion.cardTap, value: configuration.isPressed)
    }
}

struct GlowingButtonStyle: ButtonStyle {
    var tint: Color = LockinColor.red

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(
                color: tint.opacity(configuration.isPressed ? 0.25 : 0.5),
                radius: configuration.isPressed ? 12 : 24,
                x: 0,
                y: configuration.isPressed ? 4 : 12
            )
            .animation(LockinMotion.cardTap, value: configuration.isPressed)
    }
}
