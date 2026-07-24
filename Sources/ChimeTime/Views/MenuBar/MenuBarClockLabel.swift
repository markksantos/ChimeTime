import SwiftUI

/// The menu-bar label for the MenuBarExtra. Observes settings/state so the
/// label updates live when the user toggles the clock or master switch —
/// without needing an app restart.
struct MenuBarClockLabel: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settings: SettingsManager

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if settings.effectiveMenuBarClockEnabled {
            Text(formattedTime)
                .monospacedDigit()
                .onReceive(timer) { currentTime = $0 }
        } else {
            Image(systemName: appState.isEnabled ? "clock.fill" : "clock")
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.menuBarClockFormat
        return formatter.string(from: currentTime)
    }
}
