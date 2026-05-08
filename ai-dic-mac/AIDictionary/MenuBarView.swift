import SwiftUI
import AppKit

// MARK: - Notification for closing the popover from SwiftUI
extension Notification.Name {
    /// Posted by MenuBarView when the user presses Escape.
    /// AppDelegate observes this to close the NSPopover.
    static let closePopover = Notification.Name("ClosePopover")
}

// MARK: - Design System Colors (per DESIGN.md)
// VAL-LOOKUP-020: Colors adapt to light/dark mode per DESIGN.md palette.
private enum DesignColors {
    // Primary — forest green in light, desaturated green in dark
    static var forestGreen: Color {
        Color(adaptingLight: Color(hex: "#2C5F2D"), dark: Color(hex: "#3A7A3B"))
    }
    static var forestHover: Color { Color(hex: "#3A7A3B") }
    static var sage: Color { Color(hex: "#97BC62") }

    // Neutrals (Warm Gray Family)
    static var paper: Color {
        Color(adaptingLight: Color(hex: "#F8F6F3"), dark: Color(hex: "#1C1B1A"))
    }
    static var warm100: Color {
        Color(adaptingLight: Color(hex: "#E8E4DF"), dark: Color(hex: "#252422"))
    }
    static var warm200: Color {
        Color(adaptingLight: Color(hex: "#D4CFC8"), dark: Color(hex: "#2E2C2A"))
    }
    static var warm500: Color {
        Color(adaptingLight: Color(hex: "#9A9590"), dark: Color(hex: "#B8B5B2"))
    }
    static var warm700: Color {
        Color(adaptingLight: Color(hex: "#6B6763"), dark: Color(hex: "#B8B5B2"))
    }
    static var warm900: Color {
        Color(adaptingLight: Color(hex: "#4A4744"), dark: Color(hex: "#E8E6E3"))
    }

    // Semantic — error colors stay consistent across modes
    static var error: Color { Color(hex: "#B54A4A") }
    static var errorBg: Color {
        Color(adaptingLight: Color(hex: "#FEF2F2"), dark: Color(hex: "#2E1C1C"))
    }
    static var errorText: Color {
        Color(adaptingLight: Color(hex: "#991B1B"), dark: Color(hex: "#E8A0A0"))
    }

    // Card backgrounds
    static var cardBackground: Color {
        Color(adaptingLight: Color(nsColor: .controlBackgroundColor), dark: Color(hex: "#252422"))
    }

    // Popup background
    static var popupBackground: Color {
        Color(adaptingLight: Color(nsColor: .controlBackgroundColor), dark: Color(hex: "#1C1B1A"))
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

// MARK: - MenuBar Popup View
struct MenuBarView: View {
    @EnvironmentObject private var wordStore: WordStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @EnvironmentObject var localizationManager: LocalizationManager

    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResult: Word?
    @State private var errorMessage: String?
    @State private var selectedTab: MenuBarTab = .dictionary

    // VAL-LOOKUP-003: Auto-focus search field when popup opens
    @FocusState private var isSearchFieldFocused: Bool

    enum MenuBarTab: String, CaseIterable {
        case dictionary = "Define"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBarView
            tabBarView
            contentView
            footerView
        }
        .frame(width: 320, height: 480)
        // VAL-LOOKUP-020: Adaptive background for light/dark mode
        .background(DesignColors.popupBackground)
        // VAL-LOOKUP-009: Reset state every time the popover appears
        .onAppear {
            resetToFreshState()
            // VAL-LOOKUP-019: Check for shared lookup results from extensions
            checkForSharedResults()
            // VAL-LOOKUP-003: Auto-focus search field on popup open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFieldFocused = true
            }
        }
        // VAL-LOOKUP-012 / VAL-LOOKUP-022: Receive word from NSServices menu invocation.
        // When the user selects text in another app and invokes
        // "Look up in LexisDic" from the Services context menu,
        // DictionaryServiceProvider posts this notification.
        // For multi-word selections, the full phrase is looked up.
        .onReceive(NotificationCenter.default.publisher(for: .defineWordService)) { notification in
            if let word = notification.userInfo?["word"] as? String {
                handleServiceWord(word)
            }
            // VAL-LOOKUP-019: Also check if the notification includes a
            // pre-fetched Word result from the Share Extension
            if let result = notification.userInfo?["result"] as? Word {
                handleSharedResult(result)
            }
        }
        // VAL-LOOKUP-021: Escape key closes the popover.
        // NSPopover is not a window, so NSApp.keyWindow?.performClose
        // doesn't work. Instead, post a notification that AppDelegate
        // observes to close its popover reference.
        .onKeyPress(.escape) {
            NotificationCenter.default.post(name: .closePopover, object: nil)
            return .handled
        }
    }

