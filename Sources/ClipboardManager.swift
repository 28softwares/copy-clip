import AppKit
import Combine

class ClipboardItem: Identifiable, ObservableObject, Codable, Equatable {
    let id: UUID
    let content: String
    let timestamp: Date
    let type: ClipboardType
    var imageData: Data? // Store image as PNG data
    
    enum ClipboardType: String, Codable {
        case text
        case image
        case url
    }
    
    init(content: String, type: ClipboardType = .text, imageData: Data? = nil) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.type = type
        self.imageData = imageData
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Custom Codable implementation to handle imageData
    enum CodingKeys: String, CodingKey {
        case id, content, timestamp, type, imageData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(ClipboardType.self, forKey: .type)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(imageData, forKey: .imageData)
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
            
            // Check for image first (images can also have string representations)
            if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                // Convert image to PNG data
                if let tiffData = image.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    
                    // Avoid duplicates - check if same image was just copied
                    if let lastItem = history.first, 
                       lastItem.type == .image,
                       let lastImageData = lastItem.imageData,
                       lastImageData == pngData {
                        return
                    }
                    
                    let item = ClipboardItem(content: "Image", type: .image, imageData: pngData)
                    addToHistory(item)
                    return
                }
            }
            
            // Check for text
            if let string = pasteboard.string(forType: .string), !string.isEmpty {
                // Avoid duplicates if the last item is the same
                if let lastItem = history.first, lastItem.content == string && lastItem.type == .text {
                    return
                }
                
                let item = ClipboardItem(content: string, type: .text)
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
        
        if item.type == .image, let imageData = item.imageData, let image = NSImage(data: imageData) {
            // Copy image to clipboard
            pasteboard.writeObjects([image])
        } else {
            // Copy text to clipboard
            pasteboard.setString(item.content, forType: .string)
        }
        
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

