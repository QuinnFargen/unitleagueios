import SwiftUI

struct TabResearchView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var leagues: [League] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = LeagueService()

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView()
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(theme.error)
                            Text(error)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") { fetchLeagues() }
                                .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        VStack{
                            Text("Sports Leagues")
                                .font(.title)
                                .foregroundStyle(theme.primaryText(colorScheme))
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(leagues) { league in
                                        NavigationLink {
                                            ViewTeamList(league: league)
                                        } label: {
                                            LeagueCard(league: league)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                            }
                            HStack{
                                Label("Teams", systemImage: "sportscourt")
                                Spacer()
                                Label("Ranks", systemImage: "list.number")
                                Spacer()
                                Label("Sched", systemImage: "calendar")
                                Spacer()
                                Label("Odds", systemImage: "books.vertical")
                            }
                            Spacer()
                        }
                    }
                }
            }
            .tabToolbar()
        }
        .task { fetchLeagues() }
    }

    private func fetchLeagues() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                leagues = try await service.fetchLeagues()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct LeagueCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let league: League

    var body: some View {
        HStack(spacing: 16) {
            
            Image(systemName: league.sportIcon)
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 44, height: 44)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(league.abbr)
                    .font(.title)
                    .foregroundStyle(theme.primaryText(colorScheme))
                //                Text(league.name)
                //                    .font(.subheadline)
                //                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "list.number")
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 30, height: 30)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 30, height: 30)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Image(systemName: "books.vertical")
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 30, height: 30)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            //            Spacer()
            //
            //            Image(systemName: "chevron.right")
            //                .font(.caption)
            //                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    TabResearchView()
        .environmentObject(AppTheme())
}
