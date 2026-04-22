import SwiftUI

struct GoalSelectionView: View {
    @Binding var selected: Int
    let currentUsage: Int
    var onNext: () -> Void

    @State private var appeared = false
    private let options = [60, 90, 120, 180]

    private var reductionPercent: Int {
        guard currentUsage > 0 else { return 0 }
        return max(0, Int(Double(currentUsage - selected) / Double(currentUsage) * 100))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("目標時間を")
                    .lockinDisplay(36)
                Text("決めましょう")
                    .lockinDisplay(36)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(LockinMotion.soft.delay(0.05), value: appeared)

            Text("達成しやすい目標がオススメです。")
                .lockinBody(15, color: LockinColor.textSecondary)
                .padding(.horizontal, 24)
                .padding(.top, 10)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LockinColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(LockinColor.border, lineWidth: 1)
                    )

                VStack(spacing: 10) {
                    Text("1日あたり")
                        .lockinCaption(color: LockinColor.textSecondary)
                        .tracking(2)
                        .textCase(.uppercase)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(selected)")
                            .font(LockinFont.number(72, weight: .heavy))
                            .foregroundStyle(LockinColor.green)
                            .contentTransition(.numericText(value: Double(selected)))
                            .animation(LockinMotion.bouncy, value: selected)
                        Text("分")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(LockinColor.textPrimary)
                    }

                    if reductionPercent > 0 {
                        Text("現在より \(reductionPercent)% 削減")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(LockinColor.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(LockinColor.green.opacity(0.15))
                            )
                    }
                }
                .padding(.vertical, 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 28)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { m in
                    Button {
                        selected = m
                    } label: {
                        Text("\(m)分")
                            .font(.system(size: 14, weight: selected == m ? .bold : .medium))
                            .foregroundStyle(selected == m ? .white : LockinColor.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selected == m ? LockinColor.green : LockinColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(LockinColor.border, lineWidth: selected == m ? 0 : 1)
                            )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .sensoryFeedback(.selection, trigger: selected)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            PrimaryButton(title: "この目標で進める", systemImage: "arrow.right") { onNext() }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .onAppear { appeared = true }
    }
}
