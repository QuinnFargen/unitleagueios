//
//  BetConfirmationSheet.swift
//  unitleagueios
//
//  Created by Quinn Fargen on 5/23/26.
//
//  Used in SheetConfirmBet & TabProfileView

import SwiftUI

struct SheetConfirmParlay: View {
    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var betStore: BetStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let currentBet: SelectedBet?
    let bettorId: Int
    let syndicateId: Int
    var onSubmit: (() -> Void)? = nil

    // Stable snapshot of legs (UUID-stable for selection tracking)
    @State private var allLegs: [PlacedBet] = []
    @State private var selectedIds: Set<UUID> = []
    @State private var wagerUnits: Double = 1.0

    private let txnService = TxnService()

    private var selectedLegs: [PlacedBet] {
        allLegs.filter { selectedIds.contains($0.id) }
    }

    private var combinedOdds: Double {
        selectedLegs.isEmpty ? 1.0 : selectedLegs.map(\.price).reduce(1.0, *)
    }

    private var potentialReturn: Double { wagerUnits * combinedOdds }

    private func wagerLabel(_ units: Double) -> String {
        units == 0.5 ? "½" : String(format: "%.4g", units)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Leg list with selection toggles
                        VStack(spacing: 10) {
                            ForEach(allLegs) { leg in
                                let isCurrentBet = leg.betHash == currentBet?.betHash
                                let isSelected   = selectedIds.contains(leg.id)

                                Button {
                                    if isSelected { selectedIds.remove(leg.id) }
                                    else          { selectedIds.insert(leg.id) }
                                } label: {
                                    HStack(spacing: 12) {
                                        BetGameBanner(bet: SelectedBet(placedBet: leg))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .strokeBorder(
                                                        isCurrentBet ? theme.accent.opacity(0.6) : .clear,
                                                        lineWidth: 1.5
                                                    )
                                            )

                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundStyle(isSelected ? theme.accent : Color.secondary.opacity(0.4))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Summary banner
                        HStack(spacing: 0) {
                            summaryCell("Risked") {
                                HStack(spacing: 3) {
                                    Text(wagerLabel(wagerUnits))
                                    Image(systemName: "nairasign.circle.fill")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.primaryText(colorScheme))
                            }
                            Divider().frame(height: 36)
                            summaryCell("Price") {
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(String(format: "%.2f", combinedOdds))
                                    Text("x").font(.caption.weight(.semibold))
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.accent)
                            }
                            Divider().frame(height: 36)
                            summaryCell("Return") {
                                HStack(spacing: 3) {
                                    Text(wagerLabel(potentialReturn))
                                    Image(systemName: "nairasign.circle.fill")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.primaryText(colorScheme))
                            }
                        }
                        .padding(.vertical, 14)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Wager stepper
                        HStack(spacing: 0) {
                            Button {
                                wagerUnits = max(0.5, wagerUnits - 0.5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(wagerUnits <= 0.5 ? theme.loss.opacity(0.3) : theme.loss)
                            }
                            .buttonStyle(.plain)
                            .disabled(wagerUnits <= 0.5)

                            Spacer()

                            VStack(spacing: 2) {
                                Text(wagerLabel(wagerUnits))
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                HStack(spacing: 3) {
                                    Text("Units")
                                    Image(systemName: "nairasign.circle.fill")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                wagerUnits += 0.5
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(theme.win)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Submit Parlay
                        Button {
                            let legs = selectedLegs.map { (betHash: $0.betHash, price: $0.price) }
                            let b = bettorId, s = syndicateId, u = wagerUnits
                            let gameDt = selectedLegs.compactMap(\.gameDate).sorted().first
                            Task { try? await txnService.submitParlay(bettorId: b, syndicateId: s, unit: u, legs: legs, gameDt: gameDt) }
                            betStore.clearBookmarks()
                            dismiss()
                            onSubmit?()
                        } label: {
                            Text("Submit Parlay")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(selectedLegs.count >= 2 ? theme.accent : theme.accent.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.accent.opacity(selectedLegs.count >= 2 ? 0.12 : 0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(selectedLegs.count < 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Confirm Parlay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                var legs = betStore.bookmarks
                if let cb = currentBet {
                    legs.append(PlacedBet(from: cb, units: 0, bettorId: bettorId, syndicateId: syndicateId))
                }
                allLegs = legs
                selectedIds = Set(legs.map(\.id))
            }
        }
    }

    @ViewBuilder
    private func summaryCell(_ label: String, @ViewBuilder value: () -> some View) -> some View {
        VStack(spacing: 4) {
            value()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
