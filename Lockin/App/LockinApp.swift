import SwiftUI

@main
struct LockinApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .tint(LockinColor.red)
                .background(LockinColor.background.ignoresSafeArea())
        }
    }
}
