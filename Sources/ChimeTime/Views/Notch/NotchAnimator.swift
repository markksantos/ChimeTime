import AppKit
import SwiftUI
import Combine

final class NotchAnimator: ObservableObject {
    let dropDuration: Double = 0.45
    let retractDuration: Double = 0.35

    var holdDuration: Double {
        settingsManager.displayDuration
    }

    private let settingsManager: SettingsManager
    private var notchWindow: NotchWindow?
    private var holdTimer: DispatchWorkItem?

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }

    func showNotification(for date: Date) {
        // Cancel any pending retract
        holdTimer?.cancel()

        let size = settingsManager.notificationSize

        // Create or reconfigure window
        let window = NotchWindow(size: size)
        self.notchWindow = window

        window.onDismiss = { [weak self] in
            self?.dismissNow()
        }

        let hostView = NSHostingView(
            rootView: NotchDropView(
                date: date,
                showDate: settingsManager.showDateInNotification,
                use24Hour: settingsManager.effective24HourFormat,
                size: size,
                backgroundColor: settingsManager.dropdownNSColor
            )
        )
        window.contentView = hostView

        let useReducedMotion = settingsManager.effectiveReduceMotion

        if useReducedMotion {
            // Fade animation
            window.alphaValue = 0
            window.orderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1.0
            }
        } else {
            // Spring drop animation
            let finalFrame = window.frame
            var startFrame = finalFrame
            startFrame.origin.y += finalFrame.height
            window.setFrame(startFrame, display: false)
            window.alphaValue = 1.0
            window.orderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = dropDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                context.allowsImplicitAnimation = true
                window.animator().setFrame(finalFrame, display: true)
            }
        }

        // Start breathing pulse during hold
        startBreathingPulse(window: window)

        // Schedule retract
        let retractItem = DispatchWorkItem { [weak self] in
            self?.retract(reduceMotion: useReducedMotion)
        }
        holdTimer = retractItem
        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration, execute: retractItem)
    }

    func handleSystemWake() {
        // Dismiss any visible notification on wake
        holdTimer?.cancel()
        if let window = notchWindow {
            window.orderOut(nil)
            notchWindow = nil
        }
    }

    func dismissNow() {
        holdTimer?.cancel()
        let useReducedMotion = settingsManager.effectiveReduceMotion
        retract(reduceMotion: useReducedMotion)
    }

    // MARK: - Private

    private func startBreathingPulse(window: NSWindow) {
        let cycleDuration = 2.0

        func pulse() {
            guard window.isVisible else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = cycleDuration / 2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 0.92
            }, completionHandler: {
                guard window.isVisible else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = cycleDuration / 2
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().alphaValue = 1.0
                }, completionHandler: {
                    pulse()
                })
            })
        }

        pulse()
    }

    private func retract(reduceMotion: Bool) {
        guard let window = notchWindow else { return }

        if reduceMotion {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                window.orderOut(nil)
                self?.notchWindow = nil
            })
        } else {
            var retractFrame = window.frame
            retractFrame.origin.y += retractFrame.height

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = retractDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                context.allowsImplicitAnimation = true
                window.animator().setFrame(retractFrame, display: true)
            }, completionHandler: { [weak self] in
                window.orderOut(nil)
                self?.notchWindow = nil
            })
        }
    }
}
