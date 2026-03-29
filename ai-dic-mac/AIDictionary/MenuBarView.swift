import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var wordStore: WordStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @ObservedObject private var speechCoordinator = SpeechCoordinator.shared

    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResult: Word?
    @State private var errorMessage: String?
    @State private var selectedTab: StitchMenuBarTab = .define

    private let backgroundColor = Color(hex: "#111125")
    private let backgroundHighlight = Color(hex: "#2a2a44")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surface = Color(hex: "#1e1e32")
    private let surfaceHigh = Color(hex: "#28283d")
    private let surfaceHighest = Color(hex: "#333348")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")

    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBarView
            tabBarView
            contentView
            footerView
        }
        .frame(width: 320, height: 580)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 26, x: 0, y: 18)
        .onAppear(perform: seedInitialResult)
    }

    private var panelBackground: some View {
        LinearGradient(
            colors: [backgroundHighlight, backgroundColor, backgroundColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var headerView: some View {
        HStack(alignment: .top) {
            Text("Scholar")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .tracking(-0.8)
                .textCase(.uppercase)

            Spacer()

            HStack(spacing: 8) {
                statusBadge

                Button(action: fillFromClipboard) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(onSurfaceVariant)
                        .frame(width: 28, height: 28)
                        .background(surfaceHigh.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(clipboardManager.clipboardText.isEmpty)
                .opacity(clipboardManager.clipboardText.isEmpty ? 0.45 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: networkMonitor.isOnline ? "wifi" : "wifi.slash")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(networkMonitor.isOnline ? cyanAccent : onSurfaceVariant)

            Text(networkMonitor.isOnline ? "Online" : "Offline")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(onSurfaceVariant)
                .tracking(0.8)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(surfaceHigh.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var searchBarView: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(surfaceHigh.opacity(0.85))

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(onSurfaceVariant)

                TextField("", text: $searchText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(onSurface)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search lexicon...")
                            .foregroundColor(onSurfaceVariant)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .textFieldStyle(.plain)
                    .onSubmit(performSearch)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
        }
        .frame(height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(cyanAccent.opacity(0.16), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private var tabBarView: some View {
        HStack(spacing: 16) {
            ForEach(StitchMenuBarTab.allCases) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.title)
                        .font(.system(size: 10, weight: selectedTab == tab ? .black : .semibold))
                        .foregroundColor(selectedTab == tab ? cyanAccent : Color(hex: "#7b8199"))
                        .tracking(1.1)
                        .textCase(.uppercase)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                switch selectedTab {
                case .define:
                    defineContent
                case .favorites:
                    collectionCard(
                        title: "Favorites",
                        words: wordStore.favorites,
                        emptyMessage: "Starred words will appear here."
                    )
                case .history:
                    collectionCard(
                        title: "History",
                        words: wordStore.searchHistory,
                        emptyMessage: "Recent lookups will appear here."
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var defineContent: some View {
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
                .progressViewStyle(CircularProgressViewStyle(tint: cyanAccent))
            Text("Looking up your word...")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .background(surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Lookup Failed", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#ffb4ab"))

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#ffdad6"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#93000a").opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func definitionCard(for word: Word) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.term)
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(onSurface)
                        .tracking(-1)

                    Text("/lookup/ • entry")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(cyanAccent.opacity(0.9))
                        .tracking(1.1)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        Text("\(StitchUIHelpers.pronunciationLabel(for: word)) • \(word.partOfSpeech ?? "entry")")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(onSurfaceVariant)

                        Button {
                            speechCoordinator.speak(word.term)
                        } label: {
                            Image(systemName: speechCoordinator.speakingText == word.term ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(cyanAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { wordStore.addToFavorites(word) }) {
                        Image(systemName: wordStore.isFavorite(word) ? "star.fill" : "star")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(cyanAccent)
                            .frame(width: 30, height: 30)
                            .background(surfaceHigh)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: { wordStore.addToVocabulary(word) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(Color(hex: "#003642"))
                            .frame(width: 30, height: 30)
                            .background(cyanAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: cyanAccent.opacity(0.4), radius: 12, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(StitchUIHelpers.trimmedDefinition(word.definition, limit: 180))
                .font(.system(size: 15, weight: .light))
                .foregroundColor(onSurface.opacity(0.92))
                .lineSpacing(4)

            HStack(spacing: 6) {
                ForEach(StitchUIHelpers.keywordChips(from: word.definition, excluding: word.term), id: \.self) { chip in
                    Text(chip.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(onSurfaceVariant)
                        .tracking(0.9)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(surface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(surfaceLow)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(cyanAccent.opacity(0.35))
                .frame(width: 2)
                .padding(.vertical, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var frequencyCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Frequency Score")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(hex: "#7b8199"))
                    .tracking(1.1)
                    .textCase(.uppercase)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(surfaceHighest)
                        Capsule()
                            .fill(cyanAccent)
                            .frame(width: geometry.size.width * 0.76)
                            .shadow(color: cyanAccent.opacity(0.6), radius: 8, x: 0, y: 0)
                    }
                }
                .frame(width: 120, height: 4)
            }

            Spacer()

            Text("Top 12%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(onSurface)
        }
        .padding(14)
        .background(surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func exampleCard(for word: Word) -> some View {
        let sentences = Array(StitchUIHelpers.listeningSentences(for: word).prefix(2))

        return ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [surfaceLow, surfaceHigh],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(cyanAccent)

                    Spacer()

                    Button {
                        speechCoordinator.speak(sentences.joined(separator: " "))
                    } label: {
                        Image(systemName: speechCoordinator.speakingText == sentences.joined(separator: " ") ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(cyanAccent)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(Array(sentences.enumerated()), id: \.offset) { _, sentence in
                    Text("“\(sentence)”")
                        .font(.system(size: 12))
                        .italic()
                        .foregroundColor(onSurfaceVariant)
                        .lineSpacing(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)

            Image(systemName: "book.closed")
                .font(.system(size: 52))
                .foregroundColor(cyanAccent.opacity(0.08))
                .padding(.trailing, 8)
                .padding(.bottom, 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 28))
                .foregroundColor(onSurfaceVariant.opacity(0.7))

            Text("Search for a word")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(onSurface)

            Text(StitchUIHelpers.exampleSentence(for: nil))
                .font(.system(size: 12))
                .foregroundColor(onSurfaceVariant)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func collectionCard(title: String, words: [Word], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(onSurfaceVariant)
                .tracking(1)
                .textCase(.uppercase)

            if words.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 12))
                    .foregroundColor(onSurfaceVariant)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(words.prefix(6)) { word in
                        Button {
                            searchResult = word
                            searchText = word.term
                            errorMessage = nil
                            selectedTab = .define
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(word.term)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(cyanAccent)

                                    Text(StitchUIHelpers.trimmedDefinition(word.definition, limit: 70))
                                        .font(.system(size: 11))
                                        .foregroundColor(onSurface.opacity(0.8))
                                        .lineLimit(2)
                                }

                                Spacer()

                                Text(StitchUIHelpers.historyDateString(from: word.timestamp))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(onSurfaceVariant)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var footerView: some View {
        VStack(spacing: 10) {
            Button(action: openMainWindow) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(cyanAccent)

                    Text("Open Full Dictionary")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color(hex: "#d1d5db"))
                        .tracking(1)
                        .textCase(.uppercase)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#6b7280"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack {
                Button(action: { NSApp.terminate(nil) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .bold))
                        Text("Quit")
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.8)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(Color(hex: "#8a8fa5"))
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(cyanAccent)
                        .frame(width: 6, height: 6)
                    Text("AI Engine Active")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#8a8fa5"))
                        .tracking(1)
                        .textCase(.uppercase)
                }
            }
        }
        .padding(16)
        .background(backgroundColor.opacity(0.35))
    }

    private func seedInitialResult() {
        guard searchResult == nil else { return }

        if let recentWord = wordStore.searchHistory.first ?? wordStore.favorites.first ?? wordStore.vocabularyList.first {
            searchResult = recentWord
            searchText = recentWord.term
        }
    }

    private func fillFromClipboard() {
        guard !clipboardManager.clipboardText.isEmpty else { return }
        searchText = clipboardManager.clipboardText
        clipboardManager.clearNotification()
        performSearch()
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
    }

    private func performSearch() {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.lookupWord(
                    trimmedSearch.lowercased(),
                    unknownWords: []
                )

                await MainActor.run {
                    searchResult = result
                    searchText = result.term
                    selectedTab = .define
                    isLoading = false
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
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

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

struct MenuBarView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarView()
            .environmentObject(WordStore())
            .environmentObject(NetworkMonitor.shared)
            .environmentObject(ClipboardManager.shared)
    }
}
