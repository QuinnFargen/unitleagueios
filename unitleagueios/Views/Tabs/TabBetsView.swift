import SwiftUI

struct TabBetsView: View {
    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var betStore: BetStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = .now
    @State private var showingBookmarks = false
    @State private var selectedLeagueId: Int? = nil
    @State private var selectedTeamId: Int? = nil
    @State private var selectedBetType: String = "None"
    @State private var odds: [Odds] = []
    @State private var allOdds: [Odds] = []
    @State private var games: [Game] = []
    @State private var allGames: [Game] = []
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let oddsService = OddsService()
    private let gameService = GameService()
    private let teamService = TeamService()

    private let leagues: [(label: String, id: Int)] = [
        ("NBA", 1), ("NFL", 2), ("NHL", 3),
        ("MLB", 4), ("CFB", 5), ("CBB", 6)
    ]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var dateKey: String { dateFormatter.string(from: selectedDate) }
    private var fetchKey: String { "\(dateKey)-\(selectedLeagueId ?? 0)-\(selectedBetType)" }
    private var leaguesWithOdds: Set<Int> { Set(allOdds.map(\.leagueId)) }
    private var leaguesWithGames: Set<Int> { Set(allGames.map(\.leagueId)) }

    private var filteredTeams: [Team] {
        let gameTeamIds = Set(games.flatMap { [$0.homeTeamId, $0.awayTeamId] })
        return teams.filter { gameTeamIds.contains($0.id) }
    }

    private var availabilityTint: (Int) -> Color? {
        { id in
            if selectedBetType == "None" {
                return leaguesWithGames.contains(id) ? theme.win : theme.loss
            } else {
                return leaguesWithOdds.contains(id) ? theme.win : theme.loss
            }
        }
    }

    private var filteredOdds: [Odds] {
        let byType: [Odds]
        switch selectedBetType {
        case "SPR": byType = odds.filter { $0.sprAwayPrice != nil && $0.sprHomePrice != nil }
        case "O/U": byType = odds.filter { $0.overPrice != nil && $0.underPrice != nil }
        default:    byType = odds
        }
        guard let teamId = selectedTeamId else { return byType }
        return byType.filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
    }

