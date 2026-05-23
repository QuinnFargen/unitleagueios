import Foundation

final class BetStore: ObservableObject {
    @Published private(set) var bets: [PlacedBet] = []
    @Published private(set) var bookmarks: [PlacedBet] = []

    private let key         = "placedBets"
    private let bookmarkKey = "bookmarkedBets"

    init() {
        load()
        loadBookmarks()
    }

    func place(_ bet: PlacedBet) {
        bets.append(bet)
        persist()
    }

    func bookmark(_ bet: PlacedBet) {
        guard !bookmarks.contains(where: { $0.betHash == bet.betHash }) else { return }
        bookmarks.append(bet)
        persistBookmarks()
    }

    func removeBookmark(_ bet: PlacedBet) {
        bookmarks.removeAll { $0.betHash == bet.betHash }
        persistBookmarks()
    }

    func clearBookmarks() {
        bookmarks = []
        persistBookmarks()
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

    private func persistBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey),
              let saved = try? JSONDecoder().decode([PlacedBet].self, from: data)
        else { return }
        bookmarks = saved
    }
}
