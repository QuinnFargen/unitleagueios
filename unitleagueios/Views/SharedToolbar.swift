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
    @AppStorage("profileSymbol")    private var profileSymbol: String    = ProfileOption.symbols[0]
    @AppStorage("profileColorName") private var profileColorName: String = ProfileOption.colorNames[0]
    @AppStorage("leagueSymbol")     private var leagueSymbol: String     = "sportscourt"
    @AppStorage("leagueColorName")  private var leagueColorName: String  = LeagueOption.colorNames[0]
    @AppStorage("userUnits")        private var userUnits: Int           = 100
    @AppStorage("activeLeagueId")   private var activeLeagueId: Int      = -1
    @AppStorage("userLeagues")      private var userLeaguesData: Data    = Data()

    // TODO: replace with API values
    private let sampleRank  = "2nd"
    private let sampleDiff  = "-15"
    private let samplePnL   = "+5"

    private var userLeagues: [UserLeague] {
        (try? JSONDecoder().decode([UserLeague].self, from: userLeaguesData)) ?? []
    }

    private var leagueLeadingItem: some View {
        HStack(spacing: 6) {
            Image(systemName: leagueSymbol)
                .font(.title2)
                .foregroundStyle(ProfileOption.color(for: leagueColorName))

                HStack(spacing: 4) {
                    Text(sampleRank)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.primaryText(colorScheme))
                    Text(sampleDiff)
                        .font(.caption)
                        .foregroundStyle(theme.error)
                }
        }
        .fixedSize()
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            leagueSymbol    = "trophy.fill"
                            leagueColorName = profileColorName
                            activeLeagueId  = -1
                        } label: {
                            Label("My Career", systemImage: activeLeagueId == -1 ? "checkmark" : "trophy.fill")
                        }

                        if !userLeagues.isEmpty {
                            Divider()
                            ForEach(userLeagues) { league in
                                Button {
                                    leagueSymbol    = League.sportIcon(for: league.leagueId)
                                    leagueColorName = league.colorName
                                    activeLeagueId  = league.leagueId
                                } label: {
                                    Label(
                                        league.customName.isEmpty ? league.abbr : league.customName,
                                        systemImage: activeLeagueId == league.leagueId ? "checkmark" : League.sportIcon(for: league.leagueId)
                                    )
                                }
                            }
                        }
                    } label: {
                        leagueLeadingItem
                    }
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
