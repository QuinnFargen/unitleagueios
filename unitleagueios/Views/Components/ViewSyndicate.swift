import SwiftUI

struct ViewSyndicate: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("bettorId") private var bettorId: Int = 0

    let syndicate: Syndicate

    @State private var runners: [Runner] = []
    @State private var isLoading = false
    @State private var fetchError: String?

    private var sortedRunners: [Runner] {
        runners.sorted { $0.balance > $1.balance }
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
                    VStack(spacing: 8) {
                        Image(systemName: syndicate.isPublic ? "sparkles" : "person.3.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(theme.accent)
                            .padding(.top, 24)

                        Text(syndicate.name)
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundStyle(theme.primaryText(colorScheme))

                        if let desc = syndicate.description {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if syndicate.isPublic {
                            Text("Fantasy")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(theme.accent.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

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
                Text("\(runner.balance)").fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(theme.primaryText(colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isCurrentUser ? theme.cardBackgroundProminent(colorScheme) : Color.clear)
    }
}
