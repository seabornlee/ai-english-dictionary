import ApplicationServices
import SwiftUI

@main
struct AIDictionaryApp: App {
    @StateObject private var wordStore = WordStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wordStore)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // Initialize the floating window service
                    _ = FloatingWindowService.shared
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    NSApp.sendAction(#selector(AppDelegate.openPreferences), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        // Menu bar extra
        MenuBarExtra("Dictionary", systemImage: "character.book.closed") {
            MenuBarView()
                .environmentObject(wordStore)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: NSWindow?
    var selectionMonitor: SelectionMonitor?

    func applicationDidFinishLaunching(_: Notification) {
        // Initialize accessibility if needed
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)

        // 初始化SelectionMonitor
        selectionMonitor = SelectionMonitor()
    }

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
