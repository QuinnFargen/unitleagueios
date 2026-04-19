import SwiftUI

// MARK: - Shared types

struct LeagueMember: Identifiable {
    let id: UUID
    let name: String
    let symbol: String
    let colorName: String
    let units: Int
}

enum DummyLeagueMembers {
    static let alex   = LeagueMember(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Alex",   symbol: "figure.basketball.circle.fill", colorName: "blue",   units: 115)
    static let jordan = LeagueMember(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Jordan", symbol: "figure.baseball.circle.fill",   colorName: "orange", units: 80)
    static let all: [LeagueMember] = [alex, jordan]
}

enum LeagueOption {
    static let colorNames = ProfileOption.colorNames
}

// MARK: - TabToolbar

struct TabToolbar: ViewModifier {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("profileSymbol")   private var profileSymbol: String   = ProfileOption.symbols[0]
    @AppStorage("profileColorName") private var profileColorName: String = ProfileOption.colorNames[0]
    @AppStorage("leagueSymbol")    private var leagueSymbol: String    = "sportscourt"
    @AppStorage("leagueColorName") private var leagueColorName: String = LeagueOption.colorNames[0]
    @AppStorage("userUnits")       private var userUnits: Int          = 100
    @AppStorage("leaguePnL")       private var leaguePnL: Int          = 5

    private var rankInfo: (rank: Int, diff: Int?) {
        let allUnits = (DummyLeagueMembers.all.map(\.units) + [userUnits]).sorted(by: >)
        let rank = (allUnits.firstIndex(of: userUnits) ?? 0) + 1
        if rank == 1 {
            let secondUnits = allUnits.count > 1 ? allUnits[1] : userUnits
            return (rank, userUnits - secondUnits)
        } else {
            return (rank, userUnits - allUnits[0])
        }
    }

    private func ordinal(_ n: Int) -> String {
        switch n {
        case 1:  return "1st"
        case 2:  return "2nd"
        case 3:  return "3rd"
        default: return "\(n)th"
        }
    }

    private var leagueLeadingItem: some View {
        let (rank, diff) = rankInfo
        return HStack(spacing: 6) {
            Image(systemName: leagueSymbol)
                .font(.title2)
                .foregroundStyle(ProfileOption.color(for: leagueColorName))

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(ordinal(rank))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                    if let diff {
                        Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                            .font(.caption2)
                            .foregroundStyle(diff >= 0 ? Color.green : theme.error)
                    }
                }
                Text(leaguePnL >= 0 ? "+\(leaguePnL)" : "\(leaguePnL)")
                    .font(.caption2)
                    .foregroundStyle(leaguePnL >= 0 ? Color.green : theme.error)
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    leagueLeadingItem
                }
                ToolbarItem(placement: .principal) {
                    Image("UNIT_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "nairasign.circle.fill")
                            Text("\(userUnits)").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryText(colorScheme))

                        Image(systemName: profileSymbol)
                            .font(.title2)
                            .foregroundStyle(ProfileOption.color(for: profileColorName))
                    }
                }
            }
    }
}

extension View {
    func tabToolbar() -> some View {
        modifier(TabToolbar())
    }
}
