import SwiftUI
import AppKit
import Carbon.HIToolbox
import ApplicationServices

class FloatingWindowService {
    static let shared = FloatingWindowService()
    
    private var floatingWindow: NSWindow?
    private var eventMonitor: Any?
    private var selectedWord: String = ""
    
    private init() {
        setupHotkey()
    }
    
    private func setupHotkey() {
        // Register Command+D shortcut
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        
        if !AXIsProcessTrustedWithOptions(options as CFDictionary) {
            // Need to request accessibility permissions
            print("Application needs accessibility permissions")
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            if event.modifierFlags.contains(.command) && event.keyCode == UInt16(kVK_ANSI_D) {
                self.handleCommandD()
            }
        }
    }
    
    private func handleCommandD() {
        guard UserDefaults.standard.bool(forKey: "shortcutEnabled") else { return }
        
        selectedWord = getSelectedText() ?? ""
        
        if !selectedWord.isEmpty {
            showFloatingWindow()
        }
    }
    
    private func getSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        
        // Save old content
        let oldContents = pasteboard.string(forType: .string)
        
        // Clear the pasteboard and copy the selection
        pasteboard.clearContents()
        let copyScript = NSAppleScript(source: "tell application \"System Events\" to keystroke \"c\" using command down")
        var error: NSDictionary?
        copyScript?.executeAndReturnError(&error)
        
        // Get the selection
        let selectedText = pasteboard.string(forType: .string)
        
        // Restore old content if needed
        if let oldContents = oldContents {
            pasteboard.clearContents()
            pasteboard.setString(oldContents, forType: .string)
        }
        
        return selectedText?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func showFloatingWindow() {
        // Close existing window if any
        floatingWindow?.close()
        
        // Create content view
        let contentView = FloatingWordView(word: selectedWord) {
            self.closeFloatingWindow()
        }
        
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.title = "AI Dictionary"
        
        // Position window near the cursor
        if let screenFrame = NSScreen.main?.frame {
            let mouseLocation = NSEvent.mouseLocation
            var windowFrame = window.frame
            let cursorOffset: CGFloat = 20 // Offset from cursor
            
            windowFrame.origin.x = mouseLocation.x
            windowFrame.origin.y = screenFrame.height - mouseLocation.y - windowFrame.height - cursorOffset
            
            // Ensure window is visible on screen
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
        
        // Close when clicking outside
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let window = self.floatingWindow else { return }
            
            if !NSPointInRect(NSEvent.mouseLocation, window.frame) {
                self.closeFloatingWindow()
            }
        }
        
        floatingWindow = window
    }
    
    func closeFloatingWindow() {
        floatingWindow?.close()
        floatingWindow = nil
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}

struct FloatingWordView: View {
    let word: String
    let onClose: () -> Void
    
    @State private var isLoading = true
    @State private var definition: String = ""
    @State private var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(word)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                }
                .padding()
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text(definition)
                    .lineLimit(5)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button("Open in Dictionary") {
                    // Open main window with this word
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showMainWindow:")), to: nil, from: nil)
                    // TODO: Pass the word to search
                    onClose()
                }
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .onAppear {
            loadDefinition()
        }
    }
    
    private func loadDefinition() {
        isLoading = true
        
        Task {
            do {
                let result = try await APIService.shared.lookupWord(word, avoidWords: [])
                DispatchQueue.main.async {
                    self.definition = result.definition
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
} 