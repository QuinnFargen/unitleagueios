import Foundation

class OddBestService {
    func fetchOddBest(gameId: Int? = nil, gameDt: String? = nil, leagueId: Int? = nil) async throws -> [OddBest] {
        var components = URLComponents(string: "\(APIClient.baseURL)/mart/odd_best")!
        var queryItems: [URLQueryItem] = []
        if let gameId    { queryItems.append(URLQueryItem(name: "game_id",   value: "\(gameId)")) }
        if let gameDt    { queryItems.append(URLQueryItem(name: "game_dt",   value: gameDt)) }
        if let leagueId  { queryItems.append(URLQueryItem(name: "league_id", value: "\(leagueId)")) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([OddBest].self, from: data)
    }
}
