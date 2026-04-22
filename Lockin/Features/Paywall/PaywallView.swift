import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    enum Plan: String, CaseIterable, Identifiable {
        case yearly, monthly, lifetime
        var id: String { rawValue }

        var title: String {
            switch self {
            case .yearly:   return "年間"
            case .monthly:  return "月額"
            case .lifetime: return "買い切り"
            }
        }

        var priceLabel: String {
            switch self {
            case .yearly:   return "¥3,800 / 年"
            case .monthly:  return "¥480 / 月"
            case .lifetime: return "¥2,480 一度だけ"
            }
        }

        var perMonthEquivalent: String? {
            switch self {
            case .yearly:   return "月あたり ¥316（34%オフ）"
            case .monthly:  return nil
            case .lifetime: return "生涯利用・更新不要"
            }
        }

        var badge: String? {
            switch self {
            case .yearly:   return "おすすめ"
            case .monthly:  return nil
            case .lifetime: return "買い切り"
            }
        }

        var hasTrial: Bool { self == .yearly }
    }

    var contextTitle: String = "Lockin+ で\n時間を完全に取り戻す"
    var contextSubtitle: String = "Strict モード・無制限ブロック・週次レポート。"

    @State private var selected: Plan = .yearly
    @State private var appeared = false
    @State private var features: [Feature] = Feature.all
    @State private var shimmerX: CGFloat = -1

    var body: some View {
        ZStack {
            LockinColor.paywallBackdrop.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    headerIcon

                    VStack(spacing: 10) {
                        Text(contextTitle)
                            .multilineTextAlignment(.center)
                            .lockinDisplay(30, tracking: -0.5)

                        Text(contextSubtitle)
                            .multilineTextAlignment(.center)
                            .lockinBody(15, color: LockinColor.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(LockinMotion.soft.delay(0.1), value: appeared)

                    featureList

                    planSelector

                    ctaButton
                        .padding(.horizontal, 24)

                    footerLinks
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
                .padding(.top, 60)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LockinColor.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(LockinColor.surface.opacity(0.8)))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.trailing, 18)
                }
                Spacer()
            }
            .padding(.top, 12)
        }
        .task {
            withAnimation(LockinMotion.soft) { appeared = true }
        }
    }

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(LockinColor.red.opacity(0.25))
                .frame(width: 150, height: 150)
                .blur(radius: 40)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LockinColor.heroGradient)
                .frame(width: 92, height: 92)
                .overlay(
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: LockinColor.red.opacity(0.6), radius: 30, y: 8)
        }
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .animation(LockinMotion.bouncy, value: appeared)
    }

    private var featureList: some View {
        VStack(spacing: 10) {
            ForEach(Array(features.enumerated()), id: \.element.id) { (i, feature) in
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(feature.tint.opacity(0.18))
                        Image(systemName: feature.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(feature.tint)
                    }
                    .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LockinColor.textPrimary)
                        Text(feature.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(LockinColor.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 20)
                .animation(LockinMotion.soft.delay(0.25 + Double(i) * 0.06), value: appeared)
            }
        }
        .padding(.horizontal, 24)
    }

    private var planSelector: some View {
        VStack(spacing: 10) {
            ForEach(Plan.allCases) { plan in
                PlanRow(plan: plan, selected: selected == plan) {
                    withAnimation(LockinMotion.snappy) { selected = plan }
                }
            }
        }
        .padding(.horizontal, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(LockinMotion.soft.delay(0.45), value: appeared)
    }

    private var ctaButton: some View {
        Button {
            appState.isPremium = true
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Text(selected.hasTrial ? "7日間無料で試す" : "続行する")
                    .font(.system(size: 17, weight: .bold))
                Text(selected.hasTrial
                    ? "その後 \(selected.priceLabel)・いつでもキャンセル可"
                    : selected.priceLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LockinColor.heroGradient)
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.0), .white.opacity(0.35), .white.opacity(0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerX * 180)
                        .blendMode(.plusLighter)
                        .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            )
            .shadow(color: LockinColor.red.opacity(0.55), radius: 24, y: 10)
        }
        .buttonStyle(GlowingButtonStyle())
        .sensoryFeedback(.impact(weight: .heavy), trigger: appState.isPremium)
        .onAppear {
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                shimmerX = 2
            }
        }
    }

    private var footerLinks: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 11))
                Text("いつでもキャンセル可・App Store で管理")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(LockinColor.textSecondary)

            HStack(spacing: 18) {
                Button("復元") {}
                Button("利用規約") {}
                Button("プライバシー") {}
            }
            .font(.system(size: 11))
            .foregroundStyle(LockinColor.textTertiary)
        }
    }
}

private struct PlanRow: View {
    let plan: PaywallView.Plan
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? LockinColor.red : LockinColor.border,
                                      lineWidth: selected ? 6 : 1.5)
                        .frame(width: 22, height: 22)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(LockinColor.textPrimary)
                        if let badge = plan.badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(LockinColor.red))
                        }
                    }
                    if let sub = plan.perMonthEquivalent {
                        Text(sub)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(plan == .yearly ? LockinColor.green : LockinColor.textSecondary)
                    }
                }

                Spacer()

                Text(plan.priceLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LockinColor.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? LockinColor.red.opacity(0.1) : LockinColor.surface.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? LockinColor.red.opacity(0.7) : LockinColor.border,
                                  lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.selection, trigger: selected)
    }
}

struct Feature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    static let all: [Feature] = [
        .init(icon: "infinity", title: "無制限のブロック",
              subtitle: "1日5回の制限なし、何度でも集中時間を作れます", tint: LockinColor.red),
        .init(icon: "calendar.badge.clock", title: "SCHEDULE BLOCK",
              subtitle: "曜日×時間の自動ブロックで、意思に頼らず習慣化", tint: LockinColor.blue),
        .init(icon: "moon.stars.fill", title: "睡眠モード",
              subtitle: "就寝前後は自動で電子機器から距離を置く", tint: LockinColor.amber),
        .init(icon: "shield.lefthalf.filled", title: "Strict モード",
              subtitle: "60 秒クールダウンで解除を困難にする強制力", tint: LockinColor.green),
        .init(icon: "chart.bar.xaxis.ascending", title: "詳細な統計",
              subtitle: "ピックアップ数・ヒートマップ・週次レポート PDF", tint: LockinColor.blue),
    ]
}
