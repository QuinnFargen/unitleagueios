import SwiftUI

struct TabBetsView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDate: Date = .now
    @State private var selectedLeagueId: Int? = nil
    @State private var selectedBetType: String = "ALL"
    @State private var odds: [OddBest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDatePicker = false

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

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var prevDayNumber: Int {
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        return Calendar.current.component(.day, from: prev)
    }

    private var nextDayNumber: Int {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        return Calendar.current.component(.day, from: next)
    }

    private var fetchKey: String { "\(dateFormatter.string(from: selectedDate))-\(selectedLeagueId ?? 0)" }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date navigation
                    HStack(spacing: 12) {
                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.title3.weight(.semibold))
                                Image(systemName: "\(prevDayNumber).calendar")
                                    .font(.title3.weight(.semibold))
                            }
                            .foregroundStyle(theme.primaryText(colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(Capsule())

                        Button {
                            showDatePicker = true
                        } label: {
                            Text(displayFormatter.string(from: selectedDate))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.primaryText(colorScheme))
                        }
                        .sheet(isPresented: $showDatePicker) {
                            BetsDatePickerSheet(selectedDate: $selectedDate)
                        }

                        Button {
                            selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        } label: {
                            HStack {
                                Image(systemName: "\(nextDayNumber).calendar")
                                    .font(.title3.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.title3.weight(.semibold))
                            }
                            .foregroundStyle(theme.primaryText(colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(Capsule())

                        Button("Today") { selectedDate = .now }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.primaryText(colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.cardBackground(colorScheme))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    // League filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(leagues, id: \.label) { league in
                                FilterChip(
                                    label: league.label,
                                    isSelected: selectedLeagueId == league.id
                                ) {
                                    selectedLeagueId = (selectedLeagueId == league.id) ? nil : league.id
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["ML", "SPR", "O/U", "ALL"], id: \.self) { betType in
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
                        } else if odds.isEmpty {
                            Spacer()
                            Text("No odds available")
                                .foregroundStyle(.secondary)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(odds) { odd in
                                        OddBestCard(odd: odd)
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
    }

    private func fetchOdds() async {
        isLoading = true
        errorMessage = nil
        odds = []
        do {
            odds = try await service.fetchOddBest(gameDt: dateFormatter.string(from: selectedDate), leagueId: selectedLeagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - OddBestCard

private struct OddBestCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let odd: OddBest

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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Game header
            HStack {
                Text("\(odd.awayAbbr) @ \(odd.homeAbbr)")
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))
                Spacer()
                if let time = formattedTime {
                    Text(time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if odd.hasActiveBets {
                Divider().background(theme.divider(colorScheme))

                // Moneyline
                if odd.mlHomeBetHash != nil || odd.mlAwayBetHash != nil {
                    OddsRow(
                        label: "ML",
                        awayValue: odd.mlAwayPrice.map(formatPrice),
                        homeValue: odd.mlHomePrice.map(formatPrice),
                        awayPoints: nil,
                        homePoints: nil,
                        bookmaker: odd.mlHomeBookmaker ?? odd.mlAwayBookmaker,
                        theme: theme,
                        colorScheme: colorScheme
                    )
                }

                // Spread
                if odd.sprHomeBetHash != nil || odd.sprAwayBetHash != nil {
                    OddsRow(
                        label: "SPR",
                        awayValue: odd.sprAwayPrice.map(formatPrice),
                        homeValue: odd.sprHomePrice.map(formatPrice),
                        awayPoints: odd.sprAwayPoints.map(formatPoints),
                        homePoints: odd.sprHomePoints.map(formatPoints),
                        bookmaker: odd.sprHomeBookmaker ?? odd.sprAwayBookmaker,
                        theme: theme,
                        colorScheme: colorScheme
                    )
                }

                // Over/Under
                if odd.overBetHash != nil || odd.underBetHash != nil {
                    OddsRow(
                        label: "O/U",
                        awayValue: odd.overPrice.map(formatPrice),
                        homeValue: odd.underPrice.map(formatPrice),
                        awayPoints: odd.overPoints.map { "O \(formatPoints($0))" },
                        homePoints: odd.underPoints.map { "U \(formatPoints($0))" },
                        bookmaker: odd.overBookmaker ?? odd.underBookmaker,
                        theme: theme,
                        colorScheme: colorScheme
                    )
                }
            } else {
                Text("No odds available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func formatPrice(_ price: Double) -> String {
        String(format: "%.2f", price)
    }

    private func formatPoints(_ points: Double) -> String {
        points == points.rounded() ? "\(Int(points))" : String(format: "%.1f", points)
    }
}

// MARK: - OddsRow

private struct OddsRow: View {
    let label: String
    let awayValue: String?
    let homeValue: String?
    let awayPoints: String?
    let homePoints: String?
    let bookmaker: String?
    let theme: AppTheme
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    if let pts = awayPoints {
                        Text(pts)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(awayValue ?? "—")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.primaryText(colorScheme))
                }
                Spacer()
                if let book = bookmaker {
                    Text(book)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    if let pts = homePoints {
                        Text(pts)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(homeValue ?? "—")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.primaryText(colorScheme))
                }
            }
        }
    }
}

// MARK: - DatePickerSheet

private struct BetsDatePickerSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(theme.accent)
                    .padding(.horizontal)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TabBetsView()
        .environmentObject(AppTheme())
}
