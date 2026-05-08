import AppKit
import SwiftUI

// MARK: - Share Extension View Controller
/// VAL-LOOKUP-015 / VAL-LOOKUP-016: macOS Share Extension that receives shared text,
/// performs a word lookup using the same APIService as the main app, and displays
/// the definition in a compact SwiftUI view.
///
/// The extension communicates with the main app via:
/// 1. App Group shared UserDefaults (`group.site.waterlee.aidic`) for data
/// 2. Darwin notifications for cross-process signaling
///
/// VAL-LOOKUP-017: Dismisses cleanly via the Done button or when the user
/// cancels the share sheet. Always calls `extensionContext.completeRequest()`
/// to return control to the host app.
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
    /// VAL-LOOKUP-023: Non-text content is handled gracefully —
    /// returns empty string which shows "No text to look up" in the UI.
    private func extractSharedText(completion: @escaping (String) -> Void) {
        guard let context = extensionContext,
              let item = context.inputItems.first as? NSExtensionItem,
              let itemProvider = item.attachments?.first
        else {
            // No input items — non-text or empty content
            completion("")
            return
        }

        // Try loading as plain text
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
                    // VAL-LOOKUP-023: Could not extract text — non-text content
                    text = ""
                }
                DispatchQueue.main.async {
                    completion(text)
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            // URL-only content, extract URL string
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (data: NSSecureCoding?, error: (any Error)?) in
                guard self != nil else { return }
                let text: String
                if let url = data as? URL {
                    text = url.absoluteString
                } else if let urlData = data as? Data,
                          let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                    text = url.absoluteString
                } else {
                    text = ""
                }
                DispatchQueue.main.async {
                    completion(text)
                }
            }
        } else {
            // VAL-LOOKUP-023: Unsupported content type
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
