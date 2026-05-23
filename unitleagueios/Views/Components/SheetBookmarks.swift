import SwiftUI

struct SheetBookmarks: View {
    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var betStore: BetStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("bettorId")            private var bettorId: Int    = 0
    @AppStorage("selectedSyndicateId") private var syndicateId: Int = 0

    @State private var selectedBookmark: PlacedBet?
    @State private var showingParlay = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                if betStore.bookmarks.isEmpty {
                    Text("No bookmarks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(betStore.bookmarks) { bookmark in
                                Button {
                                    selectedBookmark = bookmark
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(bookmark.awayAbbr) @ \(bookmark.homeAbbr)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(theme.primaryText(colorScheme))
                                            Text(bookmark.displayLabel)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text(String(format: "%.2f", bookmark.price))
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(theme.accent)
                                            Text("x")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(theme.accent)
                                        }
                                        Button {
                                            betStore.removeBookmark(bookmark)
                                        } label: {
                                            Image(systemName: "bookmark.slash")
                                                .foregroundStyle(theme.error)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding()
                                    .background(theme.cardBackground(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if betStore.bookmarks.count >= 2 {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Parlay") { showingParlay = true }
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .sheet(item: $selectedBookmark) { bookmark in
                SheetConfirmBet(
                    bet: SelectedBet(placedBet: bookmark),
                    bettorId: bettorId,
                    syndicateId: syndicateId
                )
            }
            .sheet(isPresented: $showingParlay) {
                SheetConfirmParlay(currentBet: nil, bettorId: bettorId, syndicateId: syndicateId)
            }
        }
    }
}
