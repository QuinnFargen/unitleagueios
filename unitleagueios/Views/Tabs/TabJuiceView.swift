import SwiftUI

struct TabJuiceView: View {
    @EnvironmentObject private var theme: AppTheme
    @EnvironmentObject private var betStore: BetStore
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId")            private var bettorId: Int         = 0
    @AppStorage("selectedSyndicateId") private var syndicateId: Int      = 0

    @State private var isLoading = false

    private let timeInputFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    private let timeOutputFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func formattedTime(_ raw: String?) -> String {
        guard let raw, let date = timeInputFmt.date(from: raw) else { return "—" }
        return timeOutputFmt.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if betStore.bets.isEmpty {
                    Text("No active bets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    List(betStore.bets) { bet in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(bet.awayAbbr) @ \(bet.homeAbbr)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                Text(bet.displayLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formattedTime(bet.gameTime))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 3) {
                                    Text(String(format: "%.4g", bet.units))
                                    Image(systemName: "nairasign.circle.fill")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.primaryText(colorScheme))
                                Text(String(format: "@ %.2f", bet.price))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .tabToolbar()
        }
    }
}

#Preview {
    TabJuiceView()
        .environmentObject(AppTheme())
        .environmentObject(BetStore())
}
