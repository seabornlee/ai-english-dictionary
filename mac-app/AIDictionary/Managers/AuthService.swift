import AuthenticationServices
import CryptoKit
import Foundation
import GoogleSignIn
import os.log

// MARK: - TokenStore

/// Keychain-backed token storage for authenticated sessions.
enum TokenStore {
    private static let service = "site.waterlee.aidic.auth"
    private static let account = "authToken"

    /// Save a JWT token to the Keychain.
    /// - Parameter token: The JWT token string to store.
    static func save(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Delete any existing token first
        SecItemDelete(query as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            os_log("Failed to save token to Keychain: %{public}d", log: .auth, type: .error, status)
        }
    }

    /// Retrieve the stored JWT token from the Keychain.
    static var token: String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Clear the stored JWT token from the Keychain.
    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - AuthService

/// Handles Apple Sign In, Google Sign In, and Firebase token exchange.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published
    var isAuthenticated = false
    @Published
    var displayName: String?

    private let log = OSLog(subsystem: "site.waterlee.aidic", category: "Auth")

    private init() {
        isAuthenticated = TokenStore.token != nil
    }

    // MARK: - Apple Sign In

    /// Perform Apple Sign In using AuthenticationServices.
    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleSignInDelegate { [weak self] credential in
            await self?.handleAppleCredential(credential)
        }
        controller.performRequests()
    }

    private func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8)
        else {
            os_log("Apple Sign In: missing identity token", log: log, type: .error)
            return
        }

        let fullName = credential.fullName
        if let givenName = fullName?.givenName {
            displayName = [givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        }

        do {
            try await exchangeFirebaseToken(idToken: tokenString)
        } catch {
            os_log(
                "Apple Sign In token exchange failed: %{public}@",
                log: log,
                type: .error,
                error.localizedDescription
            )
        }
    }

    // MARK: - Google Sign In

    /// Perform Google Sign In using the GoogleSignIn SDK.
    func signInWithGoogle() async throws {
        guard let presentingWindow = NSApp.windows.first else {
            os_log("Google Sign In: no presenting window", log: log, type: .error)
            return
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)
        guard let idToken = result.user.idToken?.tokenString else {
            os_log("Google Sign In: missing ID token", log: log, type: .error)
            return
        }

        displayName = result.user.profile?.name

        do {
            try await exchangeFirebaseToken(idToken: idToken)
        } catch {
            os_log(
                "Google Sign In token exchange failed: %{public}@",
                log: log,
                type: .error,
                error.localizedDescription
            )
        }
    }

    // MARK: - Firebase Token Exchange

    /// Exchange a Firebase ID token for a server JWT.
    /// - Parameter idToken: The Firebase ID token from Apple or Google Sign In.
    func exchangeFirebaseToken(idToken: String) async throws {
        #if DEBUG
            let baseURL = "http://localhost:3000"
        #else
            let baseURL = "https://ai-dictionary-server.fly.dev"
        #endif

        guard let url = URL(string: "\(baseURL)/api/auth/firebase") else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "idToken": idToken
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            os_log(
                "Firebase token exchange failed with status: %{public}d",
                log: log,
                type: .error,
                httpResponse.statusCode
            )
            throw AuthError.serverError(httpResponse.statusCode)
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String {
            TokenStore.save(token)
            isAuthenticated = true
        } else {
            throw AuthError.noToken
        }
    }

    // MARK: - Sign Out

    /// Sign out the current user and clear stored credentials.
    func signOut() {
        TokenStore.clear()
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        displayName = nil
        os_log("User signed out", log: log, type: .info)
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noToken
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .invalidResponse:
            "Invalid response from server"
        case let .serverError(code):
            "Server error: \(code)"
        case .noToken:
            "No authentication token received"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - AppleSignInDelegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (ASAuthorizationAppleIDCredential) -> Void

    init(completion: @escaping (ASAuthorizationAppleIDCredential) -> Void) {
        self.completion = completion
        super.init()
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        completion(credential)
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        os_log("Apple Sign In error: %{public}@", log: .auth, type: .error, error.localizedDescription)
    }
}

// MARK: - OSLog extension

private extension OSLog {
    static let auth = OSLog(subsystem: "site.waterlee.aidic", category: "Auth")
}
