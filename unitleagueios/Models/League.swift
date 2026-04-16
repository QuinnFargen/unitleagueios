import Foundation

struct League: Codable, Identifiable {
    let id: Int
    let abbr: String
    let name: String
    let sport: String
    let weather: String
    let yrOrig: Int
    let yrData: Int?

    enum CodingKeys: String, CodingKey {
        case id = "league_id"
        case abbr, name, sport, weather
        case yrOrig = "yr_orig"
        case yrData = "yr_data"
    }
}
