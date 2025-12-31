import SwiftUI
import AppKit

struct KeyboardShortcutHandler: NSViewRepresentable {
    let isSearchFocused: Bool
    @Binding var selectedItem: ClipboardItem?
    let filteredHistory: [ClipboardItem]
    let clipboardManager: ClipboardManager
    
    func makeNSView(context: Context) -> KeyboardHandlerView {
        let view = KeyboardHandlerView()
        view.isSearchFocused = isSearchFocused
        view.selectedItem = $selectedItem
        view.filteredHistory = filteredHistory
        view.clipboardManager = clipboardManager
        return view
    }
    
    func updateNSView(_ nsView: KeyboardHandlerView, context: Context) {
        nsView.isSearchFocused = isSearchFocused
        nsView.selectedItem = $selectedItem
        nsView.filteredHistory = filteredHistory
        nsView.clipboardManager = clipboardManager
    }
}

class KeyboardHandlerView: NSView {
    var isSearchFocused: Bool = false
    var selectedItem: Binding<ClipboardItem?>?
    var filteredHistory: [ClipboardItem] = []
    var clipboardManager: ClipboardManager?
    
    override var acceptsFirstResponder: Bool { false }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Never intercept if search field is focused - let it handle all input
        if isSearchFocused {
            return false
        }
        
        // Check if a text field is currently editing
        if let firstResponder = self.window?.firstResponder,
           firstResponder is NSTextView || firstResponder is NSTextField {
            return false
        }
        
        let keyCode = event.keyCode
        switch keyCode {
        case 53: // Escape
            if let window = self.window {
                NSApp.setActivationPolicy(.accessory)
                if let menuBar = MenuBarController.shared {
                    menuBar.ensureMenuBarVisible()
                }
                window.orderOut(nil)
                NSApp.setActivationPolicy(.accessory)
                if let menuBar = MenuBarController.shared {
                    menuBar.ensureMenuBarVisible()
                }
            }
            return true
        case 36: // Enter
            if let selected = selectedItem?.wrappedValue {
                clipboardManager?.copyToClipboard(selected)
                if let window = self.window {
                    NSApp.setActivationPolicy(.accessory)
                    if let menuBar = MenuBarController.shared {
                        menuBar.ensureMenuBarVisible()
                    }
                    window.orderOut(nil)
                    NSApp.setActivationPolicy(.accessory)
                    if let menuBar = MenuBarController.shared {
                        menuBar.ensureMenuBarVisible()
                    }
                }
                return true
            }
            return false
        case 126: // Up Arrow
            if let current = selectedItem?.wrappedValue, let index = filteredHistory.firstIndex(where: { $0.id == current.id }) {
                if index > 0 {
                    selectedItem?.wrappedValue = filteredHistory[index - 1]
                }
            } else if !filteredHistory.isEmpty {
                selectedItem?.wrappedValue = filteredHistory.first
            }
            return true
        case 125: // Down Arrow
            if let current = selectedItem?.wrappedValue, let index = filteredHistory.firstIndex(where: { $0.id == current.id }) {
                if index < filteredHistory.count - 1 {
                    selectedItem?.wrappedValue = filteredHistory[index + 1]
                }
            } else if !filteredHistory.isEmpty {
                selectedItem?.wrappedValue = filteredHistory.first
            }
            return true
        case 51: // Delete/Backspace
            if let selected = selectedItem?.wrappedValue {
                clipboardManager?.deleteItem(selected)
                selectedItem?.wrappedValue = filteredHistory.first(where: { $0.id != selected.id })
                return true
            }
            return false
        default:
            return false
        }
    }
}

