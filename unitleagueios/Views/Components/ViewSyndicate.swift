import SwiftUI

struct ViewSyndicate: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId") private var bettorId: Int = 0

    @State var syndicate: Syndicate
    @State private var runners: [Runner] = []
    @State private var isLoading = false
    @State private var fetchError: String?
    @State private var showingEdit = false

    private var currentRunner: Runner? { runners.first(where: { $0.bettorId == bettorId }) }
    private var isAdmin: Bool { currentRunner?.role == "admin" }

    private var sortedRunners: [Runner] {
        runners.sorted { ($0.balance ?? 0) > ($1.balance ?? 0) }
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
                    syndicateBanner

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    } else if let error = fetchError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                    } else if !sortedRunners.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(sortedRunners.enumerated()), id: \.element.id) { index, runner in
                                RunnerRow(
                                    rank: index + 1,
                                    runner: runner,
                                    isCurrentUser: runner.bettorId == bettorId,
                                    ordinal: ordinal
                                )
                                if index < sortedRunners.count - 1 {
                                    Divider().padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(theme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(syndicate.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showingEdit) {
            EditSyndicateSheet(syndicate: $syndicate)
        }
    }

    private var syndicateBanner: some View {
        let bannerColor = ProfileOption.color(for: syndicate.color ?? "")
        let iconName = syndicate.symbol ?? (syndicate.isPublic ? "sparkles" : "person.3.fill")

        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [bannerColor.opacity(0.35), Color.secondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 80)

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(theme.primaryText(colorScheme))
                    .frame(width: 48, height: 48)
                    .background(theme.cardBackgroundProminent(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(syndicate.name)
                        .font(.title2).bold()
                        .foregroundStyle(theme.primaryText(colorScheme))

                    if syndicate.isPublic {
                        Text("Public")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }
                }

                Spacer()

                if isAdmin {
                    Button {
                        showingEdit = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func load() async {
        isLoading = true
        fetchError = nil
        do {
            runners = try await RunnerService().fetchRunner(syndicateId: syndicate.syndicateId)
        } catch {
            fetchError = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - EditSyndicateSheet

private struct EditSyndicateSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Binding var syndicate: Syndicate

    @State private var nameInput: String
    @State private var selectedSymbol: String
    @State private var selectedColor: AccentOption
    @State private var isEditingName = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(syndicate: Binding<Syndicate>) {
        _syndicate = syndicate
        _nameInput = State(initialValue: syndicate.wrappedValue.name)
        _selectedSymbol = State(initialValue: syndicate.wrappedValue.symbol ?? ProfileOption.symbols[0])
        _selectedColor = State(initialValue: AccentOption(rawValue: syndicate.wrappedValue.color ?? "") ?? .green)
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
                                TextField("Syndicate name", text: $nameInput)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(theme.primaryText(colorScheme))
                                    .multilineTextAlignment(.center)
                                    .autocorrectionDisabled()

                                Button("Save") {
                                    isEditingName = false
                                }
                                .tint(theme.accent)
                            }
                            .padding(.horizontal, 40)
                        } else {
                            Button {
                                isEditingName = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text(nameInput)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(theme.primaryText(colorScheme))
                                    Image(systemName: "pencil")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Syndicate Symbol")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 32)

                            HStack(spacing: 14) {
                                ForEach(ProfileOption.symbols, id: \.self) { symbol in
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
                            Text("Syndicate Color")
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
                                                .shadow(
                                                    color: option.color.opacity(selectedColor == option ? 0.6 : 0),
                                                    radius: 6
                                                )
                                            Text(option.label)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(theme.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Button {
                            save()
                        } label: {
                            Text("Save Syndicate")
                                .font(.body).fontWeight(.medium)
                                .foregroundStyle(theme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Edit Syndicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        let id = syndicate.syndicateId
        Task {
            do {
                let updated = try await SyndicateService().updateSyndicate(
                    syndicateId: id,
                    name: trimmedName,
                    symbol: selectedSymbol,
                    color: selectedColor.rawValue
                )
                syndicate = updated
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// MARK: - RunnerRow

private struct RunnerRow: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    let rank: Int
    let runner: Runner
    let isCurrentUser: Bool
    let ordinal: (Int) -> String

    var body: some View {
        HStack(spacing: 14) {
            Text(ordinal(rank))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            Image(systemName: runner.symbol ?? "person.fill")
                .font(.title2)
                .foregroundStyle(ProfileOption.color(for: runner.color ?? ""))

            VStack(alignment: .leading, spacing: 2) {
                Text(runner.profileName ?? "Unknown")
                    .font(.body).fontWeight(isCurrentUser ? .semibold : .regular)
                    .foregroundStyle(theme.primaryText(colorScheme))

                if runner.role == "admin" {
                    Text("admin")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
            }

            if isCurrentUser {
                Text("(you)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "nairasign.circle.fill")
                Text("\(runner.balance ?? 0)").fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(theme.primaryText(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? theme.cardBackgroundProminent(colorScheme) : Color.clear)
    }
}
