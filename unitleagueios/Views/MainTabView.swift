import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Leagues", systemImage: "list.bullet")
                }

            GamesView()
                .tabItem {
                    Label("Games", systemImage: "sportscourt")
                }

            PlaceholderView(title: "Bets")
                .tabItem {
                    Label("Bets", systemImage: "dollarsign.circle")
                }

            PlaceholderView(title: "Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .tint(.white)
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
