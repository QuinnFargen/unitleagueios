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

// MARK: - BetGameBanner

struct BetGameBanner: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let bet: SelectedBet

    private let timeInputFmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return f
    }()
    private let timeOutputFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()
    private let dateInputFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    private let dateOutputFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var formattedTime: String? {
        guard let raw = bet.gameTime, let d = timeInputFmt.date(from: raw) else { return nil }
        return timeOutputFmt.string(from: d)
    }

    private var formattedDate: String? {
        guard let raw = bet.gameDate, let d = dateInputFmt.date(from: raw) else { return nil }
        return dateOutputFmt.string(from: d)
    }

    private var betLabel: String {
        let teamSide = bet.team ?? (bet.side == "Away" ? bet.awayAbbr : (bet.side == "Home" ? bet.homeAbbr : bet.side))
        switch bet.type {
        case "SPR":
            if let p = bet.points {
                let s = p == p.rounded()
                    ? (p >= 0 ? "+\(Int(p))" : "\(Int(p))")
                    : String(format: p >= 0 ? "+%.1f" : "%.1f", p)
                return "\(teamSide) \(s)"
            }
            return "\(teamSide) SPR"
        case "O/U":
            if let p = bet.points {
                let s = p == p.rounded() ? "\(Int(p))" : String(format: "%.1f", p)
                return "\(teamSide) \(s)"
            }
            return "\(teamSide) O/U"
        default:
            return bet.type.isEmpty ? teamSide : "\(teamSide) \(bet.type)"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bet.awayAbbr + " @ " + bet.homeAbbr)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))
                if let date = formattedDate {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let time = formattedTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(betLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", bet.price))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(theme.accent)
                    Text("x")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(theme.accent)
                    if let u = bet.unit {
                        Text(txnWagerLabel(u))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "nairasign.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private func txnWagerLabel(_ units: Double) -> String {
    units == 0.5 ? "½" : String(format: "%.4g", units)
}

// MARK: - ViewGameDetail

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
                        CardManyOdds(odds: oddMany, awayAbbr: away, homeAbbr: home) { bet in
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


// MARK: - GameOddsCard → GameOddsCard.swift
// MARK: - AllOddsSection → AllOddsSection.swift

// MARK: - SelectedBet + PlacedBet interop

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
