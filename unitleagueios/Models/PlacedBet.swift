import Foundation

struct PlacedBet: Codable, Identifiable {
    let id: UUID
    let betHash: String
    let type: String        // "ML", "SPR", "O/U"
    let side: String        // "Away" or "Home"
    let price: Double
    let points: Double?     // spread value or O/U total; nil for ML
    let units: Double
    let awayAbbr: String
    let homeAbbr: String
    let gameTime: String?   // raw "HH:mm:ss" from API
    let gameDate: String?   // raw "yyyy-MM-dd" from API
    let bettorId: Int
    let syndicateId: Int

    init(id: UUID = UUID(), betHash: String, type: String, side: String, price: Double,
         points: Double?, units: Double, awayAbbr: String, homeAbbr: String,
         gameTime: String?, gameDate: String?, bettorId: Int, syndicateId: Int) {
        self.id          = id
        self.betHash     = betHash
        self.type        = type
        self.side        = side
        self.price       = price
        self.points      = points
        self.units       = units
        self.awayAbbr    = awayAbbr
        self.homeAbbr    = homeAbbr
        self.gameTime    = gameTime
        self.gameDate    = gameDate
        self.bettorId    = bettorId
        self.syndicateId = syndicateId
    }

    var displayLabel: String {
        var label = "\(side) \(type)"
        if let pts = points {
            let formatted = pts == pts.rounded() ? "\(Int(pts))" : String(format: "%.1f", pts)
            label += " (\(formatted))"
        }
        return label
    }
}

extension PlacedBet {
    init(from selected: SelectedBet, units: Double, bettorId: Int, syndicateId: Int) {
        self.init(
            betHash:     selected.betHash,
            type:        selected.type,
            side:        selected.side,
            price:       selected.price,
            points:      selected.points,
            units:       units,
            awayAbbr:    selected.awayAbbr,
            homeAbbr:    selected.homeAbbr,
            gameTime:    selected.gameTime,
            gameDate:    selected.gameDate,
            bettorId:    bettorId,
            syndicateId: syndicateId
        )
    }
}
