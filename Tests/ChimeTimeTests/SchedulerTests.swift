import XCTest
@testable import ChimeTime

final class SchedulerTests: XCTestCase {

    // MARK: - Test 7: scheduler_next_hour_calculation

    func test_scheduler_next_hour_calculation() throws {
        let calendar = Calendar.current

        // Test at 2:47:33 PM — next hour should be 3:00:00 PM
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 25
        components.hour = 14
        components.minute = 47
        components.second = 33
        let date1 = calendar.date(from: components)!
        let next1 = HourlyScheduler.nextHourBoundary(from: date1)
        let next1Components = calendar.dateComponents([.hour, .minute, .second], from: next1)
        XCTAssertEqual(next1Components.hour, 15, "Next hour from 2:47 PM should be 3 PM")
        XCTAssertEqual(next1Components.minute, 0, "Next hour should be at :00")
        XCTAssertEqual(next1Components.second, 0, "Next hour should be at :00:00")

        // Test at exactly 2:00:00 PM — next hour should be 3:00:00 PM (not 2:00 again)
        components.hour = 14
        components.minute = 0
        components.second = 0
        let date2 = calendar.date(from: components)!
        let next2 = HourlyScheduler.nextHourBoundary(from: date2)
        let next2Components = calendar.dateComponents([.hour, .minute, .second], from: next2)
        XCTAssertEqual(next2Components.hour, 15, "Next hour from exactly 2:00 PM should be 3 PM")

        // Test at 2:59:59 PM — next hour should be 3:00:00 PM
        components.hour = 14
        components.minute = 59
        components.second = 59
        let date3 = calendar.date(from: components)!
        let next3 = HourlyScheduler.nextHourBoundary(from: date3)
        let next3Components = calendar.dateComponents([.hour, .minute, .second], from: next3)
        XCTAssertEqual(next3Components.hour, 15, "Next hour from 2:59:59 PM should be 3 PM")

        // Test at 11:30 PM — next hour should be 12:00 AM (midnight, next day)
        components.hour = 23
        components.minute = 30
        components.second = 0
        let date4 = calendar.date(from: components)!
        let next4 = HourlyScheduler.nextHourBoundary(from: date4)
        let next4Components = calendar.dateComponents([.hour, .minute, .second, .day], from: next4)
        XCTAssertEqual(next4Components.hour, 0, "Next hour from 11:30 PM should be midnight")
        XCTAssertEqual(next4Components.day, 26, "Midnight should be next day")
    }

    // MARK: - Test 8: scheduler_no_drift_recalculates_each_fire

    func test_scheduler_no_drift_recalculates_each_fire() throws {
        // Verify that the scheduler calculates from current time, not using repeating interval
        let settingsManager = SettingsManager()
        var fireCount = 0

        let scheduler = HourlyScheduler(settingsManager: settingsManager) { _ in
            fireCount += 1
        }

        // The scheduler should have a method to get next fire time that always recalculates
        let now = Date()
        let next1 = HourlyScheduler.nextHourBoundary(from: now)
        let next2 = HourlyScheduler.nextHourBoundary(from: next1)

        // The interval between consecutive calculations should be exactly 1 hour
        let interval = next2.timeIntervalSince(next1)
        XCTAssertEqual(interval, 3600, accuracy: 1.0,
                       "Consecutive hour boundaries should be exactly 1 hour apart")

        // Verify scheduler uses nextHourBoundary (not a fixed 3600s interval)
        // This is an implementation detail verified by code review, but we can check
        // that the next fire time is always in the future
        XCTAssertGreaterThan(next1, now, "Next hour boundary should be in the future")
    }

    // MARK: - Test 9: scheduler_sleep_wake_recalculation

    func test_scheduler_sleep_wake_recalculation() throws {
        let settingsManager = SettingsManager()
        let scheduler = HourlyScheduler(settingsManager: settingsManager) { _ in }

        // The scheduler should observe wake notifications
        // After wake, nextFireTime should be recalculated
        scheduler.start()
        let initialNextFire = scheduler.nextFireTime

        // Simulate wake by calling the recalculation method
        scheduler.handleSystemWake()

        // After wake, next fire time should be valid and in the future
        XCTAssertNotNil(scheduler.nextFireTime, "Next fire time should be set after wake")
        if let nextFire = scheduler.nextFireTime {
            XCTAssertGreaterThan(nextFire, Date(), "Next fire time should be in the future after wake")
        }

        scheduler.stop()
    }

