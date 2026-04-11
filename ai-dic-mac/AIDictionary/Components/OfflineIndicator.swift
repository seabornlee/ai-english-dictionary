import SwiftUI

struct OfflineIndicator: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var wordStore: WordStore
    
    private let surfaceHigh = Color(hex: "#28283d")
    private let cyanAccent = Color(hex: "#00d4ff")
    private let onSurfaceVariant = Color(hex: "#bbc9cf")
    
    var body: some View {
        if !networkMonitor.isOnline {
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 12, weight: .medium))
                
                Text(NSLocalizedString("offline.title", comment: ""))
                    .font(.system(size: 11, weight: .bold))
                
                if wordStore.offlineCacheCount > 0 {
                    Text(String(format: NSLocalizedString("offline.cached", comment: ""), wordStore.offlineCacheCount))
                        .font(.system(size: 10))
                        .foregroundColor(onSurfaceVariant)
                }
            }
            .foregroundColor(cyanAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(surfaceHigh.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(cyanAccent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct MenuBarClipboardBadge: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var isPulsing = false
    
    private let cyanAccent = Color(hex: "#00d4ff")
    
    var body: some View {
        if clipboardManager.hasNewContent {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 10))
                
                Text(NSLocalizedString("offline.new_word", comment: ""))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(Color(hex: "#003642"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(cyanAccent)
            )
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.9 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onDisappear {
                isPulsing = false
            }
            .onTapGesture {
                clipboardManager.clearNotification()
                FloatingWindowService.shared.showFloatingWindow(with: clipboardManager.clipboardText)
            }
        }
    }
}
