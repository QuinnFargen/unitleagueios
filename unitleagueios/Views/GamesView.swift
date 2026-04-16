import SwiftUI

struct GamesView: View {
    @State private var selectedDate: Date = .now
    @State private var selectedLeagueId: Int? = nil
    @State private var games: [Game] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = GameService()

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var fetchKey: String {
        "\(selectedDate.timeIntervalSince1970)-\(selectedLeagueId ?? 0)"
    }

    private let leagues: [(label: String, id: Int?)] = [
        ("All", nil),
        ("NBA", 1), ("NFL", 2), ("NHL", 3),
        ("MLB", 4), ("CFB", 5), ("CBB", 6)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack{
                        // Date navigation
                        HStack {
                            Button {
                                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                            }
                            
                            Spacer()
                            
                            Text(displayFormatter.string(from: selectedDate))
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        // League filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(leagues, id: \.label) { league in
                                    FilterChip(
                                        label: league.label,
                                        isSelected: selectedLeagueId == league.id
                                    ) {
                                        selectedLeagueId = league.id
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
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
                        } else if games.isEmpty {
                            Spacer()
                            Text("No games scheduled")
                                .foregroundStyle(.secondary)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(games) { game in
                                        GameCard(game: game)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task(id: fetchKey) { await fetchGames() }
    }

    private func fetchGames() async {
        isLoading = true
        errorMessage = nil
        games = []
        do {
            games = try await service.fetchGames(date: selectedDate, leagueId: selectedLeagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
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

    var body: some View {
        HStack {
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

#Preview {
    GamesView()
}
