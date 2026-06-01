import AppKit

final class GlobalHotkeyMonitor {
    private var localMonitor: Any?
    private var globalMonitor: Any?
    var onHotkey: (() -> Void)?

    func start(keyCode: Int, modifiers: Int) {
        stop()

        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
            .intersection([.command, .option, .control, .shift])

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(keyCode) &&
               event.modifierFlags.intersection([.command, .option, .control, .shift]) == modifierFlags {
                self?.onHotkey?()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == UInt16(keyCode) &&
               event.modifierFlags.intersection([.command, .option, .control, .shift]) == modifierFlags {
                self?.onHotkey?()
                return nil
            }
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    deinit {
        stop()
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
