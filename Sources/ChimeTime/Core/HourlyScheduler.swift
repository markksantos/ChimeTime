import Foundation
import Combine
import AppKit

final class HourlyScheduler: ObservableObject {
    @Published var nextFireTime: Date?

    private let settingsManager: SettingsManager
    private let onFire: (Date, ChimeType) -> Void
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var clockChangeObserver: NSObjectProtocol?

    init(settingsManager: SettingsManager, onFire: @escaping (Date, ChimeType) -> Void) {
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

    static func nextHalfHourBoundary(from date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0

        if minute < 30 {
            // Next boundary is :30 of current hour
            var target = calendar.dateComponents([.year, .month, .day, .hour], from: date)
            target.minute = 30
            return calendar.date(from: target)!
        } else {
            // Next boundary is :00 of next hour
            return nextHourBoundary(from: date)
        }
    }

    // MARK: - Private

    private func scheduleNextFire() {
        timer?.invalidate()

        let now = Date()
        let nextHour = Self.nextHourBoundary(from: now)

        let fireDate: Date
        let chimeType: ChimeType

        if settingsManager.effectiveHalfHourChimeEnabled {
            let nextHalf = Self.nextHalfHourBoundary(from: now)
            if nextHalf < nextHour {
                fireDate = nextHalf
                chimeType = .halfHour
            } else {
                fireDate = nextHour
                chimeType = .hour
            }
        } else {
            fireDate = nextHour
            chimeType = .hour
        }

        nextFireTime = fireDate

        let interval = fireDate.timeIntervalSince(now)
        let scheduledType = chimeType
        timer = Timer.scheduledTimer(withTimeInterval: max(interval, 0.01), repeats: false) { [weak self] _ in
            self?.timerFired(chimeType: scheduledType)
        }
    }

    private func timerFired(chimeType: ChimeType) {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)

        if !settingsManager.shouldSuppressHour(hour) {
            onFire(now, chimeType)
        }

        // Reschedule for the next boundary
        scheduleNextFire()
    }
}
