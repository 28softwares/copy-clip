import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var selectedItem: ClipboardItem?
    
    var history: [ClipboardItem] {
        clipboardManager.history
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    Text("CopyClip")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        clipboardManager.clearHistory()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Clear History")
                    
                    Button(action: {
                        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                            // Ensure menu bar stays visible BEFORE closing
                            NSApp.setActivationPolicy(.accessory)
                            if let menuBar = MenuBarController.shared {
                                menuBar.ensureMenuBarVisible()
                            }
                            // Hide window
                            window.orderOut(nil)
                            // Immediately re-ensure menu bar
                            NSApp.setActivationPolicy(.accessory)
                            if let menuBar = MenuBarController.shared {
                                menuBar.ensureMenuBarVisible()
                            }
                            // Also check after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                NSApp.setActivationPolicy(.accessory)
                                if let menuBar = MenuBarController.shared {
                                    menuBar.ensureMenuBarVisible()
                                }
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Close")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // History list
            if history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No clipboard history")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(history) { item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                onSelect: { selectedItem = $0 },
                                onCopy: {
                                    clipboardManager.copyToClipboard($0)
                                    if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                                        // Ensure menu bar stays visible BEFORE closing
                                        NSApp.setActivationPolicy(.accessory)
                                        if let menuBar = MenuBarController.shared {
                                            menuBar.ensureMenuBarVisible()
                                        }
                                        window.orderOut(nil)
                                        // Re-ensure menu bar after closing
                                        NSApp.setActivationPolicy(.accessory)
                                        if let menuBar = MenuBarController.shared {
                                            menuBar.ensureMenuBarVisible()
                                        }
                                    }
                                },
                                onDelete: { clipboardManager.deleteItem($0) }
                            )
                        }
                    }
                }
            }
        }
        .frame(width: 450, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
        .onChange(of: history) { _ in
            // Reset selection when history changes
            if let first = history.first, selectedItem == nil {
                selectedItem = first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            selectedItem = nil
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onSelect: (ClipboardItem) -> Void
    let onCopy: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if item.type == .image, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    // Display image thumbnail
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 100)
                        .cornerRadius(4)
                } else {
                    // Display text
                    Text(item.content)
                        .lineLimit(3)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    if item.type == .image {
                        Image(systemName: "photo")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Text(item.timestamp, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { onCopy(item) }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy")
                
                Button(action: { onDelete(item) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete")
            }
            .opacity(isSelected ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color(NSColor.quaternaryLabelColor).opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(item)
            onCopy(item)
        }
        .onHover { hovering in
            if hovering {
                onSelect(item)
            }
        }
    }
}

