import AppKit
import Combine
import ObjectiveC

class MenuBarController {
    private var statusItem: NSStatusItem?
    private let windowController: WindowController
    private let clipboardManager: ClipboardManager
    private var menu: NSMenu?
    private var menuBarCheckTimer: Timer?
    
    // Keep strong reference to prevent deallocation
    static var shared: MenuBarController?
    
    init(windowController: WindowController, clipboardManager: ClipboardManager) {
        self.windowController = windowController
        self.clipboardManager = clipboardManager
        MenuBarController.shared = self
        setupMenuBar()
        observeClipboardChanges()
        startMenuBarMonitoring()
    }
    
    private func startMenuBarMonitoring() {
        // Check every 0.5 seconds if menu bar is still visible
        menuBarCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.ensureMenuBarVisible()
        }
        // Make sure timer runs even when window is closed
        RunLoop.main.add(menuBarCheckTimer!, forMode: .common)
    }
    
    deinit {
        menuBarCheckTimer?.invalidate()
    }
    
    private func setupMenuBar() {
        // Only recreate if status item is truly missing or invalid
        if let existingItem = statusItem {
            if let button = existingItem.button, button.image != nil, button.superview != nil {
                // Status item is still valid, just update menu
                updateMenu()
                return
            }
            // Remove invalid status item
            NSStatusBar.system.removeStatusItem(existingItem)
        }
        
        // Create new status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            return
        }
        
        // Use clipboard icon
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyClip")
        button.image?.isTemplate = true
        
        // Ensure status item persists
        statusItem?.autosaveName = "CopyClipStatusItem"
        
        // Keep strong references to prevent deallocation
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        
        // Store reference to prevent deallocation
        objc_setAssociatedObject(button, "MenuBarController", self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        updateMenu()
    }
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        // Show menu when clicked
        statusItem?.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.frame.height), in: sender)
    }
    
    func ensureMenuBarVisible() {
        // Ensure activation policy keeps menu bar visible FIRST
        NSApp.setActivationPolicy(.accessory)
        
        // Check if status item exists and is valid
        var needsRecreation = false
        
        if statusItem == nil {
            needsRecreation = true
        } else if let button = statusItem?.button {
            // Check if button still has image (if not, it might have been removed)
            if button.image == nil {
                // Try to restore image
                button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyClip")
                button.image?.isTemplate = true
                // If image is still nil after setting, recreate
                if button.image == nil {
                    needsRecreation = true
                }
            }
            // Verify button is still in the view hierarchy
            if button.superview == nil {
                needsRecreation = true
            }
        } else {
            // Button is nil, need to recreate
            needsRecreation = true
        }
        
        // Recreate if needed
        if needsRecreation {
            // Don't remove the old one if it still exists (to avoid flicker)
            let oldItem = statusItem
            setupMenuBar()
            // Now remove the old one if it's different
            if let old = oldItem, old !== statusItem {
                NSStatusBar.system.removeStatusItem(old)
            }
        }
        
        // Double-check activation policy
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func observeClipboardChanges() {
        // Observe clipboard history changes to update menu
        clipboardManager.$history
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateMenu() {
        menu = NSMenu()
        
        // Add clipboard history items (limit to 30)
        let historyItems = Array(clipboardManager.history.prefix(30))
        
        if historyItems.isEmpty {
            let noItems = NSMenuItem(title: "No clipboard history", action: nil, keyEquivalent: "")
            noItems.isEnabled = false
            menu?.addItem(noItems)
        } else {
            for (index, item) in historyItems.enumerated() {
                let menuItem = NSMenuItem()
                
                if item.type == .image {
                    // For images, show thumbnail and label
                    menuItem.title = "📷 Image"
                    if let imageData = item.imageData, let image = NSImage(data: imageData) {
                        // Create thumbnail (max 64x64)
                        let thumbnail = NSImage(size: NSSize(width: 64, height: 64))
                        thumbnail.lockFocus()
                        image.draw(in: NSRect(x: 0, y: 0, width: 64, height: 64),
                                  from: NSRect.zero,
                                  operation: .sourceOver,
                                  fraction: 1.0)
                        thumbnail.unlockFocus()
                        menuItem.image = thumbnail
                    }
                } else {
                    menuItem.title = truncateText(item.content, maxLength: 50)
                }
                
                menuItem.action = #selector(copyItem(_:))
                menuItem.target = self
                menuItem.representedObject = item
                menuItem.toolTip = item.type == .image ? "Image" : item.content
                menu?.addItem(menuItem)
            }
        }
        
        menu?.addItem(NSMenuItem.separator())
        
        // View All option
        let viewAllItem = NSMenuItem(title: "View All...", action: #selector(viewAll), keyEquivalent: "")
        viewAllItem.target = self
        menu?.addItem(viewAllItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        let truncated = String(text.prefix(maxLength))
        return truncated + "..."
    }
    
    @objc private func copyItem(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? ClipboardItem {
            clipboardManager.copyToClipboard(item)
        }
    }
    
    @objc private func viewAll() {
        windowController.showWindow()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

