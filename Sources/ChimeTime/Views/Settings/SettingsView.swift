import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, sound, schedule, appearance, pomodoro, about

    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: return "General"
        case .sound: return "Sound"
        case .schedule: return "Schedule"
        case .appearance: return "Appearance"
        case .pomodoro: return "Pomodoro"
        case .about: return "About"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .sound: return "speaker.wave.2"
        case .schedule: return "calendar.badge.clock"
        case .appearance: return "paintbrush"
        case .pomodoro: return "timer"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $appState.selectedSettingsTab) { tab in
                Label(tab.label, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
        } detail: {
            VStack(spacing: 0) {
                // Top bar with preview button
                if appState.selectedSettingsTab != .about {
                    HStack {
                        Spacer()
                        Button {
                            appState.onHourlyChime?(Date())
                        } label: {
                            Label("Preview", systemImage: "play.circle")
                                .font(.body)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                }

                ScrollView {
                    detailContent
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24)
                }
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .toolbar(.hidden)
        .frame(minWidth: 580, minHeight: 440)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedSettingsTab {
        case .general:
            GeneralTab()
                .environmentObject(settings)
                .environmentObject(appState)
        case .sound:
            SoundTab()
                .environmentObject(settings)
        case .schedule:
            ScheduleTab()
                .environmentObject(settings)
        case .appearance:
            AppearanceTab()
                .environmentObject(settings)
        case .pomodoro:
            PomodoroTab()
                .environmentObject(settings)
        case .about:
            AboutTab()
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
    @EnvironmentObject var appState: AppState

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

            // Feature 5: Keyboard Shortcut
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Global Shortcut", description: "Toggle chime on/off from anywhere") {
                        Toggle("", isOn: $settings.globalHotkeyEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.globalHotkeyEnabled {
                        Divider()
                        SettingRow("Shortcut") {
                            Text(GlobalHotkeyMonitor.shortcutDescription(
                                keyCode: settings.globalHotkeyKeyCode,
                                modifiers: settings.globalHotkeyModifiers
                            ))
                            .font(.body.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(4)
            }

            // Feature 4: Chime History
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Chime History", description: "Log recent chimes in menu bar") {
                        Toggle("", isOn: $settings.historyEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.historyEnabled {
                        Divider()
                        SettingRow("Max Entries") {
                            Stepper(value: $settings.historyMaxEntries, in: 5...50, step: 5) {
                                Text("\(settings.historyMaxEntries)")
                                    .font(.body.monospacedDigit())
                            }
                        }
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
                                isSelected: settings.selectedChimeSound == sound && settings.selectedCustomSound.isEmpty,
                                onSelect: {
                                    settings.selectedChimeSound = sound
                                    settings.selectedCustomSound = ""
                                },
                                onPreview: { ChimeSoundPlayer().play(sound: sound) }
                            )
                            if sound != chimeSounds.last || !settings.customSoundNames.isEmpty {
                                Divider()
                            }
                        }

                        // Feature 3: Custom Sounds
                        ForEach(settings.customSoundNames, id: \.self) { name in
                            HStack {
                                Button {
                                    settings.selectedCustomSound = name
                                    settings.selectedChimeSound = ""
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: settings.selectedCustomSound == name ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(settings.selectedCustomSound == name ? .blue : .secondary)
                                        Text(name)
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button {
                                    let manager = CustomSoundManager(settingsManager: settings)
                                    if let url = manager.soundURL(for: name) {
                                        ChimeSoundPlayer().playCustomSound(url: url)
                                    }
                                } label: {
                                    Image(systemName: "speaker.wave.2")
                                }
                                .buttonStyle(.borderless)

                                Button {
                                    let manager = CustomSoundManager(settingsManager: settings)
                                    manager.removeSound(named: name)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.borderless)
                            }
                            if name != settings.customSoundNames.last {
                                Divider()
                            }
                        }

                        Divider()

                        Button {
                            let manager = CustomSoundManager(settingsManager: settings)
                            manager.addSound { _ in }
                        } label: {
                            Label("Add Custom Sound...", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderless)
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

            // Feature 1: Half-Hour Chime
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Half-Hour Chime", description: "Play a sound at the 30-minute mark") {
                        Toggle("", isOn: $settings.halfHourChimeEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.halfHourChimeEnabled {
                        Divider()
                        SettingRow("Half-Hour Sound") {
                            Picker("", selection: $settings.halfHourChimeSound) {
                                ForEach(["gentle", "tick", "wood", "silent"], id: \.self) { sound in
                                    Text(sound.capitalized).tag(sound)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }
                    }
                }
                .padding(4)
            }

            // Feature 7: Chime Count
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Chime Count", description: "Repeat chime based on the current hour") {
                        Toggle("", isOn: $settings.chimeCountEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.chimeCountEnabled {
                        Divider()
                        SettingRow("Max Chimes", description: "Cap repeated chimes (1-12)") {
                            Stepper(value: $settings.chimeCountMax, in: 1...12) {
                                Text("\(settings.chimeCountMax)")
                                    .font(.body.monospacedDigit())
                            }
                        }
                    }
                }
                .padding(4)
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

            // Feature 2: Focus Mode Integration
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Focus Mode", description: "Suppress chimes when macOS Focus/DND is active") {
                        Toggle("", isOn: $settings.focusModeIntegration)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
                .padding(4)
            }

            // Feature 9: Calendar-Aware Quiet Hours
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Calendar Quiet Hours", description: "Suppress chimes during busy calendar events") {
                        Toggle("", isOn: $settings.calendarQuietEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.calendarQuietEnabled {
                        Divider()
                        SettingRow("Calendar", description: "Leave empty for default calendar") {
                            TextField("Calendar ID", text: $settings.calendarIdentifier)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 180)
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

            // Feature 6: Multi-Monitor Support
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Display", description: "Which screen shows the notch notification") {
                        Picker("", selection: $settings.displayPreference) {
                            ForEach(ScreenSelector.availableDisplays, id: \.id) { display in
                                Text(display.name).tag(display.id)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)
                    }
                }
                .padding(4)
            }

            // Feature 10: Menu Bar Clock
            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Menu Bar Clock", description: "Show a live clock instead of icon") {
                        Toggle("", isOn: $settings.menuBarClockEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }

                    if settings.menuBarClockEnabled {
                        Divider()
                        SettingRow("Clock Format") {
                            Picker("", selection: $settings.menuBarClockFormat) {
                                Text("h:mm").tag("h:mm")
                                Text("h:mm a").tag("h:mm a")
                                Text("HH:mm").tag("HH:mm")
                                Text("h:mm:ss").tag("h:mm:ss")
                            }
                            .labelsHidden()
                            .frame(width: 120)
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

// MARK: - Pomodoro Tab

private struct PomodoroTab: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Pomodoro", subtitle: "Work/break cycle timer with notifications")

            GroupBox {
                VStack(spacing: 12) {
                    SettingRow("Enable Pomodoro", description: "Show timer controls in the menu bar") {
                        Toggle("", isOn: $settings.pomodoroEnabled)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                }
                .padding(4)
            }

            if settings.pomodoroEnabled {
                GroupBox {
                    VStack(spacing: 12) {
                        SettingRow("Work Duration") {
                            Stepper(value: $settings.pomodoroWorkMinutes, in: 1...60) {
                                Text("\(settings.pomodoroWorkMinutes) min")
                                    .font(.body.monospacedDigit())
                            }
                        }

                        Divider()

                        SettingRow("Break Duration") {
                            Stepper(value: $settings.pomodoroBreakMinutes, in: 1...30) {
                                Text("\(settings.pomodoroBreakMinutes) min")
                                    .font(.body.monospacedDigit())
                            }
                        }
                    }
                    .padding(4)
                }
            }
        }
    }
}

// MARK: - About Tab

private struct AboutTab: View {
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App identity
            HStack(spacing: 16) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("ChimeTime")
                        .font(.title.weight(.semibold))
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("A native macOS menu bar app that chimes every hour")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 4)

            // Links
            GroupBox {
                VStack(spacing: 12) {
                    AboutLinkRow(label: "Website", icon: "globe", url: "https://nosleeplab.com")
                    Divider()
                    AboutLinkRow(label: "GitHub", icon: "chevron.left.forwardslash.chevron.right", url: "https://github.com/nosleeplab")
                    Divider()
                    AboutLinkRow(label: "Check for Updates", icon: "arrow.triangle.2.circlepath", url: "https://github.com/nosleeplab/ChimeTime/releases")
                }
                .padding(4)
            }

            // Support
            GroupBox {
                VStack(spacing: 12) {
                    AboutLinkRow(label: "Donate", icon: "heart", url: "https://nosleeplab.com/donate")
                }
                .padding(4)
            }

            // Credits
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Made by No Sleep Lab")
                        .font(.body)
                    Text("Built with Swift & SwiftUI")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }
        }
    }
}

private struct AboutLinkRow: View {
    let label: String
    let icon: String
    let url: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.body)
            Spacer()
            Button {
                if let link = URL(string: url) {
                    NSWorkspace.shared.open(link)
                }
            } label: {
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
