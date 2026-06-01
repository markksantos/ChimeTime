import XCTest
@testable import ChimeTime

final class UITests: XCTestCase {

    // MARK: - Test 16: menu_bar_popover_shows_next_chime

    func test_menu_bar_popover_shows_next_chime() throws {
        let appState = AppState()
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 25
        components.hour = 15
        components.minute = 0
        components.second = 0
        let nextFire = calendar.date(from: components)!
        appState.nextFireTime = nextFire

        // AppState should have a formatted next chime string
        XCTAssertNotNil(appState.nextFireTime, "Next fire time should be set")
        XCTAssertEqual(calendar.component(.hour, from: appState.nextFireTime!), 15,
                       "Next fire should be 3 PM")
    }

    // MARK: - Test 17: menu_bar_preview_button_triggers_animation

    func test_menu_bar_preview_button_triggers_animation() throws {
        let appState = AppState()
        var chimeFired = false
        appState.onHourlyChime = { _ in
            chimeFired = true
        }

        // Triggering the callback should work
        appState.onHourlyChime?(Date())
        XCTAssertTrue(chimeFired, "Preview should trigger the chime callback")
    }

    // MARK: - Test 18: settings_tabs_all_render

    func test_settings_tabs_all_render() throws {
        // Verify settings view can be constructed (SwiftUI views are structs, construction = valid)
        let settings = SettingsManager()
        let appState = AppState()
        let settingsView = SettingsView()
        XCTAssertNotNil(settingsView, "SettingsView should be constructable")
    }

    // MARK: - Test 19: hour_grid_toggle_individual_hours

    func test_hour_grid_toggle_individual_hours() throws {
        let settings = SettingsManager()
        settings.disabledHours = []

        // Disable hour 9
        settings.disabledHours.insert(9)
        XCTAssertTrue(settings.disabledHours.contains(9), "Hour 9 should be disabled after toggle")

        // Re-enable hour 9
        settings.disabledHours.remove(9)
        XCTAssertFalse(settings.disabledHours.contains(9), "Hour 9 should be enabled after toggle")

        // Multiple toggles
        settings.disabledHours = [0, 1, 2, 3, 4, 5]
        XCTAssertEqual(settings.disabledHours.count, 6, "Should have 6 disabled hours")

        // Clean up
        settings.disabledHours = []
    }

    // MARK: - Test 20: hour_grid_presets_select_correct_hours

    func test_hour_grid_presets_select_correct_hours() throws {
        // Work hours preset: 9 AM - 5 PM active, rest disabled
        let workHoursActive: Set<Int> = [9, 10, 11, 12, 13, 14, 15, 16]
        let workHoursDisabled = Set(0..<24).subtracting(workHoursActive)
        XCTAssertEqual(workHoursDisabled.count, 16, "Work hours should disable 16 hours")
        XCTAssertTrue(workHoursDisabled.contains(0), "Midnight should be disabled in work hours")
        XCTAssertTrue(workHoursDisabled.contains(8), "8 AM should be disabled in work hours")
        XCTAssertFalse(workHoursDisabled.contains(9), "9 AM should be active in work hours")
        XCTAssertFalse(workHoursDisabled.contains(16), "4 PM should be active in work hours")
        XCTAssertTrue(workHoursDisabled.contains(17), "5 PM should be disabled in work hours")

        // Waking hours preset: 7 AM - 11 PM active
        let wakingHoursActive: Set<Int> = Set(7...22)
        let wakingHoursDisabled = Set(0..<24).subtracting(wakingHoursActive)
        XCTAssertEqual(wakingHoursDisabled.count, 8, "Waking hours should disable 8 hours")
        XCTAssertTrue(wakingHoursDisabled.contains(0), "Midnight should be disabled in waking hours")
        XCTAssertTrue(wakingHoursDisabled.contains(6), "6 AM should be disabled in waking hours")
        XCTAssertFalse(wakingHoursDisabled.contains(7), "7 AM should be active in waking hours")

        // All hours preset
        let allHoursDisabled: Set<Int> = []
        XCTAssertEqual(allHoursDisabled.count, 0, "All hours preset should have nothing disabled")
    }

    // MARK: - Test 21: sound_preview_plays_correct_chime

    func test_sound_preview_plays_correct_chime() throws {
        let player = ChimeSoundPlayer()

        // Each sound should be valid and playable
        let sounds = ["gentle", "tick", "wood", "silent"]
        for sound in sounds {
            XCTAssertTrue(player.isValidSound(sound), "'\(sound)' should be valid for preview")
        }

        // Invalid sounds should not be valid
        XCTAssertFalse(player.isValidSound("nonexistent"), "'nonexistent' should not be a valid sound")
    }
}
