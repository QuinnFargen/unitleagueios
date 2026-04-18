import SwiftUI

struct TabGamesView: View {
    @State private var selectedDate: Date = .now
    @State private var selectedLeagueId: Int? = nil
    @State private var selectedTeamId: Int? = nil
    @State private var games: [Game] = []
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDatePicker = false

    private let gameService = GameService()
    private let teamService = TeamService()

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var selectedYear: Int {
        Calendar.current.component(.year, from: selectedDate)
    }

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: .now)
        return Array(2020...current + 1)
    }

    private var fetchKey: String {
        "\(selectedDate.timeIntervalSince1970)-\(selectedLeagueId ?? 0)"
    }

    private let leagues: [(label: String, id: Int?)] = [
        ("NBA", 1), ("NFL", 2), ("NHL", 3),
        ("MLB", 4), ("CFB", 5), ("CBB", 6)
    ]

    private var displayedGames: [Game] {
        guard let teamId = selectedTeamId else { return games }
        return games.filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date navigation row
                    HStack(spacing: 12) {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }

                        Button {
                            showDatePicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.subheadline.weight(.semibold))
                                Text(displayFormatter.string(from: selectedDate))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                        }
                        .sheet(isPresented: $showDatePicker) {
                            DatePickerSheet(selectedDate: $selectedDate)
                        }

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }

                        Button("Today") {
                            selectedDate = .now
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    // League filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(leagues, id: \.label) { league in
                                FilterChip(
                                    label: league.label,
                                    isSelected: selectedLeagueId == league.id
                                ) {
                                    selectedLeagueId = (selectedLeagueId == league.id) ? nil : league.id
                                    selectedTeamId = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Team filter — only shown when a league is selected
                    if !teams.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(teams) { team in
                                    FilterChip(
                                        label: team.abbr,
                                        isSelected: selectedTeamId == team.id
                                    ) {
                                        selectedTeamId = (selectedTeamId == team.id) ? nil : team.id
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Content
                    Group {
                        if isLoading {
                            Spacer()
                            ProgressView().tint(.white)
                            Spacer()
                        } else if let error = errorMessage {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundStyle(.red)
                                Text(error)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry") { Task { await fetchGames() } }
                                    .buttonStyle(.bordered)
                            }
                            .padding()
                            Spacer()
                        } else if displayedGames.isEmpty {
                            Spacer()
                            Text("No games scheduled")
                                .foregroundStyle(.secondary)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(displayedGames) { game in
                                        GameCard(game: game)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: teams.isEmpty)
            }
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task(id: fetchKey) { await fetchGames() }
        .onChange(of: selectedLeagueId) { _, leagueId in
            Task {
                if let id = leagueId {
                    await fetchTeams(leagueId: id)
                } else {
                    teams = []
                    selectedTeamId = nil
                }
            }
        }
    }

    private func fetchGames() async {
        isLoading = true
        errorMessage = nil
        games = []
        do {
            games = try await gameService.fetchGames(date: selectedDate, leagueId: selectedLeagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchTeams(leagueId: Int) async {
        do {
            teams = try await teamService.fetchTeams(leagueId: leagueId)
        } catch {
            teams = []
        }
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - GameCard

private struct GameCard: View {
    let game: Game

    private let timeInputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let timeOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var formattedTime: String? {
        guard let raw = game.gameTime,
              let date = timeInputFormatter.date(from: raw) else { return nil }
        return timeOutputFormatter.string(from: date)
    }

    private var sportIcon: String {
        switch game.leagueId {
        case 1:  return "basketball"
        case 2:  return "american.football.professional"
        case 3:  return "hockey.puck"
        case 4:  return "baseball"
        case 5:  return "american.football"
        case 6:  return "basketball.fill"
        default: return "sportscourt"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: sportIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(game.away)
                        .fontWeight(game.winner == game.away ? .bold : .regular)
                    Text("@")
                        .foregroundStyle(.secondary)
                    Text(game.home)
                        .fontWeight(game.winner == game.home ? .bold : .regular)
                }
                .font(.headline)
                .foregroundStyle(.white)
            }

            Spacer()

            if let hscore = game.homeScore, let ascore = game.awayScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(ascore) – \(hscore)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("FINAL")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let time = formattedTime {
                Text(time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("TBD")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - DatePickerSheet

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.white)
                .colorScheme(.dark)
                .padding(.horizontal)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    TabGamesView()
}
