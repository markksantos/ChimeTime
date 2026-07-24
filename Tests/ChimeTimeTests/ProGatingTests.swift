import XCTest
@testable import ChimeTime

/// The paywall's contract, asserted directly.
///
/// The point of these tests is that a free user gets free behavior even when
/// the *stored* preferences say otherwise — which is what happens after a
/// refund, and what someone gets by editing UserDefaults by hand. Every gate
/// is checked against a settings object whose raw values are all set to the
/// Pro configuration.
final class ProGatingTests: XCTestCase {

    /// Sets every Pro-gated preference to a non-default value.
    private func configuredSettings(isPro: Bool) -> SettingsManager {
        let settings = SettingsManager(entitlement: ProEntitlement(isPro: isPro))
        settings.displayDuration = 8.0
        settings.notificationSize = .extraLarge
        settings.showDateInNotification = false
        settings.appTheme = .light
        settings.accentColor = .pink
        settings.dropdownColorR = 1.0
        settings.selectedChimeSound = "wood"
        settings.selectedCustomSound = "MyHorn"
        settings.halfHourChimeEnabled = true
        settings.halfHourChimeSound = "wood"
        settings.chimeCountEnabled = true
        settings.chimeCountMax = 3
        settings.historyEnabled = true
        settings.globalHotkeyEnabled = true
        settings.pomodoroEnabled = true
        settings.menuBarClockEnabled = true
        settings.calendarQuietEnabled = true
        settings.displayPreference = "screen-2"
        settings.disabledHours = [1, 2, 3]
        return settings
    }

    // MARK: - Free tier falls back to free defaults

    func test_free_tier_ignores_stored_pro_preferences() {
        let s = configuredSettings(isPro: false)

        XCTAssertEqual(s.effectiveDisplayDuration, 4.0)
        XCTAssertEqual(s.effectiveNotificationSize, .medium)
        XCTAssertTrue(s.effectiveShowDateInNotification)
        XCTAssertEqual(s.effectiveAppTheme, .auto)
        XCTAssertEqual(s.effectiveAccentColor, .blue)
        XCTAssertEqual(s.effectiveDropdownNSColor.redComponent, 0.0, accuracy: 0.001)
        XCTAssertEqual(s.effectiveSelectedChimeSound, "gentle")
        XCTAssertEqual(s.effectiveSelectedCustomSound, "")
        XCTAssertFalse(s.effectiveHalfHourChimeEnabled)
        XCTAssertFalse(s.effectiveChimeCountEnabled)
        XCTAssertEqual(s.effectiveChimeCountMax, 12)
        XCTAssertFalse(s.effectiveHistoryEnabled)
        XCTAssertFalse(s.effectiveGlobalHotkeyEnabled)
        XCTAssertFalse(s.effectivePomodoroEnabled)
        XCTAssertFalse(s.effectiveMenuBarClockEnabled)
        XCTAssertFalse(s.effectiveCalendarQuietEnabled)
        XCTAssertEqual(s.effectiveDisplayPreference, "main")
        XCTAssertEqual(s.effectiveDisabledHours, [])
    }

    // MARK: - Pro tier honors every stored preference

    func test_pro_tier_honors_stored_preferences() {
        let s = configuredSettings(isPro: true)

        XCTAssertEqual(s.effectiveDisplayDuration, 8.0)
        XCTAssertEqual(s.effectiveNotificationSize, .extraLarge)
        XCTAssertFalse(s.effectiveShowDateInNotification)
        XCTAssertEqual(s.effectiveAppTheme, .light)
        XCTAssertEqual(s.effectiveAccentColor, .pink)
        XCTAssertEqual(s.effectiveDropdownNSColor.redComponent, 1.0, accuracy: 0.001)
        XCTAssertEqual(s.effectiveSelectedChimeSound, "wood")
        XCTAssertEqual(s.effectiveSelectedCustomSound, "MyHorn")
        XCTAssertTrue(s.effectiveHalfHourChimeEnabled)
        XCTAssertTrue(s.effectiveChimeCountEnabled)
        XCTAssertEqual(s.effectiveChimeCountMax, 3)
        XCTAssertTrue(s.effectiveHistoryEnabled)
        XCTAssertTrue(s.effectiveGlobalHotkeyEnabled)
        XCTAssertTrue(s.effectivePomodoroEnabled)
        XCTAssertTrue(s.effectiveMenuBarClockEnabled)
        XCTAssertTrue(s.effectiveCalendarQuietEnabled)
        XCTAssertEqual(s.effectiveDisplayPreference, "screen-2")
        XCTAssertEqual(s.effectiveDisabledHours, [1, 2, 3])
    }

