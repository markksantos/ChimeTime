import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        TabView {
            GeneralTab()
                .environmentObject(settings)
                .tabItem { Label("General", systemImage: "gear") }

            SoundTab()
                .environmentObject(settings)
                .tabItem { Label("Sound", systemImage: "speaker.wave.2") }

            ScheduleTab()
                .environmentObject(settings)
                .tabItem { Label("Schedule", systemImage: "calendar") }

            AppearanceTab()
                .environmentObject(settings)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 450, height: 360)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)

            Toggle("Enable Hourly Chime", isOn: $settings.isEnabled)

            DurationSlider(value: $settings.displayDuration)

            Picker("Notification Size", selection: $settings.notificationSize) {
                ForEach(NotificationSize.allCases) { size in
                    Text(size.displayName).tag(size)
                }
            }

            Toggle("Show Date in Notification", isOn: $settings.showDateInNotification)
        }
        .padding()
    }
}

// MARK: - Sound Tab

private struct SoundTab: View {
    @EnvironmentObject var settings: SettingsManager

    private let availableSounds = ["gentle", "tick", "wood", "silent"]

    var body: some View {
        Form {
            Picker("Sound Mode", selection: $settings.soundMode) {
                ForEach(SoundMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Section("Chime Sound") {
                ForEach(availableSounds, id: \.self) { sound in
                    SoundPreviewRow(
                        soundName: sound,
                        isSelected: settings.selectedChimeSound == sound,
                        onSelect: { settings.selectedChimeSound = sound },
                        onPreview: { previewSound(sound) }
                    )
                }
            }

            HStack {
                Text("Speak Volume")
                Slider(value: $settings.speakTimeVolume, in: 0...1)
            }
        }
        .padding()
    }

    private func previewSound(_ sound: String) {
        // ChimeSoundPlayer is built by another teammate; preview wired via AppDelegate
        // For now, this is a placeholder that will be connected at integration time
        NSSound(named: NSSound.Name(sound))?.play()
    }
}

// MARK: - Schedule Tab

private struct ScheduleTab: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HourGridView()
                .environmentObject(settings)

            Divider()

            Toggle("Quiet Hours", isOn: $settings.quietHoursEnabled)

            if settings.quietHoursEnabled {
                HStack(spacing: 16) {
                    Picker("From", selection: $settings.quietHoursStart) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .frame(width: 150)

                    Picker("To", selection: $settings.quietHoursEnd) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .frame(width: 150)
                }
            }
        }
        .padding()
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12:00 AM" }
        if hour < 12 { return "\(hour):00 AM" }
        if hour == 12 { return "12:00 PM" }
        return "\(hour - 12):00 PM"
    }
}

// MARK: - Appearance Tab

private struct AppearanceTab: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        Form {
            Picker("Theme", selection: $settings.appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Accent Color")
                HStack(spacing: 12) {
                    ForEach(AccentColor.allCases) { color in
                        Button {
                            settings.accentColor = color
                        } label: {
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            settings.accentColor == color ? Color.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle("Reduce Motion", isOn: Binding(
                get: { settings.reduceMotion ?? false },
                set: { settings.reduceMotion = $0 }
            ))

            if settings.reduceMotion != nil {
                Button("Use System Default") {
                    settings.reduceMotion = nil
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding()
    }
}
