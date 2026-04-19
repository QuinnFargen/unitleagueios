import SwiftUI

struct TabLeaguesView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userLeagues") private var userLeaguesData: Data = Data()
    @State private var showingJoin = false
    @State private var showingCreate = false

    private var userLeagues: [UserLeague] {
        (try? JSONDecoder().decode([UserLeague].self, from: userLeaguesData)) ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 12) {
                            LeagueActionButton(title: "Join", icon: "person.badge.plus", tint: .green) {
                                showingJoin = true
                            }
                            LeagueActionButton(title: "Create", icon: "plus.circle", tint: theme.error) {
                                showingCreate = true
                            }
                        }

                        if !userLeagues.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("My Leagues")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(userLeagues) { league in
                                    NavigationLink(destination: ViewLeagueDetail(userLeague: league)) {
                                        UserLeagueCard(userLeague: league)
                                    }
                                    .buttonStyle(.plain)
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
                LeagueFormSheet(title: "Join League", confirmLabel: "Join") { newLeague in
                    append(newLeague)
                }
            }
            .sheet(isPresented: $showingCreate) {
                LeagueFormSheet(title: "Create League", confirmLabel: "Create") { newLeague in
                    append(newLeague)
                }
            }
        }
    }

    private func append(_ league: UserLeague) {
        var current = userLeagues
        current.append(league)
        userLeaguesData = (try? JSONEncoder().encode(current)) ?? Data()
    }
}

// MARK: - UserLeague model

struct UserLeague: Codable, Identifiable {
    let id: UUID
    let leagueId: Int
    let abbr: String
    let sport: String
    let customName: String
    let colorName: String

    init(id: UUID, leagueId: Int, abbr: String, sport: String, customName: String, colorName: String) {
        self.id = id
        self.leagueId = leagueId
        self.abbr = abbr
        self.sport = sport
        self.customName = customName
        self.colorName = colorName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(UUID.self,   forKey: .id)
        leagueId   = try c.decode(Int.self,    forKey: .leagueId)
        abbr       = try c.decode(String.self, forKey: .abbr)
        sport      = try c.decode(String.self, forKey: .sport)
        customName = try c.decode(String.self, forKey: .customName)
        colorName  = (try? c.decode(String.self, forKey: .colorName)) ?? LeagueOption.colorNames[0]
    }
}

// MARK: - Sub-views

private struct LeagueActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(tint.opacity(0.15))
                .foregroundStyle(tint)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35), lineWidth: 1))
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
                .foregroundStyle(ProfileOption.color(for: userLeague.colorName))
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
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
    let onConfirm: (UserLeague) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var leagues: [League] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedLeagueId: Int?
    @State private var leagueName = ""
    @State private var selectedColorName: String = LeagueOption.colorNames[0]
    @AppStorage("leagueSymbol")    private var leagueSymbol: String    = "sportscourt"
    @AppStorage("leagueColorName") private var leagueColorName: String = LeagueOption.colorNames[0]

    private let service = LeagueService()

    private var selectedLeague: League? {
        leagues.first { $0.id == selectedLeagueId }
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

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                Form {
                    Section("Select League") {
                        if isLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Loading leagues...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if let error = errorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Retry") { fetchLeagues() }
                                    .font(.caption)
                            }
                        } else if leagues.isEmpty {
                            Text("No leagues available")
                                .foregroundStyle(.secondary)
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

                    Section("Your Color") {
                        HStack(spacing: 16) {
                            ForEach(LeagueOption.colorNames, id: \.self) { name in
                                Button {
                                    selectedColorName = name
                                } label: {
                                    Circle()
                                        .fill(ProfileOption.color(for: name))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(theme.primaryText(colorScheme),
                                                        lineWidth: selectedColorName == name ? 2.5 : 0)
                                        )
                                        .shadow(
                                            color: ProfileOption.color(for: name)
                                                .opacity(selectedColorName == name ? 0.6 : 0),
                                            radius: 6
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .task { fetchLeagues() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel) {
                        if let league = selectedLeague {
                            leagueSymbol    = League.sportIcon(for: league.id)
                            leagueColorName = selectedColorName
                            onConfirm(UserLeague(
                                id: UUID(),
                                leagueId: league.id,
                                abbr: league.abbr,
                                sport: league.sport,
                                customName: leagueName.trimmingCharacters(in: .whitespaces),
                                colorName: selectedColorName
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
