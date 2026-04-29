import SwiftUI

struct TabResearchView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var leagues: [League] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var expandedLeagueId: Int? = 1

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
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(leagues) { league in
                                    LeagueExpandableCard(
                                        league: league,
                                        isExpanded: expandedLeagueId == league.id
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            expandedLeagueId = expandedLeagueId == league.id ? nil : league.id
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
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

// MARK: - LeagueExpandableCard

private struct LeagueExpandableCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let league: League
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: league.sportIcon)
                        .font(.title2)
                        .foregroundStyle(theme.primaryText(colorScheme))
                        .frame(width: 44, height: 44)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(league.abbr)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(theme.primaryText(colorScheme))
                        Text(league.sport)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(Circle())
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded options
            if isExpanded {
                Divider().background(theme.divider(colorScheme))
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    NavigationLink {
                        ViewTeamList(league: league)
                    } label: {
                        LeagueOptionCell(icon: "person.2", title: "Teams")
                    }
                    .buttonStyle(.plain)

                    LeagueOptionCell(icon: "list.number", title: "Ranks")

                    LeagueOptionCell(icon: "calendar", title: "Sched")

                    LeagueOptionCell(icon: "chart.bar", title: "Odds")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - LeagueOptionCell

private struct LeagueOptionCell: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(theme.appBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.primaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    TabResearchView()
        .environmentObject(AppTheme())
}
