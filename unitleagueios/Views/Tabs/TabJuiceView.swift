import SwiftUI

struct TabJuiceView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId") private var bettorId: Int = 0

    @State private var txnRecords: [TxnRecord] = []
    @State private var completedRecords: [TxnRecord] = []
    @State private var syndicates: [Int: Syndicate] = [:]
    @State private var isLoading = false
    @State private var segment: BetSegment = .active

    private let txnService = TxnService()
    private let syndicateService = SyndicateService()

    private enum BetSegment: String, CaseIterable {
        case active = "Active"
        case history = "History"
    }

    private var activeBets: [TxnRecord] {
        txnRecords.filter { !$0.canceled }
    }

    private var displayBets: [TxnRecord] {
        segment == .active ? activeBets : completedRecords
    }

    private var syndicateGroups: [(syndicateId: Int, singles: [TxnRecord], parlays: [[TxnRecord]])] {
        let bySyndicate = Dictionary(grouping: displayBets, by: \.syndicateId)
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
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            Picker("", selection: $segment) {
                                ForEach(BetSegment.allCases, id: \.self) { seg in
                                    Text(seg.rawValue).tag(seg)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)

                            if displayBets.isEmpty {
                                Text(segment == .active ? "No active bets" : "No bet history")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 40)
                            } else {
                                HStack {
                                    Text(segment == .active ? "Active Bets" : "Bet History")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(theme.primaryText(colorScheme))
                                    Spacer()
                                    Text("\(displayBets.count)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)

                                ForEach(syndicateGroups, id: \.syndicateId) { group in
                                    VStack(alignment: .leading, spacing: 10) {
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

                                        ForEach(group.singles) { txn in
                                            BetBannerRow(
                                                txn: txn,
                                                onCancel: segment == .active ? { cancelBet(txn) } : nil
                                            )
                                        }

                                        ForEach(group.parlays, id: \.first?.parlayId) { legs in
                                            ParlayCard(
                                                legs: legs,
                                                onCancel: segment == .active ? { cancelParlay(legs) } : nil
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
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

    private func cancelBet(_ txn: TxnRecord) {
        Task {
            try? await txnService.cancelTxn(txnId: txn.id)
            txnRecords.removeAll { $0.id == txn.id }
        }
    }

    private func cancelParlay(_ legs: [TxnRecord]) {
        guard let txnId = legs.first?.id else { return }
        let parlayId = legs.first?.parlayId
        Task {
            try? await txnService.cancelTxn(txnId: txnId)
            txnRecords.removeAll { $0.parlayId == parlayId }
        }
    }

    private func fetchData() async {
        guard bettorId != 0 else { return }
        isLoading = txnRecords.isEmpty && completedRecords.isEmpty
        defer { isLoading = false }
        async let activeFetch = txnService.fetchActiveBets(bettorId: bettorId)
        async let completedFetch = txnService.fetchCompletedBets(bettorId: bettorId)
        txnRecords = (try? await activeFetch) ?? []
        completedRecords = (try? await completedFetch) ?? []
        let ids = Set((txnRecords + completedRecords).map(\.syndicateId))
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
    var onCancel: (() -> Void)? = nil

    @State private var showCancelConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BetGameBanner(bet: selectedBet(from: txn))
            HStack(spacing: 3) {
                if let won = txn.won {
                    Circle()
                        .fill(won ? theme.win : theme.loss)
                        .frame(width: 7, height: 7)
                }
                Text(wagerLabel(txn.unit))
                Image(systemName: "nairasign.circle.fill")
                Spacer()
                if onCancel != nil {
                    Button { showCancelConfirm = true } label: {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Cancel this bet?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                        Button("Cancel Bet", role: .destructive) { onCancel?() }
                    }
                }
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
    var onCancel: (() -> Void)? = nil

    @State private var showCancelConfirm = false

    private var combinedOdds: Double {
        legs.map(\.price).reduce(1.0, *)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Parlay")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let won = legs.first?.won {
                    Circle()
                        .fill(won ? theme.win : theme.loss)
                        .frame(width: 7, height: 7)
                }
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
                if onCancel != nil {
                    Button { showCancelConfirm = true } label: {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Cancel this parlay?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                        Button("Cancel Parlay", role: .destructive) { onCancel?() }
                    }
                }
            }

            Divider()

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
