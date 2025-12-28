import AppKit
import Combine

class MenuBarController {
    private var statusItem: NSStatusItem?
    private let windowController: WindowController
    private let clipboardManager: ClipboardManager
    private var menu: NSMenu?
    
    // Keep strong reference to prevent deallocation
    static var shared: MenuBarController?
    
    init(windowController: WindowController, clipboardManager: ClipboardManager) {
        self.windowController = windowController
        self.clipboardManager = clipboardManager
        MenuBarController.shared = self
        setupMenuBar()
        observeClipboardChanges()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use clipboard icon (📋) or system image
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyClip")
            button.image?.isTemplate = true
        }
        
        // Ensure status item persists
        statusItem?.autosaveName = "CopyClipStatusItem"
        
        updateMenu()
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
                menuItem.title = truncateText(item.content, maxLength: 50)
                menuItem.action = #selector(copyItem(_:))
                menuItem.target = self
                menuItem.representedObject = item
                menuItem.toolTip = item.content
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

