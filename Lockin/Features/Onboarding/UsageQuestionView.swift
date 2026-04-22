import SwiftUI

struct UsageQuestionView: View {
    @Binding var selected: Int
    var onNext: () -> Void

    private let options: [(label: String, minutes: Int, hint: String)] = [
        ("1〜2時間", 90,  "平均的な範囲です"),
        ("3〜4時間", 210, "少し多めです"),
        ("5〜6時間", 330, "かなり多い部類です"),
        ("7時間以上", 450, "依存気味かもしれません"),
    ]

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("1日に")
                    .lockinDisplay(36)
                Text("どのくらい使いますか？")
                    .lockinDisplay(36)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(LockinMotion.soft.delay(0.05), value: appeared)

            Text("正直に答えるほど、精度の高い設定になります。")
                .lockinBody(15, color: LockinColor.textSecondary)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .opacity(appeared ? 1 : 0)
                .animation(LockinMotion.soft.delay(0.15), value: appeared)

            VStack(spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.offset) { (idx, opt) in
                    OptionCard(
                        label: opt.label,
                        hint: opt.hint,
                        selected: selected == opt.minutes
                    ) {
                        selected = opt.minutes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onNext() }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(LockinMotion.soft.delay(0.25 + Double(idx) * 0.06), value: appeared)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer()
        }
        .onAppear { appeared = true }
    }
}

private struct OptionCard: View {
    let label: String
    let hint: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 17, weight: selected ? .bold : .medium))
                        .foregroundStyle(LockinColor.textPrimary)
                    Text(hint)
                        .font(.system(size: 13))
                        .foregroundStyle(LockinColor.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(selected ? LockinColor.red : LockinColor.border, lineWidth: selected ? 6 : 1.5)
                        .animation(LockinMotion.snappy, value: selected)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? LockinColor.red.opacity(0.1) : LockinColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? LockinColor.red.opacity(0.6) : LockinColor.border,
                                  lineWidth: selected ? 1.5 : 1)
                    .animation(LockinMotion.snappy, value: selected)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.selection, trigger: selected)
    }
}
