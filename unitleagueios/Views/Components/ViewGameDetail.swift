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
                            GameOddsCard(odd: odd) { bet in selectedBet = bet }
                        }
                        .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        if let awayTeam, let league {
                            NavigationLink {
                                ViewSched(team: awayTeam, league: league)
                            } label: {
                                ViewTeamBanner(team: awayTeam, league: league, showChevron: true)
                            }
                            .buttonStyle(.plain)
                        }

                        if let homeTeam, let league {
                            NavigationLink {
                                ViewSched(team: homeTeam, league: league)
                            } label: {
                                ViewTeamBanner(team: homeTeam, league: league, showChevron: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    if isUpcoming && !oddMany.isEmpty {
                        AllOddsSection(odds: oddMany, awayAbbr: away, homeAbbr: home) { bet in
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

// MARK: - GameOddsCard

struct GameOddsCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let odd: Odds
    let onBetSelected: (SelectedBet) -> Void

    private let colW: CGFloat = 58
    private let scoreW: CGFloat = 36

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
    private func scoreCapsule(_ value: Int) -> some View {
        Text("\(value)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.primaryText(colorScheme))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: scoreW)
            .background(theme.chipUnselected(colorScheme))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func priceCapsule(_ price: Double?, subtitle: String = "", betHash: String? = nil, won: Bool? = nil, displayOverride: String? = nil, onTap: (() -> Void)? = nil) -> some View {
        if let p = price {
            if betHash != nil, let onTap {
                Button(action: onTap) {
                    priceCapsuleLabel(p, display: displayOverride ?? formatPrice(p), subtitle: subtitle, betHash: betHash, won: won)
                }
                .buttonStyle(.plain)
            } else {
                priceCapsuleLabel(p, display: displayOverride ?? formatPrice(p), subtitle: subtitle, betHash: betHash, won: won)
            }
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: colW)
        }
    }

    @ViewBuilder
    private func priceCapsuleLabel(_ price: Double, display: String, subtitle: String, betHash: String?, won: Bool?) -> some View {
        VStack(spacing: 1) {
            Text(display)
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
        .background(oddsCapsuleColor(price, betHash: betHash, won: won))
        .clipShape(Capsule())
    }

    var body: some View {
        let ouTotal = (odd.overPoints ?? odd.underPoints).map(formatPoints) ?? ""
        let awayOUWon = awayIsFav ? odd.underWon : odd.overWon
        let homeOUWon = awayIsFav ? odd.overWon : odd.underWon
        let sprAwayLost = odd.sprAwayWon == false
        let sprHomeLost = odd.sprHomeWon == false

        HStack(alignment: .center, spacing: 10) {
            Image(systemName: odd.sportIcon)
                .font(.title)
                .foregroundStyle(theme.primaryText(colorScheme))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 6) {
                // Header row: time | spacer | score placeholder | ML | SPR | O/U
                HStack(spacing: 4) {
                    if let time = formattedTime {
                        Text(time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Spacer().frame(width: scoreW)
                    ForEach(["ML", "SPR", "O/U"], id: \.self) { h in
                        Text(h)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: colW, alignment: .center)
                    }
                }

                // Away row
                HStack(spacing: 4) {
                    Text(odd.awayAbbr)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let s = scores { scoreCapsule(s.away) } else { Spacer().frame(width: scoreW) }
                    priceCapsule(odd.mlAwayPrice, subtitle: impliedPct(odd.mlAwayPrice),
                                 betHash: odd.mlAwayBetHash, won: odd.mlAwayWon) {
                        guard let p = odd.mlAwayPrice, let h = odd.mlAwayBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "ML", side: "Away", price: p, points: nil,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr,
                                                  gameTime: odd.gameTime, gameDate: odd.gameDt))
                    }
                    priceCapsule(odd.sprAwayPrice,
                                 subtitle: sprAwayLost ? "" : (odd.sprAwayPoints.map(formatPoints) ?? ""),
                                 betHash: odd.sprAwayBetHash, won: odd.sprAwayWon,
                                 displayOverride: sprAwayLost ? odd.margin.map(formatPoints) : nil) {
                        guard let p = odd.sprAwayPrice, let h = odd.sprAwayBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "SPR", side: "Away", price: p, points: odd.sprAwayPoints,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr,
                                                  gameTime: odd.gameTime, gameDate: odd.gameDt))
                    }
                    priceCapsule(
                        awayIsFav ? odd.underPrice : odd.overPrice,
                        subtitle: awayOUWon == false ? "" : (awayIsFav ? "U \(ouTotal)" : "O \(ouTotal)"),
                        betHash: awayIsFav ? odd.underBetHash : odd.overBetHash,
                        won: awayOUWon,
                        displayOverride: awayOUWon == false ? odd.total.map(formatPoints) : nil
                    ) {
                        let price = awayIsFav ? odd.underPrice : odd.overPrice
                        let hash  = awayIsFav ? odd.underBetHash : odd.overBetHash
                        let pts   = odd.overPoints ?? odd.underPoints
                        guard let p = price, let h = hash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "O/U", side: awayIsFav ? "Under" : "Over",
                                                  price: p, points: pts, awayAbbr: odd.awayAbbr,
                                                  homeAbbr: odd.homeAbbr, gameTime: odd.gameTime, gameDate: odd.gameDt))
                    }
                }

                // Home row
                HStack(spacing: 4) {
                    Text("@ " + odd.homeAbbr)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let s = scores { scoreCapsule(s.home) } else { Spacer().frame(width: scoreW) }
                    priceCapsule(odd.mlHomePrice, subtitle: impliedPct(odd.mlHomePrice),
                                 betHash: odd.mlHomeBetHash, won: odd.mlHomeWon) {
                        guard let p = odd.mlHomePrice, let h = odd.mlHomeBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "ML", side: "Home", price: p, points: nil,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr,
                                                  gameTime: odd.gameTime, gameDate: odd.gameDt))
                    }
                    priceCapsule(odd.sprHomePrice,
                                 subtitle: sprHomeLost ? "" : (odd.sprHomePoints.map(formatPoints) ?? ""),
                                 betHash: odd.sprHomeBetHash, won: odd.sprHomeWon,
                                 displayOverride: sprHomeLost ? odd.margin.map(formatPoints) : nil) {
                        guard let p = odd.sprHomePrice, let h = odd.sprHomeBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "SPR", side: "Home", price: p, points: odd.sprHomePoints,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr,
                                                  gameTime: odd.gameTime, gameDate: odd.gameDt))
                    }
                    priceCapsule(
                        awayIsFav ? odd.overPrice : odd.underPrice,
                        subtitle: homeOUWon == false ? "" : (awayIsFav ? "O \(ouTotal)" : "U \(ouTotal)"),
                        betHash: awayIsFav ? odd.overBetHash : odd.underBetHash,
                        won: homeOUWon,
                        displayOverride: homeOUWon == false ? odd.total.map(formatPoints) : nil
                    ) {
                        let price = awayIsFav ? odd.overPrice : odd.underPrice
                        let hash  = awayIsFav ? odd.overBetHash : odd.underBetHash
                        let pts   = odd.overPoints ?? odd.underPoints
                        guard let p = price, let h = hash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "O/U", side: awayIsFav ? "Over" : "Under",
                                                  price: p, points: pts, awayAbbr: odd.awayAbbr,
                                                  homeAbbr: odd.homeAbbr, gameTime: odd.gameTime, gameDate: odd.gameDt))
                    }
                }
            }
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}


