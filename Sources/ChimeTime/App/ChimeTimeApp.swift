import SwiftUI

@main
struct ChimeTimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // MenuBarExtra provides the menu bar icon and popover
        MenuBarExtra {
            MenuBarIcon()
                .environmentObject(appDelegate.appState)
                .environmentObject(appDelegate.settingsManager)
        } label: {
            Image(systemName: appDelegate.appState.isEnabled ? "clock.fill" : "clock")
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appDelegate.appState)
                .environmentObject(appDelegate.settingsManager)
        }
    }
}
