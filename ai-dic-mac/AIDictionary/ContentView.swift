import SwiftUI

// MARK: - Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - View Extension for Placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Linear Style Color System (Shared with MenuBarView)
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

    static let online = Color(hex: "#22c55e")
    static let onlineBg = Color(hex: "#f0fdf4")
}

// MARK: - Sidebar Selection
enum SidebarSelection: String, Hashable {
    case dictionary
    case history
}

// MARK: - Content View (Main Window)
struct ContentView: View {
    @EnvironmentObject private var wordStore: WordStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var localizationManager: LocalizationManager
    @ObservedObject private var speechCoordinator = SpeechCoordinator.shared

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResult: Word?
    @State private var markedWords = Set<String>()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var sidebarSelection: SidebarSelection? = .dictionary

    init(initialSearchText: String = "") {
        _searchText = State(initialValue: initialSearchText)
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $sidebarSelection)
                .frame(width: 220)

            Divider()

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(LinearColors.bg)
        .onAppear {
            wordStore.loadData()
            if !searchText.isEmpty {
                performSearch()
            }
        }
    }

    // MARK: - Detail View
    @ViewBuilder
    private var detailView: some View {
        switch sidebarSelection {
        case .dictionary, .none:
            mainContentView
        case .history:
            HistoryView()
                .environmentObject(wordStore)
        }
    }

    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerView
            contentAreaView
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(LinearColors.textTertiary)

                TextField("", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(LinearColors.text)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search any word...")
                            .foregroundColor(LinearColors.textTertiary)
                            .font(.system(size: 13, weight: .regular))
                    }
                    .onSubmit(performSearch)

                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(LinearColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(LinearColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LinearColors.border, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                Circle()
                    .fill(LinearColors.online)
                    .frame(width: 8, height: 8)

                Text(networkMonitor.isOnline ? "Online" : "Offline")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(LinearColors.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(LinearColors.surface)
    }

    // MARK: - Content Area
    private var contentAreaView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let error = errorMessage, !isLoading {
                    errorView(message: error)
                } else if let word = searchResult {
                    WordDisplayView(
                        word: word.term,
                        definition: word.definition,
                        pronunciation: word.pronunciation,
                        partOfSpeech: word.partOfSpeech,
                        exampleSentences: word.exampleSentences,
                        isLoading: isLoading,
                        error: nil,
                        markedWords: $markedWords,
                        onRegenerate: regenerateDefinition
                    )
                } else if isLoading {
                    loadingView
                } else {
                    emptyStateView
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, minHeight: 500)
        }
        .background(LinearColors.bg)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text("Looking up...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(LinearColors.textSecondary)
        }
        .padding(60)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "#dc2626"))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#991b1b"))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#fef2f2"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 48))
                .foregroundColor(LinearColors.textTertiary.opacity(0.5))

            Text("Search for any word")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(LinearColors.textSecondary)
        }
        .padding(80)
    }

    // MARK: - Actions
    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.lookupWord(
                    searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    unknownWords: []
                )

                await MainActor.run {
                    searchResult = result
                    isLoading = false
                    markedWords.removeAll()
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

    private func regenerateDefinition() {
        guard let word = searchResult else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.lookupWord(
                    word.term,
                    unknownWords: Array(markedWords)
                )

                await MainActor.run {
                    withAnimation {
                        searchResult = result
                        isLoading = false
                        markedWords.removeAll()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    @EnvironmentObject private var wordStore: WordStore
    @EnvironmentObject private var localizationManager: LocalizationManager

    private let bgColor = Color(hex: "#fafafa")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            logoSection

            sidebarItems

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .background(bgColor)
    }

    private var logoSection: some View {
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
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(LinearColors.text)
                .tracking(-0.3)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 28)
    }

    private var sidebarItems: some View {
        VStack(alignment: .leading, spacing: 2) {
            sidebarButton("Dictionary", systemImage: "book.closed", item: .dictionary)
            sidebarButton("History", systemImage: "clock", item: .history, count: wordStore.searchHistory.count)
        }
    }

    private func sidebarButton(_ title: String, systemImage: String, item: SidebarSelection, count: Int? = nil) -> some View {
        let isSelected = selection == item
        return Button(action: { selection = item }) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? LinearColors.primary : LinearColors.textSecondary)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? LinearColors.primary : LinearColors.textSecondary)

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isSelected ? LinearColors.primary : LinearColors.textTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(isSelected ? LinearColors.primaryBg : LinearColors.bgSubtle)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? LinearColors.primaryBg : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Word Display View (Linear Style)
struct WordDisplayView: View {
    let word: String
    let definition: String
    let pronunciation: String?
    let partOfSpeech: String?
    let exampleSentences: [String]
    let isLoading: Bool
    let error: String?
    @Binding var markedWords: Set<String>
    let onRegenerate: () -> Void

    @ObservedObject private var speechCoordinator = SpeechCoordinator.shared
    @State private var showingShareCard = false
    @State private var selectedShareTheme: ShareCardTheme = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                loadingState
            } else if let error {
                errorState(error)
            } else {
                wordHeader
                definitionSection
                examplesSection
            }
        }
        .padding(24)
        .background(LinearColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    // MARK: - Word Header
    private var wordHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(word)
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(LinearColors.text)
                    .tracking(-1.2)

                HStack(spacing: 10) {
                    if let pronunciation {
                        Text(pronunciation)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(LinearColors.textTertiary)

                        Button(action: { speechCoordinator.speak(word) }) {
                            Image(systemName: speechCoordinator.speakingText == word ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(LinearColors.primary)
                        }
                        .buttonStyle(.plain)
                    }

                    if let pos = partOfSpeech {
                        Text(pos)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(LinearColors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(LinearColors.primaryBg)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: { showingShareCard = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(LinearColors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(LinearColors.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onRegenerate) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(LinearColors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(LinearColors.bgSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Definition
    private var definitionSection: some View {
        HighlightableText(
            text: definition,
            markedWords: $markedWords
        )
    }

    // MARK: - Examples
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LinearColors.primary)

                Text("Examples")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(LinearColors.textTertiary)
                    .textCase(.uppercase)

                Spacer()

                Button(action: {
                    speechCoordinator.speak(exampleSentences.joined(separator: " "))
                }) {
                    Image(systemName: speechCoordinator.speakingText == exampleSentences.joined(separator: " ") ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(LinearColors.primary)
                }
                .buttonStyle(.plain)
            }

            ForEach(exampleSentences.prefix(2), id: \.self) { sentence in
                HStack(alignment: .top, spacing: 10) {
                    Text(sentence)
                        .font(.system(size: 13))
                        .foregroundColor(LinearColors.textSecondary)
                        .lineSpacing(4)

                    Spacer(minLength: 0)

                    Button(action: { speechCoordinator.speak(sentence) }) {
                        Image(systemName: speechCoordinator.speakingText == sentence ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(LinearColors.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(LinearColors.bgSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var loadingState: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Spacer()
        }
        .padding(40)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#dc2626"))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#991b1b"))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#fef2f2"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Highlightable Text
struct HighlightableText: View {
    let text: String
    @Binding var markedWords: Set<String>

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(text.components(separatedBy: .whitespacesAndNewlines), id: \.self) { word in
                let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
                if !cleanWord.isEmpty {
                    Button(action: {
                        if markedWords.contains(cleanWord) {
                            markedWords.remove(cleanWord)
                        } else {
                            markedWords.insert(cleanWord)
                        }
                    }) {
                        Text(cleanWord)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(markedWords.contains(cleanWord) ? .white : LinearColors.primary)
                            .underline(markedWords.contains(cleanWord) ? false : true, color: LinearColors.primary.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(markedWords.contains(cleanWord) ? Color(hex: "#ef4444").opacity(0.8) : LinearColors.primaryBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    let punctuation = word.filter { $0 == "," || $0 == "." || $0 == ";" || $0 == "!" || $0 == "?" }
                    if !punctuation.isEmpty {
                        Text(punctuation)
                            .font(.system(size: 14))
                            .foregroundColor(LinearColors.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets

        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        guard let containerWidth = proposal.width else {
            return (sizes.map { _ in .zero }, .zero)
        }

        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxY = max(maxY, currentY + size.height)
        }

        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WordStore())
            .environmentObject(NetworkMonitor.shared)
            .environmentObject(LocalizationManager.shared)
    }
}
