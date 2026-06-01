import Foundation
import Combine

enum PomodoroPhase: String {
    case idle
    case work
    case breakTime = "break"

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .work: return "Work"
        case .breakTime: return "Break"
        }
    }
}

final class PomodoroTimer: ObservableObject {
    @Published var phase: PomodoroPhase = .idle
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0

    var onPhaseEnd: ((PomodoroPhase) -> Void)?

    private var timer: Timer?
    private var workMinutes: Int = 25
    private var breakMinutes: Int = 5

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    func configure(workMinutes: Int, breakMinutes: Int) {
        self.workMinutes = workMinutes
        self.breakMinutes = breakMinutes
    }

    func start() {
        phase = .work
        totalSeconds = workMinutes * 60
        remainingSeconds = totalSeconds
        startTicking()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        remainingSeconds = 0
        totalSeconds = 0
    }

    func reset() {
        stop()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1

        if remainingSeconds == 0 {
            timer?.invalidate()
            timer = nil
            let endedPhase = phase
            onPhaseEnd?(endedPhase)
            transitionPhase()
        }
    }

    private func transitionPhase() {
        switch phase {
        case .work:
            phase = .breakTime
            totalSeconds = breakMinutes * 60
            remainingSeconds = totalSeconds
            startTicking()
        case .breakTime:
            phase = .work
            totalSeconds = workMinutes * 60
            remainingSeconds = totalSeconds
            startTicking()
        case .idle:
            break
        }
    }
}
