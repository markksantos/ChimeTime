import AppKit
import Foundation

final class TimeSpeaker {
    private let synthesizer = NSSpeechSynthesizer()

    func speak(date: Date, volume: Float, use24Hour: Bool) {
        let phrase = phraseForTime(date, use24Hour: use24Hour)
        synthesizer.volume = volume
        synthesizer.startSpeaking(phrase)
    }

    func phraseForTime(_ date: Date, use24Hour: Bool) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        if use24Hour {
            return "It's \(hour) o'clock"
        }

        switch hour {
        case 0:
            return "It's midnight"
        case 12:
            return "It's noon"
        default:
            let displayHour = hour > 12 ? hour - 12 : hour
            let period = hour >= 12 ? "PM" : "AM"
            return "It's \(displayHour) \(period)"
        }
    }
}
