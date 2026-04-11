import SwiftUI

enum SidebarSelection: String, Hashable {
    case dictionary
    case favorites
    case vocabulary
    case history
    case unknownWords
}

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
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selection: $sidebarSelection)
                .frame(width: 240)
                .background(backgroundColor)

            Divider()

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(backgroundColor)
        .onAppear {
            wordStore.loadData()
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("OpenWordInDictionary"),
                object: nil,
                queue: .main
            ) { notification in
                if let word = notification.userInfo?["word"] as? Word {
                    self.searchResult = word
                    self.searchText = word.term
                    self.markedWords.removeAll()
                    self.sidebarSelection = .dictionary
                }
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch sidebarSelection {
        case .dictionary, .none:
            mainContentView
        case .favorites:
            FavoritesView()
                .environmentObject(wordStore)
        case .vocabulary:
            VocabularyView()
                .environmentObject(wordStore)
        case .history:
            HistoryView()
                .environmentObject(wordStore)
        case .unknownWords:
            UnknownWordsView()
                .environmentObject(wordStore)
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerView
            contentAreaView
        }
        .background(backgroundColor)
    }
    
    private var headerView: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(onSurfaceVariant)
                
                TextField("", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .placeholder(when: searchText.isEmpty) {
                        Text(NSLocalizedString("search.placeholder", comment: ""))
                            .foregroundColor(onSurfaceVariant)
                            .font(.system(size: 14))
                    }
                    .onSubmit {
                        performSearch()
                    }
                
                Button(action: performSearch) {
                    Text(NSLocalizedString("search.button", comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(cyanAccent)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(searchText.isEmpty || isLoading)
                .opacity(searchText.isEmpty || isLoading ? 0.5 : 1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(surfaceHigh)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cyanAccent.opacity(0.15), lineWidth: 1)
            )
            .frame(maxWidth: 400)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(networkMonitor.isOnline ? Color(hex: "#34d399") : Color(hex: "#f87171"))
                    .frame(width: 6, height: 6)

                Text(networkMonitor.isOnline ? NSLocalizedString("status.online", comment: "") : NSLocalizedString("status.offline", comment: ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(onSurfaceVariant)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(surfaceLow)
    }
    
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
                        onRegenerate: regenerateDefinition,
                        onAddToFavorites: {
                            wordStore.addToFavorites(word)
                        },
                        onAddToVocabulary: {
                            wordStore.addToVocabulary(word)
                        },
                        showFavoritesButton: true
                    )
                } else if isLoading {
                    loadingView
                } else {
                    emptyStateView
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 500)
        }
        .background(backgroundColor)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            Text(NSLocalizedString("loading.title", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)
        }
        .padding(60)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(surfaceLow)
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 56))
                .foregroundColor(onSurfaceVariant.opacity(0.4))
            
            Text(NSLocalizedString("search.empty_state", comment: ""))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(onSurfaceVariant)
        }
        .padding(80)
    }
    
    private func extractKeywords(from definition: String) -> [String] {
        let words = definition.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 4 && !$0.lowercased().contains(definition.lowercased()) }
        return Array(words.prefix(5))
    }

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
                    self.searchResult = result
                    self.isLoading = false
                    self.markedWords.removeAll()
                    self.wordStore.addToHistory(result)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
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
                        self.searchResult = result
                        self.isLoading = false
                        self.markedWords.removeAll()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct HighlightableText: View {
    let text: String
    @Binding var markedWords: Set<String>
    
    private let surfaceHigh = Color(hex: "#28283d")
    private let onSurface = Color(hex: "#e2e0fc")

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
                            .font(.system(size: 15))
                            .foregroundColor(markedWords.contains(cleanWord) ? .white : onSurface)
                            .strikethrough(markedWords.contains(cleanWord), color: .white.opacity(0.6))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(markedWords.contains(cleanWord) ? Color(hex: "#ef4444").opacity(0.5) : surfaceHigh.opacity(0.5))
                            .cornerRadius(4)
                            .overlay(
                                markedWords.contains(cleanWord) ?
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(hex: "#ef4444").opacity(0.8), lineWidth: 1.5)
                                    : nil
                            )
                    }
                    .buttonStyle(.plain)

                    let punctuation = word.filter { $0 == "," || $0 == "." || $0 == ";" || $0 == "!" || $0 == "?" }
                    if !punctuation.isEmpty {
                        Text(punctuation)
                            .font(.system(size: 15))
                            .foregroundColor(onSurface.opacity(0.7))
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
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

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    @EnvironmentObject private var localizationManager: LocalizationManager

    private let backgroundColor = Color(hex: "#0e0e16")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#ffffff")
    private let onSurfaceVariant = Color(hex: "#888899")

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(cyanAccent)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#003642"))
                    )

                Text(localizationManager.appName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(onSurface)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("sidebar.learning", comment: ""))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#666680"))
                    .tracking(1)

                sidebarButton(NSLocalizedString("sidebar.dictionary", comment: ""), systemImage: "book.closed", item: .dictionary)
                sidebarButton(NSLocalizedString("sidebar.favorites", comment: ""), systemImage: "star", item: .favorites)
                sidebarButton(NSLocalizedString("sidebar.vocabulary", comment: ""), systemImage: "text.book.closed", item: .vocabulary)
                sidebarButton(NSLocalizedString("sidebar.history", comment: ""), systemImage: "clock.arrow.circlepath", item: .history)
                sidebarButton(NSLocalizedString("sidebar.unknown_words", comment: ""), systemImage: "questionmark.circle", item: .unknownWords)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(backgroundColor)
    }

    private func sidebarButton(
        _ title: String,
        systemImage: String,
        item: SidebarSelection
    ) -> some View {
        let isSelected = selection == item
        return Button(action: {
            selection = item
        }) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? cyanAccent : onSurfaceVariant)

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? onSurface : onSurfaceVariant)

                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40)
            .contentShape(Rectangle())
            .background(isSelected ? surfaceLow : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WordStore())
            .environmentObject(NetworkMonitor.shared)
            .environmentObject(LocalizationManager.shared)
    }
}
