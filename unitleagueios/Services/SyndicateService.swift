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

    func createSyndicate(bettorId: Int, name: String, description: String? = nil, isPublic: Bool = false, password: String? = nil, maxRunner: Int? = nil) async throws -> Syndicate {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/syndicate") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["bettor_id": bettorId, "name": name, "is_public": isPublic]
        if let desc = description { body["description"] = desc }
        if let pw = password { body["password"] = pw }
        if let max = maxRunner { body["max_runner"] = max }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        struct CreateSyndicateResponse: Codable {
            let syndicate: Syndicate
            let runner: Runner
        }
        return try JSONDecoder().decode(CreateSyndicateResponse.self, from: data).syndicate
    }

    func joinSyndicate(bettorId: Int, syndicateId: Int, password: String? = nil) async throws -> Runner {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/syndicate/\(syndicateId)/join") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["bettor_id": bettorId]
        if let pw = password { body["password"] = pw }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 409 {
            throw SyndicateError.alreadyMember
        }
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw SyndicateError.notFound
        }
        return try JSONDecoder().decode(Runner.self, from: data)
    }
}

enum SyndicateError: LocalizedError {
    case alreadyMember
    case notFound

    var errorDescription: String? {
        switch self {
        case .alreadyMember: return "You're already a member of this syndicate."
        case .notFound:      return "Syndicate not found. Check the ID and try again."
        }
    }
}
