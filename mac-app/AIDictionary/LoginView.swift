import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @StateObject
    private var authService = AuthService.shared

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign In")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        switch result {
                        case let .success(authorization):
                            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
                            else { return }
                            await authService.signInWithApple()
                        case let .failure(error):
                            break
                        }
                    }
                }
                .frame(height: 44)

                Button {
                    Task {
                        try? await authService.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .frame(height: 44)
            }
            .padding(.horizontal, 40)
        }
        .frame(width: 320, height: 220)
    }
}

#Preview {
    LoginView()
}
