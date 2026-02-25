import SwiftUI

struct MenuBarIcon: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current time display
            Text(formattedCurrentTime)
                .font(.system(size: 32, weight: .light, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Divider()

            // Master toggle
            Toggle("Hourly Chime", isOn: $appState.isEnabled)
                .toggleStyle(.switch)

            // Next chime info
            Text(nextChimeLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Preview button
            Button {
                appState.onHourlyChime?(Date())
            } label: {
                Label("Preview", systemImage: "play.circle")
            }
            .disabled(!appState.isEnabled)

            Divider()

            // Settings
            Button("Settings...") {
                appState.onOpenSettings?()
            }
            .keyboardShortcut(",", modifiers: .command)

            // Quit
            Button("Quit ChimeTime") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 280)
        .onReceive(timer) { currentTime = $0 }
    }

    private var formattedCurrentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.effective24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: currentTime)
    }

    private var nextChimeLabel: String {
        guard appState.isEnabled else { return "Paused" }

        if let next = appState.nextFireTime {
            let hour = Calendar.current.component(.hour, from: next)
            if settings.isInQuietHours(hour) {
                let formatter = DateFormatter()
                formatter.dateFormat = settings.effective24HourFormat ? "HH:mm" : "h:mm a"
                return "Quiet hours until \(formatter.string(from: next))"
            }
            let formatter = DateFormatter()
            formatter.dateFormat = settings.effective24HourFormat ? "HH:mm" : "h:mm a"
            return "Next chime: \(formatter.string(from: next))"
        }
        return "Next chime: --"
    }
}
