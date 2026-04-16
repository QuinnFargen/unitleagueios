import SwiftUI

struct HomeView: View {
    @State private var leagues: [League] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let service = LeagueService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") { fetchLeagues() }
                                .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(leagues) { league in
                                    NavigationLink {
                                        TeamListView(league: league)
                                    } label: {
                                        LeagueCard(league: league)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Unit League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { fetchLeagues() }
    }

    private func fetchLeagues() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                leagues = try await service.fetchLeagues()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct LeagueCard: View {
    let league: League

    var sportIcon: String {
        switch league.sport {
        case "BASKET": return "basketball"
        case "FOOT":   return "football"
        case "PUCK":   return "hockey.puck"
        case "BASE":   return "baseball"
        default:       return "sportscourt"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: sportIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(league.abbr)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(league.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView()
}
