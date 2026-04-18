import SwiftUI
import AuthenticationServices

struct TabProfileView: View {
    @AppStorage("appleUserName") private var userName: String = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if userName.isEmpty {
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
                            userName = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
                            if userName.isEmpty { userName = "Player" }
                        case .failure:
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .frame(maxWidth: 280)
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.green)

                    Text(userName)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview {
    TabProfileView()
}
