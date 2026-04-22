import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var tint: Color = LockinColor.red
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                if isLoading {
                    ProgressView().tint(.white).padding(.leading, 4)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(GlowingButtonStyle(tint: tint))
        .sensoryFeedback(.impact(weight: .medium), trigger: isLoading)
    }
}

struct SecondaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LockinColor.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LockinColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}
