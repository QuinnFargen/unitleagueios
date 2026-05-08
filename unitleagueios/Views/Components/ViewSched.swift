import SwiftUI

private enum SchedMode: String, CaseIterable {
    case year = "Year"
    case recent = "Recent"
}

struct ViewSched: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let team: Team
    let league: League

    @State private var selectedMode: SchedMode = .year
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var schedule: [Sched] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var scrollTarget: String? = nil

    private var lastFinalId: String? {
        schedule.first { $0.teamScore != nil && $0.oppScore != nil }?.id
    }

    private let schedService = SchedService()

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        let start = max(league.yrOrig, 2020)
        let end = currentYear + 1
        return Array(start ... end).reversed()
    }

    var body: some View {
        ZStack {
            theme.appBackground(colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                ViewTeamBanner(team: team, league: league)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Mode picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SchedMode.allCases, id: \.self) { mode in
                            FilterChip(label: mode.rawValue, isSelected: selectedMode == mode) {
                                selectedMode = mode
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // Secondary filter row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if selectedMode == .year {
                            ForEach(years, id: \.self) { year in
                                FilterChip(label: String(year), isSelected: selectedYear == year) {
                                    selectedYear = year
                                }
                            }
                        } else {
                            FilterChip(label: "Region", isSelected: false) {}
                            FilterChip(label: "Color", isSelected: false) {}
                            FilterChip(label: "Region", isSelected: false) {}
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .animation(.easeInOut(duration: 0.2), value: selectedMode)

                Divider()
                    .background(theme.divider(colorScheme))

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
                            Button("Retry") { Task { await fetchSchedule() } }
                                .buttonStyle(.bordered)
                        }
                        .padding()
                        Spacer()
                    } else if schedule.isEmpty {
                        Spacer()
                        Text("No schedule available")
                            .foregroundStyle(.secondary)
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(schedule) { entry in
                                        SchedCard(entry: entry, isHighlighted: entry.id == lastFinalId)
                                            .id(entry.id)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                            }
                            .onChange(of: scrollTarget) { _, target in
                                guard let id = target else { return }
                                withAnimation { proxy.scrollTo(id, anchor: .top) }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedYear) { await fetchSchedule() }
    }

    private func fetchSchedule() async {
        isLoading = true
        errorMessage = nil
        schedule = []
        scrollTarget = nil
        do {
            let raw = try await schedService.fetchSchedule(teamId: team.id, yr: selectedYear)
            schedule = raw.sorted { $0.gameNum > $1.gameNum }
            scrollTarget = lastFinalId
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - SchedCard

private struct SchedCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let entry: Sched
    var isHighlighted: Bool = false

    private let dateInputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let dateOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var formattedDate: String {
        guard let raw = entry.gameDate,
              let date = dateInputFormatter.date(from: raw) else { return "TBD" }
        return dateOutputFormatter.string(from: date)
    }

    private var matchup: String {
        entry.home ? "vs \(entry.oppAbbr ?? "TBD")" : "@ \(entry.oppAbbr ?? "TBD")"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(matchup)
                    .font(.headline)
                    .foregroundStyle(entry.teamScore != nil && entry.oppScore != nil
                        ? (entry.won == true ? theme.win : theme.loss)
                        : theme.primaryText(colorScheme))
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let teamScore = entry.teamScore, let oppScore = entry.oppScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(teamScore) – \(oppScore)")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText(colorScheme))
                    if let won = entry.won {
                        Text(won ? "W · FINAL" : "L · FINAL")
                            .font(.caption2)
                            .foregroundStyle(won ? theme.win : theme.loss)
                    }
                }
            } else {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.primaryText(colorScheme).opacity(0.6), lineWidth: 1.5)
                .opacity(isHighlighted ? 1 : 0)
        )
    }
}



#Preview {
    MainTabView()
        .environmentObject(AppTheme())
}