    // MARK: - State Management

    /// VAL-LOOKUP-009: Reset to fresh empty state when popup reopens
    private func resetToFreshState() {
        searchText = ""
        searchResult = nil
        errorMessage = nil
        isLoading = false
        selectedTab = .dictionary
    }

    /// VAL-LOOKUP-019: Check for lookup results shared by the Share Extension.
    /// When the Share Extension performs a lookup, it saves the full Word model
    /// to the App Group container and posts a Darwin notification. The AppDelegate
    /// receives the Darwin notification and opens the popover. Here we check
    /// for any pending shared results and display them.
    private func checkForSharedResults() {
        if let sharedResult = SharedLookupStore.shared.readLookupResult() {
            handleSharedResult(sharedResult)
            SharedLookupStore.shared.clearSharedResult()
        } else if let sharedTerm = SharedLookupStore.shared.readWordTerm() {
            // Only a term was shared (e.g., from Services menu) — trigger lookup
            handleServiceWord(sharedTerm)
            SharedLookupStore.shared.clearSharedResult()
        }
    }

    /// VAL-LOOKUP-019: Display a shared lookup result from the Share Extension.
    /// The result is added to the shared history so it's consistent across
    /// all entry points. No redundant API call is needed.
    private func handleSharedResult(_ result: Word) {
        searchText = result.term
        searchResult = result
        isLoading = false
        errorMessage = nil
        selectedTab = .dictionary
        isSearchFieldFocused = true

        // VAL-LOOKUP-019: Add to both the local history and shared history
        wordStore.addToHistory(result)
        SharedLookupStore.shared.addToSharedHistory(result)
    }

    /// VAL-LOOKUP-012 / VAL-LOOKUP-022: Handle word received from NSServices menu.
    /// Populates the search field and automatically triggers a lookup,
    /// providing the same definition rendering as a manual search
    /// (VAL-LOOKUP-013).
    ///
    /// VAL-LOOKUP-022: Multi-word selection handling:
    /// The NSServices declaration limits selections to 5 words (NSWordLimit: 5).
    /// For multi-word phrases (e.g., "ad hoc", "de facto"), the full phrase
    /// is looked up as-is. This is the deterministic behavior: the API receives
    /// the complete selected text and attempts to define it. If the phrase is
    /// not a valid dictionary entry, the standard error/no-result handling applies.
    private func handleServiceWord(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Set the search text and trigger the lookup
        // For multi-word phrases, the full text is preserved and sent
        searchText = trimmed
        isSearchFieldFocused = true
        performSearch()
    }

