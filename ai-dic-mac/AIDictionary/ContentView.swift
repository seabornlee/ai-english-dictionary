import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var wordStore: WordStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResult: Word?
    @State private var markedWords = Set<String>()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        NavigationView {
            SidebarView()
                .frame(minWidth: 240)
                .background(backgroundColor)

            mainContentView
        }
        .navigationTitle("AI Dictionary")
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
                }
            }
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
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: networkMonitor.isOnline ? "wifi" : "wifi.slash")
                    .font(.system(size: 12))
                    .foregroundColor(networkMonitor.isOnline ? cyanAccent : onSurfaceVariant)
                
                Text(networkMonitor.isOnline ? "Online" : "Offline")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(onSurfaceVariant)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(surfaceHigh.opacity(0.5))
            .cornerRadius(6)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(onSurfaceVariant)
                
                TextField("", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(onSurface)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Type a word to look up...")
                            .foregroundColor(onSurfaceVariant)
                            .font(.system(size: 14))
                    }
                    .onSubmit {
                        performSearch()
                    }
                    .frame(maxWidth: 300)
                
                Button(action: performSearch) {
                    Text("Search")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#003642"))
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
            .background(surfaceHigh.opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(cyanAccent.opacity(0.2), lineWidth: 1)
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(surfaceLow)
    }
    
    private var contentAreaView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let word = searchResult {
                    wordResultView(word: word)
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
                .progressViewStyle(CircularProgressViewStyle(tint: cyanAccent))
                .scaleEffect(1.2)
            Text("Loading...")
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
    
    private func wordResultView(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            wordHeaderView(word: word)
            definitionView(word: word)
            actionButtonsView(word: word)
        }
        .padding(24)
        .background(surfaceLow)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cyanAccent.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func wordHeaderView(word: Word) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.term)
                    .font(.system(size: 36, weight: .black, design: .default))
                    .foregroundColor(cyanAccent)
                    .tracking(-0.5)
                
                Text("/phonetic/ • adjective")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(onSurfaceVariant)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                Button(action: {
                    wordStore.addToFavorites(word)
                }) {
                    Image(systemName: wordStore.isFavorite(word) ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundColor(wordStore.isFavorite(word) ? cyanAccent : onSurfaceVariant)
                }
                .buttonStyle(.plain)
                .frame(width: 40, height: 40)
                .background(surfaceHigh)
                .cornerRadius(8)
                
                Button(action: {
                    wordStore.addToVocabulary(word)
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#003642"))
                }
                .buttonStyle(.plain)
                .frame(width: 40, height: 40)
                .background(cyanAccent)
                .cornerRadius(8)
                .shadow(color: cyanAccent.opacity(0.3), radius: 8, x: 0, y: 2)
            }
        }
    }
    
    private func definitionView(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(word.definition)
                .font(.system(size: 17, weight: .light))
                .foregroundColor(onSurface.opacity(0.9))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            FlowLayout(spacing: 8) {
                ForEach(extractKeywords(from: word.definition), id: \.self) { keyword in
                    Button(action: {
                        let lowerKeyword = keyword.lowercased()
                        if markedWords.contains(lowerKeyword) {
                            markedWords.remove(lowerKeyword)
                        } else {
                            markedWords.insert(lowerKeyword)
                        }
                    }) {
                        Text(keyword)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(markedWords.contains(keyword.lowercased()) ? Color(hex: "#B54A4A") : onSurface)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(markedWords.contains(keyword.lowercased()) ? Color(hex: "#B54A4A").opacity(0.15) : surfaceHigh)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(markedWords.contains(keyword.lowercased()) ? Color(hex: "#B54A4A").opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func actionButtonsView(word: Word) -> some View {
        HStack(spacing: 12) {
            Button(action: regenerateDefinition) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    Text("Regenerate without marked words")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(onSurfaceVariant)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(surfaceHigh)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(markedWords.isEmpty || isLoading)
            .opacity(markedWords.isEmpty || isLoading ? 0.5 : 1)
            
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 56))
                .foregroundColor(onSurfaceVariant.opacity(0.4))
            
            Text("Search for a word to begin")
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
                            .foregroundColor(markedWords.contains(cleanWord) ? Color(hex: "#B54A4A") : onSurface)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(markedWords.contains(cleanWord) ? Color(hex: "#B54A4A").opacity(0.2) : surfaceHigh.opacity(0.5))
                            .cornerRadius(4)
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
    @EnvironmentObject private var wordStore: WordStore
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(cyanAccent)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#003642"))
                    )
                
                Text("AI Dictionary")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(onSurface)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
            Text("LEARNING")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(onSurfaceVariant)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            List {
                NavigationLink(destination: FavoritesView()) {
                    Label("Favorites", systemImage: "star")
                        .font(.system(size: 14))
                }
                .listRowBackground(surfaceLow)
                
                NavigationLink(destination: VocabularyView()) {
                    Label("Vocabulary", systemImage: "text.book.closed")
                        .font(.system(size: 14))
                }
                .listRowBackground(surfaceLow)
                
                NavigationLink(destination: HistoryView()) {
                    Label("History", systemImage: "clock")
                        .font(.system(size: 14))
                }
                .listRowBackground(surfaceLow)
                
                NavigationLink(destination: UnknownWordsView()) {
                    Label("Unknown Words", systemImage: "questionmark.circle")
                        .font(.system(size: 14))
                }
                .listRowBackground(surfaceLow)
            }
            .listStyle(SidebarListStyle())
            .background(backgroundColor)
            
            Spacer()
        }
        .background(backgroundColor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WordStore())
            .environmentObject(NetworkMonitor.shared)
    }
}
