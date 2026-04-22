import SwiftUI

enum LockinFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
            .monospacedDigit()
    }

    static func timer(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .rounded)
            .monospacedDigit()
    }

    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func caption(_ size: CGFloat = 12, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func serifItalic(_ size: CGFloat = 17) -> Font {
        .custom("HiraMinProN-W3", size: size).italic()
    }
}

struct LockinDisplayModifier: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight = .bold
    var tracking: CGFloat = -1.0

    func body(content: Content) -> some View {
        content
            .font(LockinFont.display(size, weight: weight))
            .kerning(tracking)
            .foregroundStyle(LockinColor.textPrimary)
    }
}

extension View {
    func lockinDisplay(_ size: CGFloat, weight: Font.Weight = .bold, tracking: CGFloat = -1.0) -> some View {
        modifier(LockinDisplayModifier(size: size, weight: weight, tracking: tracking))
    }

    func lockinBody(_ size: CGFloat = 16, color: Color = LockinColor.textPrimary) -> some View {
        font(LockinFont.body(size)).foregroundStyle(color)
    }

    func lockinCaption(color: Color = LockinColor.textSecondary) -> some View {
        font(LockinFont.caption(12)).foregroundStyle(color).tracking(0.3)
    }
}
