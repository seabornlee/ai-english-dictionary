import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var wordStore: WordStore
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResult: Word?
    @State private var markedWords = Set<String>()
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            SidebarView()
            
            VStack(spacing: 0) {
                // Fixed search controls
                HStack {
                    TextField("Enter a word", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 300)
                        .onSubmit {
                            performSearch()
                        }
                    
                    Button(action: performSearch) {
                        Text("Search")
                    }
                    .disabled(searchText.isEmpty || isLoading)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                // Content area
                ScrollView {
                    VStack {
                        if isLoading {
                            ProgressView("Loading...")
                                .padding()
                        } else if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else if let word = searchResult {
                            WordDisplayView(
                                word: word.term,
                                definition: word.definition,
                                isLoading: isLoading,
                                error: errorMessage,
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
                            .padding()
                        } else {
                            VStack {
                                Image(systemName: "character.book.closed")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("Search for a word to begin")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
        .navigationTitle("AI Dictionary")
        .onAppear {
            // Make sure data is loaded when app starts
            wordStore.loadData()
            
            // Add notification observer
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
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await APIService.shared.lookupWord(
                    searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                    avoidWords: []
                )
                
                DispatchQueue.main.async {
                    self.searchResult = result
                    self.isLoading = false
                    self.markedWords.removeAll()
                    
                    // Add to search history
                    self.wordStore.addToHistory(result)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
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
                    avoidWords: Array(markedWords)
                )
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.searchResult = result
                        self.isLoading = false
                        self.markedWords.removeAll()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

struct HighlightableText: View {
    let text: String
    @Binding var markedWords: Set<String>
    
    var body: some View {
        FlowLayout(spacing: 4) {
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
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(markedWords.contains(cleanWord) ? Color.gray.opacity(0.1) : Color.blue.opacity(0.3))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    // Display punctuation marks as plain text
                    let punctuation = word.filter { $0 == "," || $0 == "." }
                    if !punctuation.isEmpty {
                        Text(punctuation)
                    }
                }
            }
        }
    }
}

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

struct SidebarView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    var body: some View {
        List {
            NavigationLink(destination: FavoritesView()) {
                Label("Favorites", systemImage: "star")
            }
            
            NavigationLink(destination: VocabularyView()) {
                Label("Vocabulary", systemImage: "text.book.closed")
            }
            
            NavigationLink(destination: HistoryView()) {
                Label("History", systemImage: "clock")
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(WordStore())
    }
} 