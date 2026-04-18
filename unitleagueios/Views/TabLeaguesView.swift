import SwiftUI

struct TabLeaguesView: View {
    @AppStorage("userLeagues") private var userLeaguesData: Data = Data()
    @State private var showingJoin = false
    @State private var showingCreate = false
    @State private var leagues: [League] = []

    private let service = LeagueService()

    private var userLeagues: [UserLeague] {
        (try? JSONDecoder().decode([UserLeague].self, from: userLeaguesData)) ?? []
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Leagues")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Spacer().frame(height: 8)

                    LeagueActionButton(title: "Join League", icon: "person.badge.plus", color: .green) {
                        showingJoin = true
                    }

                    LeagueActionButton(title: "Create League", icon: "plus.circle", color: .blue) {
                        showingCreate = true
                    }

                    if !userLeagues.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Leagues")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(userLeagues) { league in
                                UserLeagueCard(userLeague: league)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingJoin) {
            LeagueFormSheet(title: "Join League", confirmLabel: "Join", leagues: leagues) { newLeague in
                append(newLeague)
            }
        }
        .sheet(isPresented: $showingCreate) {
            LeagueFormSheet(title: "Create League", confirmLabel: "Create", leagues: leagues) { newLeague in
                append(newLeague)
            }
        }
        .task { fetchLeagues() }
    }

    private func fetchLeagues() {
        Task {
            leagues = (try? await service.fetchLeagues()) ?? []
        }
    }

    private func append(_ league: UserLeague) {
        var current = userLeagues
        current.append(league)
        userLeaguesData = (try? JSONEncoder().encode(current)) ?? Data()
    }
}

struct UserLeague: Codable, Identifiable {
    let id: UUID
    let leagueId: Int
    let abbr: String
    let sport: String
    let customName: String
}

private struct LeagueActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct UserLeagueCard: View {
    let userLeague: UserLeague

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: sportIcon(for: userLeague.leagueId))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(userLeague.abbr)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(userLeague.customName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct LeagueFormSheet: View {
    let title: String
    let confirmLabel: String
    let leagues: [League]
    let onConfirm: (UserLeague) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedLeagueId: Int?
    @State private var leagueName = ""

    private var selectedLeague: League? {
        leagues.first { $0.id == selectedLeagueId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    Section("Select League") {
                        if leagues.isEmpty {
                            HStack(spacing: 10) {
                                ProgressView().tint(.white)
                                Text("Loading leagues...")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(leagues) { league in
                                LeagueOptionRow(
                                    league: league,
                                    isSelected: selectedLeagueId == league.id
                                ) {
                                    selectedLeagueId = league.id
                                }
                            }
                        }
                    }

                    Section("League Name") {
                        TextField("Enter a name", text: $leagueName)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel) {
                        if let league = selectedLeague {
                            onConfirm(UserLeague(
                                id: UUID(),
                                leagueId: league.id,
                                abbr: league.abbr,
                                sport: league.sport,
                                customName: leagueName.trimmingCharacters(in: .whitespaces)
                            ))
                        }
                        dismiss()
                    }
                    .disabled(selectedLeagueId == nil || leagueName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(.green)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct LeagueOptionRow: View {
    let league: League
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: sportIcon(for: league.id))
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(league.abbr)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(league.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private func sportIcon(for leagueId: Int) -> String {
    switch leagueId {
    case 1: return "basketball"
    case 2: return "american.football.professional"
    case 3: return "hockey.puck"
    case 4: return "baseball"
    case 5: return "american.football"
    case 6: return "basketball.fill"
    default: return "sportscourt"
    }
}

#Preview {
    TabLeaguesView()
}
