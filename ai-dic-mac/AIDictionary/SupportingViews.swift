import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var wordStore: WordStore

    private let backgroundColor = Color(hex: "#12121a")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#ffffff")
    private let onSurfaceVariant = Color(hex: "#888899")

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Favorites")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(onSurface)

                Text("Quick access to the words you want to revisit.")
                    .font(.system(size: 14))
                    .foregroundColor(onSurfaceVariant)
            }

            if wordStore.favorites.isEmpty {
                EmptyStateView(
                    title: "No Favorites Yet",
                    systemImage: "star.slash",
                    description: "Star a word from the dictionary or menu bar to pin it here."
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(wordStore.favorites) { word in
                            FavoriteWordCard(word: word)
                        }
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundColor)
    }
}

struct VocabularyView: View {
    var body: some View {
        VocabularyHistoryView(initialTab: .vocabulary)
    }
}

struct HistoryView: View {
    var body: some View {
        VocabularyHistoryView(initialTab: .history)
    }
}

struct VocabularyHistoryView: View {
    @EnvironmentObject private var wordStore: WordStore
    let initialTab: StitchLibraryTab
    @State private var selectedTab: StitchLibraryTab

    private let backgroundColor = Color(hex: "#12121a")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceLower = Color(hex: "#0e0e16")
    private let borderColor = Color(hex: "#252535")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#ffffff")
    private let onSurfaceMuted = Color(hex: "#cccccc")
    private let onSurfaceVariant = Color(hex: "#888899")

