import Foundation
import Combine
import AppKit

final class HourlyScheduler: ObservableObject {
    @Published var nextFireTime: Date?

    private let settingsManager: SettingsManager
    private let onFire: (Date) -> Void
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var clockChangeObserver: NSObjectProtocol?

    init(settingsManager: SettingsManager, onFire: @escaping (Date) -> Void) {
        self.settingsManager = settingsManager
        self.onFire = onFire
    }

    deinit {
        stop()
    }

    // MARK: - Public

    func start() {
        scheduleNextFire()

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWake()
        }

        clockChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSSystemClockDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemWake()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        nextFireTime = nil

        if let obs = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            wakeObserver = nil
        }
        if let obs = clockChangeObserver {
            NotificationCenter.default.removeObserver(obs)
            clockChangeObserver = nil
        }
    }

    func handleSystemWake() {
        scheduleNextFire()
    }

    // MARK: - Static

    static func nextHourBoundary(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        let hourStart = calendar.date(from: components)!
        return calendar.date(byAdding: .hour, value: 1, to: hourStart)!
    }

    // MARK: - Private

    private func scheduleNextFire() {
        timer?.invalidate()

        let now = Date()
        let fireDate = Self.nextHourBoundary(from: now)
        nextFireTime = fireDate

        let interval = fireDate.timeIntervalSince(now)
        timer = Timer.scheduledTimer(withTimeInterval: max(interval, 0.01), repeats: false) { [weak self] _ in
            self?.timerFired()
        }
    }

    private func timerFired() {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)

        if !settingsManager.shouldSuppressHour(hour) {
            onFire(now)
        }

        // Reschedule for the next hour
        scheduleNextFire()
    }
}
