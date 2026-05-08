import SwiftUI

// MARK: - Design System Colors (per DESIGN.md, shared with MenuBarView)
private enum ShareDesignColors {
    static let forestGreen = Color(hex: "#2C5F2D")
    static let sage = Color(hex: "#97BC62")
    static let error = Color(hex: "#B54A4A")
    static let errorBg = Color(hex: "#FEF2F2")
    static let errorText = Color(hex: "#991B1B")
}

// MARK: - Share Extension SwiftUI View
/// VAL-LOOKUP-016: Displays the definition for shared text within the
/// Share Extension UI, using the same definition rendering as the
/// menu bar popup (VAL-LOOKUP-018: identical definition across entry points).
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
        .background(Color(nsColor: .controlBackgroundColor))
        .onAppear {
            word = initialWord
            performLookup()
        }
    }

    // MARK: - Header
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
                        .foregroundColor(Color(nsColor: .labelColor))
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
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error
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
    private func definitionView(for result: Word) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                // Word term
                Text(result.term)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(Color(nsColor: .labelColor))

                // Pronunciation + part of speech
                HStack(spacing: 6) {
                    if let pronunciation = result.pronunciation, !pronunciation.isEmpty {
                        Text("/\(pronunciation)/")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
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
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .lineSpacing(3)

                // Example sentences (compact, max 1)
                if let firstExample = result.exampleSentences.first {
                    Text("\"\(firstExample)\"")
                        .font(.system(size: 11))
                        .italic()
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 22))
                .foregroundColor(ShareDesignColors.sage)

            Text("No text to look up")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))

            Text("Share text to get a definition")
                .font(.system(size: 11))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer
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
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
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

                    // Save the word to shared UserDefaults so the main app can see it
                    saveWordToSharedContainer(result.term)

                    // Post Darwin notification so main app picks it up
                    postWordUpdatedNotification()
                }
            } catch {
                await MainActor.run {
                    errorMessage = userReadableMessage(from: error)
                    isLoading = false
                }
            }
        }
    }

    /// Save the looked-up word to the App Group shared container
    private func saveWordToSharedContainer(_ word: String) {
        let sharedDefaults = UserDefaults(suiteName: "group.site.waterlee.aidic")
        sharedDefaults?.set(word, forKey: "sharedWord")
        sharedDefaults?.set(Date(), forKey: "sharedWordTimestamp")
    }

    /// Post Darwin notification for cross-process communication
    private func postWordUpdatedNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("group.site.waterlee.aidic.wordUpdated" as CFString),
            nil, nil, true
        )
    }

    /// Signal the main app to open and show the definition
    private func openInMainApp() {
        postWordUpdatedNotification()
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
