import SwiftUI

struct TabLeaguesView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("userLeagues") private var userLeaguesData: Data = Data()
    @State private var showingJoin = false
    @State private var showingCreate = false

    @AppStorage("customUserName") private var customUserName: String = ""
    @AppStorage("appleUserName")  private var appleUserName: String  = ""

    private var userLeagues: [UserLeague] {
        (try? JSONDecoder().decode([UserLeague].self, from: userLeaguesData)) ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 12) {
                            LeagueActionButton(title: "Join", icon: "person.badge.plus", tint: theme.accent) {
                                showingJoin = true
                            }
                            LeagueActionButton(title: "Create", icon: "plus.circle", tint: theme.accent) {
                                showingCreate = true
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Career")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            CareerCard(
                                displayName: customUserName.isEmpty ? (appleUserName.isEmpty ? "Me" : appleUserName) : customUserName
                            )
                        }

                        if !userLeagues.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("My Leagues")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(userLeagues) { league in
                                    NavigationLink(destination: ViewLeagueDetail(userLeague: league)) {
                                        UserLeagueCard(userLeague: league)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .tabToolbar()
            .sheet(isPresented: $showingJoin) {
                JoinLeagueSheet { newLeague in
                    append(newLeague)
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateLeagueSheet { newLeague in
                    append(newLeague)
                }
            }
        }
    }

    private func append(_ league: UserLeague) {
        var current = userLeagues
        current.append(league)
        userLeaguesData = (try? JSONEncoder().encode(current)) ?? Data()
    }
}

// MARK: - UserLeague model

struct UserLeague: Codable, Identifiable {
    let id: UUID
    let leagueId: Int
    let oddLeagueId: Int?
    let abbr: String
    let sport: String
    let customName: String
    let colorName: String

    init(id: UUID, leagueId: Int, oddLeagueId: Int? = nil, abbr: String, sport: String, customName: String, colorName: String) {
        self.id = id
        self.leagueId = leagueId
        self.oddLeagueId = oddLeagueId
        self.abbr = abbr
        self.sport = sport
        self.customName = customName
        self.colorName = colorName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        leagueId    = try c.decode(Int.self,    forKey: .leagueId)
        oddLeagueId = try? c.decode(Int.self,   forKey: .oddLeagueId)
        abbr        = try c.decode(String.self, forKey: .abbr)
        sport       = try c.decode(String.self, forKey: .sport)
        customName  = try c.decode(String.self, forKey: .customName)
        colorName   = (try? c.decode(String.self, forKey: .colorName)) ?? LeagueOption.colorNames[0]
    }
}

// MARK: - Sub-views

private struct LeagueActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(tint.opacity(0.15))
                .foregroundStyle(tint)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.35), lineWidth: 1))
        }
    }
}

