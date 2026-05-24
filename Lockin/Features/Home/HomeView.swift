import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var dailyQuote: Quote = QuoteRepository.daily()
    @State private var showPaywall = false
    @State private var showBlockSetup = false
    @State private var appeared = false

    private var usedMinutes: Int { min(appState.dailyUsageMinutes, 480) }
    private var goalMinutes: Int { max(appState.goalMinutes, 30) }
    private var progress: Double { min(1.0, Double(usedMinutes) / Double(goalMinutes)) }

    private var ringTint: Color {
        if progress > 0.9 { return LockinColor.red }
        if progress > 0.7 { return LockinColor.amber }
        return LockinColor.green
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackground(tint: ringTint)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        usageRingBlock
                        primaryAction
                        if !appState.isPremium { remainingChip }
                        streakRow
                        QuoteCard(quote: dailyQuote).padding(.horizontal, 20)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { appeared = true }
            }
            .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
            .fullScreenCover(isPresented: $showBlockSetup) {
                NavigationStack { BlockSetupView(presentation: .modal) }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("LOCKIN")
                .font(.system(size: 15, weight: .heavy))
                .tracking(4)
                .foregroundStyle(LockinColor.red)
            Spacer()
            if appState.isPremium {
                Text("Lockin+")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(LockinColor.red)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(LockinColor.red.opacity(0.15)))
            }
        }
        .padding(.horizontal, 20)
    }

    private var usageRingBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.16), .white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ), lineWidth: 1
                        )
                )
                .shadow(color: ringTint.opacity(0.14), radius: 32, y: 14)

            UsageRing(progress: progress, tint: ringTint)
            VStack(spacing: 4) {
                Text(hoursMinutesString(minutes: usedMinutes))
                    .font(LockinFont.number(38, weight: .bold))
                    .foregroundStyle(LockinColor.textPrimary)
                    .contentTransition(.numericText())
                Text("今日の使用時間")
                    .font(.system(size: 12))
                    .foregroundStyle(LockinColor.textSecondary)
                let remaining = max(0, goalMinutes - usedMinutes)
                Text("残り \(hoursMinutesString(minutes: remaining))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ringTint)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(ringTint.opacity(0.15)))
                    .padding(.top, 4)
            }
        }
        .frame(height: 260)
        .padding(.horizontal, 20)
    }

    private var primaryAction: some View {
        Group {
            if let session = appState.activeSession {
                ActiveBlockBanner(session: session).padding(.horizontal, 20)
            } else {
                Button {
                    if appState.isPremium || appState.remainingFreeBlocks > 0 {
                        showBlockSetup = true
                    } else { showPaywall = true }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").font(.system(size: 20, weight: .bold))
                        Text("今すぐ LOCK")
                            .font(.system(size: 18, weight: .heavy)).tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LockinColor.heroGradient)
                    )
                    .shadow(color: LockinColor.red.opacity(0.45), radius: 22, y: 10)
                }
                .buttonStyle(GlowingButtonStyle())
                .padding(.horizontal, 20)
                .sensoryFeedback(.impact(weight: .heavy), trigger: showBlockSetup)
            }
        }
    }

    private var remainingChip: some View {
        Button { showPaywall = true } label: {
            Text(appState.remainingFreeBlocks > 0
                 ? "本日残り \(appState.remainingFreeBlocks) 回 / 無制限はLockin+"
                 : "本日の無料回数を使い切りました・Lockin+で解放")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(appState.remainingFreeBlocks > 0 ? LockinColor.textSecondary : LockinColor.amber)
        }
        .buttonStyle(.plain)
    }

    private var streakRow: some View {
        HStack(spacing: 10) {
            StatChip(icon: "flame.fill", tint: LockinColor.amber,
                     value: "\(appState.currentStreak)", unit: "日連続")
            StatChip(icon: "clock.arrow.circlepath", tint: LockinColor.blue,
                     value: hoursOnlyString(minutes: usedMinutes * 7), unit: "週合計")
        }
        .padding(.horizontal, 20)
    }

    private func hoursMinutesString(minutes: Int) -> String { "\(minutes / 60)h \(minutes % 60)m" }
    private func hoursOnlyString(minutes: Int) -> String { "\(minutes / 60)h" }
}

// MARK: - Ambient Aurora Background

private struct AmbientBackground: View {
    let tint: Color
    @State private var phase = false

    var body: some View {
        ZStack {
            LockinColor.backgroundDeep.ignoresSafeArea()
            Ellipse()
                .fill(LockinColor.red.opacity(0.20))
                .frame(width: 380, height: 260).blur(radius: 75)
                .offset(x: -80, y: -300).offset(y: phase ? 22 : -22)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: phase)
            Ellipse()
                .fill(tint.opacity(0.13))
                .frame(width: 340, height: 220).blur(radius: 85)
                .offset(x: 120, y: 420).offset(x: phase ? 18 : -18)
                .animation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true), value: phase)
            Ellipse()
                .fill(LockinColor.amber.opacity(0.07))
                .frame(width: 200, height: 140).blur(radius: 60)
                .offset(x: -40, y: 160).scaleEffect(phase ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true), value: phase)
        }
        .ignoresSafeArea()
        .onAppear { phase = true }
    }
}

private struct StatChip: View {
    let icon: String; let tint: Color; let value: String; let unit: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(tint.opacity(0.15))
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(tint)
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(LockinFont.number(16, weight: .bold)).foregroundStyle(LockinColor.textPrimary)
                Text(unit).font(.system(size: 11)).foregroundStyle(LockinColor.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.14), .white.opacity(0.03)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

struct ActiveBlockBanner: View {
    let session: BlockSession
    @State private var pulsing = false

    var body: some View {
        HStack(spacing: 14) {
            Circle().fill(LockinColor.red).frame(width: 10, height: 10)
                .overlay(
                    Circle().stroke(LockinColor.red.opacity(0.5), lineWidth: 2)
                        .scaleEffect(pulsing ? 2.6 : 1).opacity(pulsing ? 0 : 0.8)
                )
                .onAppear {
                    withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulsing = true }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text("LOCKING").font(.system(size: 12, weight: .heavy)).tracking(2).foregroundStyle(LockinColor.red)
                Text(session.appNames.isEmpty ? "すべてのアプリ" : session.appNames.joined(separator: "・"))
                    .font(.system(size: 13)).foregroundStyle(LockinColor.textSecondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(LockinColor.textSecondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LockinColor.red.opacity(0.4), lineWidth: 1)
        )
    }
}
