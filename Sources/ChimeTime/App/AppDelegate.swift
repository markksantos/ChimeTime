import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let settingsManager: SettingsManager
    private(set) var proStore: ProStore!
    private var scheduler: HourlyScheduler?
    private var notchAnimator: NotchAnimator?
    private var chimeSoundPlayer: ChimeSoundPlayer?
    private var timeSpeaker: TimeSpeaker?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    // New managers for features
    private var calendarMonitor: CalendarMonitor?
    private var globalHotkeyMonitor: GlobalHotkeyMonitor?
    private var chimeHistory: ChimeHistory?
    private var pomodoroTimer: PomodoroTimer?
    private var customSoundManager: CustomSoundManager?
    private let loginItemManager = LoginItemManager()

    override init() {
        self.settingsManager = SettingsManager(entitlement: ProEntitlement())
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the store first so the `Transaction.updates` listener is
        // running before anything else — it delivers purchases completed on
        // another Mac, or ones interrupted mid-flight.
        proStore = ProStore(entitlement: settingsManager.entitlement)
        appState.proStore = proStore

        // Wire up state
        appState.settingsManager = settingsManager

        // Create audio components
        chimeSoundPlayer = ChimeSoundPlayer()
        timeSpeaker = TimeSpeaker()

        // Create notch animator
        notchAnimator = NotchAnimator(settingsManager: settingsManager)

        // Feature 3: Custom Sound Manager
        customSoundManager = CustomSoundManager(settingsManager: settingsManager)

        // Feature 4: Chime History
        chimeHistory = ChimeHistory()
        appState.chimeHistory = chimeHistory

        // Feature 5: Global Hotkey
        globalHotkeyMonitor = GlobalHotkeyMonitor()
        setupHotkey()

        // Feature 8: Pomodoro Timer
        pomodoroTimer = PomodoroTimer()
        pomodoroTimer?.configure(
            workMinutes: settingsManager.pomodoroWorkMinutes,
            breakMinutes: settingsManager.pomodoroBreakMinutes
        )
        pomodoroTimer?.onPhaseEnd = { [weak self] phase in
            guard let self else { return }
            let label = phase == .work ? "Break Time!" : "Work Time!"
            self.notchAnimator?.showNotification(withLabel: label)
            self.chimeSoundPlayer?.play(sound: self.settingsManager.effectiveSelectedChimeSound)
        }
        appState.pomodoroTimer = pomodoroTimer

        // Feature 9: Calendar Monitor (lazy access request)
        calendarMonitor = CalendarMonitor()
        if settingsManager.effectiveCalendarQuietEnabled {
            calendarMonitor?.requestAccess { _ in }
        }

        // Create scheduler with ChimeType support
        scheduler = HourlyScheduler(settingsManager: settingsManager) { [weak self] date, chimeType in
            self?.handleHourlyChime(at: date, chimeType: chimeType)
        }
        appState.scheduler = scheduler

        // Sync isEnabled between AppState and SettingsManager
        settingsManager.$isEnabled
            .assign(to: &appState.$isEnabled)

        appState.$isEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.settingsManager.isEnabled = enabled
                if enabled {
                    self?.scheduler?.start()
                } else {
                    self?.scheduler?.stop()
                }
            }
            .store(in: &cancellables)

        // Start scheduler if enabled
        if settingsManager.isEnabled {
            scheduler?.start()
        }

        // Update next fire time
        scheduler?.$nextFireTime
            .assign(to: &appState.$nextFireTime)

        // Wire up preview callback
        appState.onHourlyChime = { [weak self] date in
            self?.handleHourlyChime(at: date, chimeType: .hour)
        }

        // Wire up settings opener
        appState.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        // Launch-at-login: reconcile the stored preference with the real
        // SMAppService state on launch, then react to user toggles.
        if settingsManager.launchAtLogin != loginItemManager.isEnabled {
            loginItemManager.setEnabled(settingsManager.launchAtLogin)
        }
        settingsManager.$launchAtLogin
            .dropFirst()
            .sink { [weak self] enabled in self?.loginItemManager.setEnabled(enabled) }
            .store(in: &cancellables)

        // React to hotkey setting changes
        settingsManager.$globalHotkeyEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.setupHotkey() }
            .store(in: &cancellables)

        // Stop a running Pomodoro timer if the feature is turned off.
        settingsManager.$pomodoroEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                if !enabled, self?.pomodoroTimer?.phase != .idle {
                    self?.pomodoroTimer?.stop()
                }
            }
            .store(in: &cancellables)

        // React to the Pro unlock landing (or being revoked/refunded): every
        // gated feature has to start or stop for real, not just in the UI.
        settingsManager.entitlement.$isPro
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPro in
                guard let self else { return }
                self.setupHotkey()
                if !isPro, self.pomodoroTimer?.phase != .idle {
                    self.pomodoroTimer?.stop()
                }
                if isPro, self.settingsManager.calendarQuietEnabled {
                    self.calendarMonitor?.requestAccess { _ in }
                }
                // Half-hour chiming changes the next fire boundary.
                if self.settingsManager.isEnabled {
                    self.scheduler?.handleSystemWake()
                }
            }
            .store(in: &cancellables)

        // React to pomodoro setting changes
        settingsManager.$pomodoroWorkMinutes
            .dropFirst()
            .sink { [weak self] mins in self?.pomodoroTimer?.configure(workMinutes: mins, breakMinutes: self?.settingsManager.pomodoroBreakMinutes ?? 5) }
            .store(in: &cancellables)
        settingsManager.$pomodoroBreakMinutes
            .dropFirst()
            .sink { [weak self] mins in self?.pomodoroTimer?.configure(workMinutes: self?.settingsManager.pomodoroWorkMinutes ?? 25, breakMinutes: mins) }
            .store(in: &cancellables)

        // Lazy calendar access when enabled
        settingsManager.$calendarQuietEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                guard let self, enabled, self.settingsManager.isPro else { return }
                self.calendarMonitor?.requestAccess { _ in }
            }
            .store(in: &cancellables)

        // Half-hour chiming changes which boundary fires next.
        settingsManager.$halfHourChimeEnabled
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, self.settingsManager.isEnabled else { return }
                self.scheduler?.handleSystemWake()
            }
            .store(in: &cancellables)
    }

    func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(appState)
            .environmentObject(settingsManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ChimeTime Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    private func setupHotkey() {
        if settingsManager.effectiveGlobalHotkeyEnabled {
            globalHotkeyMonitor?.onHotkey = { [weak self] in
                DispatchQueue.main.async {
                    self?.appState.isEnabled.toggle()
                }
            }
            globalHotkeyMonitor?.start(
                keyCode: settingsManager.globalHotkeyKeyCode,
                modifiers: settingsManager.globalHotkeyModifiers
            )
        } else {
            globalHotkeyMonitor?.stop()
        }
    }

    private func handleHourlyChime(at date: Date, chimeType: ChimeType) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            // Feature 9: Calendar suppression
            if self.settingsManager.effectiveCalendarQuietEnabled,
               self.calendarMonitor?.hasBusyEvent(at: date, calendarIdentifier: self.settingsManager.calendarIdentifier) == true {
                return
            }

            self.appState.lastTriggeredTime = date

            // Show notch animation
            self.notchAnimator?.showNotification(for: date)

            // Play sound
            let soundMode = self.settingsManager.soundMode

            // For half-hour chimes, play the half-hour sound and skip speech
            if chimeType == .halfHour {
                if soundMode != .none {
                    self.chimeSoundPlayer?.play(sound: self.settingsManager.effectiveHalfHourChimeSound)
                }
            } else {
                // Hour chime — check for custom sound first
                let useCustom = !self.settingsManager.effectiveSelectedCustomSound.isEmpty
                switch soundMode {
                case .none:
                    break
                case .chime:
                    if useCustom {
                        self.playCustomOrBuiltin()
                    } else {
                        self.playChimeWithCount()
                    }
                case .speakTime:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.timeSpeaker?.speak(
                            date: date,
                            volume: self.settingsManager.speakTimeVolume,
                            use24Hour: self.settingsManager.effective24HourFormat
                        )
                    }
                case .chimeAndSpeak:
                    if useCustom {
                        self.playCustomOrBuiltin()
                    } else {
                        self.playChimeWithCount()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.timeSpeaker?.speak(
                            date: date,
                            volume: self.settingsManager.speakTimeVolume,
                            use24Hour: self.settingsManager.effective24HourFormat
                        )
                    }
                }
            }

            // Feature 4: Record to history
            if self.settingsManager.effectiveHistoryEnabled {
                let soundName = chimeType == .halfHour
                    ? self.settingsManager.effectiveHalfHourChimeSound
                    : self.settingsManager.effectiveSelectedChimeSound
                let record = ChimeRecord(date: date, chimeType: chimeType, soundPlayed: soundName)
                self.chimeHistory?.addRecord(record, maxEntries: self.settingsManager.historyMaxEntries)
            }
        }
    }

    private func playChimeWithCount() {
        let sound = settingsManager.effectiveSelectedChimeSound
        if settingsManager.effectiveChimeCountEnabled {
            let hour = Calendar.current.component(.hour, from: Date())
            let twelveHour = hour % 12 == 0 ? 12 : hour % 12
            let count = min(twelveHour, settingsManager.effectiveChimeCountMax)
            chimeSoundPlayer?.playRepeated(sound: sound, count: count)
        } else {
            chimeSoundPlayer?.play(sound: sound)
        }
    }

    private func playCustomOrBuiltin() {
        let customName = settingsManager.effectiveSelectedCustomSound
        if let url = customSoundManager?.soundURL(for: customName) {
            chimeSoundPlayer?.playCustomSound(url: url)
        } else {
            // Fallback to built-in
            playChimeWithCount()
        }
    }
}
