import SwiftUI

@main
struct AIDictionaryApp: App {
    @StateObject private var wordStore = WordStore()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wordStore)
                .environmentObject(networkMonitor)
                .environmentObject(clipboardManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra("Dictionary", systemImage: "character.book.closed") {
            MenuBarView()
                .environmentObject(wordStore)
                .environmentObject(networkMonitor)
                .environmentObject(clipboardManager)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: NSWindow?

    func applicationDidFinishLaunching(_: Notification) {}

    @objc func openPreferences() {
        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.center()
            preferencesWindow?.setFrameAutosaveName("Preferences")
            preferencesWindow?.contentView = NSHostingView(rootView: preferencesView)
            preferencesWindow?.title = "Preferences"
        }

        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
