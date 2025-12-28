import AppKit
import Combine

class ClipboardItem: Identifiable, ObservableObject, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ClipboardType
    
    enum ClipboardType: String, Codable {
        case text
        case image
        case url
    }
    
    init(content: String, type: ClipboardType = .text) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

class ClipboardManager: ObservableObject {
    @Published var history: [ClipboardItem] = []
    private var pasteboard: NSPasteboard
    private var changeCount: Int
    private var timer: Timer?
    private let maxHistorySize = 1000
    private let storageKey = "CopyClipHistory"
    
    init() {
        pasteboard = NSPasteboard.general
        changeCount = pasteboard.changeCount
        loadHistory()
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Schedule timer on main run loop to keep running in background
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        // Ensure timer continues even when window is open
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != changeCount {
            changeCount = currentChangeCount
            
            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                // Avoid duplicates if the last item is the same
                if let lastItem = history.first, lastItem.content == string {
                    return
                }
                
                let item = ClipboardItem(content: string, type: .text)
                addToHistory(item)
            } else if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                // Handle image (store as base64 or reference)
                let item = ClipboardItem(content: "Image", type: .image)
                addToHistory(item)
            }
        }
    }
    
    private func addToHistory(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.history.insert(item, at: 0)
            
            // Limit history size
            if self.history.count > self.maxHistorySize {
                self.history = Array(self.history.prefix(self.maxHistorySize))
            }
            
            self.saveHistory()
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        changeCount = pasteboard.changeCount
    }
    
    func deleteItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.history.removeAll { $0.id == item.id }
            self.saveHistory()
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.history.removeAll()
            self.saveHistory()
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            history = decoded
        }
    }
    
    func searchHistory(query: String) -> [ClipboardItem] {
        if query.isEmpty {
            return history
        }
        return history.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }
}

