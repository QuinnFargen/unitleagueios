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
        let colW: CGFloat = 52
        let awayIsFav = (odd.sprAwayPoints ?? 1) < 0
        let spreadPts = awayIsFav ? odd.sprAwayPoints : odd.sprHomePoints
        let ouTotal = odd.overPoints ?? odd.underPoints
        let awayAnnotation: String = {
            if awayIsFav, let pts = spreadPts { return " (\(formatPoints(pts)))" }
            if !awayIsFav, let total = ouTotal { return " (\(formatPoints(total)))" }
            return ""
        }()
        let homeAnnotation: String = {
            if !awayIsFav, let pts = spreadPts { return " (\(formatPoints(pts)))" }
            if awayIsFav, let total = ouTotal { return " (\(formatPoints(total)))" }
            return ""
        }()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                if let time = formattedTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                Spacer()
                ForEach(["ML", "SPR", "O/U"], id: \.self) { h in
                    Text(h)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: colW, alignment: .center)
                }
            }

            HStack(spacing: 0) {
                Text(odd.awayAbbr + awayAnnotation)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(odd.mlAwayPrice.map(formatPrice) ?? "—")
                    .frame(width: colW, alignment: .center)
                Text(odd.sprAwayPrice.map(formatPrice) ?? "—")
                    .frame(width: colW, alignment: .center)
                Text((awayIsFav ? odd.underPrice : odd.overPrice).map(formatPrice) ?? "—")
                    .frame(width: colW, alignment: .center)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.primaryText(colorScheme))

            HStack(spacing: 0) {
                Text("@ " + odd.homeAbbr + homeAnnotation)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(odd.mlHomePrice.map(formatPrice) ?? "—")
                    .frame(width: colW, alignment: .center)
                Text(odd.sprHomePrice.map(formatPrice) ?? "—")
                    .frame(width: colW, alignment: .center)
                Text((!awayIsFav ? odd.underPrice : odd.overPrice).map(formatPrice) ?? "—")
                    .frame(width: colW, alignment: .center)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.primaryText(colorScheme))
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
