import SwiftUI

struct BlockingActiveView: View {
    let session: BlockSession

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var quote: Quote = QuoteRepository.random()
    @State private var lastQuoteRotation = Date()
    @State private var showUnlockConfirm = false
    @State private var unlockProgress: Double = 0
    @State private var unlockTask: Task<Void, Never>?
    @State private var showComplete = false
    @State private var beaconPulsing = false

    var body: some View {
        ZStack {
            LockinColor.blockingActiveBackdrop.ignoresSafeArea()

            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let now = timeline.date
                let remaining = max(0, session.endsAt.timeIntervalSince(now))
                let total = TimeInterval(session.durationMinutes * 60)
                let progress = total > 0 ? 1 - (remaining / total) : 0

                content(now: now, remaining: remaining, progress: progress)
                    .onChange(of: Int(remaining)) { _, newRem in
                        if newRem <= 0 { complete() }
                        if now.timeIntervalSince(lastQuoteRotation) > 60 {
                            rotateQuote()
                            lastQuoteRotation = now
                        }
                    }
            }

            if showUnlockConfirm { unlockOverlay }
        }
        .statusBarHidden()
        .fullScreenCover(isPresented: $showComplete) {
            BlockCompleteView(session: session) { dismiss() }
        }
    }

    private func content(now: Date, remaining: TimeInterval, progress: Double) -> some View {
        VStack {
            HStack {
                Text("LOCKING")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(LockinColor.red)
                Circle()
                    .fill(LockinColor.red)
                    .frame(width: 6, height: 6)
                    .opacity(beaconPulsing ? 0.3 : 1.0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            beaconPulsing = true
                        }
                    }
                Spacer()
                if session.strictMode {
                    Text("STRICT")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(LockinColor.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().strokeBorder(LockinColor.red, lineWidth: 1))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            ZStack {
                Circle()
                    .trim(from: 0, to: max(0.001, progress))
                    .stroke(LockinColor.red.opacity(0.35), lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 280, height: 280)

                VStack(spacing: 8) {
                    Text(formatRemaining(remaining))
                        .font(LockinFont.timer(64))
                        .foregroundStyle(LockinColor.textPrimary)
                        .contentTransition(.numericText())

                    Text("残り時間")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(LockinColor.textSecondary)
                        .textCase(.uppercase)
                }
            }

            Spacer()

            VStack(spacing: 14) {
                Text(quote.text)
                    .font(LockinFont.serifItalic(18))
                    .foregroundStyle(LockinColor.textPrimary.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .transition(.opacity)
                    .id(quote.id)

                Text("— \(quote.author)")
                    .font(.system(size: 12))
                    .foregroundStyle(LockinColor.textSecondary)
            }
            .padding(.horizontal, 36)
            .animation(.easeInOut(duration: 0.6), value: quote.id)

            Spacer()

            unlockButton
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
        }
    }

    private var unlockButton: some View {
        Button {
            if session.strictMode {
                beginStrictUnlock()
            } else {
                complete(userCancelled: true)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 15, weight: .semibold))
                Text(session.strictMode ? "60秒押し続けて解除" : "ロック解除")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(LockinColor.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(LockinColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var unlockOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("本当に解除しますか？")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("押し続けている間だけ、解除カウントが進みます。")
                    .font(.system(size: 13))
                    .foregroundStyle(LockinColor.textSecondary)
                    .multilineTextAlignment(.center)

                ZStack {
                    Circle()
                        .stroke(LockinColor.surfacePlus, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: unlockProgress)
                        .stroke(LockinColor.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: unlockProgress)
                    Text("\(Int((1 - unlockProgress) * 60))")
                        .font(LockinFont.number(36, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 160, height: 160)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in progressStrictUnlock() }
                        .onEnded { _ in cancelStrictUnlock() }
                )

                Button("キャンセル") {
                    showUnlockConfirm = false
                    cancelStrictUnlock()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LockinColor.textSecondary)
            }
            .padding(32)
        }
    }

    private func beginStrictUnlock() {
        showUnlockConfirm = true
        unlockProgress = 0
    }

    private func progressStrictUnlock() {
        unlockTask?.cancel()
        unlockTask = Task { @MainActor in
            while unlockProgress < 1, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                unlockProgress += 0.1 / 60
            }
            if unlockProgress >= 1 { complete(userCancelled: true) }
        }
    }

    private func cancelStrictUnlock() {
        unlockTask?.cancel()
        withAnimation { unlockProgress = 0 }
    }

    private func rotateQuote() {
        withAnimation { quote = QuoteRepository.random() }
    }

    private func formatRemaining(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private func complete(userCancelled: Bool = false) {
        appState.endBlock(completed: !userCancelled)
        showComplete = true
    }
}
