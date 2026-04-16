import SwiftUI

struct TeamScheduleView: View {
    let team: Team
    let league: League

    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now) - 1
    @State private var schedule: [Sched] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let schedService = SchedService()

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        let start = max(league.yrOrig, 2020)
        let end = currentYear + 1
        return Array(start ... end)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Year capsule row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(years, id: \.self) { year in
                            FilterChip(
                                label: "\(year)",
                                isSelected: selectedYear == year
                            ) {
                                selectedYear = year
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()
                    .background(Color.white.opacity(0.1))

                // Content
                Group {
                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
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
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(schedule) { entry in
                                    SchedCard(entry: entry)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 12)
                        }
                    }
                }
            }
        }
        .navigationTitle(team.abbr)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task(id: selectedYear) { await fetchSchedule() }
    }

    private func fetchSchedule() async {
        isLoading = true
        errorMessage = nil
        schedule = []
        do {
            let raw = try await schedService.fetchSchedule(teamId: team.id, yr: selectedYear)
            schedule = raw.sorted { $0.gameNum < $1.gameNum }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - SchedCard

private struct SchedCard: View {
    let entry: Sched

    private let dateInputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private let dateOutputFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
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
                    .foregroundStyle(.white)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let teamScore = entry.teamScore, let oppScore = entry.oppScore {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(teamScore) – \(oppScore)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let won = entry.won {
                        Text(won ? "W · FINAL" : "L · FINAL")
                            .font(.caption2)
                            .foregroundStyle(won ? .green : .red)
                    }
                }
            } else {
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
