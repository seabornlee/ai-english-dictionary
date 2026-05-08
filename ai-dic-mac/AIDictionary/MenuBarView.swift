import SwiftUI

// MARK: - Design System Colors (per DESIGN.md)
private enum DesignColors {
    // Primary
    static let forestGreen = Color(hex: "#2C5F2D")
    static let forestHover = Color(hex: "#3A7A3B")
    static let sage = Color(hex: "#97BC62")

    // Neutrals (Warm Gray Family)
    static let paper = Color(hex: "#F8F6F3")
    static let warm100 = Color(hex: "#E8E4DF")
    static let warm200 = Color(hex: "#D4CFC8")
    static let warm500 = Color(hex: "#9A9590")
    static let warm700 = Color(hex: "#6B6763")
    static let warm900 = Color(hex: "#4A4744")

    // Semantic
    static let error = Color(hex: "#B54A4A")
    static let errorBg = Color(hex: "#FEF2F2")
    static let errorText = Color(hex: "#991B1B")

    // Online indicator
    static let online = Color(hex: "#2C5F2D")

    // Dark mode
    static let darkBg = Color(hex: "#1C1B1A")
    static let darkSurface = Color(hex: "#252422")
    static let darkElevated = Color(hex: "#2E2C2A")
    static let darkText = Color(hex: "#E8E6E3")
    static let darkTextSecondary = Color(hex: "#B8B5B2")
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
        .background(Color(nsColor: .controlBackgroundColor))
        // VAL-LOOKUP-009: Reset state every time the popover appears
        .onAppear {
            resetToFreshState()
            // VAL-LOOKUP-003: Auto-focus search field on popup open
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFieldFocused = true
            }
        }
        // VAL-LOOKUP-021: Escape key closes the popup
        .onKeyPress(.escape) {
            NSApp.keyWindow?.performClose(nil)
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

    // MARK: - Header
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
                        .foregroundColor(Color(nsColor: .labelColor))
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
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
        }
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))

            TextField("Search any word…", text: $searchText)
                .font(.system(size: 13, weight: .medium))
                .textFieldStyle(.plain)
                .focused($isSearchFieldFocused)
                .onSubmit(performSearch)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSearchFieldFocused ? DesignColors.forestGreen : Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Tab Bar
    private var tabBarView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(MenuBarTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? DesignColors.forestGreen : Color(nsColor: .tertiaryLabelColor))
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
    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Looking up…")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Error Card
    /// VAL-LOOKUP-008: User-readable error message (not raw exception names)
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
    private func definitionCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.term)
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(Color(nsColor: .labelColor))
                        .tracking(-0.5)

                    if let pronunciation = word.pronunciation, !pronunciation.isEmpty {
                        Text("/\(pronunciation)/")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
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
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .lineSpacing(4)

            if !keywordChips(from: word.definition, excluding: word.term).isEmpty {
                HStack(spacing: 6) {
                    ForEach(keywordChips(from: word.definition, excluding: word.term), id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(nsColor: .secondaryLabelColor))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Example Card
    private func exampleCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignColors.sage)

                Spacer()

                Text("Examples")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                    .textCase(.uppercase)
            }

            ForEach(word.exampleSentences.prefix(2), id: \.self) { sentence in
                Text("\"\(sentence)\"")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Empty State Card
    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 28))
                .foregroundColor(DesignColors.sage)

            Text("Search for any word")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(nsColor: .labelColor))

            Text("Get instant definitions powered by AI")
                .font(.system(size: 12))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .lineSpacing(2)

            Text("Press ⌘⇧D to open this popup")
                .font(.system(size: 11))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Footer
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
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Search Logic

    /// VAL-LOOKUP-004: Typing a word and pressing Return triggers lookup
    /// VAL-LOOKUP-007: Empty or whitespace-only input handled gracefully (no API call)
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
                    wordStore.addToHistory(result)
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
