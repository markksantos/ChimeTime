import Foundation
import Combine
import AppKit

final class SettingsManager: ObservableObject {
    private let defaults = UserDefaults.standard
    private enum Keys {
        static let isEnabled = "chimetime.isEnabled"
        static let displayDuration = "chimetime.displayDuration"
        static let notificationSize = "chimetime.notificationSize"
        static let soundMode = "chimetime.soundMode"
        static let selectedChimeSound = "chimetime.selectedChimeSound"
        static let speakTimeVolume = "chimetime.speakTimeVolume"
        static let showDate = "chimetime.showDate"
        static let use24HourFormat = "chimetime.use24HourFormat"
        static let reduceMotion = "chimetime.reduceMotion"
        static let quietHoursEnabled = "chimetime.quietHoursEnabled"
        static let quietHoursStart = "chimetime.quietHoursStart"
        static let quietHoursEnd = "chimetime.quietHoursEnd"
        static let disabledHours = "chimetime.disabledHours"
        static let launchAtLogin = "chimetime.launchAtLogin"
        static let showDateInNotification = "chimetime.showDateInNotification"
        static let appTheme = "chimetime.appTheme"
        static let accentColor = "chimetime.accentColor"
        static let dropdownColorR = "chimetime.dropdownColorR"
        static let dropdownColorG = "chimetime.dropdownColorG"
        static let dropdownColorB = "chimetime.dropdownColorB"
        // Feature 1: Half-Hour Chime
        static let halfHourChimeEnabled = "chimetime.halfHourChimeEnabled"
        static let halfHourChimeSound = "chimetime.halfHourChimeSound"
        // Feature 2: Focus Mode
        static let focusModeIntegration = "chimetime.focusModeIntegration"
        // Feature 3: Custom Sounds
        static let customSoundNames = "chimetime.customSoundNames"
        static let selectedCustomSound = "chimetime.selectedCustomSound"
        // Feature 4: Chime History
        static let historyEnabled = "chimetime.historyEnabled"
        static let historyMaxEntries = "chimetime.historyMaxEntries"
        // Feature 5: Keyboard Shortcut
        static let globalHotkeyEnabled = "chimetime.globalHotkeyEnabled"
        static let globalHotkeyKeyCode = "chimetime.globalHotkeyKeyCode"
        static let globalHotkeyModifiers = "chimetime.globalHotkeyModifiers"
        // Feature 6: Multi-Monitor
        static let displayPreference = "chimetime.displayPreference"
        // Feature 7: Chime Count
        static let chimeCountEnabled = "chimetime.chimeCountEnabled"
        static let chimeCountMax = "chimetime.chimeCountMax"
        // Feature 8: Pomodoro
        static let pomodoroEnabled = "chimetime.pomodoroEnabled"
        static let pomodoroWorkMinutes = "chimetime.pomodoroWorkMinutes"
        static let pomodoroBreakMinutes = "chimetime.pomodoroBreakMinutes"
        // Feature 9: Calendar Quiet Hours
        static let calendarQuietEnabled = "chimetime.calendarQuietEnabled"
        static let calendarIdentifier = "chimetime.calendarIdentifier"
        // Feature 10: Menu Bar Clock
        static let menuBarClockEnabled = "chimetime.menuBarClockEnabled"
        static let menuBarClockFormat = "chimetime.menuBarClockFormat"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var displayDuration: Double {
        didSet { defaults.set(displayDuration, forKey: Keys.displayDuration) }
    }

    @Published var notificationSize: NotificationSize {
        didSet { defaults.set(notificationSize.rawValue, forKey: Keys.notificationSize) }
    }

    @Published var soundMode: SoundMode {
        didSet { defaults.set(soundMode.rawValue, forKey: Keys.soundMode) }
    }

    @Published var selectedChimeSound: String {
        didSet { defaults.set(selectedChimeSound, forKey: Keys.selectedChimeSound) }
    }

    @Published var speakTimeVolume: Float {
        didSet { defaults.set(speakTimeVolume, forKey: Keys.speakTimeVolume) }
    }

