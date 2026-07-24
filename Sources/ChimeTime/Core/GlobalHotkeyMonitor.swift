import AppKit
import Carbon.HIToolbox

/// System-wide hotkey via Carbon's `RegisterEventHotKey`.
///
/// Deliberately *not* `NSEvent.addGlobalMonitorForEvents`: that requires the
/// Accessibility permission, which a sandboxed Mac App Store app cannot get
/// (and asking for it is an App Review rejection). `RegisterEventHotKey` needs
/// no permission and no prompt, and works fine inside the sandbox.
final class GlobalHotkeyMonitor {

    var onHotkey: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var registrationID: UInt32?

    /// The Carbon callback must be a capture-free C function pointer, so live
    /// monitors are looked up through this registry by hotkey ID.
    private static var registry: [UInt32: GlobalHotkeyMonitor] = [:]
    private static var nextID: UInt32 = 1
    private static let signature: OSType = 0x43_48_4D_45  // 'CHME'

    func start(keyCode: Int, modifiers: Int) {
        stop()

        let id = Self.nextID
        Self.nextID += 1
        Self.registry[id] = self
        registrationID = id

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }
                var firedID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &firedID
                )
                guard status == noErr,
                      let monitor = GlobalHotkeyMonitor.registry[firedID.id] else {
                    return OSStatus(eventNotHandledErr)
                }
                DispatchQueue.main.async { monitor.onHotkey?() }
                return noErr
            },
            1,
            &eventType,
            nil,
            &handlerRef
        )

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        RegisterEventHotKey(
            UInt32(keyCode),
            Self.carbonModifiers(from: modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
        if let registrationID {
            Self.registry.removeValue(forKey: registrationID)
            self.registrationID = nil
        }
    }

    deinit {
        stop()
    }

    /// Translate `NSEvent.ModifierFlags` raw bits into Carbon modifier bits.
    static func carbonModifiers(from modifiers: Int) -> UInt32 {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }

    /// Human-readable description of the current shortcut
    static func shortcutDescription(keyCode: Int, modifiers: Int) -> String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        if flags.contains(.control) { parts.append("\u{2303}") }
        if flags.contains(.option) { parts.append("\u{2325}") }
        if flags.contains(.shift) { parts.append("\u{21E7}") }
        if flags.contains(.command) { parts.append("\u{2318}") }

        let keyName: String
        switch keyCode {
        case 49: keyName = "Space"
        case 36: keyName = "Return"
        case 48: keyName = "Tab"
        case 51: keyName = "Delete"
        case 53: keyName = "Esc"
        default:
            if let char = keyCodeToChar(keyCode) {
                keyName = char
            } else {
                keyName = "Key\(keyCode)"
            }
        }
        parts.append(keyName)
        return parts.joined()
    }

    private static func keyCodeToChar(_ keyCode: Int) -> String? {
        let mapping: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
            45: "N", 46: "M"
        ]
        return mapping[keyCode]
    }
}
