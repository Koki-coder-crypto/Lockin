import SwiftUI

struct BlockSetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    enum Presentation { case modal, tab }
    var presentation: Presentation = .tab

    @State private var mode: BlockMode = .now
    @State private var durationMinutes: Int = 30
    @State private var strictMode: Bool = false
    @State private var selectedApps: Set<String> = ["Instagram", "X", "TikTok"]
    @State private var showActive = false
    @State private var showPaywall = false

    private let presetDurations = [15, 30, 60, 120, 180]
    private let sampleApps = ["Instagram", "X", "TikTok", "YouTube", "LINE", "Safari"]

    var body: some View {
        ZStack {
            LockinColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if presentation == .modal {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(LockinColor.textSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(LockinColor.surface))
                            }
                            .buttonStyle(PressableButtonStyle())
                            Spacer()
                        }
                        .padding(.top, 8)
                    }

                    Text("どのようにロックしますか？")
                        .lockinDisplay(26)
                        .padding(.top, presentation == .modal ? 0 : 8)

                    modeSelector

                    if mode == .now {
                        durationSection
                    }

                    appListSection

                    strictToggle

                    Spacer(minLength: 20)

                    PrimaryButton(title: "LOCK 開始", systemImage: "lock.fill") {
                        start()
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
            }
        }
        .fullScreenCover(isPresented: $showActive) {
            if let session = appState.activeSession {
                BlockingActiveView(session: session)
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(
                contextTitle: "Lockin+ で\nSCHEDULE BLOCK を解放",
                contextSubtitle: "曜日×時間の自動ブロックはプレミアム機能です。"
            )
        }
    }

    private var modeSelector: some View {
        VStack(spacing: 10) {
            ForEach(BlockMode.allCases) { m in
                ModeCard(mode: m, selected: mode == m, locked: m.isPremiumOnly && !appState.isPremium) {
                    if m.isPremiumOnly && !appState.isPremium {
                        showPaywall = true
                    } else {
                        withAnimation(LockinMotion.snappy) { mode = m }
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "時間")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(durationMinutes)")
                    .font(LockinFont.number(48, weight: .heavy))
                    .foregroundStyle(LockinColor.textPrimary)
                    .contentTransition(.numericText(value: Double(durationMinutes)))
                Text("分")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LockinColor.textSecondary)
            }

            HStack(spacing: 8) {
                ForEach(presetDurations, id: \.self) { m in
                    Button {
                        withAnimation(LockinMotion.snappy) { durationMinutes = m }
                    } label: {
                        Text("\(m)分")
                            .font(.system(size: 13, weight: durationMinutes == m ? .bold : .medium))
                            .foregroundStyle(durationMinutes == m ? .white : LockinColor.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(durationMinutes == m ? LockinColor.red : LockinColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(LockinColor.border,
                                                  lineWidth: durationMinutes == m ? 0 : 1)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .sensoryFeedback(.selection, trigger: durationMinutes)
                }
            }
        }
    }

    private var appListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "ブロック対象アプリ")

            VStack(spacing: 0) {
                ForEach(Array(sampleApps.enumerated()), id: \.element) { (i, app) in
                    AppRow(
                        name: app,
                        selected: selectedApps.contains(app)
                    ) {
                        if selectedApps.contains(app) {
                            selectedApps.remove(app)
                        } else {
                            selectedApps.insert(app)
                        }
                    }
                    if i < sampleApps.count - 1 {
                        Divider().background(LockinColor.border).padding(.leading, 60)
                    }
                }
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

    private var strictToggle: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LockinColor.red.opacity(0.15))
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LockinColor.red)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Strict モード")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LockinColor.textPrimary)
                    if !appState.isPremium {
                        Text("Lockin+")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(LockinColor.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(LockinColor.red.opacity(0.15)))
                    }
                }
                Text("解除に60秒クールダウン")
                    .font(.system(size: 12))
                    .foregroundStyle(LockinColor.textSecondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { strictMode },
                set: { new in
                    if new && !appState.isPremium {
                        showPaywall = true
                    } else {
                        strictMode = new
                    }
                }
            ))
            .labelsHidden()
            .tint(LockinColor.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LockinColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LockinColor.border, lineWidth: 1)
        )
    }

    private func start() {
        if !appState.isPremium && appState.remainingFreeBlocks <= 0 {
            showPaywall = true
            return
        }
        let session = BlockSession(
            mode: mode,
            durationMinutes: durationMinutes,
            appNames: Array(selectedApps),
            strictMode: strictMode
        )
        appState.startBlock(session)
        showActive = true
    }
}

private struct ModeCard: View {
    let mode: BlockMode
    let selected: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? LockinColor.red.opacity(0.2) : LockinColor.surfacePlus)
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected ? LockinColor.red : LockinColor.textSecondary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(mode.title)
                            .font(.system(size: 16, weight: .heavy))
                            .tracking(1)
                            .foregroundStyle(LockinColor.textPrimary)
                        if locked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(LockinColor.red)
                        }
                    }
                    Text(mode.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(LockinColor.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(selected ? LockinColor.red : LockinColor.border,
                                      lineWidth: selected ? 6 : 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? LockinColor.red.opacity(0.08) : LockinColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? LockinColor.red.opacity(0.6) : LockinColor.border,
                                  lineWidth: selected ? 1.5 : 1)
            )
            .opacity(locked ? 0.75 : 1)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct AppRow: View {
    let name: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(LockinColor.surfacePlus)
                    Text(String(name.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(LockinColor.textPrimary)
                }
                .frame(width: 32, height: 32)

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LockinColor.textPrimary)

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? LockinColor.red : LockinColor.border)
                    .symbolEffect(.bounce, value: selected)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.99))
        .sensoryFeedback(.selection, trigger: selected)
    }
}

private struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy))
            .tracking(2)
            .foregroundStyle(LockinColor.textSecondary)
            .textCase(.uppercase)
    }
}
