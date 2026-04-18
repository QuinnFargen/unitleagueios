import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 4

    var body: some View {
        TabView(selection: $selectedTab) {
            TabLeaguesView()
                .tabItem {
                    Label("Leagues", systemImage: "person.3")
                }
                .tag(0)

            TabResearchView()
                .tabItem {
                    Label("Research", systemImage: "plus.forwardslash.minus")
                }
                .tag(1)

            TabGamesView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }
                .tag(2)

            PlaceholderView(title: "Bets")
                .tabItem {
                    Label("Bets", systemImage: "bitcoinsign.bank.building")
                }
                .tag(3)

            TabProfileView()
                .tabItem {
                    Label("Profile", systemImage: "figure.pickleball")
                }
                .tag(4)
        }
        .tint(.green)
    }
}

private struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(title)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MainTabView()
}
