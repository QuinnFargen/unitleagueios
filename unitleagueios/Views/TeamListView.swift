import SwiftUI

struct TeamListView: View {
    let league: League

    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let teamService = TeamService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await fetchTeams() } }
                            .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(teams) { team in
                                NavigationLink {
                                    TeamScheduleView(team: team, league: league)
                                } label: {
                                    TeamCard(team: team)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle(league.abbr)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await fetchTeams() }
    }

    private func fetchTeams() async {
        isLoading = true
        errorMessage = nil
        do {
            teams = try await teamService.fetchTeams(leagueId: league.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - TeamCard

private struct TeamCard: View {
    let team: Team

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(team.abbr)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(team.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
