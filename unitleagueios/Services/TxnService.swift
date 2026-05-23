import Foundation

struct TxnRecord: Codable, Identifiable {
    let id: Int
    let bettorId: Int
    let syndicateId: Int
    let betHash: String?
    let parlayId: Int?
    let unit: Double
    let price: Double
    let won: Bool?
    let canceled: Bool

    enum CodingKeys: String, CodingKey {
        case id          = "txn_id"
        case bettorId    = "bettor_id"
        case syndicateId = "syndicate_id"
        case betHash     = "bet_hash"
        case parlayId    = "parlay_id"
        case unit, price, won, canceled
    }
}

struct TxnService {

    func submitBet(bettorId: Int, syndicateId: Int, betHash: String, unit: Double, price: Double) async throws {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/txn") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "bettor_id": bettorId,
            "syndicate_id": syndicateId,
            "bet_hash": betHash,
            "unit": unit,
            "price": price
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func submitParlay(bettorId: Int, syndicateId: Int, unit: Double,
                      legs: [(betHash: String, price: Double)]) async throws {
        guard let url = URL(string: "\(APIClient.baseURL)/odd/parlay") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let legsArray = legs.map { ["bet_hash": $0.betHash, "price": $0.price] as [String: Any] }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "bettor_id": bettorId,
            "syndicate_id": syndicateId,
            "unit": unit,
            "legs": legsArray
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func fetchActiveBets(bettorId: Int, syndicateId: Int) async throws -> [TxnRecord] {
        var components = URLComponents(string: "\(APIClient.baseURL)/odd/txn")!
        components.queryItems = [
            URLQueryItem(name: "bettor_id",    value: "\(bettorId)"),
            URLQueryItem(name: "syndicate_id", value: "\(syndicateId)")
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode([TxnRecord].self, from: data)
    }
}
