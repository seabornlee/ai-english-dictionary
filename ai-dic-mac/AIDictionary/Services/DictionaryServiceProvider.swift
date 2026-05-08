import AppKit

// MARK: - Notification Name for Service-Initiated Lookup
extension Notification.Name {
    /// Posted when the NSServices menu handler receives selected text.
    /// UserInfo contains "word" (String) — the trimmed text from the pasteboard.
    static let defineWordService = Notification.Name("DefineWordService")
}

// MARK: - DictionaryServiceProvider
/// VAL-LOOKUP-011 / VAL-LOOKUP-012: NSServices provider that receives selected text
/// from any application and triggers a word lookup in LexisDic.
///
/// Registered in `AppDelegate.applicationDidFinishLaunching` via
/// `NSApplication.shared.servicesProvider = DictionaryServiceProvider()`.
///
/// The service is declared in Info.plist under the `NSServices` key with:
/// - Menu item title: "Look up in LexisDic"
/// - Message selector: `defineWord:userData:error:`
/// - Accepts: `NSStringPboardType` (plain text)
/// - Required context: up to 5 words selected
///
/// When invoked, the provider extracts text from the pasteboard,
/// trims whitespace, and posts a `Notification.Name.defineWordService`
/// notification. The main app's `MenuBarView` observes this notification
/// to populate the search field and trigger the lookup flow.
final class DictionaryServiceProvider: NSObject {

    // MARK: - Service Handler

    /// VAL-LOOKUP-012: Called by macOS when the user invokes "Look up in LexisDic"
    /// from the Services context menu in any application.
    ///
    /// VAL-LOOKUP-014: Handles empty and non-text selections gracefully —
    /// no crash, no API call with empty/invalid payload.
    @objc func defineWord(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        // VAL-LOOKUP-014: Extract text; if none available, return silently
        guard let selectedText = pasteboard.string(forType: .string) else {
            // No text on pasteboard — non-text selection (image, file, etc.)
            // Graceful: do nothing, no crash, no invalid API call
            return
        }

        let word = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)

        // VAL-LOOKUP-014: Empty/whitespace-only selection handled gracefully
        guard !word.isEmpty else {
            // Empty text — do nothing
            return
        }

        // VAL-LOOKUP-012: Post notification with the word; main app will
        // activate, open the menu bar popup, and trigger lookup
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .defineWordService,
                object: nil,
                userInfo: ["word": word]
            )

            // Activate the app so the popup is visible
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
