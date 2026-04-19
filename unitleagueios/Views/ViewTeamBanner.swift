import SwiftUI

struct ViewTeamBanner: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let team: Team
    let league: League
    var showChevron: Bool = false

    var teamColor: Color {
        switch team.color ?? "" {
        case "Blue":         return Color(red: 0.10, green: 0.25, blue: 0.80)
        case "Red":          return .red
        case "Green":        return .green
        case "Yellow":       return .yellow
        case "Black":        return Color(white: 0.15)
        case "Purple":       return .purple
        case "Orange":       return .orange
        case "Brown":        return Color(red: 0.55, green: 0.27, blue: 0.07)
        case "White":        return .white
        case "Gray":         return .gray
        case "Gold":         return Color(red: 1.0, green: 0.75, blue: 0.0)
        case "Navy":         return Color(red: 0.0, green: 0.0, blue: 0.50)
        default:             return .gray
        }
    }

    var sportIcon: String {
        switch league.id {
        case 1:  return "basketball"
        case 2:  return "american.football.professional"
        case 3:  return "hockey.puck"
        case 4:  return "baseball"
        case 5:  return "american.football"
        case 6:  return "basketball.fill"
        default: return "sportscourt"
        }
    }

    var categoryIcon: String {
        switch team.category ?? "" {
        case "Person":    return "person"
        case "Animal":    return "pawprint"
        case "Bird":      return "bird"
        case "Cat":       return "cat"
        case "Dog":       return "dog"
        case "Color":     return "paintpalette"
        case "Imaginary": return "person.fill.questionmark"
        default:          return "questionmark"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.primary, teamColor.opacity(0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity)
            .frame(height: 80)

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: sportIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(width: 48, height: 48)
                    .background(theme.cardBackgroundProminent(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(team.abbr)
                            .font(.title2).bold()
                            .foregroundStyle(theme.primaryText(colorScheme))
                        if let mascot = team.mascot {
                            Label(mascot, systemImage: categoryIcon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TeamMetaRow(team: team, categoryIcon: categoryIcon)
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - TeamMetaRow

struct TeamMetaRow: View {
    let team: Team
    let categoryIcon: String

    var body: some View {
        let confDiv = [team.conf, team.div].compactMap { $0 }.joined(separator: " · ")

        HStack(spacing: 6) {
            if !confDiv.isEmpty {
                Text(confDiv)
            }
            if let region = team.region {
                if !confDiv.isEmpty { Text("·").foregroundStyle(.tertiary) }
                Label(region, systemImage: "location.fill")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
