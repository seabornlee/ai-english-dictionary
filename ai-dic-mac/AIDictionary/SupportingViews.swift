import SwiftUI
import UniformTypeIdentifiers

struct FavoritesView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    var body: some View {
        VStack {
            if wordStore.favorites.isEmpty {
                ContentUnavailableView {
                    Label("No Favorites", systemImage: "star.slash")
                } description: {
                    Text("Words you mark as favorites will appear here.")
                }
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
                ContentUnavailableView {
                    Label("No Vocabulary Words", systemImage: "text.book.closed")
                } description: {
                    Text("Words you add to your vocabulary will appear here.")
                }
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
                ContentUnavailableView {
                    Label("No Search History", systemImage: "clock")
                } description: {
                    Text("Words you search for will appear here.")
                }
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
        VStack {
            Image(systemName: systemImage)
                .font(.largeTitle)
            Text(title)
                .font(.headline)
            Text(description)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .foregroundColor(.tertiary)
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