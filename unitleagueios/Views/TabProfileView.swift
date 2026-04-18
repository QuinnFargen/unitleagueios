import SwiftUI
import AuthenticationServices

struct TabProfileView: View {
    @AppStorage("appleUserName") private var appleUserName: String = ""
    @AppStorage("customUserName") private var customUserName: String = ""
    @AppStorage("profileSymbol") private var profileSymbol: String = ProfileOption.symbols[0]
    @AppStorage("profileColorName") private var profileColorName: String = ProfileOption.colorNames[0]
    @State private var authError: String?
    @State private var isEditingUsername = false
    @State private var usernameInput = ""

    private var displayName: String {
        customUserName.isEmpty ? appleUserName : customUserName
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if appleUserName.isEmpty {
                signInView
            } else {
                profileView
            }
        }
    }

    private var signInView: some View {
        VStack(spacing: 40) {
            Text("Unit League")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
                    let first = credential.fullName?.givenName ?? ""
                    let last = credential.fullName?.familyName ?? ""
                    appleUserName = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
                    if appleUserName.isEmpty { appleUserName = "Player" }
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
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private var profileView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: profileSymbol)
                    .font(.system(size: 72))
                    .foregroundStyle(ProfileOption.color(for: profileColorName))
                    .padding(.top, 32)

                if isEditingUsername {
                    HStack(spacing: 12) {
                        TextField("Username", text: $usernameInput)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        Button("Save") {
                            let trimmed = usernameInput.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty { customUserName = trimmed }
                            isEditingUsername = false
                        }
                        .tint(.green)
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
                                .foregroundStyle(.white)
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
                                    .foregroundStyle(profileSymbol == symbol ? .white : .secondary)
                                    .frame(width: 52, height: 52)
                                    .background(profileSymbol == symbol ? Color.white.opacity(0.15) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                profileSymbol == symbol ? Color.white.opacity(0.4) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Profile Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)

                    HStack(spacing: 16) {
                        ForEach(ProfileOption.colorNames, id: \.self) { name in
                            Button {
                                profileColorName = name
                            } label: {
                                Circle()
                                    .fill(ProfileOption.color(for: name))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: profileColorName == name ? 2.5 : 0)
                                    )
                                    .shadow(
                                        color: ProfileOption.color(for: name).opacity(profileColorName == name ? 0.6 : 0),
                                        radius: 6
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Button {
                    appleUserName = ""
                    customUserName = ""
                } label: {
                    Text("Sign Out")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        "person.circle.fill",
        "star.circle.fill",
        "bolt.circle.fill",
        "flame.circle.fill",
        "crown.fill"
    ]

    static let colorNames = ["green", "blue", "orange", "purple", "red"]

    static func color(for name: String) -> Color {
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
}
