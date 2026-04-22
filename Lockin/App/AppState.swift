import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @AppStorage("onboarding.completed") var onboardingCompleted: Bool = false
    @AppStorage("onboarding.dailyMinutes") var dailyUsageMinutes: Int = 210
    @AppStorage("onboarding.goalMinutes") var goalMinutes: Int = 120
    @AppStorage("entitlement.premium") var isPremium: Bool = false
    @AppStorage("streak.current") var currentStreak: Int = 0
    @AppStorage("block.countToday") var nowBlockCountToday: Int = 0

    @Published var activeSession: BlockSession?

    let freeNowBlockPerDay = 5

    var remainingFreeBlocks: Int {
        max(0, freeNowBlockPerDay - nowBlockCountToday)
    }

    func startBlock(_ session: BlockSession) {
        activeSession = session
        if !isPremium {
            nowBlockCountToday += 1
        }
    }

    func endBlock(completed: Bool) {
        if completed {
            currentStreak += 1
        }
        activeSession = nil
    }
}
