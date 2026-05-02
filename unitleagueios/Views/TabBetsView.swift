import SwiftUI

struct TabBetsView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = .now
    @State private var selectedLeagueId: Int? = nil
    @State private var selectedBetType: String = "ALL"
    @State private var odds: [OddBest] = []
    @State private var allOdds: [OddBest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = OddBestService()

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
    private var fetchKey: String { "\(dateKey)-\(selectedLeagueId ?? 0)" }
    private var leaguesWithOdds: Set<Int> { Set(allOdds.map(\.leagueId)) }

    private var filteredOdds: [OddBest] {
        switch selectedBetType {
        case "SPR": return odds.filter { $0.sprAwayPrice != nil && $0.sprHomePrice != nil }
        case "O/U": return odds.filter { $0.overPrice != nil && $0.underPrice != nil }
        default: return odds
        }
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
                                    availabilityTint: leaguesWithOdds.contains(league.id) ? theme.win : theme.loss
                                ) {
                                    selectedLeagueId = (selectedLeagueId == league.id) ? nil : league.id
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Bet type filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["ALL", "ML", "SPR", "O/U"], id: \.self) { betType in
                                FilterChip(
                                    label: betType,
                                    isSelected: selectedBetType == betType
                                ) {
                                    selectedBetType = betType
                                }
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
                                Button("Retry") { Task { await fetchOdds() } }
                                    .buttonStyle(.bordered)
                            }
                            .padding()
                            Spacer()
                        } else if filteredOdds.isEmpty {
                            Spacer()
                            Text("No odds available")
                                .foregroundStyle(.secondary)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredOdds) { odd in
                                        OddBestCard(odd: odd, betType: selectedBetType)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                            }
                        }
                    }
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
        .task(id: fetchKey) { await fetchOdds() }
        .task(id: dateKey) { await fetchAllOdds() }
    }

    private func fetchOdds() async {
        isLoading = true
        errorMessage = nil
        odds = []
        do {
            odds = try await service.fetchOddBest(gameDt: dateKey, leagueId: selectedLeagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchAllOdds() async {
        allOdds = (try? await service.fetchOddBest(gameDt: dateKey, leagueId: nil)) ?? []
    }
}

// MARK: - OddBestCard

private struct OddBestCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let odd: OddBest
    let betType: String

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
                // Header inside VStack so labels align naturally with capsules below
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

                // Away row — invisible "@ " prefix aligns abbr with home row
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
            }
        }
    }

    private struct SingleData {
        let awayPrice: Double?
        let awayBetLabel: String
        let awayMLPct: String
        let homePrice: Double?
        let homeBetLabel: String
        let homeMLPct: String
    }

    private func singleData() -> SingleData {
        switch betType {
        case "ML":
            return SingleData(
                awayPrice: odd.mlAwayPrice, awayBetLabel: "", awayMLPct: impliedPct(odd.mlAwayPrice),
                homePrice: odd.mlHomePrice, homeBetLabel: "", homeMLPct: impliedPct(odd.mlHomePrice)
            )
        case "SPR":
            return SingleData(
                awayPrice: odd.sprAwayPrice,
                awayBetLabel: odd.sprAwayPoints.map(formatPoints) ?? "",
                awayMLPct: impliedPct(odd.mlAwayPrice),
                homePrice: odd.sprHomePrice,
                homeBetLabel: odd.sprHomePoints.map(formatPoints) ?? "",
                homeMLPct: impliedPct(odd.mlHomePrice)
            )
        case "O/U":
            let total = (odd.overPoints ?? odd.underPoints).map(formatPoints) ?? ""
            return SingleData(
                awayPrice: odd.overPrice, awayBetLabel: "O \(total)", awayMLPct: "",
                homePrice: odd.underPrice, homeBetLabel: "U \(total)", homeMLPct: ""
            )
        default:
            return SingleData(awayPrice: nil, awayBetLabel: "", awayMLPct: "",
                              homePrice: nil, homeBetLabel: "", homeMLPct: "")
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

            priceCapsule(d.awayPrice)

            VStack(alignment: .trailing, spacing: 2) {
                if !d.awayBetLabel.isEmpty {
                    Text(d.awayBetLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                }
                if !d.awayMLPct.isEmpty {
                    Text(d.awayMLPct).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 32, alignment: .trailing)

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

            VStack(alignment: .leading, spacing: 2) {
                if !d.homeBetLabel.isEmpty {
                    Text(d.homeBetLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                }
                if !d.homeMLPct.isEmpty {
                    Text(d.homeMLPct).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 32, alignment: .leading)

            priceCapsule(d.homePrice)
        }
    }
}

#Preview {
    TabBetsView()
        .environmentObject(AppTheme())
}
