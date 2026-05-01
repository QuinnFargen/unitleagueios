import Foundation

struct OddLeague: Codable {
    let leagueId: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case leagueId = "league_id"
        case name
    }
}

struct OddBbl: Codable {
    let bblId: Int
    let bettorId: Int
    let leagueId: Int
    let role: String

    enum CodingKeys: String, CodingKey {
        case bblId = "bbl_id"
        case bettorId = "bettor_id"
        case leagueId = "league_id"
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

    func createLeague(bettorId: Int, name: String, description: String? = nil, fantasy: Bool = false) async throws -> OddLeague {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/league") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["bettor_id": bettorId, "name": name, "fantasy": fantasy]
        if let desc = description { body["description"] = desc }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        struct CreateLeagueResponse: Codable {
            let league: OddLeague
            let membership: OddBbl
        }
        return try JSONDecoder().decode(CreateLeagueResponse.self, from: data).league
    }

    func joinLeague(bettorId: Int, oddLeagueId: Int) async throws -> OddBbl {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/league/\(oddLeagueId)/join") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONSerialization.data(withJSONObject: ["bettor_id": bettorId])

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode == 409 {
            throw LeagueError.alreadyMember
        }
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw LeagueError.notFound
        }
        return try JSONDecoder().decode(OddBbl.self, from: data)
    }
}

enum LeagueError: LocalizedError {
    case alreadyMember
    case notFound

    var errorDescription: String? {
        switch self {
        case .alreadyMember: return "You're already a member of this league."
        case .notFound:      return "League not found. Check the ID and try again."
        }
    }
}
