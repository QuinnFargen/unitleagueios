import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TabResearchView()
                .tabItem {
                    Label("Leagues", systemImage: "person.3")
                }
            
            TabResearchView()
                .tabItem {
                    Label("Research", systemImage: "plus.forwardslash.minus")
                }

            TabGamesView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }

            PlaceholderView(title: "Bets")
                .tabItem {
                    Label("Bets", systemImage: "bitcoinsign.bank.building")
                }

            PlaceholderView(title: "Profile")
                .tabItem {
                    Label("Profile", systemImage: "figure.pickleball")
                }
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
