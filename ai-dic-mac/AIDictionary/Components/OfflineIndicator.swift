import SwiftUI

struct OfflineIndicator: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var wordStore: WordStore
    
    var body: some View {
        if !networkMonitor.isOnline {
            HStack(spacing: 6) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 12, weight: .medium))
                
                Text("Offline")
                    .font(.system(size: 12, weight: .medium))
                
                if wordStore.offlineCacheCount > 0 {
                    Text("(\(wordStore.offlineCacheCount) cached)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct MenuBarClipboardBadge: View {
    @EnvironmentObject private var clipboardManager: ClipboardManager
    @State private var isPulsing = false
    
    var body: some View {
        if clipboardManager.hasNewContent {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 10))
                
                Text("New word")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(NSColor.systemGreen))
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
                // Trigger lookup
                FloatingWindowService.shared.showFloatingWindow(with: clipboardManager.clipboardText)
            }
        }
    }
}
