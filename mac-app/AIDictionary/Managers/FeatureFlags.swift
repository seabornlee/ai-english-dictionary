import Foundation
import os.log

/// Simple feature flag system backed by UserDefaults.
enum FeatureFlag: String, CaseIterable {
    case newSignIn
    case vocabularySync
    case experimentalAPI
}

enum FeatureFlags {
    private static let defaults = UserDefaults.standard
    private static let prefix = "feature_"

    static func isEnabled(_ flag: FeatureFlag) -> Bool {
        let key = prefix + flag.rawValue
        return defaults.object(forKey: key) as? Bool ?? false
    }

    static func enable(_ flag: FeatureFlag) {
        defaults.set(true, forKey: prefix + flag.rawValue)
    }

    static func disable(_ flag: FeatureFlag) {
        defaults.set(false, forKey: prefix + flag.rawValue)
    }

    static func allFlags() -> [String: Bool] {
        FeatureFlag.allCases.reduce(into: [:]) { result, flag in
            result[flag.rawValue] = isEnabled(flag)
        }
    }
}
