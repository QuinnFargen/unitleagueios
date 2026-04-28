import SwiftUI
import AuthenticationServices

struct TabProfileView: View {
    @EnvironmentObject private var theme: AppTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appleUserName")   private var appleUserName: String   = ""
    @AppStorage("customUserName")  private var customUserName: String  = ""
    @AppStorage("profileSymbol")   private var profileSymbol: String   = ProfileOption.symbols[0]
    @AppStorage("profileSaved")    private var profileSaved: Bool      = false
    @AppStorage("bettorId")        private var bettorId: Int           = 0
    @State private var authError: String?
    @State private var isEditingUsername = false
    @State private var usernameInput = ""

    private var displayName: String {
        customUserName.isEmpty ? appleUserName : customUserName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.appBackground(colorScheme).ignoresSafeArea()

                if appleUserName.isEmpty {
                    signInView
                } else {
                    profileView
                }
            }
            .tabToolbar()
        }
    }

    private var signInView: some View {
        VStack(spacing: 40) {
            Text("Unit League")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText(colorScheme))

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                    let first = credential.fullName?.givenName ?? ""
                    let last = credential.fullName?.familyName ?? ""
                    let name = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
                    appleUserName = name.isEmpty ? "Player" : name
                    let appleSub = credential.user
                    let appleEmail = credential.email
                    let appleName = name.isEmpty ? nil : name
                    Task {
                        if let bettor = try? await BettorService().createBettor(
                            appleSub: appleSub,
                            appleEmail: appleEmail,
                            appleName: appleName
                        ) {
                            bettorId = bettor.bettorId
                        }
                    }
                case .failure(let error):
                    let asError = error as? ASAuthorizationError
                    if asError?.code != .canceled {
                        authError = "Sign in failed. Make sure you're signed into an Apple ID in Settings."
                    }
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .frame(maxWidth: 280)
            .cornerRadius(8)

            if let msg = authError {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(theme.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Sign in as Test User") {
                appleUserName = "Test User"
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var profileView: some View {
        Group {
            if profileSaved {
                savedProfileView
            } else {
                editProfileView
            }
        }
    }

    private var savedProfileView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: profileSymbol)
                .font(.system(size: 80))
                .foregroundStyle(theme.accent)

            Text(displayName)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(theme.primaryText(colorScheme))

            Button("Edit Profile") {
                profileSaved = false
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(theme.accent)
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var editProfileView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: profileSymbol)
                    .font(.system(size: 72))
                    .foregroundStyle(theme.accent)
                    .padding(.top, 32)

                if isEditingUsername {
                    HStack(spacing: 12) {
                        TextField("Username", text: $usernameInput)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.primaryText(colorScheme))
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button("Save") {
                            let trimmed = usernameInput.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { customUserName = trimmed }
                            isEditingUsername = false
                        }
                        .tint(theme.accent)
                    }
                    .padding(.horizontal, 40)
                } else {
                    Button {
                        usernameInput = displayName
                        isEditingUsername = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(displayName)
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
                    Text("Profile Symbol")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)

                    HStack(spacing: 14) {
                        ForEach(ProfileOption.symbols, id: \.self) { symbol in
                            Button {
                                profileSymbol = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title2)
                                    .foregroundStyle(profileSymbol == symbol ? theme.primaryText(colorScheme) : .secondary)
                                    .frame(width: 52, height: 52)
                                    .background(profileSymbol == symbol ? theme.cardBackgroundProminent(colorScheme) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                profileSymbol == symbol ? theme.primaryText(colorScheme).opacity(0.4) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Accent Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)

                    HStack(spacing: 12) {
                        ForEach(AccentOption.allCases) { option in
                            Button {
                                theme.accentOption = option
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(theme.primaryText(colorScheme), lineWidth: theme.accentOption == option ? 2.5 : 0)
                                        )
                                        .shadow(
                                            color: option.color.opacity(theme.accentOption == option ? 0.6 : 0),
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

                VStack(spacing: 12) {
                    Button {
                        profileSaved = true
                        isEditingUsername = false
                    } label: {
                        Text("Save Profile")
                            .font(.body).fontWeight(.medium)
                            .foregroundStyle(theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        appleUserName = ""
                        customUserName = ""
                        profileSaved = false
                    } label: {
                        Text("Sign Out")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.error.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }
}

enum ProfileOption {
    static let symbols = [
        "figure.american.football.circle.fill",
        "figure.basketball.circle.fill",
        "figure.baseball.circle.fill",
        "figure.hockey.circle.fill",
        "figure.pickleball.circle.fill",
        "figure.equestrian.sports.circle.fill"
    ]

    static let colorNames = ["green", "blue", "orange", "purple", "red"]

    static func color(for name: String) -> Color {
        if let accent = AccentOption(rawValue: name) { return accent.color }
        switch name {
        case "green":  return .green
        case "blue":   return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "red":    return .red
        default:       return .green
        }
    }
}

#Preview {
    TabProfileView()
        .environmentObject(AppTheme())
}
