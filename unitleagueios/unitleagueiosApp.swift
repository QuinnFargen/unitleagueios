import SwiftUI

@main
struct unitleagueiosApp: App {
    @StateObject private var theme = AppTheme()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(theme)
        }
    }
}
