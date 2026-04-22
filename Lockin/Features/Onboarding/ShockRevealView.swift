import SwiftUI

struct ShockRevealView: View {
    let minutesPerDay: Int
    var onNext: () -> Void

    @State private var phase: RevealPhase = .intro
    @State private var displayedHours: Double = 0

    enum RevealPhase: Int, CaseIterable, Comparable {
        case intro, buildup, bigNumber, caption, cta
        static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
    }

    private var yearlyHours: Int { (minutesPerDay * 365) / 60 }
    private var lifetimeDays: Int { (yearlyHours * 10) / 24 }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("あなたの場合")
                    .lockinCaption(color: LockinColor.textSecondary)
                    .tracking(3)
                    .textCase(.uppercase)
                    .opacity(phase >= .buildup ? 1 : 0)
                    .animation(LockinMotion.soft, value: phase)

                Text("1年で")
                    .lockinDisplay(22, weight: .semibold, tracking: 0)
                    .opacity(phase >= .buildup ? 1 : 0)
                    .offset(y: phase >= .buildup ? 0 : 10)
                    .animation(LockinMotion.soft.delay(0.1), value: phase)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(displayedHours, format: .number.precision(.fractionLength(0)))
                    .font(LockinFont.number(96, weight: .heavy))
                    .foregroundStyle(LockinColor.heroGradient)
                    .contentTransition(.numericText(value: displayedHours))
                    .animation(.easeOut(duration: 1.6), value: displayedHours)

                Text("時間")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(LockinColor.textPrimary)
                    .opacity(phase >= .bigNumber ? 1 : 0)
            }
            .padding(.top, 18)
            .opacity(phase >= .bigNumber ? 1 : 0)

            Text("スマホに消えています")
                .lockinBody(18, color: LockinColor.textPrimary)
                .padding(.top, 8)
                .opacity(phase >= .caption ? 1 : 0)
                .animation(LockinMotion.soft, value: phase)

            VStack(spacing: 6) {
                Text("それは、人生のおよそ")
                    .lockinBody(14, color: LockinColor.textSecondary)
                Text("\(lifetimeDays)日分")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(LockinColor.amber)
            }
            .padding(.top, 28)
            .opacity(phase >= .caption ? 1 : 0)
            .animation(LockinMotion.soft.delay(0.2), value: phase)

            Spacer()

            if phase >= .cta {
                PrimaryButton(title: "取り戻す", systemImage: "arrow.right") { onNext() }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .offset(y: 14)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { runReveal() }
    }

    private func runReveal() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            withAnimation { phase = .buildup }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation { phase = .bigNumber }
            displayedHours = Double(yearlyHours)
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation { phase = .caption }
            try? await Task.sleep(nanoseconds: 900_000_000)
            withAnimation(LockinMotion.bouncy) { phase = .cta }
        }
    }
}