    // MARK: - Free features must never be gated

    func test_free_features_are_never_gated() {
        let s = SettingsManager()  // free
        s.isEnabled = true
        s.quietHoursEnabled = true
        s.quietHoursStart = 22
        s.quietHoursEnd = 6
        s.launchAtLogin = true
        s.soundMode = .chimeAndSpeak
        s.speakTimeVolume = 0.3
        s.reduceMotion = true

        XCTAssertTrue(s.isEnabled, "Master toggle is free")
        XCTAssertTrue(s.quietHoursEnabled, "Quiet Hours is free")
        XCTAssertTrue(s.isInQuietHours(23), "Quiet Hours evaluates for free users")
        XCTAssertTrue(s.launchAtLogin, "Launch at Login is free")
        XCTAssertEqual(s.soundMode, .chimeAndSpeak, "Sound mode incl. Speak Time is free")
        XCTAssertEqual(s.speakTimeVolume, 0.3, "Speech volume is free")
        XCTAssertTrue(s.effectiveReduceMotion, "Accessibility is never gated")
    }

    // MARK: - Entitlement transitions

    func test_unlocking_pro_flips_every_gate_live() {
        let entitlement = ProEntitlement(isPro: false)
        let s = SettingsManager(entitlement: entitlement)
        s.pomodoroEnabled = true
        s.selectedChimeSound = "wood"

        XCTAssertFalse(s.effectivePomodoroEnabled)
        XCTAssertEqual(s.effectiveSelectedChimeSound, "gentle")

        entitlement.setPro(true)

        XCTAssertTrue(s.effectivePomodoroEnabled, "Unlock must take effect without a relaunch")
        XCTAssertEqual(s.effectiveSelectedChimeSound, "wood")
    }

    func test_revoking_pro_restores_free_behavior() {
        // Refunds and family-sharing revocations arrive via Transaction.updates.
        let entitlement = ProEntitlement(isPro: true)
        let s = SettingsManager(entitlement: entitlement)
        s.menuBarClockEnabled = true
        s.disabledHours = [4, 5]

        XCTAssertTrue(s.effectiveMenuBarClockEnabled)

        entitlement.setPro(false)

        XCTAssertFalse(s.effectiveMenuBarClockEnabled, "Revoked entitlement must re-lock features")
        XCTAssertEqual(s.effectiveDisabledHours, [])
    }

    func test_settings_manager_defaults_to_free() {
        XCTAssertFalse(SettingsManager().isPro, "Nothing is unlocked until StoreKit says so")
    }

    // MARK: - Catalog integrity

    func test_paywall_advertises_every_pro_feature() {
        // A feature missing from paywallOrder would be sold-but-invisible.
        XCTAssertEqual(
            Set(ProFeature.paywallOrder),
            Set(ProFeature.allCases),
            "Every ProFeature must appear on the paywall exactly once"
        )
        XCTAssertEqual(
            ProFeature.paywallOrder.count,
            ProFeature.allCases.count,
            "paywallOrder must not contain duplicates"
        )
    }

    func test_every_feature_has_copy() {
        for feature in ProFeature.allCases {
            XCTAssertFalse(feature.title.isEmpty, "\(feature) needs a title")
            XCTAssertFalse(feature.summary.isEmpty, "\(feature) needs a summary")
            XCTAssertFalse(feature.icon.isEmpty, "\(feature) needs an icon")
        }
    }
}
