import SwiftUI

struct TabGamesView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
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

    private var prevDayNumber: Int {
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        return Calendar.current.component(.day, from: prev)
    }

    private var nextDayNumber: Int {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        return Calendar.current.component(.day, from: next)
    }

    private var todayDayNumber: Int {
        Calendar.current.component(.day, from: .now)
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
                theme.appBackground(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date navigation row
                    HStack(spacing: 12) {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            HStack{
                                Image(systemName: "chevron.left")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                Image(systemName: "\(prevDayNumber).calendar")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(Capsule())

                        Button {
                            showDatePicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(displayFormatter.string(from: selectedDate))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(theme.primaryText(colorScheme))
                        }
                        .sheet(isPresented: $showDatePicker) {
                            DatePickerSheet(selectedDate: $selectedDate)
                        }

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        } label: {
                            HStack{
                                Image(systemName: "\(nextDayNumber).calendar")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                Image(systemName: "chevron.right")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(Capsule())

                        Button("Today") {
                                selectedDate = .now
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.primaryText(colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.cardBackground(colorScheme))
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
                        .background(theme.divider(colorScheme))

                    // Content
                    Group {
                        if isLoading {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else if let error = errorMessage {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundStyle(theme.error)
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
                .gesture(
                    DragGesture(minimumDistance: 40, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = abs(value.translation.height)
                            guard abs(horizontal) > vertical else { return }
                            if horizontal < 0 {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            } else {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            }
                        }
                )
            }
            .tabToolbar()
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
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? theme.chipSelectedFG(colorScheme) : theme.primaryText(colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? theme.chipSelected(colorScheme) : theme.chipUnselected(colorScheme))
                .clipShape(Capsule())
        }
    }
}

// MARK: - GameCard

private struct GameCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
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

    var body: some View {
        HStack {
            Image(systemName: game.sportIcon)
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 36, height: 36)
                .background(theme.cardBackground(colorScheme))
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
                .foregroundStyle(theme.primaryText(colorScheme))
            }

            Spacer()

            if let hscore = game.homeScore, let ascore = game.awayScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(ascore) – \(hscore)")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText(colorScheme))
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
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - DatePickerSheet

private struct DatePickerSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()
                DatePicker(
                    "",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(theme.accent)
                .padding(.horizontal)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TabGamesView()
        .environmentObject(AppTheme())
}