    @Published var showDate: Bool {
        didSet { defaults.set(showDate, forKey: Keys.showDate) }
    }

    @Published var use24HourFormat: Bool? {
        didSet {
            if let value = use24HourFormat {
                defaults.set(value, forKey: Keys.use24HourFormat)
            } else {
                defaults.removeObject(forKey: Keys.use24HourFormat)
            }
        }
    }

    @Published var reduceMotion: Bool? {
        didSet {
            if let value = reduceMotion {
                defaults.set(value, forKey: Keys.reduceMotion)
            } else {
                defaults.removeObject(forKey: Keys.reduceMotion)
            }
        }
    }

    @Published var quietHoursEnabled: Bool {
        didSet { defaults.set(quietHoursEnabled, forKey: Keys.quietHoursEnabled) }
    }

    @Published var quietHoursStart: Int {
        didSet { defaults.set(quietHoursStart, forKey: Keys.quietHoursStart) }
    }

    @Published var quietHoursEnd: Int {
        didSet { defaults.set(quietHoursEnd, forKey: Keys.quietHoursEnd) }
    }

    @Published var disabledHours: Set<Int> {
        didSet { defaults.set(Array(disabledHours), forKey: Keys.disabledHours) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showDateInNotification: Bool {
        didSet { defaults.set(showDateInNotification, forKey: Keys.showDateInNotification) }
    }

    @Published var appTheme: AppTheme {
        didSet { defaults.set(appTheme.rawValue, forKey: Keys.appTheme) }
    }

    @Published var accentColor: AccentColor {
        didSet { defaults.set(accentColor.rawValue, forKey: Keys.accentColor) }
    }

    @Published var dropdownColorR: Double {
        didSet { defaults.set(dropdownColorR, forKey: Keys.dropdownColorR) }
    }
    @Published var dropdownColorG: Double {
        didSet { defaults.set(dropdownColorG, forKey: Keys.dropdownColorG) }
    }
    @Published var dropdownColorB: Double {
        didSet { defaults.set(dropdownColorB, forKey: Keys.dropdownColorB) }
    }

    // Feature 1: Half-Hour Chime
    @Published var halfHourChimeEnabled: Bool {
        didSet { defaults.set(halfHourChimeEnabled, forKey: Keys.halfHourChimeEnabled) }
    }
    @Published var halfHourChimeSound: String {
        didSet { defaults.set(halfHourChimeSound, forKey: Keys.halfHourChimeSound) }
    }

    // Feature 2: Focus Mode
    @Published var focusModeIntegration: Bool {
        didSet { defaults.set(focusModeIntegration, forKey: Keys.focusModeIntegration) }
    }

    // Feature 3: Custom Sounds
    @Published var customSoundNames: [String] {
        didSet { defaults.set(customSoundNames, forKey: Keys.customSoundNames) }
    }
    @Published var selectedCustomSound: String {
        didSet { defaults.set(selectedCustomSound, forKey: Keys.selectedCustomSound) }
    }

    // Feature 4: Chime History
    @Published var historyEnabled: Bool {
        didSet { defaults.set(historyEnabled, forKey: Keys.historyEnabled) }
    }
    @Published var historyMaxEntries: Int {
        didSet { defaults.set(historyMaxEntries, forKey: Keys.historyMaxEntries) }
    }

    // Feature 5: Keyboard Shortcut
    @Published var globalHotkeyEnabled: Bool {
        didSet { defaults.set(globalHotkeyEnabled, forKey: Keys.globalHotkeyEnabled) }
    }
    @Published var globalHotkeyKeyCode: Int {
        didSet { defaults.set(globalHotkeyKeyCode, forKey: Keys.globalHotkeyKeyCode) }
    }
    @Published var globalHotkeyModifiers: Int {
        didSet { defaults.set(globalHotkeyModifiers, forKey: Keys.globalHotkeyModifiers) }
    }

    // Feature 6: Multi-Monitor
    @Published var displayPreference: String {
        didSet { defaults.set(displayPreference, forKey: Keys.displayPreference) }
    }

    // Feature 7: Chime Count
    @Published var chimeCountEnabled: Bool {
        didSet { defaults.set(chimeCountEnabled, forKey: Keys.chimeCountEnabled) }
    }
    @Published var chimeCountMax: Int {
        didSet { defaults.set(chimeCountMax, forKey: Keys.chimeCountMax) }
    }

    // Feature 8: Pomodoro
    @Published var pomodoroEnabled: Bool {
        didSet { defaults.set(pomodoroEnabled, forKey: Keys.pomodoroEnabled) }
    }
    @Published var pomodoroWorkMinutes: Int {
        didSet { defaults.set(pomodoroWorkMinutes, forKey: Keys.pomodoroWorkMinutes) }
    }
    @Published var pomodoroBreakMinutes: Int {
        didSet { defaults.set(pomodoroBreakMinutes, forKey: Keys.pomodoroBreakMinutes) }
    }

    // Feature 9: Calendar Quiet Hours
    @Published var calendarQuietEnabled: Bool {
        didSet { defaults.set(calendarQuietEnabled, forKey: Keys.calendarQuietEnabled) }
    }
    @Published var calendarIdentifier: String {
        didSet { defaults.set(calendarIdentifier, forKey: Keys.calendarIdentifier) }
    }

    // Feature 10: Menu Bar Clock
    @Published var menuBarClockEnabled: Bool {
        didSet { defaults.set(menuBarClockEnabled, forKey: Keys.menuBarClockEnabled) }
    }
    @Published var menuBarClockFormat: String {
        didSet { defaults.set(menuBarClockFormat, forKey: Keys.menuBarClockFormat) }
    }

    var dropdownNSColor: NSColor {
        NSColor(red: dropdownColorR, green: dropdownColorG, blue: dropdownColorB, alpha: 0.95)
    }

    /// Whether to use reduced motion (resolves app override vs system preference)
    var effectiveReduceMotion: Bool {
        if let override = reduceMotion { return override }
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    /// Whether to use 24-hour format (resolves app override vs system locale)
    var effective24HourFormat: Bool {
        if let override = use24HourFormat { return override }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let sample = formatter.string(from: Date())
        // If the formatted string contains AM/PM, system uses 12-hour
        return !sample.contains(formatter.amSymbol) && !sample.contains(formatter.pmSymbol)
    }

    init() {
        // Load from UserDefaults with sensible defaults
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.displayDuration = defaults.object(forKey: Keys.displayDuration) as? Double ?? 4.0
        self.notificationSize = NotificationSize(rawValue: defaults.string(forKey: Keys.notificationSize) ?? "") ?? .medium
        self.soundMode = SoundMode(rawValue: defaults.string(forKey: Keys.soundMode) ?? "") ?? .chime
        self.selectedChimeSound = defaults.string(forKey: Keys.selectedChimeSound) ?? "gentle"
        self.speakTimeVolume = defaults.object(forKey: Keys.speakTimeVolume) as? Float ?? 0.7
        self.showDate = defaults.object(forKey: Keys.showDate) as? Bool ?? true
        self.use24HourFormat = defaults.object(forKey: Keys.use24HourFormat) as? Bool
        self.reduceMotion = defaults.object(forKey: Keys.reduceMotion) as? Bool
        self.quietHoursEnabled = defaults.object(forKey: Keys.quietHoursEnabled) as? Bool ?? false
        self.quietHoursStart = defaults.object(forKey: Keys.quietHoursStart) as? Int ?? 23
        self.quietHoursEnd = defaults.object(forKey: Keys.quietHoursEnd) as? Int ?? 7
        let storedDisabledHours = defaults.array(forKey: Keys.disabledHours) as? [Int] ?? []
        self.disabledHours = Set(storedDisabledHours)
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        self.showDateInNotification = defaults.object(forKey: Keys.showDateInNotification) as? Bool ?? true
        self.appTheme = AppTheme(rawValue: defaults.string(forKey: Keys.appTheme) ?? "") ?? .auto
        self.accentColor = AccentColor(rawValue: defaults.string(forKey: Keys.accentColor) ?? "") ?? .blue
        self.dropdownColorR = defaults.object(forKey: Keys.dropdownColorR) as? Double ?? 0.0
        self.dropdownColorG = defaults.object(forKey: Keys.dropdownColorG) as? Double ?? 0.0
        self.dropdownColorB = defaults.object(forKey: Keys.dropdownColorB) as? Double ?? 0.0

        // Feature 1: Half-Hour Chime
        self.halfHourChimeEnabled = defaults.object(forKey: Keys.halfHourChimeEnabled) as? Bool ?? false
        self.halfHourChimeSound = defaults.string(forKey: Keys.halfHourChimeSound) ?? "tick"
        // Feature 2: Focus Mode
        self.focusModeIntegration = defaults.object(forKey: Keys.focusModeIntegration) as? Bool ?? false
        // Feature 3: Custom Sounds
        self.customSoundNames = defaults.stringArray(forKey: Keys.customSoundNames) ?? []
        self.selectedCustomSound = defaults.string(forKey: Keys.selectedCustomSound) ?? ""
        // Feature 4: Chime History
        self.historyEnabled = defaults.object(forKey: Keys.historyEnabled) as? Bool ?? false
        self.historyMaxEntries = defaults.object(forKey: Keys.historyMaxEntries) as? Int ?? 10
        // Feature 5: Keyboard Shortcut
        self.globalHotkeyEnabled = defaults.object(forKey: Keys.globalHotkeyEnabled) as? Bool ?? false
        self.globalHotkeyKeyCode = defaults.object(forKey: Keys.globalHotkeyKeyCode) as? Int ?? 49
        self.globalHotkeyModifiers = defaults.object(forKey: Keys.globalHotkeyModifiers) as? Int ?? Int(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue)
        // Feature 6: Multi-Monitor
        self.displayPreference = defaults.string(forKey: Keys.displayPreference) ?? "main"
        // Feature 7: Chime Count
        self.chimeCountEnabled = defaults.object(forKey: Keys.chimeCountEnabled) as? Bool ?? false
        self.chimeCountMax = defaults.object(forKey: Keys.chimeCountMax) as? Int ?? 12
        // Feature 8: Pomodoro
        self.pomodoroEnabled = defaults.object(forKey: Keys.pomodoroEnabled) as? Bool ?? false
        self.pomodoroWorkMinutes = defaults.object(forKey: Keys.pomodoroWorkMinutes) as? Int ?? 25
        self.pomodoroBreakMinutes = defaults.object(forKey: Keys.pomodoroBreakMinutes) as? Int ?? 5
        // Feature 9: Calendar Quiet Hours
        self.calendarQuietEnabled = defaults.object(forKey: Keys.calendarQuietEnabled) as? Bool ?? false
        self.calendarIdentifier = defaults.string(forKey: Keys.calendarIdentifier) ?? ""
        // Feature 10: Menu Bar Clock
        self.menuBarClockEnabled = defaults.object(forKey: Keys.menuBarClockEnabled) as? Bool ?? false
        self.menuBarClockFormat = defaults.string(forKey: Keys.menuBarClockFormat) ?? "h:mm"
    }

    /// Check if a given hour (0-23) is within quiet hours
    func isInQuietHours(_ hour: Int) -> Bool {
        guard quietHoursEnabled else { return false }
        if quietHoursStart <= quietHoursEnd {
            return hour >= quietHoursStart && hour < quietHoursEnd
        } else {
            // Wraps midnight, e.g., 23 to 7
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
    }

    /// Check if a given hour (0-23) is disabled
    func isHourDisabled(_ hour: Int) -> Bool {
        disabledHours.contains(hour)
    }

    /// Check if a given hour should be suppressed (quiet or disabled)
    func shouldSuppressHour(_ hour: Int) -> Bool {
        isInQuietHours(hour) || isHourDisabled(hour)
    }
}
