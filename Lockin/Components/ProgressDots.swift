import SwiftUI

struct ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                let active = i == current
                Capsule()
                    .fill(active ? LockinColor.red : LockinColor.surfacePlus)
                    .frame(width: active ? 28 : 8, height: 8)
                    .animation(LockinMotion.soft, value: current)
            }
        }
    }
}
