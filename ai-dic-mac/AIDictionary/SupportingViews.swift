import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

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
                .listStyle(PlainListStyle())
                .background(backgroundColor)
            }
        }
        .navigationTitle("Favorites")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}

struct VocabularyView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

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
                .listStyle(PlainListStyle())
                .background(backgroundColor)
            }
        }
        .navigationTitle("Vocabulary")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}

struct HistoryView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        VStack {
            if wordStore.searchHistory.isEmpty {
                EmptyStateView(
                    title: "No Search History",
                    systemImage: "clock",
                    description: "Words you search for will appear here."
                )
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("\(wordStore.searchHistory.count) words looked up · Auto-cleared after 30 days")
                            .font(.system(size: 13))
                            .foregroundColor(onSurfaceVariant)
                        
                        Spacer()
                        
                        Button("Clear History") {
                            wordStore.clearHistory()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(onSurfaceVariant)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(surfaceHigh)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(surfaceLow)

                    List {
                        ForEach(wordStore.searchHistory) { word in
                            WordRow(word: word)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(backgroundColor)
                }
            }
        }
        .navigationTitle("History")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
    }
}

struct UnknownWordsView: View {
    @EnvironmentObject private var wordStore: WordStore
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    private let errorColor = Color(hex: "#B54A4A")

    var body: some View {
        VStack(spacing: 0) {
            if wordStore.unknownWords.isEmpty {
                EmptyStateView(
                    title: "No Unknown Words",
                    systemImage: "questionmark.circle",
                    description: "Words you mark as unknown will appear here."
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("\(wordStore.unknownWords.count) words marked · Used to filter AI explanations")
                            .font(.system(size: 13))
                            .foregroundColor(onSurfaceVariant)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(cyanAccent)
                        
                        Text("When you mark words in definitions as unknown, they appear here. The AI will avoid using these words when generating new explanations.")
                            .font(.system(size: 13))
                            .foregroundColor(onSurfaceVariant)
                            .lineSpacing(2)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(surfaceLow)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    List {
                        ForEach(wordStore.unknownWords, id: \.self) { word in
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenWordInDictionary"),
                                    object: nil,
                                    userInfo: ["word": Word(
                                        term: word,
                                        definition: "",
                                        timestamp: Date()
                                    )]
                                )
                            }) {
                                HStack {
                                    Text(word)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(errorColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(onSurfaceVariant)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(surfaceLow)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(backgroundColor)
                }
            }
        }
        .navigationTitle("Unknown Words")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .onAppear {
            Task {
                await wordStore.loadUnknownWords()
            }
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String
    
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundColor(onSurfaceVariant.opacity(0.5))
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(onSurface)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

struct WordRow: View {
    let word: Word
    
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(word.term)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(cyanAccent)

            Text(word.definition)
                .font(.system(size: 14))
                .foregroundColor(onSurface.opacity(0.8))
                .lineLimit(2)
                .lineSpacing(2)

            Text(formattedDate(word.timestamp))
                .font(.system(size: 11))
                .foregroundColor(onSurfaceVariant)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(surfaceLow)
        .cornerRadius(8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    private let errorColor = Color(hex: "#B54A4A")

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word)
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(cyanAccent)
                        .tracking(-0.5)
                    
                    Text("/phonetic/ • adjective")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(onSurfaceVariant)
                }

                Spacer()

                HStack(spacing: 10) {
                    if showFavoritesButton, let onAddToFavorites = onAddToFavorites {
                        Button(action: onAddToFavorites) {
                            Image(systemName: "star")
                                .font(.system(size: 18))
                                .foregroundColor(onSurfaceVariant)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 40, height: 40)
                        .background(surfaceHigh)
                        .cornerRadius(8)
                    }
                    
                    if !markedWords.isEmpty {
                        Button {
                            onRegenerate()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16))
                                .foregroundColor(onSurfaceVariant)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 40, height: 40)
                        .background(surfaceHigh)
                        .cornerRadius(8)
                        .help("Regenerate definition")
                    }

                    if let onAddToVocabulary = onAddToVocabulary {
                        Button(action: onAddToVocabulary) {
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

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: cyanAccent))
                        .scaleEffect(1.2)
                    Spacer()
                }
                .padding(40)
            } else if let error = error {
                Text(error)
                    .foregroundColor(errorColor)
                    .padding()
                    .background(errorColor.opacity(0.1))
                    .cornerRadius(8)
            } else {
                HighlightableText(
                    text: definition,
                    markedWords: $markedWords
                )

                if !markedWords.isEmpty {
                    HStack {
                        Text("Unknown words:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(onSurfaceVariant)

                        ForEach(Array(markedWords), id: \.self) { word in
                            Text(word)
                                .font(.system(size: 13))
                                .foregroundColor(errorColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(errorColor.opacity(0.15))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(errorColor.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.vertical)
                }
            }

            Spacer(minLength: 0)
        }
    }
}
