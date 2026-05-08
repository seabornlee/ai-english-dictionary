import SwiftUI

@main
struct AIDictionaryApp: App {
    @StateObject private var wordStore = WordStore()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var initialSearchText: String = ""
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(initialSearchText: initialSearchText)
                .environmentObject(wordStore)
                .environmentObject(networkMonitor)
                .environmentObject(clipboardManager)
                .environmentObject(localizationManager)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    let text = clipboardManager.clipboardText
                    let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                    if wordCount <= 3, TextValidation.isValidEnglishWord(text) {
                        initialSearchText = text
                    }
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button(NSLocalizedString("preferences.title", comment: "")) {
                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // VAL-LOOKUP-010: In-app Cmd+Shift+D shortcut to open menu bar popup
            CommandMenu("Lookup") {
                Button("Look Up Word") {
                    appDelegate.togglePopover()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - AppDelegate with Manual Status Item + Popover
class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: NSWindow?
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_: Notification) {
        // VAL-LOOKUP-001: Menu bar icon visible after app launch
        setupStatusBarItem()

        // VAL-LOOKUP-011: Register NSServices provider so "Look up in LexisDic"
        // appears in the Services context menu of other applications
        NSApplication.shared.servicesProvider = DictionaryServiceProvider()

        // VAL-LOOKUP-012: When a service invocation delivers a word,
        // show the popover and let MenuBarView handle the lookup
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDefineWordService(_:)),
            name: .defineWordService,
            object: nil
        )

        // VAL-LOOKUP-024 / VAL-LOOKUP-016: Observe Darwin notification from
        // the Share Extension. When the extension saves a word to the shared
        // App Group container, it posts this notification so the main app
        // can activate and show the definition in the menu bar popup.
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { (center, observer, name, object, userInfo) in
                DispatchQueue.main.async {
                    // Read the shared word from the App Group UserDefaults
                    let sharedDefaults = UserDefaults(suiteName: "group.site.waterlee.aidic")
                    guard let word = sharedDefaults?.string(forKey: "sharedWord"),
                          !word.isEmpty else { return }

                    // Post the same notification as the Services menu flow
                    // so MenuBarView picks it up and performs the lookup
                    NotificationCenter.default.post(
                        name: .defineWordService,
                        object: nil,
                        userInfo: ["word": word]
                    )

                    // Activate the app to show the popover
                    NSApp.activate(ignoringOtherApps: true)
                }
            },
            "group.site.waterlee.aidic.wordUpdated" as CFString,
            nil,
            .deliverImmediately
        )
    }

    /// VAL-LOOKUP-012: Show the popover when a service delivers a word.
    /// The MenuBarView observes the same notification and performs the lookup.
    /// Also called when the Share Extension sends a word via Darwin notification.
    @objc private func handleDefineWordService(_ notification: Notification) {
        guard let button = statusItem?.button, let popover else { return }

        // Show the popover if it's not already visible
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// VAL-LOOKUP-001: Create menu bar status item with book icon
    private func setupStatusBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: "LexisDic")
        item.button?.image?.size = NSSize(width: 18, height: 18)
        item.button?.action = #selector(togglePopover)
        item.button?.target = self
        self.statusItem = item

        // VAL-LOOKUP-002: Create popover for the menu bar popup
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 480)
        popover.behavior = .transient
        popover.animates = true

        let menuBarView = MenuBarView()
            .environmentObject(WordStore())
            .environmentObject(NetworkMonitor.shared)
            .environmentObject(ClipboardManager.shared)
            .environmentObject(LocalizationManager.shared)

        let hostingController = NSHostingController(rootView: menuBarView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 320, height: 480)
        popover.contentViewController = hostingController
        self.popover = popover
    }

    /// VAL-LOOKUP-002 / VAL-LOOKUP-010: Toggle the menu bar popover
    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Activate the app so keyboard events are captured
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title != "" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
                .environmentObject(LocalizationManager.shared)
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 350),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.center()
            preferencesWindow?.setFrameAutosaveName("Preferences")
            preferencesWindow?.contentView = NSHostingView(rootView: preferencesView)
            preferencesWindow?.title = NSLocalizedString("preferences.title", comment: "")
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
