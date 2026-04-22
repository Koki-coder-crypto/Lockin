import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPaywall = false

    private var weekData: [DayUsage] {
        let cal = Calendar.current
        let base = Date()
        return (0..<7).reversed().map { i in
            let d = cal.date(byAdding: .day, value: -i, to: base) ?? base
            let value = [72, 140, 95, 210, 165, 240, appState.dailyUsageMinutes][6 - i]
            return DayUsage(date: d, minutes: value)
        }
    }

    private var weekAverage: Int {
        let total = weekData.map(\.minutes).reduce(0, +)
        return total / max(weekData.count, 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LockinColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("記録")
                            .lockinDisplay(30)
                            .padding(.top, 4)

                        weekChart

                        streakCard

                        pickupCard

                        if !appState.isPremium {
                            premiumUpsell
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(
                    contextTitle: "Lockin+ で\n詳細な統計を解放",
                    contextSubtitle: "ピックアップ数・ヒートマップ・週次 PDF レポート。"
                )
            }
        }
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("週間平均")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(LockinColor.textSecondary)
                        .textCase(.uppercase)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(weekAverage / 60)")
                            .font(LockinFont.number(34, weight: .heavy))
                            .foregroundStyle(LockinColor.textPrimary)
                        Text("h")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LockinColor.textSecondary)
                        Text("\(weekAverage % 60)")
                            .font(LockinFont.number(34, weight: .heavy))
                            .foregroundStyle(LockinColor.textPrimary)
                        Text("m")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LockinColor.textSecondary)
                    }
                }
                Spacer()
            }

            Chart(weekData) { d in
                BarMark(
                    x: .value("Day", d.date, unit: .day),
                    y: .value("Minutes", d.minutes),
                    width: .fixed(18)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [LockinColor.red.opacity(0.9), LockinColor.red.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { v in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .foregroundStyle(LockinColor.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 120, 240, 360]) { v in
                    AxisGridLine().foregroundStyle(LockinColor.border.opacity(0.5))
                    AxisValueLabel { Text("\((v.as(Int.self) ?? 0) / 60)h").font(.system(size: 10)) }
                        .foregroundStyle(LockinColor.textSecondary)
                }
            }
            .frame(height: 170)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LockinColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LockinColor.border, lineWidth: 1)
        )
    }

    private var streakCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(LockinColor.amber.opacity(0.18))
                Image(systemName: "flame.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(LockinColor.amber)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text("連続達成")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LockinColor.textSecondary)
                Text("\(appState.currentStreak) 日")
                    .font(LockinFont.number(28, weight: .heavy))
                    .foregroundStyle(LockinColor.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LockinColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LockinColor.border, lineWidth: 1)
        )
    }

    private var pickupCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(LockinColor.blue.opacity(0.18))
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(LockinColor.blue)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("ピックアップ回数")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LockinColor.textSecondary)
                    if !appState.isPremium {
                        Text("Lockin+")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(LockinColor.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(LockinColor.red.opacity(0.15)))
                    }
                }
                Text(appState.isPremium ? "78 回" : "—")
                    .font(LockinFont.number(24, weight: .heavy))
                    .foregroundStyle(appState.isPremium ? LockinColor.textPrimary : LockinColor.textSecondary)
            }

            Spacer()

            if !appState.isPremium {
                Button { showPaywall = true } label: {
                    Text("解放")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(LockinColor.red))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LockinColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LockinColor.border, lineWidth: 1)
        )
    }

    private var premiumUpsell: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LockinColor.red.opacity(0.2))
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LockinColor.red)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("週次レポートをPDFで受け取る")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(LockinColor.textPrimary)
                    Text("Lockin+ でヒートマップも見られます")
                        .font(.system(size: 12))
                        .foregroundStyle(LockinColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LockinColor.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LockinColor.red.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(LockinColor.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct DayUsage: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let minutes: Int
}
