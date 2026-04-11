import SwiftUI

@main
struct AIDictionaryApp: App {
    @StateObject private var wordStore = WordStore()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wordStore)
                .environmentObject(networkMonitor)
                .environmentObject(clipboardManager)
                .environmentObject(localizationManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button(NSLocalizedString("preferences.title", comment: "")) {
                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra(localizationManager.appName, systemImage: "character.book.closed") {
            MenuBarView()
                .environmentObject(wordStore)
                .environmentObject(networkMonitor)
                .environmentObject(clipboardManager)
                .environmentObject(localizationManager)
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
