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
            
            VStack {
                HStack {
                    TextField("Enter a word", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 300)
                    
                    Button(action: performSearch) {
                        Text("Search")
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(searchText.isEmpty || isLoading)
                }
                .padding()
                
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if let word = searchResult {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(word.term)
                                    .font(.largeTitle)
                                    .bold()
                                
                                Spacer()
                                
                                Button(action: {
                                    wordStore.addToFavorites(word)
                                }) {
                                    Image(systemName: wordStore.isFavorite(word) ? "star.fill" : "star")
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Divider()
                            
                            Text("Definition")
                                .font(.headline)
                            
                            HighlightableText(
                                text: word.definition,
                                markedWords: $markedWords
                            )
                            
                            if !markedWords.isEmpty {
                                HStack {
                                    Text("Marked words: ")
                                        .font(.caption)
                                    
                                    ForEach(Array(markedWords), id: \.self) { word in
                                        Text(word)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    Spacer()
                                    
                                    Button("Clear") {
                                        markedWords.removeAll()
                                    }
                                    
                                    Button("Regenerate") {
                                        regenerateDefinition()
                                    }
                                }
                                .padding(.vertical)
                            }
                            
                            // Add to vocabulary button
                            Button("Add to Vocabulary") {
                                wordStore.addToVocabulary(word)
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
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
        .navigationTitle("AI Dictionary")
        .onAppear {
            // Make sure data is loaded when app starts
            wordStore.loadData()
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
                    self.searchResult = result
                    self.isLoading = false
                    self.markedWords.removeAll()
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
        Text(.init(attributedString()))
            .lineSpacing(4)
    }
    
    private func attributedString() -> NSAttributedString {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let attrString = NSMutableAttributedString()
        
        for (index, word) in words.enumerated() {
            // Strip punctuation for matching but keep it for display
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: markedWords.contains(cleanWord) ? NSColor.blue : NSColor.textColor
            ]
            
            let wordAttrString = NSAttributedString(
                string: word + (index < words.count - 1 ? " " : ""),
                attributes: attributes
            )
            
            let tapGesture = NSMutableAttributedString(attributedString: wordAttrString)
            let range = NSRange(location: 0, length: word.count)
            
            tapGesture.addAttribute(.link, value: "word:\(cleanWord)", range: range)
            
            attrString.append(tapGesture)
        }
        
        return attrString
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