import Foundation

class LeagueService {
    static let baseURL = "http://192.168.4.59:8000"

    func fetchLeagues() async throws -> [League] {
        guard let url = URL(string: "\(Self.baseURL)/ball/league") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([League].self, from: data)
    }
}
