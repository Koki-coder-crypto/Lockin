import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                LockinColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("設定")
                            .lockinDisplay(30)
                            .padding(.top, 4)

                        if !appState.isPremium {
                            premiumUpsell
                        } else {
                            premiumBadge
                        }

                        SettingsSection(title: "ブロック") {
                            SettingsRow(icon: "rectangle.grid.1x2.fill", tint: LockinColor.red,
                                        title: "テンプレート", detail: "勉強・睡眠・仕事")
                            SettingsRow(icon: "moon.stars.fill", tint: LockinColor.amber,
                                        title: "睡眠モード", detail: "Lockin+", locked: !appState.isPremium) {
                                showPaywall = true
                            }
                            SettingsRow(icon: "square.stack.3d.up.fill", tint: LockinColor.blue,
                                        title: "アプリグループ", detail: "Lockin+", locked: !appState.isPremium) {
                                showPaywall = true
                            }
                        }

                        SettingsSection(title: "通知") {
                            SettingsRow(icon: "bell.fill", tint: LockinColor.amber,
                                        title: "リマインダー", detail: "毎週月曜")
                            SettingsRow(icon: "bell.slash.fill", tint: LockinColor.blue,
                                        title: "通知ブロック", detail: "Lockin+", locked: !appState.isPremium) {
                                showPaywall = true
                            }
                        }

                        SettingsSection(title: "その他") {
                            SettingsRow(icon: "person.fill", tint: LockinColor.textSecondary,
                                        title: "アカウント")
                            SettingsRow(icon: "doc.text.fill", tint: LockinColor.textSecondary,
                                        title: "利用規約")
                            SettingsRow(icon: "hand.raised.fill", tint: LockinColor.textSecondary,
                                        title: "プライバシー")
                        }

                        Text("Lockin · 1.0.0")
                            .font(.system(size: 11))
                            .foregroundStyle(LockinColor.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var premiumUpsell: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LockinColor.heroGradient)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Lockin+ にアップグレード")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(LockinColor.textPrimary)
                    Text("7日間無料・全機能解放")
                        .font(.system(size: 12))
                        .foregroundStyle(LockinColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LockinColor.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LockinColor.red.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(LockinColor.red.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: LockinColor.red.opacity(0.2), radius: 18, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var premiumBadge: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LockinColor.heroGradient)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text("Lockin+ 有効")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LockinColor.textPrimary)
                Text("すべての機能をご利用いただけます")
                    .font(.system(size: 12))
                    .foregroundStyle(LockinColor.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LockinColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LockinColor.border, lineWidth: 1)
        )
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(LockinColor.textSecondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LockinColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(LockinColor.border, lineWidth: 1)
            )
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String? = nil
    var locked: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tint.opacity(0.15))
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 30, height: 30)

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LockinColor.textPrimary)

                Spacer()

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(LockinColor.red)
                } else if let detail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(LockinColor.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LockinColor.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99))
    }
}
