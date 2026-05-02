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

// MARK: - FilterChip

struct FilterChip: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let isSelected: Bool
    var availabilityTint: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? theme.chipSelectedFG(colorScheme) : theme.primaryText(colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? theme.chipSelected(colorScheme) : theme.chipUnselected(colorScheme))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(availabilityTint ?? .clear, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - DateNavigationHeader

struct DateNavigationHeader: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    @State private var showDatePicker = false

    private let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d, yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var prevDayNumber: Int {
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        return Calendar.current.component(.day, from: prev)
    }

    private var nextDayNumber: Int {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        return Calendar.current.component(.day, from: next)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                HStack {
                    Image(systemName: "chevron.left").font(.title3.weight(.semibold))
                    Image(systemName: "\(prevDayNumber).calendar").font(.title3.weight(.semibold))
                }
                .foregroundStyle(theme.primaryText(colorScheme))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.cardBackground(colorScheme))
            .clipShape(Capsule())

            Button { showDatePicker = true } label: {
                Text(displayFormatter.string(from: selectedDate))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
            }
            .sheet(isPresented: $showDatePicker) {
                SharedDatePickerSheet(selectedDate: $selectedDate)
            }

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                HStack {
                    Image(systemName: "\(nextDayNumber).calendar").font(.title3.weight(.semibold))
                    Image(systemName: "chevron.right").font(.title3.weight(.semibold))
                }
                .foregroundStyle(theme.primaryText(colorScheme))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(theme.cardBackground(colorScheme))
            .clipShape(Capsule())

            Button("Today") { selectedDate = .now }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.primaryText(colorScheme))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.cardBackground(colorScheme))
                .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - SharedDatePickerSheet

private struct SharedDatePickerSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(theme.accent)
                    .padding(.horizontal)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - TabToolbar

struct TabToolbar: ViewModifier {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("profileSymbol")   private var profileSymbol: String   = ProfileOption.symbols[0]
    @AppStorage("leagueSymbol")    private var leagueSymbol: String    = "sportscourt"
    @AppStorage("leagueColorName") private var leagueColorName: String = AccentOption.allCases[0].rawValue
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
                            leagueColorName = theme.accentOption.rawValue
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
                            .foregroundStyle(theme.accent)
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
