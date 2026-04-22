import SwiftUI

struct BlockCompleteView: View {
    let session: BlockSession
    var onClose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var quote: Quote = QuoteRepository.random()

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [LockinColor.green.opacity(0.25), LockinColor.backgroundDeep],
                center: .top,
                startRadius: 60,
                endRadius: 700
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LockinColor.green.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)

                    ZStack {
                        Circle()
                            .fill(LockinColor.green)
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
                    .animation(LockinMotion.bouncy, value: appeared)
                }
                .symbolEffect(.bounce, value: appeared)

                VStack(spacing: 6) {
                    Text("達成！")
                        .lockinDisplay(32)
                    Text("\(session.durationMinutes)分間、集中できました。")
                        .lockinBody(15, color: LockinColor.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(LockinMotion.soft.delay(0.2), value: appeared)

                QuoteCard(quote: quote, compact: true)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(LockinMotion.soft.delay(0.3), value: appeared)

                Spacer()

                VStack(spacing: 10) {
                    PrimaryButton(title: "もう一度ロックする", systemImage: "lock.fill", tint: LockinColor.green) {
                        close()
                    }
                    Button("ホームに戻る", action: close)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LockinColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    private func close() {
        dismiss()
        onClose()
    }
}
