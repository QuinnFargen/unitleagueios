import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Leagues", systemImage: "person.3")
                }

            GamesView()
                .tabItem {
                    Label("Games", systemImage: "gamecontroller")
                }

            PlaceholderView(title: "Bets")
                .tabItem {
                    Label("Bets", systemImage: "bitcoinsign.bank.building")
                }
            
            PlaceholderView(title: "History")
                .tabItem {
                    Label("History", systemImage: "wallet.bifold.fill")
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