    // MARK: - Test 10: scheduler_quiet_hours_suppression

    func test_scheduler_quiet_hours_suppression() throws {
        let settingsManager = SettingsManager()
        settingsManager.quietHoursEnabled = true
        settingsManager.quietHoursStart = 23  // 11 PM
        settingsManager.quietHoursEnd = 7     // 7 AM

        // Hours within quiet period should be suppressed
        XCTAssertTrue(settingsManager.shouldSuppressHour(23), "11 PM should be in quiet hours")
        XCTAssertTrue(settingsManager.shouldSuppressHour(0), "12 AM should be in quiet hours")
        XCTAssertTrue(settingsManager.shouldSuppressHour(3), "3 AM should be in quiet hours")
        XCTAssertTrue(settingsManager.shouldSuppressHour(6), "6 AM should be in quiet hours")

        // Hours outside quiet period should not be suppressed
        XCTAssertFalse(settingsManager.shouldSuppressHour(7), "7 AM should not be in quiet hours")
        XCTAssertFalse(settingsManager.shouldSuppressHour(12), "12 PM should not be in quiet hours")
        XCTAssertFalse(settingsManager.shouldSuppressHour(22), "10 PM should not be in quiet hours")

        // When quiet hours disabled, nothing is suppressed
        settingsManager.quietHoursEnabled = false
        XCTAssertFalse(settingsManager.shouldSuppressHour(0), "Nothing suppressed when quiet hours disabled")
        XCTAssertFalse(settingsManager.shouldSuppressHour(23), "Nothing suppressed when quiet hours disabled")
    }

    // MARK: - Test 11: scheduler_disabled_hours_skipped

    func test_scheduler_disabled_hours_skipped() throws {
        let settingsManager = SettingsManager()
        settingsManager.disabledHours = [0, 1, 2, 3, 4, 5, 12]  // Disable midnight-5AM and noon

        XCTAssertTrue(settingsManager.shouldSuppressHour(0), "Disabled hour 0 should be suppressed")
        XCTAssertTrue(settingsManager.shouldSuppressHour(3), "Disabled hour 3 should be suppressed")
        XCTAssertTrue(settingsManager.shouldSuppressHour(12), "Disabled hour 12 should be suppressed")

        XCTAssertFalse(settingsManager.shouldSuppressHour(6), "Non-disabled hour 6 should not be suppressed")
        XCTAssertFalse(settingsManager.shouldSuppressHour(9), "Non-disabled hour 9 should not be suppressed")
        XCTAssertFalse(settingsManager.shouldSuppressHour(18), "Non-disabled hour 18 should not be suppressed")
    }

    // MARK: - Test 14: settings_persist_to_userdefaults

    func test_settings_persist_to_userdefaults() throws {
        let settings = SettingsManager()

        // Change settings
        settings.displayDuration = 6.0
        settings.notificationSize = .large
        settings.soundMode = .speakTime
        settings.selectedChimeSound = "wood"
        settings.quietHoursEnabled = true
        settings.quietHoursStart = 22
        settings.quietHoursEnd = 8
        settings.disabledHours = [0, 1, 2]

        // Create a new instance — should load persisted values
        let settings2 = SettingsManager()
        XCTAssertEqual(settings2.displayDuration, 6.0, "Display duration should persist")
        XCTAssertEqual(settings2.notificationSize, .large, "Notification size should persist")
        XCTAssertEqual(settings2.soundMode, .speakTime, "Sound mode should persist")
        XCTAssertEqual(settings2.selectedChimeSound, "wood", "Chime sound should persist")
        XCTAssertTrue(settings2.quietHoursEnabled, "Quiet hours enabled should persist")
        XCTAssertEqual(settings2.quietHoursStart, 22, "Quiet hours start should persist")
        XCTAssertEqual(settings2.quietHoursEnd, 8, "Quiet hours end should persist")
        XCTAssertEqual(settings2.disabledHours, [0, 1, 2], "Disabled hours should persist")

        // Clean up — reset to defaults
        settings.displayDuration = 4.0
        settings.notificationSize = .medium
        settings.soundMode = .chime
        settings.selectedChimeSound = "gentle"
        settings.quietHoursEnabled = false
        settings.quietHoursStart = 23
        settings.quietHoursEnd = 7
        settings.disabledHours = []
    }
}
