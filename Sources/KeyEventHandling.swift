import SwiftUI
import AppKit

struct KeyEventHandling: NSViewRepresentable {
    let onEscape: () -> Void
    let onEnter: () -> Void
    let onUp: () -> Void
    let onDown: () -> Void
    let onDelete: () -> Void
    
    func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.onEscape = onEscape
        view.onEnter = onEnter
        view.onUp = onUp
        view.onDown = onDown
        view.onDelete = onDelete
        return view
    }
    
    func updateNSView(_ nsView: KeyView, context: Context) {
        nsView.onEscape = onEscape
        nsView.onEnter = onEnter
        nsView.onUp = onUp
        nsView.onDown = onDown
        nsView.onDelete = onDelete
    }
}

class KeyView: NSView {
    var onEscape: (() -> Void)?
    var onEnter: (() -> Void)?
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?
    var onDelete: (() -> Void)?
    
    // Don't accept first responder - let TextField handle it
    override var acceptsFirstResponder: Bool { false }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Check if a text field is currently editing
        if let firstResponder = self.window?.firstResponder,
           firstResponder is NSTextView || firstResponder is NSTextField {
            // Let text field handle it
            return false
        }
        
        // Only handle navigation keys when not in text field
        let keyCode = event.keyCode
        switch keyCode {
        case 53: // Escape
            onEscape?()
            return true
        case 36: // Enter
            onEnter?()
            return true
        case 126: // Up Arrow
            onUp?()
            return true
        case 125: // Down Arrow
            onDown?()
            return true
        case 51: // Delete/Backspace
            onDelete?()
            return true
        default:
            return false
        }
    }
}

