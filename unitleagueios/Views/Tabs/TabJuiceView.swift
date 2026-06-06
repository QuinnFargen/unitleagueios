import SwiftUI

struct TabJuiceView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId") private var bettorId: Int = 0

    @State private var txnRecords: [Txn] = []
    @State private var completedRecords: [Txn] = []
    @State private var syndicates: [Int: Syndicate] = [:]
    @State private var isLoading = false
    @State private var segment: BetSegment = .active

    private let txnService = TxnService()
    private let syndicateService = SyndicateService()

    private enum BetSegment: String, CaseIterable {
        case active = "Active"
        case history = "History"
    }

    private var activeBets: [Txn] {
        txnRecords.filter { $0.canceled != true }
    }

    private var displayBets: [Txn] {
        segment == .active ? activeBets : completedRecords
    }

    private var syndicateGroups: [(syndicateId: Int, singles: [Txn], parlays: [[Txn]])] {
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
                                            CardPlacedBet(
                                                txn: txn,
                                                onCancel: segment == .active ? { cancelBet(txn) } : nil
                                            )
                                        }

                                        ForEach(group.parlays, id: \.first?.parlayId) { legs in
                                            CardPlacedParlay(
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

    private func cancelBet(_ txn: Txn) {
        Task {
            try? await txnService.cancelTxn(txnId: txn.txnId)
            txnRecords.removeAll { $0.txnId == txn.txnId }
        }
    }

    private func cancelParlay(_ legs: [Txn]) {
        guard let txnId = legs.first?.txnId, let parlayId = legs.first?.parlayId else { return }
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

#Preview {
    TabJuiceView()
        .environmentObject(AppTheme())
}
