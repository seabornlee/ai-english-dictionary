import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            updateLocale()
        }
    }

    var appName: String {
        currentLanguage == "zh-Hans" ? "浪溪词典" : "CleverDict"
    }

    var appNameWithEnglish: String {
        currentLanguage == "zh-Hans" ? "浪溪词典 (CleverDict)" : "CleverDict"
    }

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           LocalizationManager.supportedLanguages.contains(savedLanguage) {
            self.currentLanguage = savedLanguage
        } else {
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            self.currentLanguage = LocalizationManager.supportedLanguages.contains(preferredLanguage) ? preferredLanguage : "en"
        }
        updateLocale()
    }

    static let supportedLanguages = ["en", "zh-Hans"]
    static let languageNames = [
        "en": "English",
        "zh-Hans": "简体中文"
    ]

    func setLanguage(_ language: String) {
        guard LocalizationManager.supportedLanguages.contains(language) else { return }
        currentLanguage = language
    }

    private func updateLocale() {}
}

private enum AppLocalization {
    static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
            return .module
        #else
            return .main
        #endif
    }

    static var currentLanguage: String {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           LocalizationManager.supportedLanguages.contains(savedLanguage) {
            return savedLanguage
        }

        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        if LocalizationManager.supportedLanguages.contains(preferredLanguage) {
            return preferredLanguage
        }

        if preferredLanguage.lowercased().hasPrefix("zh") {
            return "zh-Hans"
        }

        return "en"
    }

    static func localizedString(forKey key: String, table tableName: String? = nil) -> String {
        let candidates = [
            currentLanguage,
            currentLanguage.lowercased(),
            "en",
        ]

        for candidate in candidates {
            guard let path = resourceBundle.path(forResource: candidate, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                continue
            }

            let localizedValue = bundle.localizedString(forKey: key, value: nil, table: tableName)
            if localizedValue != key {
                return localizedValue
            }
        }

        return resourceBundle.localizedString(forKey: key, value: nil, table: tableName)
    }
}

func NSLocalizedString(_ key: String, comment: String) -> String {
    AppLocalization.localizedString(forKey: key)
}

func localized(_ key: String, _ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, arguments: arguments)
}

extension Text {
    init(localized key: String) {
        self.init(NSLocalizedString(key, comment: ""))
    }
}
