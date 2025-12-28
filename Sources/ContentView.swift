import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var searchText: String = ""
    @State private var selectedItem: ClipboardItem?
    @FocusState private var isSearchFocused: Bool
    @State private var timeRefreshTrigger: Date = Date()
    
    var filteredHistory: [ClipboardItem] {
        clipboardManager.searchHistory(query: searchText)
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
                            window.orderOut(nil)
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
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search clipboard history...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSearchFocused = true
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // History list
            if filteredHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No clipboard history" : "No results found")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredHistory) { item in
                            ClipboardItemRow(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                timeRefreshTrigger: timeRefreshTrigger,
                                onSelect: { selectedItem = $0 },
                                onCopy: {
                                    clipboardManager.copyToClipboard($0)
                                    if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                                        window.orderOut(nil)
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
        .onAppear {
            isSearchFocused = true
            // Start timer to refresh timestamps every 10 seconds
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                timeRefreshTrigger = Date()
            }
        }
        .onChange(of: filteredHistory) { _ in
            // Reset selection when filtered results change
            if let first = filteredHistory.first, selectedItem == nil {
                selectedItem = first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in
            searchText = ""
            selectedItem = nil
        }
        .background(
            // Keyboard shortcuts
            KeyEventHandling(
                onEscape: {
                    if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                        window.orderOut(nil)
                    }
                },
                onEnter: {
                    if let selected = selectedItem {
                        clipboardManager.copyToClipboard(selected)
                        if let window = NSApplication.shared.windows.first(where: { $0.isVisible }) {
                            window.orderOut(nil)
                        }
                    }
                },
                onUp: {
                    if let current = selectedItem, let index = filteredHistory.firstIndex(where: { $0.id == current.id }) {
                        if index > 0 {
                            selectedItem = filteredHistory[index - 1]
                        }
                    } else if !filteredHistory.isEmpty {
                        selectedItem = filteredHistory.first
                    }
                },
                onDown: {
                    if let current = selectedItem, let index = filteredHistory.firstIndex(where: { $0.id == current.id }) {
                        if index < filteredHistory.count - 1 {
                            selectedItem = filteredHistory[index + 1]
                        }
                    } else if !filteredHistory.isEmpty {
                        selectedItem = filteredHistory.first
                    }
                },
                onDelete: {
                    if let selected = selectedItem {
                        clipboardManager.deleteItem(selected)
                        selectedItem = filteredHistory.first(where: { $0.id != selected.id })
                    }
                }
            )
        )
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let timeRefreshTrigger: Date
    let onSelect: (ClipboardItem) -> Void
    let onCopy: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .lineLimit(3)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                Text(item.timestamp, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .id(timeRefreshTrigger) // Force refresh every 10 seconds
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

