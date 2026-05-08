import SwiftUI

@main
struct AIDictionaryApp: App {
    @StateObject private var wordStore = WordStore()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var initialSearchText: String = ""
    @State private var licenseActivated = false
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
                .task {
                    await activateLicenseIfNeeded()
                }
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
            Button("Open Dictionary") {
                appDelegate.openMainWindow()
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }

    private func activateLicenseIfNeeded() async {
        // Skip activation if already has license
        if LicenseManager.shared.hasLicense() {
            return
        }

        // In development, skip if no receipt
        if Bundle.main.appStoreReceiptURL == nil {
            print("Development mode: No App Store receipt, skipping activation")
            return
        }

        do {
            try await LicenseManager.shared.activateLicense()
            print("License activated successfully")
        } catch {
            print("License activation failed: \(error)")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: NSWindow?
    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_: Notification) {}

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        } else {
            // If no window exists, the app will create one via WindowGroup
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
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
