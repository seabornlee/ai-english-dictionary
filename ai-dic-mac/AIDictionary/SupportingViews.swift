import SwiftUI
import UniformTypeIdentifiers

struct FavoritesView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    var body: some View {
        VStack {
            if wordStore.favorites.isEmpty {
                EmptyStateView(
                    title: "No Favorites",
                    systemImage: "star.slash",
                    description: "Words you mark as favorites will appear here."
                )
            } else {
                List {
                    ForEach(wordStore.favorites) { word in
                        WordRow(word: word)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VocabularyView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    var body: some View {
        VStack {
            if wordStore.vocabularyList.isEmpty {
                EmptyStateView(
                    title: "No Vocabulary Words",
                    systemImage: "text.book.closed",
                    description: "Words you add to your vocabulary will appear here."
                )
            } else {
                List {
                    ForEach(wordStore.vocabularyList) { word in
                        WordRow(word: word)
                            .contextMenu {
                                Button(role: .destructive) {
                                    wordStore.removeFromVocabulary(word)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Vocabulary")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    var body: some View {
        VStack {
            if wordStore.searchHistory.isEmpty {
                EmptyStateView(
                    title: "No Search History",
                    systemImage: "clock",
                    description: "Words you search for will appear here."
                )
            } else {
                VStack {
                    HStack {
                        Spacer()
                        Button("Clear History") {
                            wordStore.clearHistory()
                        }
                        .padding()
                    }
                    
                    List {
                        ForEach(wordStore.searchHistory) { word in
                            WordRow(word: word)
                        }
                    }
                }
            }
        }
        .navigationTitle("Search History")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(description)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct WordRow: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(word.term)
                .font(.headline)
            
            Text(word.definition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(formattedDate(word.timestamp))
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct VocabularyDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var words: [Word]
    
    init(words: [Word]) {
        self.words = words
    }
    
    init(configuration: ReadConfiguration) throws {
        words = []
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let text = words.map { "\($0.term): \($0.definition)" }.joined(separator: "\n")
        return FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct WordDisplayView: View {
    let word: String
    let definition: String
    let isLoading: Bool
    let error: String?
    @Binding var markedWords: Set<String>
    let onRegenerate: () -> Void
    let onAddToFavorites: (() -> Void)?
    let onAddToVocabulary: (() -> Void)?
    let showFavoritesButton: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(word)
                    .font(.title)
                
                Spacer()
                
                if !markedWords.isEmpty {
                    Button {
                        onRegenerate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Regenerate definition")
                }
                
                if showFavoritesButton, let onAddToFavorites = onAddToFavorites {
                    Button(action: onAddToFavorites) {
                        Image(systemName: "star")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                }
                .padding()
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                HighlightableText(
                    text: definition,
                    markedWords: $markedWords
                )
                
                if !markedWords.isEmpty {
                    HStack {
                        Text("Marked words: ")
                            .font(.title3)
                        
                        ForEach(Array(markedWords), id: \.self) { word in
                            Text(word)
                                .font(.title3)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical)
                }
                
                if let onAddToVocabulary = onAddToVocabulary {
                    Button("Add to Vocabulary") {
                        onAddToVocabulary()
                    }
                    .padding(.top)
                }
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                
                if let onAddToVocabulary = onAddToVocabulary {
                    Button {
                        onAddToVocabulary()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Add to Vocabulary")
                }
            }
        }
    }
} 