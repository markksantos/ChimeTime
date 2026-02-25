import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let settingsManager = SettingsManager()
    private var scheduler: HourlyScheduler?
    private var notchAnimator: NotchAnimator?
    private var chimeSoundPlayer: ChimeSoundPlayer?
    private var timeSpeaker: TimeSpeaker?
    private var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Wire up state
        appState.settingsManager = settingsManager

        // Create audio components
        chimeSoundPlayer = ChimeSoundPlayer()
        timeSpeaker = TimeSpeaker()

        // Create notch animator
        notchAnimator = NotchAnimator(settingsManager: settingsManager)

        // Create scheduler
        scheduler = HourlyScheduler(settingsManager: settingsManager) { [weak self] date in
            self?.handleHourlyChime(at: date)
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
            self?.handleHourlyChime(at: date)
        }

        // Wire up settings opener
        appState.onOpenSettings = { [weak self] in
            self?.openSettings()
        }
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
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

    private func handleHourlyChime(at date: Date) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.appState.lastTriggeredTime = date

            // Show notch animation
            self.notchAnimator?.showNotification(for: date)

            // Play sound
            let soundMode = self.settingsManager.soundMode
            switch soundMode {
            case .none:
                break
            case .chime:
                self.chimeSoundPlayer?.play(sound: self.settingsManager.selectedChimeSound)
            case .speakTime:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.timeSpeaker?.speak(
                        date: date,
                        volume: self.settingsManager.speakTimeVolume,
                        use24Hour: self.settingsManager.effective24HourFormat
                    )
                }
            case .chimeAndSpeak:
                self.chimeSoundPlayer?.play(sound: self.settingsManager.selectedChimeSound)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.timeSpeaker?.speak(
                        date: date,
                        volume: self.settingsManager.speakTimeVolume,
                        use24Hour: self.settingsManager.effective24HourFormat
                    )
                }
            }
        }
    }
}
