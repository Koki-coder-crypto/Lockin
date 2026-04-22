import SwiftUI

struct QuoteCard: View {
    let quote: Quote
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(LockinColor.red.opacity(0.6))

                Text(quote.text)
                    .font(LockinFont.serifItalic(compact ? 16 : 18))
                    .foregroundStyle(LockinColor.textPrimary.opacity(0.92))
                    .lineSpacing(6)
            }

            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(LockinColor.textSecondary)
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
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
