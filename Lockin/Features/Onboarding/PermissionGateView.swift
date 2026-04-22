import SwiftUI
import FamilyControls

struct PermissionGateView: View {
    var onGranted: () -> Void

    @State private var notificationGranted = false
    @State private var familyControlsGranted = false
    @State private var requestingFamilyControls = false
    @State private var appeared = false

    private var canProceed: Bool { familyControlsGranted }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("最後に")
                    .lockinDisplay(36)
                Text("権限を設定します")
                    .lockinDisplay(36)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(LockinMotion.soft.delay(0.05), value: appeared)

            Text("アプリを実際にブロックするために必要です。")
                .lockinBody(15, color: LockinColor.textSecondary)
                .padding(.horizontal, 24)
                .padding(.top, 10)

            VStack(spacing: 12) {
                PermissionRow(
                    icon: "lock.shield.fill",
                    tint: LockinColor.red,
                    title: "スクリーンタイム",
                    subtitle: "アプリのブロック／利用制限に必要",
                    status: familyControlsGranted ? .granted : .pending,
                    busy: requestingFamilyControls
                ) { Task { await requestFamilyControls() } }

                PermissionRow(
                    icon: "bell.badge.fill",
                    tint: LockinColor.amber,
                    title: "通知",
                    subtitle: "完了・リマインダーの送信",
                    status: notificationGranted ? .granted : .optional,
                    busy: false
                ) { Task { await requestNotifications() } }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Spacer()

            PrimaryButton(
                title: canProceed ? "Lockin を始める" : "スクリーンタイムを許可してください",
                systemImage: canProceed ? "arrow.right" : nil,
                tint: canProceed ? LockinColor.red : LockinColor.surfacePlus
            ) {
                if canProceed { onGranted() }
            }
            .disabled(!canProceed)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear { appeared = true }
    }

    private func requestFamilyControls() async {
        requestingFamilyControls = true
        defer { requestingFamilyControls = false }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            familyControlsGranted = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            familyControlsGranted = false
        }
    }

    private func requestNotifications() async {
        let center = UNUserNotificationCenter.current()
        if let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound]) {
            notificationGranted = granted
        }
    }
}

private struct PermissionRow: View {
    enum Status { case pending, granted, optional }

    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let status: Status
    let busy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LockinColor.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(LockinColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                trailing
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LockinColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(status == .granted ? tint.opacity(0.5) : LockinColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(status == .granted || busy)
    }

    @ViewBuilder
    private var trailing: some View {
        if busy {
            ProgressView().controlSize(.small).tint(tint)
        } else {
            switch status {
            case .granted:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(tint)
                    .symbolEffect(.bounce, value: status == .granted)
            case .pending:
                Text("許可")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(tint))
            case .optional:
                Text("任意")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LockinColor.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(LockinColor.surfacePlus))
            }
        }
    }
}
