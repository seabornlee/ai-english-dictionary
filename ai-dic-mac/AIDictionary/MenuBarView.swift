import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var wordStore: WordStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var searchResult: Word?
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    private let backgroundColor = Color(hex: "#111125")
    private let surfaceLow = Color(hex: "#1a1a2e")
    private let surfaceHigh = Color(hex: "#28283d")
    private let surfaceHighest = Color(hex: "#333348")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurface = Color(hex: "#e2e0fc")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchBarView
            tabNavigationView
            contentView
            footerView
        }
        .frame(width: 320, height: 520)
        .background(backgroundColor.opacity(0.95))
    }
    
    private var headerView: some View {
        HStack {
            Text("AI Dictionary")
                .font(.system(size: 18, weight: .black, design: .default))
                .foregroundColor(.white)
                .tracking(-0.5)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: networkMonitor.isOnline ? "wifi" : "wifi.slash")
                    .font(.system(size: 12))
                    .foregroundColor(networkMonitor.isOnline ? cyanAccent : onSurfaceVariant)
                
                Text(networkMonitor.isOnline ? "Online" : "Offline")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(onSurfaceVariant)
                    .tracking(0.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(surfaceHighest.opacity(0.5))
            .cornerRadius(6)
            
            Button(action: {
                if !clipboardManager.clipboardText.isEmpty {
                    searchText = clipboardManager.clipboardText
                    performSearch()
                }
            }) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16))
                    .foregroundColor(onSurfaceVariant)
            }
            .buttonStyle(.plain)
            .padding(6)
            .background(Color.clear)
            .cornerRadius(6)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Handle hover state if needed
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(surfaceLow)
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)
            
            TextField("", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(onSurface)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search...")
                        .foregroundColor(onSurfaceVariant)
                        .font(.system(size: 14))
                }
                .onSubmit {
                    performSearch()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(surfaceHigh.opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(cyanAccent.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var tabNavigationView: some View {
        HStack(spacing: 16) {
            TabButton(title: "Define", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Favorites", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            TabButton(title: "History", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let word = searchResult {
                    wordCardView(word: word)
                    frequencyView
                    exampleView
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(backgroundColor)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: cyanAccent))
                .scaleEffect(0.8)
            Text("Loading...")
                .font(.system(size: 12))
                .foregroundColor(onSurfaceVariant)
                .padding(.top, 8)
        }
        .padding(40)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(surfaceLow)
        .cornerRadius(12)
    }
    
    private func wordCardView(word: Word) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(word.term)
                        .font(.system(size: 32, weight: .black, design: .default))
                        .foregroundColor(.white)
                        .tracking(-0.5)
                    
                    Text("/phonetic/ • adj.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(cyanAccent.opacity(0.8))
                        .tracking(1)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        wordStore.addToFavorites(word)
                    }) {
                        Image(systemName: wordStore.isFavorite(word) ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(wordStore.isFavorite(word) ? cyanAccent : onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(surfaceHigh)
                    .cornerRadius(8)
                    
                    Button(action: {
                        wordStore.addToVocabulary(word)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#003642"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                    .background(cyanAccent)
                    .cornerRadius(8)
                    .shadow(color: cyanAccent.opacity(0.4), radius: 8, x: 0, y: 0)
                }
            }
            
            Text(word.definition)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(onSurface.opacity(0.9))
                .lineSpacing(4)
            
            HStack(spacing: 6) {
                ForEach(["Radiant", "Lucid", "Vivid"], id: \.self) { synonym in
                    Text(synonym)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(onSurfaceVariant)
                        .tracking(0.5)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(surfaceHighest)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(surfaceLow)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cyanAccent.opacity(0.2), lineWidth: 2)
                .padding(1)
        )
    }
    
    private var frequencyView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Frequency Score")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(hex: "#6b7280"))
                    .tracking(0.5)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(surfaceHighest)
                            .frame(height: 3)
                        
                        RoundedRectangle(cornerRadius: 1)
                            .fill(cyanAccent)
                            .frame(width: geometry.size.width * 0.75, height: 3)
                            .shadow(color: cyanAccent.opacity(0.6), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(width: 120, height: 3)
            }
            
            Spacer()
            
            Text("Top 12%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(onSurface)
        }
        .padding(12)
        .background(surfaceLow)
        .cornerRadius(10)
    }
    
    private var exampleView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 16))
                .foregroundColor(cyanAccent)
            
            Text("The luminous dial of his watch glowed in the dark cabin.")
                .font(.system(size: 12))
                .italic()
                .foregroundColor(onSurfaceVariant)
                .lineSpacing(2)
            
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [surfaceLow, surfaceHigh],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(10)
        .overlay(
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Image(systemName: "book.closed")
                        .font(.system(size: 64))
                        .foregroundColor(cyanAccent.opacity(0.1))
                        .offset(x: 10, y: 10)
                }
            }
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 48))
                .foregroundColor(onSurfaceVariant.opacity(0.5))
            
            Text("Search for a word")
                .font(.system(size: 14))
                .foregroundColor(onSurfaceVariant)
        }
        .padding(40)
    }
    
    private var footerView: some View {
        VStack(spacing: 8) {
            Button(action: {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
            }) {
                HStack {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 14))
                        .foregroundColor(cyanAccent)
                    
                    Text("Open Full Dictionary")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#d1d5db"))
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6b7280"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            HStack {
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                        Text("Quit")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(Color(hex: "#6b7280"))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(cyanAccent)
                        .frame(width: 6, height: 6)
                    
                    Text("AI Active")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color(hex: "#6b7280"))
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(surfaceLow.opacity(0.8))
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
                    wordStore.addToHistory(result)
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

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? cyanAccent : onSurfaceVariant)
                .tracking(0.5)
                .textCase(.uppercase)
        }
        .buttonStyle(.plain)
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
