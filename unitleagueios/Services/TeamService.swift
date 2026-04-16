import Foundation

class TeamService {
    func fetchTeams(leagueId: Int) async throws -> [Team] {
        guard let url = URL(string: "\(APIClient.baseURL)/ball/team?league_id=\(leagueId)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Team].self, from: data)
    }
}
