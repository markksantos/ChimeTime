import Foundation

/// The catalog of features behind the Pro unlock.
///
/// Everything the paywall advertises comes from here, so the marketing copy
/// and the actual gate can never drift apart.
enum ProFeature: String, CaseIterable, Identifiable {
    case appearance
    case chimeSound
    case customSounds
    case halfHourChime
    case chimeCount
    case chimeHistory
    case globalShortcut
    case pomodoro
    case customSchedule
    case menuBarClock
    case multiMonitor
    case calendarQuietHours

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .chimeSound: return "Chime Sounds"
        case .customSounds: return "Custom Sounds"
        case .halfHourChime: return "Half-Hour Chime"
        case .chimeCount: return "Chime Count"
        case .chimeHistory: return "Chime History"
        case .globalShortcut: return "Global Shortcut"
        case .pomodoro: return "Pomodoro Timer"
        case .customSchedule: return "Custom Schedule"
        case .menuBarClock: return "Menu Bar Clock"
        case .multiMonitor: return "Multi-Monitor"
        case .calendarQuietHours: return "Calendar Quiet Hours"
        }
    }

    var summary: String {
        switch self {
        case .appearance: return "Theme, accent color, notch color, size, and display duration"
        case .chimeSound: return "Pick from every built-in chime instead of the default"
        case .customSounds: return "Use your own audio files as the hourly chime"
        case .halfHourChime: return "A lighter chime on the 30-minute mark"
        case .chimeCount: return "Strike once per hour, grandfather-clock style"
        case .chimeHistory: return "See a log of recent chimes in the menu bar"
        case .globalShortcut: return "Toggle chiming from anywhere with a hotkey"
        case .pomodoro: return "Work/break cycles with notch and sound alerts"
        case .customSchedule: return "Choose exactly which hours chime with the 24-hour grid"
        case .menuBarClock: return "Show a live clock in the menu bar instead of the icon"
        case .multiMonitor: return "Choose which display the notch drop appears on"
        case .calendarQuietHours: return "Stay silent automatically during calendar events"
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .chimeSound: return "speaker.wave.2.fill"
        case .customSounds: return "waveform"
        case .halfHourChime: return "clock.badge"
        case .chimeCount: return "repeat"
        case .chimeHistory: return "list.bullet.rectangle"
        case .globalShortcut: return "command"
        case .pomodoro: return "timer"
        case .customSchedule: return "calendar.badge.clock"
        case .menuBarClock: return "menubar.rectangle"
        case .multiMonitor: return "display.2"
        case .calendarQuietHours: return "calendar"
        }
    }

    /// Order shown on the paywall — highest perceived value first.
    static let paywallOrder: [ProFeature] = [
        .appearance,
        .chimeSound,
        .customSounds,
        .customSchedule,
        .pomodoro,
        .globalShortcut,
        .halfHourChime,
        .chimeCount,
        .menuBarClock,
        .chimeHistory,
        .multiMonitor,
        .calendarQuietHours
    ]
}