    // MARK: - Header
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.forestGreen)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    Text(localizationManager.appName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignColors.warm900)
                        .tracking(-0.3)
                }

                Spacer()

                // Network status indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(networkMonitor.isOnline ? DesignColors.forestGreen : Color.red.opacity(0.6))
                        .frame(width: 6, height: 6)

                    Text(networkMonitor.isOnline ? "Online" : "Offline")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(networkMonitor.isOnline ? DesignColors.forestGreen : Color.red.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DesignColors.warm100)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(DesignColors.warm200, lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
        }
    }

    // MARK: - Search Bar
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignColors.warm500)

            TextField("Search any word…", text: $searchText)
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(.plain)
                .focused($isSearchFieldFocused)
                .onSubmit(performSearch)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(DesignColors.warm500)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DesignColors.warm100)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSearchFieldFocused ? DesignColors.forestGreen : DesignColors.warm200, lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Tab Bar
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private var tabBarView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(MenuBarTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? DesignColors.forestGreen : DesignColors.warm500)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? DesignColors.forestGreen.opacity(0.08) : Color.clear)
                            .overlay(
                                Rectangle()
                                    .fill(selectedTab == tab ? DesignColors.forestGreen : Color.clear)
                                    .frame(height: 2),
                                alignment: .bottom
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)

            Divider()
        }
    }

    // MARK: - Content Area
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                switch selectedTab {
                case .dictionary:
                    dictionaryContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var dictionaryContent: some View {
        if isLoading {
            // VAL-LOOKUP-005: Loading indicator appears during lookup
            loadingCard
        } else if let errorMessage {
            // VAL-LOOKUP-008: User-readable error message
            errorCard(message: errorMessage)
        } else if let searchResult {
            // VAL-LOOKUP-006: Definition appears in results area on success
            definitionCard(for: searchResult)
            exampleCard(for: searchResult)
        } else {
            emptyStateCard
        }
    }

    // MARK: - Loading Card
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Looking up…")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignColors.warm700)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(DesignColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Error Card
    /// VAL-LOOKUP-008: User-readable error message (not raw exception names)
    /// VAL-LOOKUP-020: Error card uses adaptive dark mode colors
    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Lookup Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignColors.error)

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(DesignColors.errorText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignColors.errorBg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Definition Card
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private func definitionCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.term)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(DesignColors.warm900)
                        .tracking(-0.5)

                    if let pronunciation = word.pronunciation, !pronunciation.isEmpty {
                        Text("/\(pronunciation)/")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignColors.warm500)
                    }

                    if let partOfSpeech = word.partOfSpeech, !partOfSpeech.isEmpty {
                        Text(partOfSpeech)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DesignColors.forestGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DesignColors.forestGreen.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }

            Text(word.definition)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(DesignColors.warm700)
                .lineSpacing(4)

            if !keywordChips(from: word.definition, excluding: word.term).isEmpty {
                HStack(spacing: 6) {
                    ForEach(keywordChips(from: word.definition, excluding: word.term), id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignColors.warm700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DesignColors.warm100)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(DesignColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Example Card
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private func exampleCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignColors.sage)

                Spacer()

                Text("Examples")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignColors.warm500)
                    .textCase(.uppercase)
            }

            ForEach(word.exampleSentences.prefix(2), id: \.self) { sentence in
                Text("\"\(sentence)\"")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(DesignColors.warm700)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(DesignColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Empty State Card
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 28))
                .foregroundColor(DesignColors.sage)

            Text("Search for any word")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(DesignColors.warm900)

            Text("Get instant definitions powered by AI")
                .font(.system(size: 12))
                .foregroundColor(DesignColors.warm700)
                .lineSpacing(2)

            Text("Press ⌘⇧D to open this popup")
                .font(.system(size: 11))
                .foregroundColor(DesignColors.warm500)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DesignColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Footer
    // VAL-LOOKUP-020: Uses adaptive colors for light/dark mode
    private var footerView: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                Button(action: openMainWindow) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Open App")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(DesignColors.forestGreen)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(DesignColors.forestGreen)
                        .frame(width: 5, height: 5)
                    Text("Powered by AI")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignColors.warm500)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Search Logic

    /// VAL-LOOKUP-004: Typing a word and pressing Return triggers lookup
    /// VAL-LOOKUP-007: Empty or whitespace-only input handled gracefully (no API call)
    /// VAL-LOOKUP-019: Result is added to both local and shared history
    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.lookupWord(trimmed.lowercased(), unknownWords: [])
                await MainActor.run {
                    searchResult = result
                    searchText = result.term
                    isLoading = false
                    selectedTab = .dictionary

                    // VAL-LOOKUP-019: Add to local history AND shared App Group
                    // history so all entry points see the same results
                    wordStore.addToHistory(result)
                    SharedLookupStore.shared.addToSharedHistory(result)
                }
            } catch {
                await MainActor.run {
                    // VAL-LOOKUP-008: Show user-readable error messages
                    errorMessage = userReadableMessage(from: error)
                    isLoading = false
                }
            }
        }
    }

    /// Convert technical errors to user-friendly messages
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
        // Fallback for unknown errors
        return "An unexpected error occurred. Please try again."
    }

    // MARK: - Helpers
    private func keywordChips(from definition: String, excluding term: String) -> [String] {
        let words = definition.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 4 && !$0.lowercased().contains(term.lowercased()) }
        return Array(words.prefix(4))
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: {
            $0.title != "" && !String(describing: type(of: $0.contentView)).contains("MenuBarView")
        }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(WordStore())
        .environmentObject(NetworkMonitor.shared)
        .environmentObject(ClipboardManager.shared)
        .environmentObject(LocalizationManager.shared)
}
