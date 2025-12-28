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
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Escape
            onEscape?()
        case 36: // Enter
            onEnter?()
        case 126: // Up Arrow
            onUp?()
        case 125: // Down Arrow
            onDown?()
        case 51: // Delete/Backspace
            onDelete?()
        default:
            super.keyDown(with: event)
        }
    }
}

