import AppKit
import Carbon

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(signature: FourCharCode(fromString: "COPY"), id: 1)
    private var callback: (() -> Void)?
    private static var managerInstance: HotKeyManager?
    
    func register(control: Bool = true, option: Bool = true, key: UInt32 = 0x09, callback: @escaping () -> Void) {
        self.callback = callback
        HotKeyManager.managerInstance = self
        
        var modifiers: UInt32 = 0
        if control {
            modifiers |= UInt32(controlKey)
        }
        if option {
            modifiers |= UInt32(optionKey)
        }
        
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // Use InstallEventHandler with a C function pointer
        let handler: @convention(c) (EventHandlerCallRef?, EventRef?, UnsafeMutableRawPointer?) -> OSStatus = { (nextHandler, theEvent, userData) in
            guard let theEvent = theEvent else { return OSStatus(eventNotHandledErr) }

           
            
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if let manager = HotKeyManager.managerInstance {
                if hotKeyID.id == manager.hotKeyID.id {
                    DispatchQueue.main.async {
                        manager.callback?()
                    }
                }
            }
            
            return noErr
        }
        
        let handlerUPP = unsafeBitCast(handler, to: EventHandlerUPP.self)
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerUPP,
            1,
            &eventSpec,
            nil,
            nil
        )
        
        RegisterEventHotKey(
            key,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        HotKeyManager.managerInstance = nil
    }
}

extension FourCharCode {
    init(fromString string: String) {
        var result: FourCharCode = 0
        for (index, char) in string.utf8.prefix(4).enumerated() {
            result |= FourCharCode(char) << (8 * (3 - index))
        }
        self = result
    }
}
