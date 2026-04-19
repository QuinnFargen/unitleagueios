import SwiftUI

enum LeagueOption {
    static let symbols = [
        "trophy.fill",
        "shield.fill",
        "star.fill",
        "flame.fill",
        "bolt.fill",
        "crown.fill"
    ]
    static let colorNames = ProfileOption.colorNames
}

struct TabToolbar: ViewModifier {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("profileSymbol") private var profileSymbol: String = ProfileOption.symbols[0]
    @AppStorage("profileColorName") private var profileColorName: String = ProfileOption.colorNames[0]
    @AppStorage("leagueSymbol") private var leagueSymbol: String = LeagueOption.symbols[0]
    @AppStorage("leagueColorName") private var leagueColorName: String = LeagueOption.colorNames[0]
    @AppStorage("userUnits") private var userUnits: Int = 100

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: leagueSymbol)
                        .font(.title2)
                        .foregroundStyle(ProfileOption.color(for: leagueColorName))
                }
                ToolbarItem(placement: .principal) {
                    Image("UNIT_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 26)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        HStack(spacing: 3) {
                            Image(systemName: "nairasign.circle.fill")
                            Text("\(userUnits)")
                                .fontWeight(.semibold)
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
