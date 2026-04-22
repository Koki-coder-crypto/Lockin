import SwiftUI

struct UsageRing: View {
    var progress: Double
    var tint: Color
    var diameter: CGFloat = 232
    var lineWidth: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .stroke(LockinColor.surfacePlus, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.8), tint, tint.opacity(0.9), tint],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.5), radius: 12, y: 0)
                .animation(LockinMotion.lazy, value: progress)

            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(tint.opacity(0.35), style: StrokeStyle(lineWidth: lineWidth + 14, lineCap: .round))
                .blur(radius: 18)
                .rotationEffect(.degrees(-90))
                .allowsHitTesting(false)
        }
        .frame(width: diameter, height: diameter)
    }
}