private struct UserLeagueCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let userLeague: UserLeague

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: League.sportIcon(for: userLeague.leagueId))
                .font(.title2)
                .foregroundStyle(ProfileOption.color(for: userLeague.colorName))
                .frame(width: 44, height: 44)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(userLeague.abbr)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))
                Text(userLeague.customName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct CareerCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let displayName: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(theme.accent)
                .frame(width: 44, height: 44)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))
                Text("My Career")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(theme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Join Sheet

private struct JoinLeagueSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let onConfirm: (UserLeague) -> Void

    @AppStorage("bettorId") private var bettorId: Int = 0

    @State private var leagueIdInput = ""
    @State private var password = ""
    @State private var selectedSymbolId: Int = 1
    @State private var selectedColorName: String = AccentOption.allCases[0].rawValue
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let sportSymbols: [(id: Int, icon: String, label: String, sport: String)] = [
        (1, "basketball",             "NBA",   "Basketball"),
        (2, "american.football",      "NFL",   "Football"),
        (3, "hockey.puck",            "NHL",   "Hockey"),
        (4, "baseball",               "MLB",   "Baseball"),
        (5, "american.football.fill", "NCAAF", "Coll. Football"),
        (6, "basketball.fill",        "NCAAB", "Coll. Basketball"),
    ]

    private var selectedSport: (id: Int, icon: String, label: String, sport: String) {
        sportSymbols.first { $0.id == selectedSymbolId } ?? sportSymbols[0]
    }

    private var oddLeagueId: Int? { Int(leagueIdInput.trimmingCharacters(in: .whitespaces)) }

    private func join() {
        guard let oddId = oddLeagueId else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let bbl = try await LeagueService().joinLeague(bettorId: bettorId, oddLeagueId: oddId)
                let sport = selectedSport
                onConfirm(UserLeague(
                    id: UUID(),
                    leagueId: sport.id,
                    oddLeagueId: bbl.leagueId,
                    abbr: sport.label,
                    sport: sport.sport,
                    customName: "League \(bbl.leagueId)",
                    colorName: selectedColorName
                ))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                Form {
                    Section("League ID") {
                        TextField("Enter league ID", text: $leagueIdInput)
                            .keyboardType(.numberPad)
                    }

                    Section("Password") {
                        SecureField("Enter password", text: $password)
                    }

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(theme.error)
                        }
                    }

                    Section("Symbol") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 12) {
                            ForEach(sportSymbols, id: \.id) { sport in
                                Button {
                                    selectedSymbolId = sport.id
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: sport.icon)
                                            .font(.title2)
                                            .foregroundStyle(selectedSymbolId == sport.id ? theme.accent : theme.primaryText(colorScheme))
                                            .frame(width: 48, height: 48)
                                            .background(selectedSymbolId == sport.id ? theme.accent.opacity(0.15) : theme.cardBackground(colorScheme))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedSymbolId == sport.id ? theme.accent : Color.clear, lineWidth: 1.5)
                                            )
                                        Text(sport.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }

                    Section("Your Color") {
                        HStack(spacing: 16) {
                            ForEach(AccentOption.allCases) { option in
                                Button {
                                    selectedColorName = option.rawValue
                                } label: {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(theme.primaryText(colorScheme),
                                                        lineWidth: selectedColorName == option.rawValue ? 2.5 : 0)
                                        )
                                        .shadow(
                                            color: option.color.opacity(selectedColorName == option.rawValue ? 0.6 : 0),
                                            radius: 6
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)

                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Join League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") { join() }
                        .disabled(oddLeagueId == nil || isLoading)
                        .tint(theme.accent)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Create Sheet

private struct CreateLeagueSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let onConfirm: (UserLeague) -> Void

    @AppStorage("bettorId") private var bettorId: Int = 0

    @State private var martLeagues: [League] = []
    @State private var isFetchingLeagues = false
    @State private var fetchError: String?
    @State private var selectedLeagueId: Int?

    @State private var leagueName = ""
    @State private var selectedColorName: String = AccentOption.allCases[0].rawValue
    @State private var isLoading = false
    @State private var errorMessage: String?

    @AppStorage("leagueSymbol")    private var leagueSymbol: String    = "sportscourt"
    @AppStorage("leagueColorName") private var leagueColorName: String = AccentOption.allCases[0].rawValue

    private let service = LeagueService()

    private var selectedLeague: League? {
        martLeagues.first { $0.id == selectedLeagueId }
    }

    private func fetchLeagues() {
        isFetchingLeagues = true
        fetchError = nil
        Task {
            do {
                martLeagues = try await service.fetchLeagues()
            } catch {
                fetchError = error.localizedDescription
            }
            isFetchingLeagues = false
        }
    }

    private func create() {
        guard let league = selectedLeague else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let oddLeague = try await service.createLeague(
                    bettorId: bettorId,
                    name: leagueName.trimmingCharacters(in: .whitespaces)
                )
                leagueSymbol    = League.sportIcon(for: league.id)
                leagueColorName = selectedColorName
                onConfirm(UserLeague(
                    id: UUID(),
                    leagueId: league.id,
                    oddLeagueId: oddLeague.leagueId,
                    abbr: league.abbr,
                    sport: league.sport,
                    customName: leagueName.trimmingCharacters(in: .whitespaces),
                    colorName: selectedColorName
                ))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                Form {
                    Section("Select Sport") {
                        if isFetchingLeagues {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("Loading leagues...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if let error = fetchError {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Retry") { fetchLeagues() }
                                    .font(.caption)
                            }
                        } else if martLeagues.isEmpty {
                            Text("No leagues available")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(martLeagues) { league in
                                LeagueOptionRow(
                                    league: league,
                                    isSelected: selectedLeagueId == league.id
                                ) {
                                    selectedLeagueId = league.id
                                }
                            }
                        }
                    }

                    Section("League Name") {
                        TextField("Enter a name", text: $leagueName)
                    }

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(theme.error)
                        }
                    }

                    Section("Your Color") {
                        HStack(spacing: 16) {
                            ForEach(AccentOption.allCases) { option in
                                Button {
                                    selectedColorName = option.rawValue
                                } label: {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(theme.primaryText(colorScheme),
                                                        lineWidth: selectedColorName == option.rawValue ? 2.5 : 0)
                                        )
                                        .shadow(
                                            color: option.color.opacity(selectedColorName == option.rawValue ? 0.6 : 0),
                                            radius: 6
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)

                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Create League")
            .navigationBarTitleDisplayMode(.inline)
            .task { fetchLeagues() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(selectedLeagueId == nil || leagueName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        .tint(theme.accent)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct LeagueOptionRow: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let league: League
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: League.sportIcon(for: league.id))
                    .font(.title3)
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(width: 36, height: 36)
                    .background(theme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(league.abbr)
                        .font(.headline)
                        .foregroundStyle(theme.primaryText(colorScheme))
                    Text(league.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabLeaguesView()
        .environmentObject(AppTheme())
}
