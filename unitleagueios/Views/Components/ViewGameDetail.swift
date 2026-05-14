import SwiftUI

// MARK: - SelectedBet

struct SelectedBet: Identifiable {
    let id = UUID()
    let betHash: String
    let type: String        // "ML", "SPR", "O/U"
    let side: String        // "Away" or "Home"
    let price: Double
    let points: Double?     // spread value or O/U total; nil for ML
    let awayAbbr: String
    let homeAbbr: String
    let gameTime: String?
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

    private let oddService = OddsService()
    private let teamService = TeamService()
    private let leagueService = LeagueService()

    var body: some View {
        ZStack {
            theme.appBackground(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let odd {
                        GameOddsCard(odd: odd) { bet in selectedBet = bet }
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
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("\(away) @ \(home)")
        .navigationBarTitleDisplayMode(.inline)
        .task { await fetchData() }
        .sheet(item: $selectedBet) { bet in
            BetConfirmationSheet(bet: bet, bettorId: bettorId, syndicateId: selectedSyndicateId)
        }
    }

    private func fetchData() async {
        async let oddsTask = try? oddService.fetchOddBest(gameId: gameId)
        async let teamsTask = try? teamService.fetchTeams(leagueId: leagueId)
        async let leaguesTask = try? leagueService.fetchLeagues()

        let (odds, teams, leagues) = await (oddsTask, teamsTask, leaguesTask)

        odd = odds?.first
        awayTeam = teams?.first { $0.id == awayTeamId }
        homeTeam = teams?.first { $0.id == homeTeamId }
        league = leagues?.first { $0.id == leagueId }
    }
}

// MARK: - GameOddsCard

private struct GameOddsCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let odd: Odds
    let onBetSelected: (SelectedBet) -> Void

    private let colW: CGFloat = 58

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
        guard let raw = odd.gameTime,
              let date = timeInputFormatter.date(from: raw) else { return nil }
        return timeOutputFormatter.string(from: date)
    }

    private var awayIsFav: Bool { (odd.sprAwayPoints ?? 1) < 0 }

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

    private func oddsCapsuleColor(_ price: Double) -> Color {
        let distance = min(abs(price - 2.0) * 0.5, 0.85)
        let base = price < 2.0 ? theme.win : theme.loss
        return base.opacity(0.15 + distance)
    }

    @ViewBuilder
    private func priceCapsule(_ price: Double?, subtitle: String = "", onTap: (() -> Void)? = nil) -> some View {
        if let p = price {
            Button(action: { onTap?() }) {
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
                .background(oddsCapsuleColor(p))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: colW)
        }
    }

    var body: some View {
        let ouTotal = (odd.overPoints ?? odd.underPoints).map(formatPoints) ?? ""
        VStack(alignment: .leading, spacing: 4) {
            Text("Best Odds")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                // Away row
                HStack(spacing: 4) {
                    HStack(spacing: 0) {
                        Text("@ ").opacity(0)
                        Text(odd.awayAbbr)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    priceCapsule(odd.mlAwayPrice, subtitle: impliedPct(odd.mlAwayPrice)) {
                        guard let p = odd.mlAwayPrice, let h = odd.mlAwayBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "ML", side: "Away", price: p, points: nil,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr, gameTime: odd.gameTime))
                    }
                    priceCapsule(odd.sprAwayPrice, subtitle: odd.sprAwayPoints.map(formatPoints) ?? "") {
                        guard let p = odd.sprAwayPrice, let h = odd.sprAwayBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "SPR", side: "Away", price: p, points: odd.sprAwayPoints,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr, gameTime: odd.gameTime))
                    }
                    priceCapsule(
                        awayIsFav ? odd.underPrice : odd.overPrice,
                        subtitle: awayIsFav ? "U \(ouTotal)" : "O \(ouTotal)"
                    ) {
                        let price = awayIsFav ? odd.underPrice : odd.overPrice
                        let hash  = awayIsFav ? odd.underBetHash : odd.overBetHash
                        let pts   = odd.overPoints ?? odd.underPoints
                        guard let p = price, let h = hash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "O/U", side: awayIsFav ? "Under" : "Over",
                                                  price: p, points: pts, awayAbbr: odd.awayAbbr,
                                                  homeAbbr: odd.homeAbbr, gameTime: odd.gameTime))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                Divider()

