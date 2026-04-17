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

    private var teamColor: Color {
        switch team.color ?? "" {
        case "Blue":         return Color(red: 0.10, green: 0.25, blue: 0.80)
        case "Red":          return .red
        case "Green":        return .green
        case "Orange":       return .orange
        case "Purple":       return .purple
        case "Yellow":       return .yellow
        case "White":        return .white
        case "Black":        return Color(white: 0.15)
        case "Brown":        return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "Gray", "Grey": return .gray
        case "Gold":         return Color(red: 1.0, green: 0.75, blue: 0.0)
        case "Crimson":      return Color(red: 0.70, green: 0.07, blue: 0.07)
        case "Navy":         return Color(red: 0.0, green: 0.0, blue: 0.50)
        default:             return .gray
        }
    }

    private var sportIcon: String {
        switch league.id {
        case 1:  return "basketball"
        case 2:  return "american.football.professional"
        case 3:  return "hockey.puck"
        case 4:  return "baseball"
        case 5:  return "american.football"
        case 6:  return "basketball.fill"
        default: return "sportscourt"
        }
    }

    private var categoryIcon: String {
        switch team.category ?? "" {
        case "Person":  return "person"
        case "Animal":  return "pawprint"
        case "Bird":    return "bird"
        case "Cat":     return "cat"
        case "Dog":     return "dog"
        case "Color":   return "paintpalette"
        case "Imaginary":   return "questionmark"
        default:        return "questionmark"
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Team header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [Color.black, teamColor.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)

                    HStack(alignment: .center, spacing: 14) {
                        Image(systemName: sportIcon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(team.abbr)
                                    .font(.title2).bold()
                                    .foregroundStyle(.white)
                                if let mascot = team.mascot {
                                    Text(mascot)
                                        .font(.caption)
                                        .foregroundStyle(.background)
                                }
                            }
                            
                            TeamMetaRow(team: team, categoryIcon: categoryIcon)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 14)
                }

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
        .navigationTitle(team.name)
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

// MARK: - TeamMetaRow

private struct TeamMetaRow: View {
    let team: Team
    let categoryIcon: String

    var body: some View {
        let confDiv = [team.conf, team.div].compactMap { $0 }.joined(separator: " · ")

        HStack(spacing: 6) {
            if !confDiv.isEmpty {
                Text(confDiv)
            }
            if let region = team.region {
                if !confDiv.isEmpty { Text("·").foregroundStyle(.tertiary) }
                Text(region)
            }
            if let cat = team.category {
                if team.conf != nil || team.region != nil { Text("·").foregroundStyle(.tertiary) }
                Image( systemName: categoryIcon)
            }
        }
        .font(.caption)
        .foregroundStyle(.background)
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



#Preview {
    MainTabView()
}
