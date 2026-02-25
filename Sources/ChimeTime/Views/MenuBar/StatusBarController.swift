import AppKit
import SwiftUI
import Combine

final class StatusBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    private let appState: AppState
    private let settingsManager: SettingsManager

    init(appState: AppState, settingsManager: SettingsManager) {
        self.appState = appState
        self.settingsManager = settingsManager
        super.init()
        setupStatusItem()
        observeState()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()

        if let button = statusItem?.button {
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarIcon()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        )
        self.popover = popover
    }

    private func observeState() {
        appState.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
    }

    private func updateIcon() {
        let imageName = appState.isEnabled ? "clock.fill" : "clock"
        statusItem?.button?.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "ChimeTime")
    }

    @objc private func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