                // Home row
                HStack(spacing: 4) {
                    Text("@ " + odd.homeAbbr)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    priceCapsule(odd.mlHomePrice, subtitle: impliedPct(odd.mlHomePrice)) {
                        guard let p = odd.mlHomePrice, let h = odd.mlHomeBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "ML", side: "Home", price: p, points: nil,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr, gameTime: odd.gameTime))
                    }
                    priceCapsule(odd.sprHomePrice, subtitle: odd.sprHomePoints.map(formatPoints) ?? "") {
                        guard let p = odd.sprHomePrice, let h = odd.sprHomeBetHash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "SPR", side: "Home", price: p, points: odd.sprHomePoints,
                                                  awayAbbr: odd.awayAbbr, homeAbbr: odd.homeAbbr, gameTime: odd.gameTime))
                    }
                    priceCapsule(
                        awayIsFav ? odd.overPrice : odd.underPrice,
                        subtitle: awayIsFav ? "O \(ouTotal)" : "U \(ouTotal)"
                    ) {
                        let price = awayIsFav ? odd.overPrice : odd.underPrice
                        let hash  = awayIsFav ? odd.overBetHash : odd.underBetHash
                        let pts   = odd.overPoints ?? odd.underPoints
                        guard let p = price, let h = hash else { return }
                        onBetSelected(SelectedBet(betHash: h, type: "O/U", side: awayIsFav ? "Over" : "Under",
                                                  price: p, points: pts, awayAbbr: odd.awayAbbr,
                                                  homeAbbr: odd.homeAbbr, gameTime: odd.gameTime))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(theme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - BetConfirmationSheet

private struct BetConfirmationSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var betStore: BetStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let bet: SelectedBet
    let bettorId: Int
    let syndicateId: Int

    @State private var unitsInput: String = ""

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

    private var formattedTime: String {
        guard let raw = bet.gameTime,
              let date = timeInputFormatter.date(from: raw)
        else { return "—" }
        return timeOutputFormatter.string(from: date)
    }

    private var betTypeLabel: String {
        var label = "\(bet.side) \(bet.type)"
        if let pts = bet.points {
            let formatted = pts == pts.rounded() ? "\(Int(pts))" : String(format: "%.1f", pts)
            label += " (\(formatted))"
        }
        return label
    }

    private var computedUnits: Int { Int(unitsInput) ?? 0 }

    private var potentialReturn: String {
        guard computedUnits > 0 else { return "—" }
        return String(format: "%.2f", Double(computedUnits) * bet.price)
    }

    private var impliedPct: String {
        guard bet.price > 0 else { return "—" }
        return "\(Int((1.0 / bet.price * 100.0).rounded()))%"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                Form {
                    Section("Game") {
                        LabeledContent("Match", value: "\(bet.awayAbbr) @ \(bet.homeAbbr)")
                        LabeledContent("Time", value: formattedTime)
                        LabeledContent("Bet Type", value: betTypeLabel)
                        LabeledContent("Odds", value: String(format: "%.2f", bet.price))
                        LabeledContent("Implied Prob", value: impliedPct)
                    }

                    Section("IDs") {
                        LabeledContent("Bettor ID", value: "\(bettorId)")
                        LabeledContent("Syndicate ID", value: "\(syndicateId)")
                        LabeledContent("Bet ID", value: bet.betHash)
                            .font(.caption)
                    }

                    Section("Wager") {
                        HStack {
                            Text("Units")
                            Spacer()
                            TextField("0", text: $unitsInput)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        LabeledContent("Potential Return", value: "\(potentialReturn) units")
                    }

                    Section {
                        Button("Submit Bet") {
                            guard computedUnits > 0 else { return }
                            betStore.place(PlacedBet(
                                id: UUID(),
                                betHash: bet.betHash,
                                type: bet.type,
                                side: bet.side,
                                price: bet.price,
                                points: bet.points,
                                units: computedUnits,
                                awayAbbr: bet.awayAbbr,
                                homeAbbr: bet.homeAbbr,
                                gameTime: bet.gameTime,
                                bettorId: bettorId,
                                syndicateId: syndicateId
                            ))
                            dismiss()
                        }
                        .disabled(computedUnits == 0)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(computedUnits == 0 ? .secondary : theme.accent)
                        .fontWeight(.semibold)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Confirm Bet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
