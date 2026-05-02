import Foundation

struct OddSyndicate: Codable {
    let syndicateId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case syndicateId = "syndicate_id"
        case name
    }
}

struct OddRunner: Codable {
    let runnerId: Int
    let bettorId: Int
    let syndicateId: Int
    let role: String

    enum CodingKeys: String, CodingKey {
        case runnerId    = "runner_id"
        case bettorId    = "bettor_id"
        case syndicateId = "syndicate_id"
        case role
    }
}

class LeagueService {
    func fetchLeagues() async throws -> [League] {
        guard let url = URL(string: "\(APIClient.baseURL)/mart/league") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([League].self, from: data)
    }

    func createSyndicate(bettorId: Int, name: String, description: String? = nil, fantasy: Bool = false) async throws -> OddSyndicate {
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
            let syndicate: OddSyndicate
            let runner: OddRunner
        }
        return try JSONDecoder().decode(CreateSyndicateResponse.self, from: data).syndicate
    }

    func joinSyndicate(bettorId: Int, syndicateId: Int, password: String? = nil) async throws -> OddRunner {
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
        return try JSONDecoder().decode(OddRunner.self, from: data)
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
