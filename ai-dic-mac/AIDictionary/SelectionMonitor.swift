import Cocoa
import ApplicationServices

class SelectionMonitor {
    private var observer: AXObserver?
    private var lastSelectedText: String?
    private var currentAppPID: pid_t = 0
    private var safariPollingTimer: Timer?
    private var lastClipboardContent: String?
    private var clipboardTimer: Timer?
    private var mouseDownMonitor: Any?
    private var mouseUpMonitor: Any?
    private var isMouseDown = false
    
    init() {
        // 监听前台应用切换
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Start clipboard monitoring
        startClipboardMonitoring()
        
        // Setup mouse event monitoring
        setupMouseMonitoring()
        
        startMonitoring()
    }
    
    private func setupMouseMonitoring() {
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.isMouseDown = true
        }
        
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.isMouseDown = false
            self?.checkCurrentSelection()
        }
    }
    
    private func checkCurrentSelection() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        
        if let webArea = findWebArea(element: appElement) {
            var selectedText: AnyObject?
            if AXUIElementCopyAttributeValue(webArea, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
               let text = selectedText as? String, !text.isEmpty {
                processSelectedText(text)
            }
        }
    }
    
    private func processSelectedText(_ text: String) {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        if wordCount <= 3 && text != lastSelectedText {
            print("[SelectionMonitor] Selected text: \(text)")
            lastSelectedText = text
            DispatchQueue.main.async {
                FloatingWindowService.shared.showFloatingWindow(with: text)
            }
        }
    }
    
    private func startClipboardMonitoring() {
        // Check clipboard every 0.5 seconds
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard let clipboardString = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardString.isEmpty,
              clipboardString != lastClipboardContent else {
            return
        }
        
        // Only process if it's a single word (no spaces)
        if !clipboardString.contains(" ") {
            lastClipboardContent = clipboardString
            DispatchQueue.main.async {
                FloatingWindowService.shared.showFloatingWindow(with: clipboardString)
            }
        }
    }
    
    deinit {
        clipboardTimer?.invalidate()
        safariPollingTimer?.invalidate()
        if let eventMonitor = observer {
            NSEvent.removeMonitor(eventMonitor)
        }
        if let mouseDownMonitor = mouseDownMonitor {
            NSEvent.removeMonitor(mouseDownMonitor)
        }
        if let mouseUpMonitor = mouseUpMonitor {
            NSEvent.removeMonitor(mouseUpMonitor)
        }
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
        
        // Check if the element is in a browser's address bar
        var role: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
           let roleStr = role as? String {
            // Ignore if it's a text field (which includes address bars)
            if roleStr == "AXTextField" || roleStr == "AXTextArea" {
                return
            }
        }
        
        // Only process selection if mouse is not down
        if !isMouseDown {
            var selectedText: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText) == .success,
               let text = selectedText as? String, !text.isEmpty {
                processSelectedText(text)
            }
        }
    }
} 