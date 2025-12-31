import SwiftUI
import AppKit

class KeyboardWindow: NSWindow {
    override var acceptsFirstResponder: Bool { true }
    override func makeFirstResponder(_ responder: NSResponder?) -> Bool {
        return super.makeFirstResponder(responder)
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Ensure menu bar stays visible BEFORE hiding
        NSApp.setActivationPolicy(.accessory)
        if let menuBar = MenuBarController.shared {
            menuBar.ensureMenuBarVisible()
        }
        // Hide window instead of closing it
        sender.orderOut(nil)
        // Immediately ensure menu bar stays visible after hiding
        NSApp.setActivationPolicy(.accessory)
        if let menuBar = MenuBarController.shared {
            menuBar.ensureMenuBarVisible()
        }
        return false
    }
    
    func windowWillClose(_ notification: Notification) {
        // Ensure app stays running and menu bar stays active
        NSApp.setActivationPolicy(.accessory)
        if let menuBar = MenuBarController.shared {
            menuBar.ensureMenuBarVisible()
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // When window loses focus, ensure menu bar stays
        NSApp.setActivationPolicy(.accessory)
        if let menuBar = MenuBarController.shared {
            menuBar.ensureMenuBarVisible()
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // When window becomes key, keep as regular to allow keyboard input
        // We'll change back to accessory when window closes
        NSApp.setActivationPolicy(.regular)
    }
}

class WindowController: ObservableObject {
    private var window: NSWindow?
    private let clipboardManager: ClipboardManager
    private let windowDelegate = WindowDelegate()
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
    }
    
    func toggleWindow() {
        if let window = window, window.isVisible {
            window.orderOut(nil)
            // Change back to accessory mode to hide dock icon
            NSApp.setActivationPolicy(.accessory)
            // Re-ensure menu bar controller is still active
            if let menuBar = MenuBarController.shared {
                menuBar.ensureMenuBarVisible()
            }
        } else {
            showWindow()
        }
    }
    
    func showWindow() {
        if window == nil {
            let contentView = ContentView(clipboardManager: clipboardManager)
            let hostingView = NSHostingView(rootView: contentView)
            
            window = KeyboardWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 500),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            window?.delegate = windowDelegate
            window?.contentView = hostingView
            window?.backgroundColor = .clear
            window?.isOpaque = false
            window?.hasShadow = true
            window?.level = .floating
            window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
        
        // Center window on current screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window!.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Temporarily change to regular activation to allow keyboard input
        // This is necessary for TextField to work properly
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Make window key and order front so it can accept keyboard input
        window?.makeKeyAndOrderFront(nil)
        
        // Ensure window accepts keyboard events
        window?.acceptsMouseMovedEvents = true
        window?.isMovableByWindowBackground = false
        
        // Make window key
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.window?.makeKey()
        }
    }
}

