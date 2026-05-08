import Foundation
import Security
import AppKit

enum LicenseError: Error {
    case noReceipt
    case activationFailed(String)
    case networkError(Error)
    case invalidResponse
    case noLicenseToken
    case keychainError(OSStatus)
}

struct LicenseActivationResponse: Codable {
    let success: Bool
    let token: String?
    let licenseId: String?
    let message: String?
    let error: String?
    let code: String?
}

struct LicenseStatusResponse: Codable {
    let valid: Bool
    let licenseId: String?
    let bundleId: String?
    let appVersion: String?
    let originalPurchaseDate: String?
    let expirationDate: String?
    let lastValidationDate: String?
}

class LicenseManager {
    static let shared = LicenseManager()

    private let authBaseURL = "http://localhost:3000/api/auth"
    private let keychainService = "com.qidao.ai-dictionary"
    private let licenseTokenKey = "license_token"

    private init() {}

    // MARK: - Receipt

    private func getReceiptData() -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return nil
        }

        guard FileManager.default.fileExists(atPath: receiptURL.path) else {
            return nil
        }

        return try? Data(contentsOf: receiptURL)
    }

    private func getReceiptBase64() -> String? {
        guard let receiptData = getReceiptData() else {
            return nil
        }
        return receiptData.base64EncodedString()
    }

    // MARK: - Device ID

    private func getDeviceId() -> String {
        if let existingId = getFromKeychain(key: "device_id") {
            return existingId
        }

        let newId = UUID().uuidString
        saveToKeychain(key: "device_id", value: newId)
        return newId
    }

    // MARK: - Bundle Info

    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - License Token

    func getLicenseToken() -> String? {
        return getFromKeychain(key: licenseTokenKey)
    }

    func hasLicense() -> Bool {
        return getLicenseToken() != nil
    }

    // MARK: - Activation

    func activateLicense() async throws {
        guard let receipt = getReceiptBase64() else {
            throw LicenseError.noReceipt
        }

        let deviceId = getDeviceId()
        let url = URL(string: "\(authBaseURL)/activate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "receipt": receipt,
            "deviceId": deviceId,
            "bundleId": bundleId,
            "appVersion": appVersion,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LicenseError.activationFailed(errorMessage)
        }

        let decoder = JSONDecoder()
        let activationResponse = try decoder.decode(LicenseActivationResponse.self, from: data)

        if activationResponse.success, let token = activationResponse.token {
            saveToKeychain(key: licenseTokenKey, value: token)
        } else {
            let errorMsg = activationResponse.error ?? activationResponse.message ?? "Activation failed"
            throw LicenseError.activationFailed(errorMsg)
        }
    }

    func checkLicenseStatus() async throws -> LicenseStatusResponse {
        guard let token = getLicenseToken() else {
            throw LicenseError.noLicenseToken
        }

        let url = URL(string: "\(authBaseURL)/license-status")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw LicenseError.activationFailed("License check failed: \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(LicenseStatusResponse.self, from: data)
    }

    // MARK: - Keychain

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data

        SecItemAdd(newQuery as CFDictionary, nil)
    }

    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return string
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }

    func clearLicense() {
        deleteFromKeychain(key: licenseTokenKey)
    }
}
