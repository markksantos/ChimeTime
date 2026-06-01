import Foundation

final class FocusModeMonitor {
    /// Check if macOS Focus/DND is currently active
    var isFocusActive: Bool {
        // macOS stores DND state in the notification center preferences
        guard let defaults = UserDefaults(suiteName: "com.apple.controlcenter") else {
            return false
        }
        // Check for Focus/DND being enabled
        if defaults.bool(forKey: "NSStatusItem Visible FocusModes") {
            // Focus indicator is visible, check if actively in a focus mode
            return checkDNDActive()
        }
        return checkDNDActive()
    }

    private func checkDNDActive() -> Bool {
        // Read from the DND preferences plist
        guard let dndDefaults = UserDefaults(suiteName: "com.apple.notificationcenterui") else {
            return false
        }
        // doNotDisturbDate being set indicates DND/Focus is active
        if dndDefaults.object(forKey: "doNotDisturb") as? Bool == true {
            return true
        }
        // For newer macOS versions, check via the Focus status
        if let dndPrefs = dndDefaults.dictionary(forKey: "dnd_prefs"),
           let dndMirroring = dndPrefs["dndMirrored"] as? Bool, dndMirroring {
            return true
        }
        // Alternative: check assertion status via IOKit notification state
        // Use a shell-free approach reading the preferences
        let focusConfig = UserDefaults(suiteName: "com.apple.focus")
        if let modes = focusConfig?.array(forKey: "activeModes") as? [[String: Any]],
           !modes.isEmpty {
            return true
        }
        return false
    }
}
