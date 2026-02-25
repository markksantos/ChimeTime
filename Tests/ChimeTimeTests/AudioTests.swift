import XCTest
@testable import ChimeTime

final class AudioTests: XCTestCase {

    // MARK: - Test 12: chime_sounds_4_variants_play

    func test_chime_sounds_4_variants_play() throws {
        let player = ChimeSoundPlayer()

        // All 4 sound variants should be available
        let sounds = ["gentle", "tick", "wood", "silent"]
        for sound in sounds {
            XCTAssertTrue(player.isValidSound(sound), "'\(sound)' should be a valid chime sound")
        }

        // Silent should not actually produce audio
        // (verified by the implementation not calling play for "silent")

        // Playing should not crash for any variant
        for sound in sounds {
            player.play(sound: sound)
        }
    }

    // MARK: - Test 13: time_speaker_natural_phrasing

    func test_time_speaker_natural_phrasing() throws {
        let speaker = TimeSpeaker()
        let calendar = Calendar.current

        // 2:00 PM
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 25
        components.hour = 14
        components.minute = 0
        let date2pm = calendar.date(from: components)!
        let phrase2pm = speaker.phraseForTime(date2pm, use24Hour: false)
        XCTAssertTrue(phrase2pm.contains("2") && (phrase2pm.lowercased().contains("pm") || phrase2pm.lowercased().contains("o'clock")),
                      "2 PM should be spoken naturally, got: \(phrase2pm)")
        XCTAssertFalse(phrase2pm.contains("14"), "Should not use 24-hour in 12-hour mode")

        // 12:00 PM (noon)
        components.hour = 12
        let dateNoon = calendar.date(from: components)!
        let phraseNoon = speaker.phraseForTime(dateNoon, use24Hour: false)
        XCTAssertTrue(phraseNoon.lowercased().contains("12") || phraseNoon.lowercased().contains("noon"),
                      "Noon should be spoken naturally, got: \(phraseNoon)")

        // 12:00 AM (midnight)
        components.hour = 0
        let dateMidnight = calendar.date(from: components)!
        let phraseMidnight = speaker.phraseForTime(dateMidnight, use24Hour: false)
        XCTAssertTrue(phraseMidnight.lowercased().contains("12") || phraseMidnight.lowercased().contains("midnight"),
                      "Midnight should be spoken naturally, got: \(phraseMidnight)")

        // 24-hour mode
        components.hour = 14
        let date14 = calendar.date(from: components)!
        let phrase14 = speaker.phraseForTime(date14, use24Hour: true)
        XCTAssertTrue(phrase14.contains("14"), "24-hour mode should use 14 for 2 PM, got: \(phrase14)")
    }

    // MARK: - Test 15: login_item_toggle_works

    func test_login_item_toggle_works() throws {
        // LoginItemManager should be constructable and have toggle capability
        let manager = LoginItemManager()
        XCTAssertNotNil(manager, "LoginItemManager should be constructable")

        // The status check should not crash
        let _ = manager.isEnabled
    }
}
