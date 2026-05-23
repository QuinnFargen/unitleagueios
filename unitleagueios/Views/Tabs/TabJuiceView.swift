import SwiftUI

struct TabJuiceView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId") private var bettorId: Int = 0

    @State private var txnRecords: [TxnRecord] = []
    @State private var syndicates: [Int: Syndicate] = [:]
    @State private var isLoading = false

    private let txnService = TxnService()
    private let syndicateService = SyndicateService()

    private var activeBets: [TxnRecord] {
        txnRecords.filter { !$0.canceled }
    }

    private var syndicateGroups: [(syndicateId: Int, singles: [TxnRecord], parlays: [[TxnRecord]])] {
        let bySyndicate = Dictionary(grouping: activeBets, by: \.syndicateId)
        return bySyndicate.keys.sorted().map { sid in
            let group = bySyndicate[sid] ?? []
            let singles = group.filter { $0.parlayId == nil }
            let parlayMap = Dictionary(grouping: group.filter { $0.parlayId != nil }, by: { $0.parlayId! })
            let parlays = parlayMap.values.map { $0 }
            return (syndicateId: sid, singles: singles, parlays: parlays)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if activeBets.isEmpty {
                    Text("No active bets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            HStack {
                                Text("Active Bets")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                Spacer()
                                Text("\(activeBets.count)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)

                            // Per-syndicate sections
                            ForEach(syndicateGroups, id: \.syndicateId) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    // Syndicate header
                                    let syndicate = syndicates[group.syndicateId]
                                    HStack(spacing: 6) {
                                        Image(systemName: syndicate?.symbol ?? "house.fill")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(ProfileOption.color(for: syndicate?.color ?? ""))
                                        Text(syndicate?.name ?? "Syndicate \(group.syndicateId)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 4)

                                    // Individual bets
                                    ForEach(group.singles) { txn in
                                        BetBannerRow(txn: txn)
                                    }

                                    // Parlay groups
                                    ForEach(group.parlays, id: \.first?.parlayId) { legs in
                                        ParlayCard(legs: legs)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                    .refreshable { await fetchData() }
                }
            }
            .tabToolbar()
            .task { await fetchData() }
        }
    }

    private func fetchData() async {
        guard bettorId != 0 else { return }
        isLoading = txnRecords.isEmpty
        defer { isLoading = false }
        txnRecords = (try? await txnService.fetchActiveBets(bettorId: bettorId)) ?? []
        let ids = Set(txnRecords.map(\.syndicateId))
        for sid in ids where syndicates[sid] == nil {
            if let result = try? await syndicateService.fetchSyndicate(syndicateId: sid, bettorId: nil) {
                syndicates[sid] = result.first
            }
        }
    }
}

// MARK: - BetBannerRow

private struct BetBannerRow: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let txn: TxnRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BetGameBanner(bet: selectedBet(from: txn))
            HStack(spacing: 3) {
                Text(wagerLabel(txn.unit))
                Image(systemName: "nairasign.circle.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - ParlayCard

private struct ParlayCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let legs: [TxnRecord]

    private var combinedOdds: Double {
        legs.map(\.price).reduce(1.0, *)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Parlay header
            HStack {
                Text("Parlay")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 3) {
                    Text(wagerLabel(legs.first?.unit ?? 0))
                    Image(systemName: "nairasign.circle.fill")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", combinedOdds))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.accent)
                    Text("x")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
            }

            Divider()

            // Legs
            ForEach(legs) { leg in
                VStack(alignment: .leading, spacing: 6) {
                    BetGameBanner(bet: selectedBet(from: leg))
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.2f", leg.price))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accent)
                        Text("x")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(theme.divider(colorScheme), lineWidth: 0.5)
        )
    }
}

// MARK: - Helpers

private func selectedBet(from txn: TxnRecord) -> SelectedBet {
    SelectedBet(
        betHash:  txn.betHash ?? "",
        type:     txn.type ?? "BET",
        side:     txn.side ?? "",
        price:    txn.price,
        points:   txn.points,
        awayAbbr: txn.awayAbbr ?? "—",
        homeAbbr: txn.homeAbbr ?? "—",
        gameTime: txn.gameTime,
        gameDate: txn.gameDate
    )
}

private func wagerLabel(_ units: Double) -> String {
    units == 0.5 ? "½" : String(format: "%.4g", units)
}

#Preview {
    TabJuiceView()
        .environmentObject(AppTheme())
}
