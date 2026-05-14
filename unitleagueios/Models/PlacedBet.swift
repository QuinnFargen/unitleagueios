import Foundation

struct PlacedBet: Codable, Identifiable {
    let id: UUID
    let betHash: String
    let type: String        // "ML", "SPR", "O/U"
    let side: String        // "Away" or "Home"
    let price: Double
    let points: Double?     // spread value or O/U total; nil for ML
    let units: Int
    let awayAbbr: String
    let homeAbbr: String
    let gameTime: String?   // raw "HH:mm:ss" from API
    let bettorId: Int
    let syndicateId: Int
}
