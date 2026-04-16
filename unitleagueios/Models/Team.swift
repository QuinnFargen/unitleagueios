import Foundation

struct Team: Codable, Identifiable {
    let id: Int
    let leagueId: Int
    let abbr: String
    let teamConcat: String
    let name: String
    let location: String?
    let conf: String?
    let div: String?
    let lat: Double?
    let lon: Double?
    let weather: Int

    enum CodingKeys: String, CodingKey {
        case id         = "team_id"
        case leagueId   = "league_id"
        case abbr
        case teamConcat = "team_concat"
        case name, location, conf, div, lat, lon, weather
    }
}
