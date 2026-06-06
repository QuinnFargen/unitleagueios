import SwiftUI

// MARK: - SelectedBet

struct SelectedBet: Identifiable {
    let id = UUID()
    let betHash: String
    let type: String        // "ML", "SPR", "O/U", or "" when unknown
    let side: String        // kept for PlacedBet compat; "" when unused
    let price: Double
    let points: Double?     // spread value or O/U total; nil for ML
    let awayAbbr: String
    let homeAbbr: String
    let gameTime: String?
    let gameDate: String?
    var team: String? = nil  // team abbr from Txn (e.g. "BAL"); preferred over side-logic
    var unit: Double? = nil  // when set, BetGameBanner shows unit count after price
}

struct ViewGameDetail: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme

    let gameId: Int
    let home: String
    let away: String
    let homeTeamId: Int
    let awayTeamId: Int
    let leagueId: Int

    @AppStorage("bettorId")            private var bettorId: Int           = 0
    @AppStorage("selectedSyndicateId") private var selectedSyndicateId: Int = 0

    @State private var odd: Odds?
    @State private var homeTeam: Team?
    @State private var awayTeam: Team?
    @State private var league: League?
    @State private var selectedBet: SelectedBet?
    @State private var oddMany: [OddMany] = []

    private let oddService = OddsService()
    private let teamService = TeamService()
    private let leagueService = LeagueService()
    private let oddManyService = OddManyService()

    private var isUpcoming: Bool {
        let gameDt = odd?.gameDt ?? oddMany.first?.gameDt
        guard let raw = gameDt else { return false }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        guard let date = f.date(from: raw) else { return false }
        return Calendar.current.startOfDay(for: date) >= Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ZStack {
            theme.appBackground(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let odd {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Best Odds")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            CardGameOdds(odd: odd) { bet in selectedBet = bet }
                        }
                        .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        if let awayTeam, let league {
                            NavigationLink {
                                ViewSched(team: awayTeam, league: league)
                            } label: {
                                CardTeam(team: awayTeam, league: league, showChevron: true)
                            }
                            .buttonStyle(.plain)
                        }

                        if let homeTeam, let league {
                            NavigationLink {
                                ViewSched(team: homeTeam, league: league)
                            } label: {
                                CardTeam(team: homeTeam, league: league, showChevron: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    if isUpcoming && !oddMany.isEmpty {
                        CardOddMany(odds: oddMany, awayAbbr: away, homeAbbr: home) { bet in
                            selectedBet = bet
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("\(away) @ \(home)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await fetchData() }
        .sheet(item: $selectedBet) { bet in
            SheetConfirmBet(bet: bet, bettorId: bettorId, syndicateId: selectedSyndicateId)
        }
    }

    private func fetchData() async {
        async let oddsTask = try? oddService.fetchOddBest(gameId: gameId)
        async let teamsTask = try? teamService.fetchTeams(leagueId: leagueId)
        async let leaguesTask = try? leagueService.fetchLeagues()
        async let oddManyTask = try? oddManyService.fetchOddAll(gameId: gameId)

        let (odds, teams, leagues, many) = await (oddsTask, teamsTask, leaguesTask, oddManyTask)

        odd = odds?.first
        awayTeam = teams?.first { $0.id == awayTeamId }
        homeTeam = teams?.first { $0.id == homeTeamId }
        league = leagues?.first { $0.id == leagueId }
        oddMany = many ?? []
    }
}

extension SelectedBet {
    init(placedBet: PlacedBet) {
        self.init(
            betHash:  placedBet.betHash,
            type:     placedBet.type,
            side:     placedBet.side,
            price:    placedBet.price,
            points:   placedBet.points,
            awayAbbr: placedBet.awayAbbr,
            homeAbbr: placedBet.homeAbbr,
            gameTime: placedBet.gameTime,
            gameDate: placedBet.gameDate
        )
    }
}

#Preview("ViewGameDetail") {
    NavigationStack {
        ViewGameDetail(
            gameId: 101,
            home: "LAL",
            away: "BOS",
            homeTeamId: 1,
            awayTeamId: 2,
            leagueId: 1
        )
    }
    .environmentObject(AppTheme())
    .environmentObject(BetStore())
}
