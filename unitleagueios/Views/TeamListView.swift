import SwiftUI

struct TeamListView: View {
    let league: League

    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedConf: String? = nil
    @State private var selectedDiv: String? = nil

    private let teamService = TeamService()

    private var confs: [String] {
        Array(Set(teams.compactMap(\.conf))).sorted()
    }

    private var divs: [String] {
        guard let conf = selectedConf else { return [] }
        return Array(Set(teams.filter { $0.conf == conf }.compactMap(\.div))).sorted()
    }

    private var displayedTeams: [Team] {
        teams.filter { team in
            if let conf = selectedConf, team.conf != conf { return false }
            if let div = selectedDiv, team.div != div { return false }
            return true
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                VStack(spacing: 0) {
                    // Conf filter
                    if !confs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(confs, id: \.self) { conf in
                                    FilterChip(
                                        label: conf,
                                        isSelected: selectedConf == conf
                                    ) {
                                        if selectedConf == conf {
                                            selectedConf = nil
                                            selectedDiv = nil
                                        } else {
                                            selectedConf = conf
                                            selectedDiv = nil
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }

                    // Div filter — only shown when a conf is selected and divs exist
                    if !divs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(divs, id: \.self) { div in
                                    FilterChip(
                                        label: div,
                                        isSelected: selectedDiv == div
                                    ) {
                                        selectedDiv = (selectedDiv == div) ? nil : div
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if !confs.isEmpty {
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(displayedTeams) { team in
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
                .animation(.easeInOut(duration: 0.2), value: selectedConf)
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