    private var displayedGames: [Game] {
        guard let teamId = selectedTeamId else { return games }
        return games.filter { $0.homeTeamId == teamId || $0.awayTeamId == teamId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    DateNavigationHeader(selectedDate: $selectedDate)

                    // League filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(leagues, id: \.label) { league in
                                FilterChip(
                                    label: league.label,
                                    isSelected: selectedLeagueId == league.id,
                                    availabilityTint: availabilityTint(league.id)
                                ) {
                                    selectedLeagueId = (selectedLeagueId == league.id) ? nil : league.id
                                    selectedTeamId = nil
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Team filter — shown between league and bet types when a league is selected
                    if !filteredTeams.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filteredTeams) { team in
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

                    // Bet type filter + bookmark
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["None", "ALL", "ML", "SPR", "O/U"], id: \.self) { betType in
                                FilterChip(
                                    label: betType,
                                    isSelected: selectedBetType == betType
                                ) {
                                    selectedBetType = betType
                                }
                            }

                            Button {
                                showingBookmarks = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "bookmark.fill")
                                    if !betStore.bookmarks.isEmpty {
                                        Text("\(betStore.bookmarks.count)")
                                            .font(.caption2.weight(.bold))
                                    }
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(betStore.bookmarks.isEmpty ? theme.primaryText(colorScheme) : theme.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(betStore.bookmarks.isEmpty ? theme.chipUnselected(colorScheme) : theme.accent.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    Divider().background(theme.divider(colorScheme))

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
                                Button("Retry") { Task { await fetchContent() } }
                                    .buttonStyle(.bordered)
                            }
                            .padding()
                            Spacer()
                        } else if selectedBetType == "None" {
                            if displayedGames.isEmpty {
                                Spacer()
                                Text("No games scheduled")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(displayedGames) { game in
                                            NavigationLink {
                                                ViewGameDetail(
                                                    gameId: game.id,
                                                    home: game.home,
                                                    away: game.away,
                                                    homeTeamId: game.homeTeamId,
                                                    awayTeamId: game.awayTeamId,
                                                    leagueId: game.leagueId
                                                )
                                            } label: {
                                                GameCard(game: game)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                }
                            }
                        } else {
                            if filteredOdds.isEmpty {
                                Spacer()
                                Text("No odds available")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredOdds) { odd in
                                            NavigationLink {
                                                ViewGameDetail(
                                                    gameId: odd.gameId,
                                                    home: odd.homeAbbr,
                                                    away: odd.awayAbbr,
                                                    homeTeamId: odd.homeTeamId,
                                                    awayTeamId: odd.awayTeamId,
                                                    leagueId: odd.leagueId
                                                )
                                            } label: {
                                                OddBestCard(odd: odd, betType: selectedBetType)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: teams.isEmpty)
                .sheet(isPresented: $showingBookmarks) {
                    SheetBookmarks()
                }
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
        .task(id: fetchKey) { await fetchContent() }
        .task(id: dateKey) { await fetchAllContent() }
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

    private func fetchContent() async {
        isLoading = true
        errorMessage = nil
        games = []
        odds = []
        do {
            async let fetchedGames = gameService.fetchGames(date: selectedDate, leagueId: selectedLeagueId)
            async let fetchedOdds = oddsService.fetchOddBest(gameDt: dateKey, leagueId: selectedLeagueId)
            games = try await fetchedGames
            odds = try await fetchedOdds
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchAllContent() async {
        async let fetchedGames = gameService.fetchGames(date: selectedDate, leagueId: nil)
        async let fetchedOdds = oddsService.fetchOddBest(gameDt: dateKey, leagueId: nil)
        allGames = (try? await fetchedGames) ?? []
        allOdds = (try? await fetchedOdds) ?? []
    }

    private func fetchTeams(leagueId: Int) async {
        do {
            teams = try await teamService.fetchTeams(leagueId: leagueId)
        } catch {
            teams = []
        }
    }
}

// MARK: - GameCard

private struct GameCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let game: Game

    private let timeInputFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return f
    }()

    private let timeOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
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
                        .foregroundStyle(game.winner == game.away ? theme.win : theme.primaryText(colorScheme))
                    Text("@")
                        .foregroundStyle(.secondary)
                    Text(game.home)
                        .foregroundStyle(game.winner == game.home ? theme.win : theme.primaryText(colorScheme))
                }
                .font(.headline)
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

// MARK: - OddBestCard

private struct OddBestCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let odd: Odds
    let betType: String

    private let colW: CGFloat = 58

    private let timeInputFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return f
    }()

    private let timeOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private var formattedTime: String? {
        guard let raw = odd.gameTime,
              let date = timeInputFormatter.date(from: raw) else { return nil }
        return timeOutputFormatter.string(from: date)
    }

    private var awayIsFav: Bool { (odd.sprAwayPoints ?? 1) < 0 }

    private var scores: (away: Int, home: Int)? {
        guard let margin = odd.margin, let total = odd.total, let winner = odd.winner else { return nil }
        let hi = (total + margin) / 2.0
        let lo = (total - margin) / 2.0
        if winner == odd.homeAbbr {
            return (away: Int(lo.rounded()), home: Int(hi.rounded()))
        } else {
            return (away: Int(hi.rounded()), home: Int(lo.rounded()))
        }
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }

    private func formatPoints(_ points: Double) -> String {
        points == points.rounded() ? "\(Int(points))" : String(format: "%.1f", points)
    }

    private func impliedPct(_ price: Double?) -> String {
        guard let p = price, p > 0 else { return "" }
        return "\(Int((1.0 / p * 100.0).rounded()))%"
    }

    private func oddsCapsuleColor(_ price: Double, betHash: String?, won: Bool?) -> Color {
        guard betHash != nil else { return theme.accent.opacity(0.2) }
        if let won { return won ? theme.accent.opacity(0.7) : theme.chipUnselected(colorScheme) }
        let distance = min(abs(price - 2.0) * 0.5, 0.85)
        let base = price < 2.0 ? theme.win : theme.loss
        return base.opacity(0.15 + distance)
    }

    @ViewBuilder
    private func priceCapsule(_ price: Double?, subtitle: String = "", betHash: String? = nil, won: Bool? = nil) -> some View {
        if let p = price {
            VStack(spacing: 1) {
                Text(formatPrice(p))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: colW)
            .background(oddsCapsuleColor(p, betHash: betHash, won: won))
            .clipShape(Capsule())
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: colW)
        }
    }

    var body: some View {
        Group {
            if betType == "ALL" {
                allModeLayout
            } else {
                singleModeLayout
            }
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var allModeLayout: some View {
        let ouTotal = (odd.overPoints ?? odd.underPoints).map(formatPoints) ?? ""
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: odd.sportIcon)
                .font(.title)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    if let time = formattedTime {
                        Text(time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ForEach(["ML", "SPR", "O/U"], id: \.self) { h in
                        Text(h)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: colW, alignment: .center)
                    }
                }

                HStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text("@ ").opacity(0)
                        Text(odd.awayAbbr)
                        if let s = scores {
                            Text(" \(s.away)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    priceCapsule(odd.mlAwayPrice, subtitle: impliedPct(odd.mlAwayPrice), betHash: odd.mlAwayBetHash, won: odd.mlAwayWon)
                    priceCapsule(odd.sprAwayPrice, subtitle: {
                        let line = odd.sprAwayPoints.map(formatPoints) ?? ""
                        if let m = odd.margin { return "\(line) (\(formatPoints(m)))" }
                        return line
                    }(), betHash: odd.sprAwayBetHash, won: odd.sprAwayWon)
                    priceCapsule(
                        awayIsFav ? odd.underPrice : odd.overPrice,
                        subtitle: {
                            let prefix = awayIsFav ? "U" : "O"
                            if let t = odd.total { return "\(prefix) \(ouTotal) (\(formatPoints(t)))" }
                            return "\(prefix) \(ouTotal)"
                        }(),
                        betHash: awayIsFav ? odd.underBetHash : odd.overBetHash,
                        won: awayIsFav ? odd.underWon : odd.overWon
                    )
                }

                HStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text("@ " + odd.homeAbbr)
                        if let s = scores {
                            Text(" \(s.home)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    priceCapsule(odd.mlHomePrice, subtitle: impliedPct(odd.mlHomePrice), betHash: odd.mlHomeBetHash, won: odd.mlHomeWon)
                    priceCapsule(odd.sprHomePrice, subtitle: {
                        let line = odd.sprHomePoints.map(formatPoints) ?? ""
                        if let m = odd.margin { return "\(line) (\(formatPoints(m)))" }
                        return line
                    }(), betHash: odd.sprHomeBetHash, won: odd.sprHomeWon)
                    priceCapsule(
                        awayIsFav ? odd.overPrice : odd.underPrice,
                        subtitle: {
                            let prefix = awayIsFav ? "O" : "U"
                            if let t = odd.total { return "\(prefix) \(ouTotal) (\(formatPoints(t)))" }
                            return "\(prefix) \(ouTotal)"
                        }(),
                        betHash: awayIsFav ? odd.overBetHash : odd.underBetHash,
                        won: awayIsFav ? odd.overWon : odd.underWon
                    )
                }
            }
        }
    }

    private struct SingleData {
        let awayPrice: Double?
        let awayBetLabel: String
        let awayMLPct: String
        let awayBetHash: String?
        let awayWon: Bool?
        let homePrice: Double?
        let homeBetLabel: String
        let homeMLPct: String
        let homeBetHash: String?
        let homeWon: Bool?
    }

    private func singleData() -> SingleData {
        switch betType {
        case "ML":
            return SingleData(
                awayPrice: odd.mlAwayPrice, awayBetLabel: "", awayMLPct: impliedPct(odd.mlAwayPrice),
                awayBetHash: odd.mlAwayBetHash, awayWon: odd.mlAwayWon,
                homePrice: odd.mlHomePrice, homeBetLabel: "", homeMLPct: impliedPct(odd.mlHomePrice),
                homeBetHash: odd.mlHomeBetHash, homeWon: odd.mlHomeWon
            )
        case "SPR":
            return SingleData(
                awayPrice: odd.sprAwayPrice,
                awayBetLabel: odd.sprAwayPoints.map(formatPoints) ?? "",
                awayMLPct: impliedPct(odd.sprAwayPrice),
                awayBetHash: odd.sprAwayBetHash, awayWon: odd.sprAwayWon,
                homePrice: odd.sprHomePrice,
                homeBetLabel: odd.sprHomePoints.map(formatPoints) ?? "",
                homeMLPct: impliedPct(odd.sprHomePrice),
                homeBetHash: odd.sprHomeBetHash, homeWon: odd.sprHomeWon
            )
        case "O/U":
            let total = (odd.overPoints ?? odd.underPoints).map(formatPoints) ?? ""
            return SingleData(
                awayPrice: odd.overPrice, awayBetLabel: "O \(total)", awayMLPct: impliedPct(odd.overPrice),
                awayBetHash: odd.overBetHash, awayWon: odd.overWon,
                homePrice: odd.underPrice, homeBetLabel: "U \(total)", homeMLPct: impliedPct(odd.underPrice),
                homeBetHash: odd.underBetHash, homeWon: odd.underWon
            )
        default:
            return SingleData(awayPrice: nil, awayBetLabel: "", awayMLPct: "", awayBetHash: nil, awayWon: nil,
                              homePrice: nil, homeBetLabel: "", homeMLPct: "", homeBetHash: nil, homeWon: nil)
        }
    }

    @ViewBuilder
    private var singleModeLayout: some View {
        let d = singleData()
        HStack(spacing: 8) {
            Image(systemName: odd.sportIcon)
                .font(.title2)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 28)

            VStack(spacing: 2) {
                priceCapsule(d.awayPrice, betHash: d.awayBetHash, won: d.awayWon)
                if !d.awayBetLabel.isEmpty {
                    Text(d.awayBetLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !d.awayMLPct.isEmpty {
                Text(d.awayMLPct)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                Text(odd.awayAbbr + " @ " + odd.homeAbbr)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)
                if let time = formattedTime {
                    Text(time).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            if !d.homeMLPct.isEmpty {
                Text(d.homeMLPct)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 2) {
                priceCapsule(d.homePrice, betHash: d.homeBetHash, won: d.homeWon)
                if !d.homeBetLabel.isEmpty {
                    Text(d.homeBetLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    TabBetsView()
        .environmentObject(AppTheme())
        .environmentObject(BetStore())
}
