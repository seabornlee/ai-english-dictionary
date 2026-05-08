import SwiftUI
import AppKit

// MARK: - Design System Colors (per DESIGN.md, shared with MenuBarView)
// VAL-LOOKUP-020: Adaptive colors for dark/light mode in Share Extension
private enum ShareDesignColors {
    static var forestGreen: Color {
        Color(adaptingLight: Color(hex: "#2C5F2D"), dark: Color(hex: "#3A7A3B"))
    }
    static var sage: Color { Color(hex: "#97BC62") }
    static var error: Color { Color(hex: "#B54A4A") }
    static var errorBg: Color {
        Color(adaptingLight: Color(hex: "#FEF2F2"), dark: Color(hex: "#2E1C1C"))
    }
    static var errorText: Color {
        Color(adaptingLight: Color(hex: "#991B1B"), dark: Color(hex: "#E8A0A0"))
    }
    static var popupBackground: Color {
        Color(adaptingLight: Color(nsColor: .controlBackgroundColor), dark: Color(hex: "#1C1B1A"))
    }
    static var cardBackground: Color {
        Color(adaptingLight: Color(nsColor: .controlBackgroundColor), dark: Color(hex: "#252422"))
    }
    static var warm900: Color {
        Color(adaptingLight: Color(hex: "#4A4744"), dark: Color(hex: "#E8E6E3"))
    }
    static var warm700: Color {
        Color(adaptingLight: Color(hex: "#6B6763"), dark: Color(hex: "#B8B5B2"))
    }
    static var warm500: Color {
        Color(adaptingLight: Color(hex: "#9A9590"), dark: Color(hex: "#B8B5B2"))
    }
}

// MARK: - Color Light/Dark Adaptive Initializer (macOS)
private extension Color {
    /// Creates a color that adapts between light and dark appearances on macOS
    init(adaptingLight light: Color, dark: Color) {
        self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        }))
    }
}

// MARK: - Share Extension SwiftUI View
/// VAL-LOOKUP-016: Displays the definition for shared text within the
/// Share Extension UI, using the same definition rendering as the
/// menu bar popup (VAL-LOOKUP-018: identical definition across entry points).
///
/// VAL-LOOKUP-019: After a successful lookup, saves the full Word model to
/// the App Group shared container (via SharedLookupStore) so the main app
/// can add it to its history without a redundant API call.
///
/// VAL-LOOKUP-023: Non-text content shows "Text required for lookup" message.
struct ShareExtensionView: View {
    let initialWord: String
    let onDone: () -> Void

    @State private var word: String = ""
    @State private var isLoading = false
    @State private var searchResult: Word?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if isLoading {
                loadingView
            } else if let errorMessage {
                errorView(message: errorMessage)
            } else if let searchResult {
                definitionView(for: searchResult)
            } else {
                emptyStateView
            }

            footerView
        }
        .frame(width: 320, height: 240)
        // VAL-LOOKUP-020: Adaptive background for dark mode
        .background(ShareDesignColors.popupBackground)
        .onAppear {
            word = initialWord
            performLookup()
        }
    }

    // MARK: - Header
    // VAL-LOOKUP-020: Uses adaptive colors for dark mode
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ShareDesignColors.forestGreen)
                        .frame(width: 22, height: 22)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    Text("LexisDic")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ShareDesignColors.warm900)
                }

                Spacer()

                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShareDesignColors.forestGreen)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()
        }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Looking up…")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ShareDesignColors.warm700)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error
    // VAL-LOOKUP-020: Uses adaptive error colors for dark mode
    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Lookup Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ShareDesignColors.error)

            Text(message)
                .font(.system(size: 11))
                .foregroundColor(ShareDesignColors.errorText)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ShareDesignColors.errorBg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Definition (identical rendering to MenuBarView for VAL-LOOKUP-018)
    // VAL-LOOKUP-020: Uses adaptive colors for dark mode
    private func definitionView(for result: Word) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                // Word term
                Text(result.term)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(ShareDesignColors.warm900)

                // Pronunciation + part of speech
                HStack(spacing: 6) {
                    if let pronunciation = result.pronunciation, !pronunciation.isEmpty {
                        Text("/\(pronunciation)/")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(ShareDesignColors.warm500)
                    }

                    if let partOfSpeech = result.partOfSpeech, !partOfSpeech.isEmpty {
                        Text(partOfSpeech)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(ShareDesignColors.forestGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ShareDesignColors.forestGreen.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }

                // Definition text
                Text(result.definition)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(ShareDesignColors.warm700)
                    .lineSpacing(3)

                // Example sentences (compact, max 1)
                if let firstExample = result.exampleSentences.first {
                    Text("\"\(firstExample)\"")
                        .font(.system(size: 11))
                        .italic()
                        .foregroundColor(ShareDesignColors.warm500)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State
    // VAL-LOOKUP-023: Shows clear "Text required for lookup" message for non-text content
    // VAL-LOOKUP-020: Uses adaptive colors for dark mode
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 22))
                .foregroundColor(ShareDesignColors.sage)

            // VAL-LOOKUP-023: Clear indication that text is required for lookup.
            // This message appears when the shared content is non-text
            // (image, file, etc.) or when no text was extracted.
            Text("Text required for lookup")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(ShareDesignColors.warm900)

            Text("Share text to get a definition")
                .font(.system(size: 11))
                .foregroundColor(ShareDesignColors.warm500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer
    // VAL-LOOKUP-020: Uses adaptive colors for dark mode
    private var footerView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(ShareDesignColors.forestGreen)
                        .frame(width: 4, height: 4)
                    Text("Powered by AI")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(ShareDesignColors.warm500)
                }

                Spacer()

                if searchResult != nil {
                    Button("Open in App") {
                        openInMainApp()
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ShareDesignColors.forestGreen)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Lookup Logic

    /// VAL-LOOKUP-016: Perform lookup using the same APIService as the main app,
    /// ensuring identical definitions across all entry points (VAL-LOOKUP-018).
    ///
    /// VAL-LOOKUP-019: After a successful lookup, saves the full Word model to
    /// the App Group shared container via SharedLookupStore. The main app reads
    /// this data when it receives the Darwin notification, adding the result
    /// to its history without making a redundant API call.
    private func performLookup() {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.lookupWord(trimmed.lowercased(), unknownWords: [])
                await MainActor.run {
                    searchResult = result
                    word = result.term
                    isLoading = false

                    // VAL-LOOKUP-019 / VAL-LOOKUP-024: Save the full Word result
                    // to the shared App Group container. SharedLookupStore handles
                    // both the full result (for history) and the Darwin notification.
                    SharedLookupStore.shared.saveLookupResult(result)
                }
            } catch {
                await MainActor.run {
                    errorMessage = userReadableMessage(from: error)
                    isLoading = false
                }
            }
        }
    }

    /// Signal the main app to open and show the definition
    private func openInMainApp() {
        SharedLookupStore.shared.postWordUpdatedNotification()
    }

    /// Convert technical errors to user-friendly messages (same as MenuBarView)
    private func userReadableMessage(from error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                return "Could not connect to the server. Please check your internet connection."
            case .serverError:
                return "The server encountered an error. Please try again later."
            case .invalidResponse:
                return "Received an unexpected response from the server."
            case .decodingError:
                return "Could not understand the server's response."
            case .invalidURL:
                return "Could not reach the dictionary service."
            case .noData:
                return "No data was received from the server."
            }
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Color Hex Extension (same as used in main app)
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
