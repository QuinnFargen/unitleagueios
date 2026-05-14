import Foundation

final class BetStore: ObservableObject {
    @Published private(set) var bets: [PlacedBet] = []

    private let key = "placedBets"

    init() { load() }

    func place(_ bet: PlacedBet) {
        bets.append(bet)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(bets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([PlacedBet].self, from: data)
        else { return }
        bets = saved
    }
}
