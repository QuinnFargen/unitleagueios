import SwiftUI

struct TabSyndicateView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId")            private var bettorId: Int = 0
    @AppStorage("selectedSyndicateId") private var selectedSyndicateId: Int = 0

    @State private var syndicates: [Syndicate] = []
    @State private var isLoading = false
    @State private var fetchError: String?
    @State private var showingJoin = false
    @State private var showingCreate = false

    private let service = SyndicateService()

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

                        if isLoading {
                            ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                        } else if let error = fetchError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if !syndicates.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Syndicates")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(syndicates) { syndicate in
                                    NavigationLink(destination: ViewSyndicate(syndicate: syndicate)) {
                                        SyndicateCard(
                                            syndicate: syndicate,
                                            isSelected: syndicate.syndicateId == selectedSyndicateId
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            Text("You're not in any syndicates yet.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .tabToolbar()
            .task { await load() }
            .sheet(isPresented: $showingJoin, onDismiss: { Task { await load() } }) {
                JoinSyndicateSheet(bettorId: bettorId)
            }
            .sheet(isPresented: $showingCreate, onDismiss: { Task { await load() } }) {
                CreateSyndicateSheet(bettorId: bettorId)
            }
        }
    }

    private func load() async {
        guard bettorId > 0 else { return }
        isLoading = true
        fetchError = nil
        do {
            let raw = try await service.fetchSyndicate(bettorId: bettorId)
            var seen = Set<Int>()
            syndicates = raw.filter { seen.insert($0.syndicateId).inserted }
        } catch {
            fetchError = error.localizedDescription
        }
        isLoading = false
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

private struct SyndicateCard: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let syndicate: Syndicate
    var isSelected: Bool = false

    var body: some View {
        let iconName = syndicate.symbol ?? (syndicate.isPublic ? "sportscourt" : "house.fill")
        let iconColor = ProfileOption.color(for: syndicate.color ?? "")

        return HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(isSelected ? theme.accent.opacity(0.15) : theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(syndicate.name)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))

                if let desc = syndicate.description {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if syndicate.isPublic {
                    Text("Public")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(theme.accent)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(
            isSelected
                ? LinearGradient(colors: [theme.accent.opacity(0.18), theme.cardBackground(colorScheme)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [theme.cardBackground(colorScheme)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? theme.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Join Sheet

private struct JoinSyndicateSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let bettorId: Int

    @State private var syndicateCode = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var codeIsValid: Bool { !syndicateCode.trimmingCharacters(in: .whitespaces).isEmpty }

    private func join() {
        guard codeIsValid else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await SyndicateService().joinSyndicate(
                    bettorId: bettorId,
                    code: syndicateCode.trimmingCharacters(in: .whitespaces),
                    password: password.isEmpty ? nil : password
                )
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
                    Section("Syndicate Code") {
                        TextField("Enter syndicate code", text: $syndicateCode)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                    }

                    Section("Password (optional)") {
                        SecureField("Enter password", text: $password)
                    }

                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(theme.error)
                        }
                    }
                }
                .scrollContentBackground(.hidden)

                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Join Syndicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Join") { join() }
                        .disabled(!codeIsValid || isLoading)
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

private struct CreateSyndicateSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let bettorId: Int

    @State private var name = ""
    @State private var description = ""
    @State private var password = ""
    @State private var maxRunnerInput = ""
    @State private var isPublic = false
    @State private var selectedSymbol: String = SyndicateOption.symbols[0]
    @State private var selectedColor: AccentOption = .green
    @State private var isEditingName = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var maxRunner: Int? { Int(maxRunnerInput.trimmingCharacters(in: .whitespaces)) }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && maxRunner != nil }

    private func create() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await SyndicateService().createSyndicate(
                    bettorId: bettorId,
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                    isPublic: isPublic,
                    password: password.isEmpty ? nil : password,
                    maxRunner: maxRunner,
                    symbol: selectedSymbol,
                    color: selectedColor.rawValue
                )
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

                ScrollView {
                    VStack(spacing: 32) {
                        Image(systemName: selectedSymbol)
                            .font(.system(size: 72))
                            .foregroundStyle(selectedColor.color)
                            .padding(.top, 32)

                        if isEditingName {
                            HStack(spacing: 12) {
                                TextField("Syndicate name", text: $name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                    .multilineTextAlignment(.center)
                                    .autocorrectionDisabled()

                                Button("Save") { isEditingName = false }
                                    .tint(theme.accent)
                            }
                            .padding(.horizontal, 40)
                        } else {
                            Button {
                                isEditingName = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text(name.isEmpty ? "Syndicate Name" : name)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(name.isEmpty ? Color.secondary : theme.primaryText(colorScheme))
                                    Image(systemName: "pencil")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Symbol")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 32)

                            HStack(spacing: 14) {
                                ForEach(SyndicateOption.symbols, id: \.self) { symbol in
                                    Button {
                                        selectedSymbol = symbol
                                    } label: {
                                        Image(systemName: symbol)
                                            .font(.title2)
                                            .foregroundStyle(selectedSymbol == symbol ? theme.primaryText(colorScheme) : .secondary)
                                            .frame(width: 52, height: 52)
                                            .background(selectedSymbol == symbol ? theme.cardBackgroundProminent(colorScheme) : Color.clear)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedSymbol == symbol ? theme.primaryText(colorScheme).opacity(0.4) : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Color")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 32)

                            HStack(spacing: 12) {
                                ForEach(AccentOption.allCases) { option in
                                    Button {
                                        selectedColor = option
                                    } label: {
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(option.color)
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle()
                                                        .stroke(theme.primaryText(colorScheme), lineWidth: selectedColor == option ? 2.5 : 0)
                                                )
                                                .shadow(color: option.color.opacity(selectedColor == option ? 0.6 : 0), radius: 6)
                                            Text(option.label)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Max Members")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                TextField("Enter max members", text: $maxRunnerInput)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(theme.cardBackground(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Toggle("Public", isOn: $isPublic)
                                .tint(theme.accent)
                                .padding(.horizontal, 4)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description (optional)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                TextField("Add a description", text: $description)
                                    .padding(12)
                                    .background(theme.cardBackground(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password (optional)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                SecureField("Set a password", text: $password)
                                    .padding(12)
                                    .background(theme.cardBackground(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 32)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(theme.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Button {
                            create()
                        } label: {
                            Text("Create")
                                .font(.body).fontWeight(.medium)
                                .foregroundStyle(theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!isValid || isLoading)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }

                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Create Syndicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

enum SyndicateOption {
    static let symbols = [
        "person.3.fill",
        "house.fill",
        "bitcoinsign.bank.building.fill",
        "brain.filled.head.profile",
        "puzzlepiece.fill",
        "lock.fill"
    ]
}

#Preview {
    TabSyndicateView()
        .environmentObject(AppTheme())
}
