import AppKit
import SwiftUI

// MARK: - Share Extension View Controller
/// VAL-LOOKUP-015 / VAL-LOOKUP-016: macOS Share Extension that receives shared text,
/// performs a word lookup using the same APIService as the main app, and displays
/// the definition in a compact SwiftUI view.
///
/// The extension communicates with the main app via:
/// 1. App Group shared UserDefaults (`group.site.waterlee.aidic`) for data —
///    saves the full Word model (not just the term) so the main app can add
///    it to history without a redundant API call (VAL-LOOKUP-019).
/// 2. Darwin notifications for cross-process signaling
///
/// VAL-LOOKUP-017: Dismisses cleanly via the Done button or when the user
/// cancels the share sheet. Always calls `extensionContext.completeRequest()`
/// to return control to the host app.
///
/// VAL-LOOKUP-023: Non-text content (images, files, URLs without text) is
/// handled gracefully — the extension shows a clear "Text required for lookup"
/// message and does not crash or send invalid API requests.
class ShareExtensionViewController: NSViewController {

    private var hostingView: NSHostingView<ShareExtensionView>?
    private var extractedText: String = ""

    // MARK: - Lifecycle

    override func loadView() {
        // Extract text from the extension context before creating the view
        extractSharedText { [weak self] text in
            guard let self else { return }

            self.extractedText = text

            // Create SwiftUI view with the extracted text
            let shareView = ShareExtensionView(
                initialWord: text,
                onDone: { [weak self] in
                    self?.dismissExtension()
                }
            )

            let hosting = NSHostingView(rootView: shareView)
            hosting.frame = NSRect(x: 0, y: 0, width: 320, height: 240)
            hosting.autoresizingMask = [.width, .height]
            self.hostingView = hosting
            self.view = hosting
        }
    }

    // MARK: - Text Extraction

    /// Extract shared text from the NSExtensionContext.
    /// Supports plain text items shared from any app.
    ///
    /// VAL-LOOKUP-023: Non-text content is handled gracefully:
    /// - Images, files, binary data: returns empty string → UI shows "Text required for lookup"
    /// - No crash, no API call with invalid payload
    /// - The NSExtensionActivationRule already limits activation to text content
    ///   (NSExtensionActivationSupportsText = 1), but some apps may share mixed
    ///   content, so we still handle non-text gracefully as a safety net.
    private func extractSharedText(completion: @escaping (String) -> Void) {
        guard let context = extensionContext,
              let item = context.inputItems.first as? NSExtensionItem,
              let itemProvider = item.attachments?.first
        else {
            // No input items — non-text or empty content
            // VAL-LOOKUP-023: Graceful handling
            completion("")
            return
        }

        // Try loading as plain text first
        if itemProvider.hasItemConformingToTypeIdentifier("public.plain-text") {
            itemProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { [weak self] (data: NSSecureCoding?, error: (any Error)?) in
                guard self != nil else { return }
                let text: String
                if let data = data as? Data,
                   let decoded = String(data: data, encoding: .utf8) {
                    text = decoded
                } else if let stringData = data as? String {
                    text = stringData
                } else {
                    // VAL-LOOKUP-023: Could not decode text from data
                    text = ""
                }
                DispatchQueue.main.async {
                    completion(text)
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            // URL-only content — extract the URL string.
            // Note: URLs are not typical dictionary lookup content, but we
            // extract the string representation to avoid showing an empty view.
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (data: NSSecureCoding?, error: (any Error)?) in
                guard self != nil else { return }
                let text: String
                if let url = data as? URL {
                    text = url.absoluteString
                } else if let urlData = data as? Data,
                          let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                    text = url.absoluteString
                } else {
                    // VAL-LOOKUP-023: Could not extract URL
                    text = ""
                }
                DispatchQueue.main.async {
                    completion(text)
                }
            }
        } else {
            // VAL-LOOKUP-023: Unsupported content type (image, file, etc.)
            // The extension does not appear for non-text content due to
            // NSExtensionActivationSupportsText = 1, but if we end up here,
            // show a clear message instead of crashing.
            completion("")
        }
    }

    // MARK: - Dismissal

    /// VAL-LOOKUP-017: Dismiss the extension cleanly.
    /// Calls `completeRequest(returningItems: [])` to signal the host app
    /// that the extension is done. The host app returns to its prior state.
    private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
