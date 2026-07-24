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

            // Pomodoro controls
            if settings.effectivePomodoroEnabled, let pomodoro = appState.pomodoroTimer {
                Divider()
                pomodoroSection(pomodoro)
            }

            // Recent chimes history
            if settings.effectiveHistoryEnabled, let history = appState.chimeHistory, !history.recentEntries.isEmpty {
                Divider()
                historySection(history)
            }

            Divider()

            // About
            Button("About ChimeTime") {
                appState.onOpenSettings?()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.selectedSettingsTab = .about
                }
            }

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

    // MARK: - Pomodoro Section

    @ViewBuilder
    private func pomodoroSection(_ pomodoro: PomodoroTimer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Pomodoro")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if pomodoro.phase != .idle {
                    Text("\(pomodoro.phase.displayName) - \(pomodoro.formattedTime)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                if pomodoro.phase == .idle {
                    Button("Start") { pomodoro.start() }
                } else {
                    Button("Stop") { pomodoro.stop() }
                    Button("Reset") { pomodoro.reset() }
                }
            }
        }
    }

    // MARK: - History Section

    @ViewBuilder
    private func historySection(_ history: ChimeHistory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent Chimes")
                .font(.subheadline.weight(.medium))

            ForEach(history.recentEntries) { record in
                HStack {
                    Text(formatRecordDate(record.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(record.soundPlayed)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Helpers

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

    private func formatRecordDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.effective24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }
}
