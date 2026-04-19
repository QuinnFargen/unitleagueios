import SwiftUI

struct ViewLeagueDetail: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userLeagues")      private var userLeaguesData: Data    = Data()
    @AppStorage("appleUserName")    private var appleUserName: String    = ""
    @AppStorage("customUserName")   private var customUserName: String   = ""
    @AppStorage("profileSymbol")    private var profileSymbol: String    = ProfileOption.symbols[0]
    @AppStorage("profileColorName") private var profileColorName: String = ProfileOption.colorNames[0]
    @AppStorage("userUnits")        private var userUnits: Int           = 100
    @AppStorage("leagueSymbol")     private var leagueSymbol: String     = "sportscourt"
    @AppStorage("leagueColorName")  private var leagueColorName: String  = LeagueOption.colorNames[0]
    @Environment(\.dismiss)         private var dismiss

    let userLeague: UserLeague

    private var currentUser: LeagueMember {
        LeagueMember(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: customUserName.isEmpty ? (appleUserName.isEmpty ? "Me" : appleUserName) : customUserName,
            symbol: profileSymbol,
            colorName: profileColorName,
            units: userUnits
        )
    }

    private var sortedMembers: [LeagueMember] {
        (DummyLeagueMembers.all + [currentUser]).sorted { $0.units > $1.units }
    }

    private func ordinal(_ n: Int) -> String {
        switch n {
        case 1:  return "1st"
        case 2:  return "2nd"
        case 3:  return "3rd"
        default: return "\(n)th"
        }
    }

    var body: some View {
        ZStack {
            theme.appBackground(colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 6) {
                        Image(systemName: League.sportIcon(for: userLeague.leagueId))
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(ProfileOption.color(for: userLeague.colorName))
                            .padding(.top, 24)

                        Text(userLeague.abbr)
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(theme.primaryText(colorScheme))

                        Text(userLeague.customName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Member list
                    VStack(spacing: 0) {
                        ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                            MemberRow(
                                rank: index + 1,
                                member: member,
                                isCurrentUser: member.id == currentUser.id,
                                ordinal: ordinal
                            )
                            if index < sortedMembers.count - 1 {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(theme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        Button {
                            leagueSymbol    = League.sportIcon(for: userLeague.leagueId)
                            leagueColorName = userLeague.colorName
                        } label: {
                            Text("Set as Active League")
                                .font(.body).fontWeight(.medium)
                                .foregroundStyle(ProfileOption.color(for: userLeague.colorName))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ProfileOption.color(for: userLeague.colorName).opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            deleteLeague()
                        } label: {
                            Text("Delete League")
                                .font(.body).fontWeight(.medium)
                                .foregroundStyle(theme.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.error.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(userLeague.abbr)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteLeague() {
        let current = (try? JSONDecoder().decode([UserLeague].self, from: userLeaguesData)) ?? []
        userLeaguesData = (try? JSONEncoder().encode(current.filter { $0.id != userLeague.id })) ?? Data()
        dismiss()
    }
}

// MARK: - MemberRow

private struct MemberRow: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let rank: Int
    let member: LeagueMember
    let isCurrentUser: Bool
    let ordinal: (Int) -> String

    var body: some View {
        HStack(spacing: 14) {
            Text(ordinal(rank))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            Image(systemName: member.symbol)
                .font(.title2)
                .foregroundStyle(ProfileOption.color(for: member.colorName))

            Text(member.name)
                .font(.body).fontWeight(isCurrentUser ? .semibold : .regular)
                .foregroundStyle(theme.primaryText(colorScheme))

            if isCurrentUser {
                Text("(you)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "nairasign.circle.fill")
                Text("\(member.units)").fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(theme.primaryText(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? theme.cardBackgroundProminent(colorScheme) : Color.clear)
    }
}
