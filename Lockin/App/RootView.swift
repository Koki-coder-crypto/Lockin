import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            LockinColor.background.ignoresSafeArea()

            if appState.onboardingCompleted {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.02)),
                        removal: .opacity
                    ))
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(LockinMotion.soft, value: appState.onboardingCompleted)
    }
}

struct MainTabView: View {
    @State private var selection: Tab = .home

    enum Tab: Hashable { case home, block, stats, settings }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(Tab.home)

            BlockSetupView()
                .tabItem { Label("ブロック", systemImage: "lock.fill") }
                .tag(Tab.block)

            StatsView()
                .tabItem { Label("記録", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(LockinColor.red)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(LockinColor.surface)
            appearance.shadowColor = UIColor(LockinColor.border)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
