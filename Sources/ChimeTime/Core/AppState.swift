import SwiftUI
import Combine

// MARK: - Enums shared across the app

enum NotificationSize: String, CaseIterable, Identifiable {
    case small, medium, large, extraLarge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 48
        case .large: return 64
        case .extraLarge: return 80
        }
    }

    var windowWidth: CGFloat {
        switch self {
        case .small: return 220
        case .medium: return 280
        case .large: return 340
        case .extraLarge: return 400
        }
    }
}

enum SoundMode: String, CaseIterable, Identifiable {
    case none, chime, speakTime, chimeAndSpeak

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .chime: return "Chime Only"
        case .speakTime: return "Speak Time"
        case .chimeAndSpeak: return "Chime + Speak Time"
        }
    }
}

enum TimeDisplayStyle: Sendable {
    case minimal      // "2:00"
    case standard     // "2:00 PM"
    case verbose      // "2:00 PM · Tuesday"
}

enum AppTheme: String, CaseIterable, Identifiable {
    case auto, dark, light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto (match system)"
        case .dark: return "Always Dark"
        case .light: return "Always Light"
        }
    }
}

enum AccentColor: String, CaseIterable, Identifiable {
    case blue, green, orange, purple, pink, white

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .pink: return .pink
        case .white: return .white
        }
    }
}

// MARK: - App State

final class AppState: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var nextFireTime: Date?
    @Published var lastTriggeredTime: Date?

    // References to managers (set during app init)
    var settingsManager: SettingsManager?
    var scheduler: HourlyScheduler?

    // Callback for triggering the notch animation
    var onHourlyChime: ((Date) -> Void)?

    init() {}
}
