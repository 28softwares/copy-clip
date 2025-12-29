import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var clipboardManager: ClipboardManager?
    var windowController: WindowController?
    var hotKeyManager: HotKeyManager?
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon but show in menu bar
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize clipboard manager (runs in background continuously)
        clipboardManager = ClipboardManager()
        
        // Initialize window controller
        windowController = WindowController(clipboardManager: clipboardManager!)
        
        // Setup menu bar icon (stays active in background)
        menuBarController = MenuBarController(windowController: windowController!, clipboardManager: clipboardManager!)
        
        // Setup global hotkey: Ctrl+Option+V
        hotKeyManager = HotKeyManager()
        hotKeyManager?.register(control: true, option: true, key: 0x09) { [weak self] in
            self?.windowController?.toggleWindow()
        }
        
        // Keep app running in background even when window is closed
        // The menu bar icon and clipboard monitoring will continue
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when window closes - keep menu bar running
        // Ensure menu bar stays visible
        NSApp.setActivationPolicy(.accessory)
        menuBarController?.ensureMenuBarVisible()
        return false
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Ensure menu bar stays visible when app becomes active
        NSApp.setActivationPolicy(.accessory)
        menuBarController?.ensureMenuBarVisible()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        // Ensure menu bar stays visible when app resigns active
        NSApp.setActivationPolicy(.accessory)
        menuBarController?.ensureMenuBarVisible()
    }
}

