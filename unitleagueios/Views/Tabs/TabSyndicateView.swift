import SwiftUI

struct TabSyndicateView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId") private var bettorId: Int = 0

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

                        Text("bettor_id: \(bettorId)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

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
                                        SyndicateCard(syndicate: syndicate)
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

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: syndicate.isPublic ? "sportscourt" : "house.fill")
                .font(.title2)
                .foregroundStyle(theme.accent)
                .frame(width: 44, height: 44)
                .background(theme.cardBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(syndicate.name)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText(colorScheme))

                Group {
                    if let desc = syndicate.description {
                        Text(desc)
                    } else {
                        Text("ID \(syndicate.syndicateId)\(syndicate.isPublic ? " · Fantasy" : " · Standard")")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
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

// MARK: - Join Sheet

private struct JoinSyndicateSheet: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let bettorId: Int

    @State private var syndicateIdInput = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var syndicateId: Int? { Int(syndicateIdInput.trimmingCharacters(in: .whitespaces)) }

    private func join() {
        guard let id = syndicateId else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await SyndicateService().joinSyndicate(
                    bettorId: bettorId,
                    syndicateId: id,
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
                    Section("Syndicate ID") {
                        TextField("Enter syndicate ID", text: $syndicateIdInput)
                            .keyboardType(.numberPad)
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
                        .disabled(syndicateId == nil || isLoading)
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
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var maxRunner: Int? { Int(maxRunnerInput.trimmingCharacters(in: .whitespaces)) }

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
                    maxRunner: maxRunner
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
                    Section("Name") {
                        TextField("Syndicate name", text: $name)
                    }

                    Section("Description (optional)") {
                        TextField("Add a description", text: $description)
                    }

                    Section("Password (optional)") {
                        SecureField("Set a password", text: $password)
                    }

                    Section("Max Members (optional)") {
                        TextField("No limit", text: $maxRunnerInput)
                            .keyboardType(.numberPad)
                    }

                    Section {
                        Toggle("Fantasy", isOn: $isPublic)
                            .tint(theme.accent)
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
            .navigationTitle("Create Syndicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(!isValid || isLoading)
                        .tint(theme.accent)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TabSyndicateView()
        .environmentObject(AppTheme())
}
