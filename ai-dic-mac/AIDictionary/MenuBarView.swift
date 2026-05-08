import SwiftUI

// MARK: - Linear Style Color System
private enum LinearColors {
    static let bg = Color(hex: "#fafafa")
    static let bgSubtle = Color(hex: "#f4f4f5")
    static let surface = Color(hex: "#ffffff")
    static let surfaceHover = Color(hex: "#f9f9fb")
    static let surfaceActive = Color(hex: "#f0f0f2")

    static let border = Color(hex: "#e4e4e7")
    static let borderHover = Color(hex: "#d1d1d6")
    static let borderFocus = Color(hex: "#8b5cf6")

    static let primary = Color(hex: "#8b5cf6")
    static let primaryHover = Color(hex: "#7c3aed")
    static let primaryLight = Color(hex: "#a78bfa")
    static let primaryBg = Color(hex: "#f3f0ff")
    static let primaryBgHover = Color(hex: "#ebe4ff")

    static let text = Color(hex: "#18181b")
    static let textSecondary = Color(hex: "#71717a")
    static let textTertiary = Color(hex: "#a1a1aa")

    static let online = Color(hex: "#10b981")
    static let onlineBg = Color(hex: "#f0fdf4")
}

// MARK: - MenuBar Window
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

    enum MenuBarTab: String, CaseIterable {
        case dictionary = "define"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBarView
            tabBarView
            contentView
            footerView
        }
        .frame(width: 320, height: 580)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 40, x: 0, y: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .onAppear(perform: seedInitialResult)
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [LinearColors.primary, LinearColors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "book.closed")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    Text(localizationManager.appName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(LinearColors.text)
                        .tracking(-0.3)
                }

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(LinearColors.online)
                        .frame(width: 6, height: 6)

                    Text(networkMonitor.isOnline ? "Online" : "Offline")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(LinearColors.online)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(LinearColors.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(LinearColors.border, lineWidth: 1)
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Rectangle()
                .fill(LinearColors.border)
                .frame(height: 1)
        }
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(LinearColors.textTertiary)

            TextField("", text: $searchText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(LinearColors.text)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search any word...")
                        .foregroundColor(LinearColors.textTertiary)
                        .font(.system(size: 13, weight: .medium))
                }
                .textFieldStyle(.plain)
                .onSubmit(performSearch)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(LinearColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(LinearColors.border, lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Tab Bar
    private var tabBarView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(MenuBarTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? LinearColors.primary : LinearColors.textTertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? LinearColors.primaryBg : Color.clear)
                            .overlay(
                                Rectangle()
                                    .fill(selectedTab == tab ? LinearColors.primary : Color.clear)
                                    .frame(height: 2),
                                alignment: .bottom
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)

            Rectangle()
                .fill(LinearColors.border)
                .frame(height: 1)
        }
    }

    private func iconFor(_ tab: MenuBarTab) -> String {
        switch tab {
        case .dictionary: return "book.closed"
        }
    }

    // MARK: - Content
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
            loadingCard
        } else if let errorMessage {
            errorCard(message: errorMessage)
        } else if let searchResult {
            definitionCard(for: searchResult)
            frequencyCard
            exampleCard(for: searchResult)
        } else {
            emptyStateCard
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Looking up...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(LinearColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Lookup Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#dc2626"))

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#991b1b"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#fef2f2"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func definitionCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.term)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(LinearColors.text)
                        .tracking(-0.8)

                    Text(word.pronunciation ?? "")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(LinearColors.textTertiary)

                    Text(word.partOfSpeech ?? "")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(LinearColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LinearColors.bgSubtle)
                        .clipShape(Capsule())
                }

                Spacer()
            }

            Text(word.definition)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(LinearColors.textSecondary)
                .lineSpacing(4)

            HStack(spacing: 6) {
                ForEach(keywordChips(from: word.definition, excluding: word.term), id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(LinearColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(LinearColors.bgSubtle)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var frequencyCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Usage Frequency")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(LinearColors.textTertiary)
                    .textCase(.uppercase)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LinearColors.bgSubtle)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [LinearColors.primary, LinearColors.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * 0.76)
                    }
                }
                .frame(width: 100, height: 4)
            }

            Spacer()

            Text("Top 24%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(LinearColors.primary)
        }
        .padding(14)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func exampleCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(LinearColors.primary)

                Spacer()

                Text("Examples")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(LinearColors.textTertiary)
                    .textCase(.uppercase)
            }

            ForEach(word.exampleSentences.prefix(2), id: \.self) { sentence in
                Text("\"\(sentence)\"")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(LinearColors.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 28))
                .foregroundColor(LinearColors.textTertiary)

            Text("Search for any word")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(LinearColors.text)

            Text("Get instant definitions powered by AI")
                .font(.system(size: 12))
                .foregroundColor(LinearColors.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - History
    private var historyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if wordStore.searchHistory.isEmpty {
                emptyListState(
                    icon: "clock",
                    title: "No history yet",
                    description: "Your searched words will appear here"
                )
            } else {
                ForEach(wordStore.searchHistory.prefix(10)) { word in
                    wordListItem(word: word, showDate: true)
                }
            }
        }
    }

    private func emptyListState(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(LinearColors.textTertiary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(LinearColors.text)
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(LinearColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func wordListItem(word: Word, showDate: Bool = false) -> some View {
        Button(action: {
            searchResult = word
            searchText = word.term
            selectedTab = .dictionary
        }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.term)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(LinearColors.primary)

                    Text(word.definition.prefix(60) + (word.definition.count > 60 ? "..." : ""))
                        .font(.system(size: 11))
                        .foregroundColor(LinearColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if showDate {
                    Text(formatDate(word.timestamp))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(LinearColors.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(LinearColors.textTertiary)
            }
            .padding(12)
            .background(LinearColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Button(action: openMainWindow) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Open App")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(LinearColors.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(LinearColors.online)
                    .frame(width: 5, height: 5)
                Text("Powered by AI")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(LinearColors.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers
    private func keywordChips(from definition: String, excluding term: String) -> [String] {
        let words = definition.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 4 && !$0.lowercased().contains(term.lowercased()) }
        return Array(words.prefix(4))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func seedInitialResult() {
        guard searchResult == nil else { return }
        if let recentWord = wordStore.searchHistory.first {
            searchResult = recentWord
            searchText = recentWord.term
        }
    }

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
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(WordStore())
        .environmentObject(NetworkMonitor.shared)
        .environmentObject(ClipboardManager.shared)
        .environmentObject(LocalizationManager.shared)
}
