import Cocoa
import ApplicationServices

class SelectionMonitor {
    private var observer: AXObserver?
    private var lastSelectedText: String?
    private var currentAppPID: pid_t = 0
    private var safariPollingTimer: Timer?
    
    init() {
        // 监听前台应用切换
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        startMonitoring()
    }
    
    @objc private func frontAppChanged() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        safariPollingTimer?.invalidate()
        safariPollingTimer = nil
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        if pid == currentAppPID { return }
        currentAppPID = pid
        let appElement = AXUIElementCreateApplication(pid)
        let bundleID = app.bundleIdentifier ?? ""
        
        if bundleID == "com.apple.Safari" {
            // Safari特殊处理：定时轮询
            safariPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.pollSafariSelection(pid: pid)
            }
            return
        }
        
        var observer: AXObserver?
        let callback: AXObserverCallback = { observer, element, notification, refcon in
            let monitor = Unmanaged<SelectionMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            monitor.handleSelectionChange(element: element)
        }
        
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        if AXObserverCreate(pid, callback, &observer) == .success, let observer = observer {
            self.observer = observer
            // 递归监听所有可选中文本的子元素
            addNotificationRecursively(element: appElement, observer: observer, selfPtr: selfPtr)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }
    }
    
    private func addNotificationRecursively(element: AXUIElement, observer: AXObserver, selfPtr: UnsafeMutableRawPointer) {
        // 尝试添加通知
        let result = AXObserverAddNotification(observer, element, kAXSelectedTextChangedNotification as CFString, selfPtr)
        if result == .success {
            // print("Added notification to element: \(element)")
        }
        // 获取子元素
        var children: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
           let childrenArray = children as? [AXUIElement] {
            for child in childrenArray {
                addNotificationRecursively(element: child, observer: observer, selfPtr: selfPtr)
            }
        }
        // 兼容某些控件（如WebView）用AXFocusedUIElement
        var focused: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
           let focusedElement = focused, focusedElement !== element {
            addNotificationRecursively(element: focusedElement as! AXUIElement, observer: observer, selfPtr: selfPtr)
        }
    }
    
    private func pollSafariSelection(pid: pid_t) {
        let appElement = AXUIElementCreateApplication(pid)
        if let webArea = findWebArea(element: appElement) {
            var selectedText: AnyObject?
            if AXUIElementCopyAttributeValue(webArea, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
               let text = selectedText as? String, !text.isEmpty {
                if text != lastSelectedText {
                    print("[Safari Poll - WebArea] Selected text: \(text)")
                    lastSelectedText = text
                    DispatchQueue.main.async {
                        FloatingWindowService.shared.showFloatingWindow(with: text)
                    }
                }
            }
        }
    }
    
    // 递归查找AXWebArea
    private func findWebArea(element: AXUIElement) -> AXUIElement? {
        var role: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
           let roleStr = role as? String, roleStr == "AXWebArea" {
            return element
        }
        var children: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success,
           let childrenArray = children as? [AXUIElement] {
            for child in childrenArray {
                if let found = findWebArea(element: child) {
                    return found
                }
            }
        }
        return nil
    }
    
    private func handleSelectionChange(element: AXUIElement) {
        // Ignore selection changes when the main window is active
        if NSApp.isActive {
            return
        }
        
        var selectedText: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
           let text = selectedText as? String, !text.isEmpty {
            print("[SelectionMonitor] Selected text: \(text)") // 调试日志
            if text != lastSelectedText {
                lastSelectedText = text
                DispatchQueue.main.async {
                    FloatingWindowService.shared.showFloatingWindow(with: text)
                }
            }
        }
    }
} 