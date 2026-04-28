import Foundation

class BettorService {
    func createBettor(appleSub: String, appleEmail: String?, appleName: String?) async throws -> Bettor {
        guard let url = URL(string: "\(APIClient.baseURL)/mart/bettor") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["apple_sub": appleSub]
        if let email = appleEmail { body["apple_email"] = email }
        if let name = appleName   { body["apple_name"] = name }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Bettor.self, from: data)
    }
}
