import SwiftUI
import AppKit

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
        // When window becomes key, ensure menu bar stays
        NSApp.setActivationPolicy(.accessory)
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
            // Ensure menu bar stays visible after closing window
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
            
            window = NSWindow(
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
        
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(window?.contentView)
        // Don't activate app - keep menu bar active in background
        NSApp.activate(ignoringOtherApps: false)
        // Ensure activation policy stays as accessory (menu bar only)
        NSApp.setActivationPolicy(.accessory)
    }
}

