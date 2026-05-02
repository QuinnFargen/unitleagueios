import Foundation


class LeagueService {
    func fetchLeagues() async throws -> [League] {
        guard let url = URL(string: "\(APIClient.baseURL)/mart/league") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([League].self, from: data)
    }

    func createSyndicate(bettorId: Int, name: String, description: String? = nil, fantasy: Bool = false) async throws -> Syndicate {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/syndicate") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["bettor_id": bettorId, "name": name, "fantasy": fantasy]
        if let desc = description { body["description"] = desc }
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
