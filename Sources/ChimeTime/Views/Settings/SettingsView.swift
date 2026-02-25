import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, sound, schedule, appearance

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: return "General"
        case .sound: return "Sound"
        case .schedule: return "Schedule"
        case .appearance: return "Appearance"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .sound: return "speaker.wave.2"
        case .schedule: return "calendar.badge.clock"
        case .appearance: return "paintbrush"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager

    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.label, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            ScrollView {
                detailContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .toolbar(.hidden)
        .frame(minWidth: 580, minHeight: 440)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .general:
            GeneralTab()
                .environmentObject(settings)
        case .sound:
            SoundTab()
                .environmentObject(settings)
        case .schedule:
            ScheduleTab()
                .environmentObject(settings)
        case .appearance:
            AppearanceTab()
                .environmentObject(settings)
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title2.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Setting Row

private struct SettingRow<Content: View>: View {
    let label: String
    let description: String?
    let content: Content

    init(_ label: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.description = description
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                if let description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            content
        }
        .padding(.vertical, 4)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("General", subtitle: "Core app behavior and notification display")

            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Launch at Login", description: "Start ChimeTime when you log in") {
                        Toggle("", isOn: $settings.launchAtLogin)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    Divider()

                    SettingRow("Hourly Chime", description: "Master on/off for all notifications") {
                        Toggle("", isOn: $settings.isEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
                .padding(4)
            }

            GroupBox {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Display Duration")
                                .font(.body)
                            Spacer()
                            Text(String(format: "%.1fs", settings.displayDuration))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.displayDuration, in: 2.0...8.0, step: 0.5)
                    }

                    Divider()

                    SettingRow("Notification Size") {
                        Picker("", selection: $settings.notificationSize) {
                            ForEach(NotificationSize.allCases) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }

                    Divider()

                    SettingRow("Show Date", description: "Display day and date below the time") {
                        Toggle("", isOn: $settings.showDateInNotification)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
                .padding(4)
            }
        }
    }
}

// MARK: - Sound Tab

private struct SoundTab: View {
    @EnvironmentObject var settings: SettingsManager

    private let chimeSounds = ["gentle", "tick", "wood", "silent"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Sound", subtitle: "Chime and spoken time settings")

            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Sound Mode") {
                        Picker("", selection: $settings.soundMode) {
                            ForEach(SoundMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 160)
                    }
                }
                .padding(4)
            }

            if settings.soundMode != .none {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chime Sound")
                            .font(.body.weight(.medium))
                            .padding(.bottom, 4)

                        ForEach(chimeSounds, id: \.self) { sound in
                            SoundPreviewRow(
                                soundName: sound,
                                isSelected: settings.selectedChimeSound == sound,
                                onSelect: { settings.selectedChimeSound = sound },
                                onPreview: { ChimeSoundPlayer().play(sound: sound) }
                            )
                            if sound != chimeSounds.last {
                                Divider()
                            }
                        }
                    }
                    .padding(4)
                }
                .opacity(settings.soundMode == .speakTime ? 0.5 : 1.0)
                .disabled(settings.soundMode == .speakTime)
            }

            if settings.soundMode == .speakTime || settings.soundMode == .chimeAndSpeak {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speech Volume")
                                .font(.body)
                            Spacer()
                            Text("\(Int(settings.speakTimeVolume * 100))%")
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $settings.speakTimeVolume, in: 0...1)
                        Text("Sounds respect your system volume")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(4)
                }
            }
        }
    }
}

// MARK: - Schedule Tab

private struct ScheduleTab: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Schedule", subtitle: "Choose which hours to receive notifications")

            GroupBox {
                HourGridView()
                    .environmentObject(settings)
                    .padding(4)
            }

            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Quiet Hours", description: "Suppress notifications during a time range") {
                        Toggle("", isOn: $settings.quietHoursEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.quietHoursEnabled {
                        Divider()

                        HStack(spacing: 24) {
                            HStack(spacing: 8) {
                                Text("From")
                                    .foregroundStyle(.secondary)
                                Picker("", selection: $settings.quietHoursStart) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(formatHour(hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 110)
                            }

                            HStack(spacing: 8) {
                                Text("To")
                                    .foregroundStyle(.secondary)
                                Picker("", selection: $settings.quietHoursEnd) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(formatHour(hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 110)
                            }
                        }
                    }
                }
                .padding(4)
            }
        }
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

    @State private var dropdownColor: Color = .black

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Appearance", subtitle: "Visual style of the notification")

            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Theme") {
                        Picker("", selection: $settings.appTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.body)

                        HStack(spacing: 10) {
                            ForEach(AccentColor.allCases) { color in
                                Button {
                                    settings.accentColor = color
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 28, height: 28)
                                        if settings.accentColor == color {
                                            Circle()
                                                .strokeBorder(Color.primary, lineWidth: 2.5)
                                                .frame(width: 34, height: 34)
                                        }
                                    }
                                    .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dropdown Color")
                                .font(.body)
                            Text("Background color of the notch notification")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        ColorPicker("", selection: $dropdownColor, supportsOpacity: false)
                            .labelsHidden()
                            .onChange(of: dropdownColor) { newColor in
                                if let components = NSColor(newColor).usingColorSpace(.deviceRGB) {
                                    settings.dropdownColorR = components.redComponent
                                    settings.dropdownColorG = components.greenComponent
                                    settings.dropdownColorB = components.blueComponent
                                }
                            }
                    }
                    .padding(.vertical, 4)
                }
                .padding(4)
            }

            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Reduce Motion", description: "Use fade instead of slide animation") {
                        Toggle("", isOn: Binding(
                            get: { settings.effectiveReduceMotion },
                            set: { settings.reduceMotion = $0 }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }

                    if settings.reduceMotion != nil {
                        HStack {
                            Spacer()
                            Button("Reset to System Default") {
                                settings.reduceMotion = nil
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(4)
            }
        }
        .onAppear {
            dropdownColor = Color(nsColor: NSColor(
                red: settings.dropdownColorR,
                green: settings.dropdownColorG,
                blue: settings.dropdownColorB,
                alpha: 1.0
            ))
        }
    }
}
