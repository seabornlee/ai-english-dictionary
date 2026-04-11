import AppKit
import SwiftUI

class FloatingWindowService {
    static let shared = FloatingWindowService()

    private let floatingWindowWidth: CGFloat = 420

    private var floatingWindow: NSWindow?
    private var selectedWord: String = ""
    private var clickMonitor: Any?

    private init() {}

    func showFloatingWindow() {
        // Close existing window if any
        floatingWindow?.close()
        removeClickMonitor()

        // Create content view
        let contentView = FloatingWordView(word: selectedWord) {
            self.closeFloatingWindow()
        }

        // Create hosting view
        let hostingView = NSHostingView(rootView: contentView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: floatingWindowWidth, height: 0),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.title = LocalizationManager.shared.appName

        // Position window near the cursor
        if let screenFrame = NSScreen.main?.frame {
            let mouseLocation = NSEvent.mouseLocation
            var windowFrame = window.frame
            let cursorOffset: CGFloat = 20

            let idealSize = hostingView.fittingSize
            windowFrame.size.width = floatingWindowWidth
            windowFrame.size.height = min(idealSize.height, screenFrame.height * 0.8)

            windowFrame.origin.x = mouseLocation.x
            windowFrame.origin.y = screenFrame.height - mouseLocation.y - windowFrame.height - cursorOffset

            if windowFrame.maxX > screenFrame.maxX {
                windowFrame.origin.x = screenFrame.maxX - windowFrame.width
            }
            if windowFrame.minX < screenFrame.minX {
                windowFrame.origin.x = screenFrame.minX
            }
            if windowFrame.minY < screenFrame.minY {
                windowFrame.origin.y = screenFrame.minY
            }
            if windowFrame.maxY > screenFrame.maxY {
                windowFrame.origin.y = screenFrame.maxY - windowFrame.height
            }

            window.setFrame(windowFrame, display: true)
        }

        // Close when clicking outside using local monitor (sandbox-safe)
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let window = self.floatingWindow else { return event }

            let windowPoint = event.locationInWindow
            if let contentView = window.contentView, !contentView.bounds.contains(windowPoint) {
                self.closeFloatingWindow()
            }
            return event
        }

        floatingWindow = window
    }

    func showFloatingWindow(with text: String) {
        selectedWord = text
        showFloatingWindow()
    }

    func closeFloatingWindow() {
        floatingWindow?.close()
        floatingWindow = nil
        removeClickMonitor()
    }

    private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    deinit {
        removeClickMonitor()
    }
}

struct FloatingWordView: View {
    let word: String
    let onClose: () -> Void

    @State private var isLoading = true
    @State private var definition: String = ""
    @State private var error: String?
    @State private var markedWords = Set<String>()
    @State private var wordResult: Word?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WordDisplayView(
                word: word,
                definition: wordResult?.definition ?? definition,
                pronunciation: wordResult?.pronunciation,
                partOfSpeech: wordResult?.partOfSpeech,
                exampleSentences: wordResult?.exampleSentences ?? [],
                isLoading: isLoading,
                error: error,
                markedWords: $markedWords,
                onRegenerate: regenerateDefinition,
                onAddToFavorites: nil,
                onAddToVocabulary: nil,
                showFavoritesButton: false
            )

            HStack {
                Spacer()

                Button {
                    // Open main window with this word
                    NSApp.activate(ignoringOtherApps: true)
                    if let wordResult = wordResult {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("OpenWordInDictionary"),
                            object: nil,
                            userInfo: ["word": wordResult]
                        )
                    }
                    NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
                    onClose()
                } label: {
                    Image(systemName: "book.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help(NSLocalizedString("action.open_in_dictionary", comment: ""))
            }
        }
        .padding()
        .frame(width: 420)
        .onAppear {
            loadDefinition()
        }
    }

    private func loadDefinition() {
        isLoading = true

        Task {
            do {
                let result = try await APIService.shared.lookupWord(word, unknownWords: [])
                DispatchQueue.main.async {
                    self.definition = result.definition
                    self.wordResult = result
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func regenerateDefinition() {
        isLoading = true
        error = nil

        Task {
            do {
                let result = try await APIService.shared.lookupWord(word, unknownWords: Array(markedWords))

                DispatchQueue.main.async {
                    self.definition = result.definition
                    self.wordResult = result
                    self.isLoading = false
                    self.markedWords.removeAll()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
