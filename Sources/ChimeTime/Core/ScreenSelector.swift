import AppKit

final class ScreenSelector {
    /// Maps a display preference string to an NSScreen
    /// - "main": the main screen (with menu bar)
    /// - "builtin": the built-in display (laptop screen)
    /// - Screen name string: matches by localizedName
    static func screen(for preference: String) -> NSScreen {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            return NSScreen.main ?? NSScreen.screens[0]
        }

        switch preference {
        case "main":
            return NSScreen.main ?? screens[0]
        case "builtin":
            // Built-in display typically has a specific device description
            if let builtin = screens.first(where: { isBuiltIn($0) }) {
                return builtin
            }
            return NSScreen.main ?? screens[0]
        default:
            // Match by localized name
            if let named = screens.first(where: { $0.localizedName == preference }) {
                return named
            }
            return NSScreen.main ?? screens[0]
        }
    }

    /// Get display options for the picker
    static var availableDisplays: [(id: String, name: String)] {
        var options: [(id: String, name: String)] = [("main", "Main Display")]

        for screen in NSScreen.screens {
            let name = screen.localizedName
            if !options.contains(where: { $0.name == name }) {
                options.append((name, name))
            }
        }

        return options
    }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        let description = screen.deviceDescription
        if let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return CGDisplayIsBuiltin(screenNumber) != 0
        }
        return false
    }
}
