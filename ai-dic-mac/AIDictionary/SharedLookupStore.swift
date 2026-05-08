import Foundation

// MARK: - Shared Lookup Store
/// VAL-LOOKUP-019 / VAL-LOOKUP-024: Manages shared lookup data between the main app
/// and extensions (Share Extension) via the App Group container.
///
/// The Share Extension saves lookup results (full Word model) to the shared
/// UserDefaults, and the main app reads them to maintain consistent history
/// across all entry points.
///
/// Cross-process signaling uses Darwin notifications:
/// - Extension posts `"group.site.waterlee.aidic.wordUpdated"` after saving
/// - Main app observes this notification and reads the shared data
final class SharedLookupStore {
    static let shared = SharedLookupStore()

    /// App Group identifier shared between main app and extensions
    static let appGroupIdentifier = "group.site.waterlee.aidic"

    /// Darwin notification name for cross-process signaling
    static let wordUpdatedNotification = "group.site.waterlee.aidic.wordUpdated"

    /// Keys for shared UserDefaults
    private enum Keys {
        static let sharedWord = "sharedWord"
        static let sharedWordTimestamp = "sharedWordTimestamp"
        static let sharedWordResult = "sharedWordResult"
        static let sharedLookupHistory = "sharedLookupHistory"
    }

    private let sharedDefaults: UserDefaults?

    private init() {
        sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    // MARK: - Save (called by Share Extension)

    /// Save a complete lookup result to the shared container.
    /// Called by the Share Extension after a successful lookup.
    /// VAL-LOOKUP-019: The main app reads this to add to its history,
    /// ensuring consistent history across all entry points.
    func saveLookupResult(_ word: Word) {
        guard let defaults = sharedDefaults else { return }

        // Save the term for quick access
        defaults.set(word.term, forKey: Keys.sharedWord)
        defaults.set(Date(), forKey: Keys.sharedWordTimestamp)

        // Save the full Word model as JSON data
        // VAL-LOOKUP-024: Full data sharing via App Group container
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(word)
            defaults.set(data, forKey: Keys.sharedWordResult)
        } catch {
            // If encoding fails, at least the term is saved
            print("SharedLookupStore: Failed to encode word result: \(error)")
        }

        // Also append to the shared history array
        appendToSharedHistory(word)

        defaults.synchronize()

        // Post Darwin notification so main app picks it up
        postWordUpdatedNotification()
    }

    /// Save just the word term (for Services menu flow, which triggers
    /// lookup in the main app rather than in the extension).
    func saveWordTerm(_ term: String) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(term, forKey: Keys.sharedWord)
        defaults.set(Date(), forKey: Keys.sharedWordTimestamp)
        defaults.synchronize()
    }

    /// Post Darwin notification for cross-process communication
    func postWordUpdatedNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.wordUpdatedNotification as CFString),
            nil, nil, true
        )
    }

    // MARK: - Read (called by Main App)

    /// Read the last shared lookup result (full Word model).
    /// Returns nil if no result is available or decoding fails.
    /// VAL-LOOKUP-024: Main app reads extension's lookup result
    func readLookupResult() -> Word? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.sharedWordResult)
        else { return nil }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Word.self, from: data)
        } catch {
            print("SharedLookupStore: Failed to decode word result: \(error)")
            return nil
        }
    }

    /// Read just the shared word term.
    func readWordTerm() -> String? {
        return sharedDefaults?.string(forKey: Keys.sharedWord)
    }

    /// Read the timestamp of the last shared word.
    func readWordTimestamp() -> Date? {
        return sharedDefaults?.object(forKey: Keys.sharedWordTimestamp) as? Date
    }

    /// Clear the shared result after the main app has consumed it.
    func clearSharedResult() {
        sharedDefaults?.removeObject(forKey: Keys.sharedWordResult)
        sharedDefaults?.removeObject(forKey: Keys.sharedWord)
        sharedDefaults?.removeObject(forKey: Keys.sharedWordTimestamp)
        sharedDefaults?.synchronize()
    }

    // MARK: - Shared History (VAL-LOOKUP-019)

    /// Append a lookup result to the shared history array.
    /// Both the main app and extensions write to this array.
    private func appendToSharedHistory(_ word: Word) {
        guard let defaults = sharedDefaults else { return }

        var history = loadSharedHistory()

        // Remove duplicate entries (same term) to keep history clean
        history.removeAll(where: { $0.term == word.term })

        // Insert at the beginning (most recent first)
        history.insert(word, at: 0)

        // Keep max 100 entries
        if history.count > 100 {
            history = Array(history.prefix(100))
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            defaults.set(data, forKey: Keys.sharedLookupHistory)
        } catch {
            print("SharedLookupStore: Failed to encode shared history: \(error)")
        }
    }

    /// Add a lookup result to the shared history from the main app.
    /// VAL-LOOKUP-019: All entry points write to the same shared history.
    func addToSharedHistory(_ word: Word) {
        appendToSharedHistory(word)
    }

    /// Load the shared history array from the App Group container.
    func loadSharedHistory() -> [Word] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.sharedLookupHistory)
        else { return [] }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Word].self, from: data)
        } catch {
            print("SharedLookupStore: Failed to decode shared history: \(error)")
            return []
        }
    }

    /// Clear the shared history.
    func clearSharedHistory() {
        sharedDefaults?.removeObject(forKey: Keys.sharedLookupHistory)
        sharedDefaults?.synchronize()
    }
}
