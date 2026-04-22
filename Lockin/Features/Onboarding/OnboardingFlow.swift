import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case usage, shock, goal, permission

    var title: String {
        switch self {
        case .usage:      return "1日にどのくらい使いますか？"
        case .shock:      return ""
        case .goal:       return "目標時間を決めましょう"
        case .permission: return "最後のステップ"
        }
    }
}

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .usage
    @State private var selectedMinutes: Int = 210
    @State private var selectedGoal: Int = 120

    var body: some View {
        ZStack {
            backdrop.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                ZStack {
                    switch step {
                    case .usage:
                        UsageQuestionView(selected: $selectedMinutes) { advance(to: .shock) }
                            .transition(pageTransition)
                    case .shock:
                        ShockRevealView(minutesPerDay: selectedMinutes) { advance(to: .goal) }
                            .transition(pageTransition)
                    case .goal:
                        GoalSelectionView(selected: $selectedGoal, currentUsage: selectedMinutes) {
                            advance(to: .permission)
                        }
                        .transition(pageTransition)
                    case .permission:
                        PermissionGateView {
                            appState.dailyUsageMinutes = selectedMinutes
                            appState.goalMinutes = selectedGoal
                            withAnimation(LockinMotion.soft) {
                                appState.onboardingCompleted = true
                            }
                        }
                        .transition(pageTransition)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var backdrop: some View {
        ZStack {
            LockinColor.background
            RadialGradient(
                colors: [
                    tint.opacity(0.35),
                    LockinColor.background.opacity(0.0)
                ],
                center: anchor,
                startRadius: 60,
                endRadius: 520
            )
            .animation(.easeInOut(duration: 0.9), value: step)
        }
    }

    private var tint: Color {
        switch step {
        case .usage:      return LockinColor.blue
        case .shock:      return LockinColor.red
        case .goal:       return LockinColor.green
        case .permission: return LockinColor.amber
        }
    }

    private var anchor: UnitPoint {
        switch step {
        case .usage:      return .topLeading
        case .shock:      return .center
        case .goal:       return .bottom
        case .permission: return .topTrailing
        }
    }

    private var topBar: some View {
        HStack {
            if step != .usage {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LockinColor.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(LockinColor.surface))
                }
                .buttonStyle(PressableButtonStyle())
                .transition(.opacity.combined(with: .scale))
            } else {
                Color.clear.frame(width: 36, height: 36)
            }

            Spacer()

            ProgressDots(current: step.rawValue, total: OnboardingStep.allCases.count)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(x: 24, y: 0)),
            removal: .opacity.combined(with: .offset(x: -24, y: 0))
        )
    }

    private func advance(to next: OnboardingStep) {
        withAnimation(LockinMotion.soft) { step = next }
    }

    private func back() {
        guard let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        withAnimation(LockinMotion.soft) { step = prev }
    }
}
