import SwiftUI
import Combine

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published var hasNewContent = false
    @Published var clipboardText: String = ""
    
    private var timer: Timer?
    private var lastClipboardContent: String?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard
            let clipboardString = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !clipboardString.isEmpty,
            clipboardString != lastClipboardContent
        else {
            return
        }
        
        lastClipboardContent = clipboardString
        clipboardText = clipboardString
        
        // Check if it's a valid English word
        let wordCount = clipboardString.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        if wordCount <= 3, TextValidation.isValidEnglishWord(clipboardString) {
            hasNewContent = true
            
            // Auto-hide after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.hasNewContent = false
            }
        }
    }
    
    func clearNotification() {
        hasNewContent = false
    }
    
    deinit {
        timer?.invalidate()
    }
}