    init(initialTab: StitchLibraryTab) {
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    private var displayedWords: [Word] {
        switch selectedTab {
        case .vocabulary:
            return wordStore.vocabularyList
        case .history:
            return wordStore.searchHistory
        }
    }

    private var emptyDescription: String {
        switch selectedTab {
        case .vocabulary:
            return "Words you add from the dictionary or menu bar will appear here."
        case .history:
            return "Your recent lookups will appear here after you search."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            tabBar

            if displayedWords.isEmpty {
                EmptyStateView(
                    title: selectedTab == .vocabulary ? "No Vocabulary Saved" : "No History Yet",
                    systemImage: selectedTab == .vocabulary ? "text.book.closed" : "clock",
                    description: emptyDescription
                )
            } else {
                libraryTable
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(backgroundColor)
        .onChange(of: initialTab) { newValue in
            selectedTab = newValue
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Vocabulary & History")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(onSurface)

                Text("Manage your learned words and lookup history")
                    .font(.system(size: 14))
                    .foregroundColor(onSurfaceVariant)
            }

            Spacer()

            if selectedTab == .history {
                Button(action: { wordStore.clearHistory() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                        Text("Clear History")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(onSurfaceVariant)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(surfaceLow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(StitchLibraryTab.allCases) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.title)
                        .font(.system(size: 14, weight: tab == selectedTab ? .semibold : .regular))
                        .foregroundColor(tab == selectedTab ? backgroundColor : onSurfaceVariant)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(tab == selectedTab ? cyanAccent : surfaceLow)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var libraryTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                tableHeader("Word", width: 220, alignment: .leading)
                tableHeader("Definition", width: nil, alignment: .leading)
                tableHeader("Date Added", width: 120, alignment: .leading)
                Spacer()
                    .frame(width: 44)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(surfaceLower)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(displayedWords) { word in
                        LibraryWordRow(
                            word: word,
                            showsRemoveAction: selectedTab == .vocabulary,
                            onRemove: {
                                if selectedTab == .vocabulary {
                                    wordStore.removeFromVocabulary(word)
                                }
                            },
                            onOpen: {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenWordInDictionary"),
                                    object: nil,
                                    userInfo: ["word": word]
                                )
                            }
                        )

                        if word.id != displayedWords.last?.id {
                            Divider()
                                .background(borderColor)
                        }
                    }
                }
            }
        }
        .background(surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func tableHeader(_ title: String, width: CGFloat?, alignment: Alignment) -> some View {
        Group {
            if let width {
                Text(title)
                    .frame(width: width, alignment: alignment)
            } else {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color(hex: "#666680"))
    }
}

private struct FavoriteWordCard: View {
    let word: Word

    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#ffffff")
    private let onSurfaceVariant = Color(hex: "#888899")

    var body: some View {
        Button {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenWordInDictionary"),
                object: nil,
                userInfo: ["word": word]
            )
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(word.term)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(cyanAccent)

                    Spacer()

                    Text(StitchUIHelpers.historyDateString(from: word.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(onSurfaceVariant)
                }

                Text(StitchUIHelpers.trimmedDefinition(word.definition, limit: 180))
                    .font(.system(size: 14))
                    .foregroundColor(onSurface.opacity(0.82))
                    .lineSpacing(3)

                HStack(spacing: 8) {
                    ForEach(StitchUIHelpers.keywordChips(from: word.definition, excluding: word.term), id: \.self) { chip in
                        Text(chip.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(onSurfaceVariant)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(surfaceHigh)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryWordRow: View {
    let word: Word
    let showsRemoveAction: Bool
    let onRemove: () -> Void
    let onOpen: () -> Void

    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurfaceMuted = Color(hex: "#cccccc")
    private let onSurfaceVariant = Color(hex: "#888899")

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onOpen) {
                Text(word.term)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(cyanAccent)
                    .frame(width: 220, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text(StitchUIHelpers.trimmedDefinition(word.definition, limit: 90))
                .font(.system(size: 14))
                .foregroundColor(onSurfaceMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(StitchUIHelpers.historyDateString(from: word.timestamp))
                .font(.system(size: 13))
                .foregroundColor(onSurfaceVariant)
                .frame(width: 120, alignment: .leading)

            Button(action: showsRemoveAction ? onRemove : onOpen) {
                Image(systemName: showsRemoveAction ? "trash" : "arrow.up.forward.square")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(onSurfaceVariant)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.01))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
    }
}

struct UnknownWordsView: View {
    @EnvironmentObject private var wordStore: WordStore

    private let backgroundColor = Color(hex: "#12121a")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#ffffff")
    private let onSurfaceVariant = Color(hex: "#888899")
    private let errorColor = Color(hex: "#ff8f8f")

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Unknown Words")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(onSurface)

                Text("Words you mark as unknown are collected here and used to simplify future explanations.")
                    .font(.system(size: 14))
                    .foregroundColor(onSurfaceVariant)
            }

            if wordStore.unknownWords.isEmpty {
                EmptyStateView(
                    title: "No Unknown Words",
                    systemImage: "questionmark.circle",
                    description: "Tap words in definitions to mark them and build your review list."
                )
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(cyanAccent)

                        Text("\(wordStore.unknownWords.count) saved words will be filtered out when you regenerate explanations.")
                            .font(.system(size: 14))
                            .foregroundColor(onSurfaceVariant)
                    }
                    .padding(18)
                    .background(surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    FlowLayout(spacing: 10) {
                        ForEach(wordStore.unknownWords, id: \.self) { word in
                            Button {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenWordInDictionary"),
                                    object: nil,
                                    userInfo: ["word": Word(term: word, definition: "", timestamp: Date())]
                                )
                            } label: {
                                Text(word)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(errorColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(surfaceHigh)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    private let surfaceLow = Color(hex: "#1a1a2e")
    private let onSurface = Color(hex: "#ffffff")
    private let onSurfaceVariant = Color(hex: "#888899")
    private let cyanAccent = Color(hex: "#00d4ff")

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundColor(cyanAccent.opacity(0.7))

            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(onSurface)

            Text(description)
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

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
    let onAddToFavorites: (() -> Void)?
    let onAddToVocabulary: (() -> Void)?
    let showFavoritesButton: Bool

    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    private let errorColor = Color(hex: "#B54A4A")
    @ObservedObject private var speechCoordinator = SpeechCoordinator.shared

    private var renderedWord: Word {
        Word(
            term: word,
            definition: definition,
            pronunciation: pronunciation,
            partOfSpeech: partOfSpeech,
            exampleSentences: exampleSentences,
            timestamp: Date()
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word)
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(cyanAccent)
                        .tracking(-0.5)

                    HStack(spacing: 8) {
                        Text("\(StitchUIHelpers.pronunciationLabel(for: renderedWord)) • \(partOfSpeech ?? "entry")")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(onSurfaceVariant)

                        Button {
                            speechCoordinator.speak(word)
                        } label: {
                            Image(systemName: speechCoordinator.speakingText == word ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(cyanAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    if showFavoritesButton, let onAddToFavorites {
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
                        Button(action: onRegenerate) {
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

                    if let onAddToVocabulary {
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Spacer()
                }
                .padding(40)
            } else if let error {
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

                let listeningSentences = StitchUIHelpers.listeningSentences(for: renderedWord)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(StitchUIHelpers.listeningSectionTitle(for: renderedWord))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(onSurface)

                        Spacer()

                        Button {
                            speechCoordinator.speak(listeningSentences.joined(separator: " "))
                        } label: {
                            Image(systemName: speechCoordinator.speakingText == listeningSentences.joined(separator: " ") ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(cyanAccent)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(Array(listeningSentences.enumerated()), id: \.offset) { _, sentence in
                        HStack(alignment: .top, spacing: 10) {
                            Text(sentence)
                                .font(.system(size: 13))
                                .foregroundColor(onSurface.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)

                            Button {
                                speechCoordinator.speak(sentence)
                            } label: {
                                Image(systemName: speechCoordinator.speakingText == sentence ? "speaker.wave.2.fill" : "speaker.wave.2")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(cyanAccent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(surfaceHigh.opacity(0.45))
                        .cornerRadius(8)
                    }
                }

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
        .padding(24)
        .background(surfaceLow)
        .cornerRadius(12)
    }
}
