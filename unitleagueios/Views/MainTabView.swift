import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 4

    var body: some View {
        TabView(selection: $selectedTab) {
            TabLeaguesView()
                .tabItem {
                    Label("Leagues", systemImage: "person.3")
                }
//                .tag(0)

            TabResearchView()
                .tabItem {
                    Label("Research", systemImage: "plus.forwardslash.minus")
                }
//                .tag(1)

            TabGamesView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }
//                .tag(2)

            PlaceholderView(title: "Bets")
                .tabItem {
                    Label("Bets", systemImage: "bitcoinsign.bank.building")
                }
//                .tag(3)

            TabProfileView()
                .tabItem {
                    Label("Profile", systemImage: "figure.pickleball")
                }
//                .tag(4)
        }
        .tint(theme.accent)
    }
}

private struct PlaceholderView: View {
    let title: String
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            theme.appBackground(colorScheme).ignoresSafeArea()
            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppTheme())
}
