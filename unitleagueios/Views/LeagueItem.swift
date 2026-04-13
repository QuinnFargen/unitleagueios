//
//  LeagueItem.swift
//  unitleagueios
//
//  Created by Quinn Fargen on 3/27/26.
//


import SwiftUI
import SwiftData

// MARK: - Model
@Model
class LeagueItem {
    @Attribute(.unique) var id: Int
    var name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - API Service
class LeagueService {
    func fetchLeague(completion: @escaping ([LeagueItem]) -> Void) {
        guard let url = URL(string: "https://192.168.4.59:8000/league") else {
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let items = jsonArray.prefix(6).compactMap { dict -> LeagueItem? in
                        if let id = dict["id"] as? Int,
                           let name = dict["name"] as? String {
                            return LeagueItem(id: id, name: name)
                        }
                        return nil
                    }
                    completion(Array(items))
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }
        task.resume()
    }
}

// MARK: - SwiftUI View
struct LeagueListView: View {
    @Environment(\.modelContext) private var context
    @Query private var leagueItems: [LeagueItem]
    let service = LeagueService()
    
    var body: some View {
        List(leagueItems) { item in
            Text(item.name)
        }
        .onAppear {
            service.fetchLeague { items in
                Task { @MainActor in
                    for item in items {
                        // Avoid duplicates
                        if !leagueItems.contains(where: { $0.id == item.id }) {
                            context.insert(item)
                        }
                    }
                    try? context.save()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LeagueListView()
        .modelContainer(for: LeagueItem.self)
}
