import SwiftUI

struct ViewGameDetail: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme

    let gameId: Int
    let home: String
    let away: String
    let homeTeamId: Int
    let awayTeamId: Int
    let leagueId: Int

    @State private var odd: OddBest?
    @State private var homeTeam: Team?
    @State private var awayTeam: Team?
    @State private var league: League?

    private let oddService = OddBestService()
    private let teamService = TeamService()
    private let leagueService = LeagueService()

    var body: some View {
        ZStack {
            theme.appBackground(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let odd {
                        GameOddsCard(odd: odd)
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
    let odd: OddBest

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
    private func priceCapsule(_ price: Double?, subtitle: String = "") -> some View {
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
            .background(oddsCapsuleColor(p))
            .clipShape(Capsule())
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

                    priceCapsule(odd.mlAwayPrice, subtitle: impliedPct(odd.mlAwayPrice))
                    priceCapsule(odd.sprAwayPrice, subtitle: odd.sprAwayPoints.map(formatPoints) ?? "")
                    priceCapsule(
                        awayIsFav ? odd.underPrice : odd.overPrice,
                        subtitle: awayIsFav ? "U \(ouTotal)" : "O \(ouTotal)"
                    )
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

                    priceCapsule(odd.mlHomePrice, subtitle: impliedPct(odd.mlHomePrice))
                    priceCapsule(odd.sprHomePrice, subtitle: odd.sprHomePoints.map(formatPoints) ?? "")
                    priceCapsule(
                        awayIsFav ? odd.overPrice : odd.underPrice,
                        subtitle: awayIsFav ? "O \(ouTotal)" : "U \(ouTotal)"
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(theme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
