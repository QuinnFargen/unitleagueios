import Foundation

class SyndicateService {
    func fetchSyndicate(syndicateId: Int? = nil, bettorId: Int? = nil) async throws -> [Syndicate] {
        var components = URLComponents(string: "\(APIClient.baseURL)/mart/syndicate")!
        var queryItems: [URLQueryItem] = []
        if let syndicateId { queryItems.append(URLQueryItem(name: "syndicate_id", value: "\(syndicateId)")) }
        if let bettorId    { queryItems.append(URLQueryItem(name: "bettor_id",    value: "\(bettorId)")) }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Syndicate].self, from: data)
    }
}
