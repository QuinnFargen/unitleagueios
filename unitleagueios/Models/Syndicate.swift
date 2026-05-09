import Foundation

struct Syndicate: Codable, Identifiable {
    var id: Int { syndicateId }
    let syndicateId: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let maxRunner: Int?
    let createdByBettorId: Int

    enum CodingKeys: String, CodingKey {
        case syndicateId = "syndicate_id"
        case name
        case description
        case isPublic = "is_public"
        case maxRunner = "max_runner"
        case createdByBettorId = "created_by_bettor_id"
    }
}
