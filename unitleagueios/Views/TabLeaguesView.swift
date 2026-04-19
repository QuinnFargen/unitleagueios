import SwiftUI

struct TabLeaguesView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userLeagues") private var userLeaguesData: Data = Data()
    @AppStorage("leagueSymbol") private var leagueSymbol: String = LeagueOption.symbols[0]
    @AppStorage("leagueColorName") private var leagueColorName: String = LeagueOption.colorNames[0]
    @State private var showingJoin = false
    @State private var showingCreate = false
    @State private var leagues: [League] = []

    private let service = LeagueService()

    private var userLeagues: [UserLeague] {
        (try? JSONDecoder().decode([UserLeague].self, from: userLeaguesData)) ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        LeagueActionButton(title: "Join League", icon: "person.badge.plus") {
                            showingJoin = true
                        }

                        LeagueActionButton(title: "Create League", icon: "plus.circle") {
                            showingCreate = true
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("League Badge")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 32)

                            HStack(spacing: 14) {
                                ForEach(LeagueOption.symbols, id: \.self) { symbol in
                                    Button { leagueSymbol = symbol } label: {
                                        Image(systemName: symbol)
                                            .font(.title2)
                                            .foregroundStyle(leagueSymbol == symbol ? theme.primaryText(colorScheme) : .secondary)
                                            .frame(width: 52, height: 52)
                                            .background(leagueSymbol == symbol ? theme.cardBackgroundProminent(colorScheme) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        leagueSymbol == symbol ? theme.primaryText(colorScheme).opacity(0.4) : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            HStack(spacing: 16) {
                                ForEach(LeagueOption.colorNames, id: \.self) { name in
                                    Button { leagueColorName = name } label: {
                                        Circle()
                                            .fill(ProfileOption.color(for: name))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(theme.primaryText(colorScheme), lineWidth: leagueColorName == name ? 2.5 : 0)
                                            )
                                            .shadow(
                                                color: ProfileOption.color(for: name).opacity(leagueColorName == name ? 0.6 : 0),
                                                radius: 6
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }

                        if !userLeagues.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("My Leagues")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(userLeagues) { league in
                                    UserLeagueCard(userLeague: league)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .tabToolbar()
            .sheet(isPresented: $showingJoin) {
                LeagueFormSheet(title: "Join League", confirmLabel: "Join", leagues: leagues) { newLeague in
                    append(newLeague)
                }
            }
            .sheet(isPresented: $showingCreate) {
                LeagueFormSheet(title: "Create League", confirmLabel: "Create", leagues: leagues) { newLeague in
                    append(newLeague)
                }
            }
            .task { fetchLeagues() }
        }
    }

    private func fetchLeagues() {
        Task {
            leagues = (try? await service.fetchLeagues()) ?? []
        }
    }

    private func append(_ league: UserLeague) {
        var current = userLeagues
        current.append(league)
        userLeaguesData = (try? JSONEncoder().encode(current)) ?? Data()
    }
}

struct UserLeague: Codable, Identifiable {
    let id: UUID
    let leagueId: Int
    let abbr: String
    let sport: String
    let customName: String
}

private struct LeagueActionButton: View {
    @EnvironmentObject private var theme: AppTheme
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct UserLeagueCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let userLeague: UserLeague

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: League.sportIcon(for: userLeague.leagueId))
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 44, height: 44)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(userLeague.abbr)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))
                Text(userLeague.customName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct LeagueFormSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let confirmLabel: String
    let leagues: [League]
    let onConfirm: (UserLeague) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedLeagueId: Int?
    @State private var leagueName = ""

    private var selectedLeague: League? {
        leagues.first { $0.id == selectedLeagueId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                Form {
                    Section("Select League") {
                        if leagues.isEmpty {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Loading leagues...")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(leagues) { league in
                                LeagueOptionRow(
                                    league: league,
                                    isSelected: selectedLeagueId == league.id
                                ) {
                                    selectedLeagueId = league.id
                                }
                            }
                        }
                    }

                    Section("League Name") {
                        TextField("Enter a name", text: $leagueName)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel) {
                        if let league = selectedLeague {
                            onConfirm(UserLeague(
                                id: UUID(),
                                leagueId: league.id,
                                abbr: league.abbr,
                                sport: league.sport,
                                customName: leagueName.trimmingCharacters(in: .whitespaces)
                            ))
                        }
                        dismiss()
                    }
                    .disabled(selectedLeagueId == nil || leagueName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(theme.accent)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct LeagueOptionRow: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let league: League
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: League.sportIcon(for: league.id))
                    .font(.title3)
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(width: 36, height: 36)
                    .background(theme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(league.abbr)
                        .font(.headline)
                        .foregroundStyle(theme.primaryText(colorScheme))
                    Text(league.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabLeaguesView()
        .environmentObject(AppTheme())
}