// MARK: - AllOddsSection

private struct AllOddsSection: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme

    let odds: [OddMany]
    let awayAbbr: String
    let homeAbbr: String
    let onBetSelected: (SelectedBet) -> Void

    @State private var isExpanded = false
    @State private var selectedBetType = "ML"

    private let colW: CGFloat = 62

    private func formatPrice(_ price: Double) -> String { String(format: "%.2f", price) }
    private func formatPoints(_ points: Double) -> String {
        points == points.rounded() ? "\(Int(points))" : String(format: "%.1f", points)
    }

    private func oddsCapsuleColor(_ price: Double) -> Color {
        let distance = min(abs(price - 2.0) * 0.5, 0.85)
        let base = price < 2.0 ? theme.win : theme.loss
        return base.opacity(0.15 + distance)
    }

    private func selectedBet(from oddMany: OddMany) -> SelectedBet {
        let type = (oddMany.betType == "OVER" || oddMany.betType == "UNDER") ? "O/U" : oddMany.betType
        let side: String
        if oddMany.teamAbbr == nil {
            side = oddMany.betType == "OVER" ? "Over" : "Under"
        } else {
            side = oddMany.teamAbbr == awayAbbr ? "Away" : "Home"
        }
        return SelectedBet(betHash: oddMany.betHash, type: type, side: side,
                           price: oddMany.price, points: oddMany.points,
                           awayAbbr: oddMany.awayAbbr, homeAbbr: oddMany.homeAbbr,
                           gameTime: oddMany.gameTime, gameDate: oddMany.gameDt,
                           team: oddMany.teamAbbr)
    }

    private var filteredOdds: [OddMany] {
        switch selectedBetType {
        case "ML":   return odds.filter { $0.betType == "ML" }
        case "SPR":  return odds.filter { $0.betType == "SPR" }
        case "O/U":  return odds.filter { $0.betType == "OVER" || $0.betType == "UNDER" }
        default:     return []
        }
    }

    private var bookmakers: [String] {
        Array(Set(filteredOdds.map(\.bookmaker))).sorted()
    }

    @ViewBuilder
    private func oddsRow(bookmaker: String) -> some View {
        let lhsBets = filteredOdds.filter { $0.bookmaker == bookmaker && lhsMatch($0) }
        let rhsBets = filteredOdds.filter { $0.bookmaker == bookmaker && rhsMatch($0) }
        let lhs = lhsBets.first
        let rhs = rhsBets.first

        HStack(spacing: 8) {
            if let bet = lhs {
                Button { onBetSelected(selectedBet(from: bet)) } label: {
                    oddsLabel(bet)
                }
                .buttonStyle(.plain)
            } else {
                Text("—").font(.caption).foregroundStyle(.secondary).frame(width: colW)
            }

            Text(bookmaker)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(1)

            if let bet = rhs {
                Button { onBetSelected(selectedBet(from: bet)) } label: {
                    oddsLabel(bet)
                }
                .buttonStyle(.plain)
            } else {
                Text("—").font(.caption).foregroundStyle(.secondary).frame(width: colW)
            }
        }
    }

    private func lhsMatch(_ odd: OddMany) -> Bool {
        switch selectedBetType {
        case "ML", "SPR": return odd.teamAbbr == awayAbbr
        case "O/U":        return odd.betType == "OVER"
        default:           return false
        }
    }

    private func rhsMatch(_ odd: OddMany) -> Bool {
        switch selectedBetType {
        case "ML", "SPR": return odd.teamAbbr == homeAbbr
        case "O/U":        return odd.betType == "UNDER"
        default:           return false
        }
    }

    @ViewBuilder
    private func oddsLabel(_ odd: OddMany) -> some View {
        VStack(spacing: 1) {
            Text(formatPrice(odd.price))
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.primaryText(colorScheme))
            if let pts = odd.points {
                let prefix = odd.betType == "OVER" ? "O" : (odd.betType == "UNDER" ? "U" : "")
                let label = prefix.isEmpty ? formatPoints(pts) : "\(prefix) \(formatPoints(pts))"
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: colW)
        .background(oddsCapsuleColor(odd.price))
        .clipShape(Capsule())
    }

    private var columnHeaders: (String, String) {
        switch selectedBetType {
        case "O/U": return ("Over", "Under")
        default:    return (awayAbbr, homeAbbr)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("All Odds")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(theme.divider(colorScheme))

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(["ML", "SPR", "O/U"], id: \.self) { t in
                            FilterChip(label: t, isSelected: selectedBetType == t) {
                                selectedBetType = t
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                    let (lhsLabel, rhsLabel) = columnHeaders
                    HStack(spacing: 8) {
                        Text(lhsLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: colW, alignment: .center)
                        Spacer()
                        Text(rhsLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: colW, alignment: .center)
                    }
                    .padding(.horizontal, 14)

                    VStack(spacing: 6) {
                        ForEach(bookmakers, id: \.self) { bm in
                            oddsRow(bookmaker: bm)
                                .padding(.horizontal, 14)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}


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
