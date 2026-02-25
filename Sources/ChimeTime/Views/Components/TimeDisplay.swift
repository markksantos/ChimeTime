import SwiftUI

struct TimeDisplay: View {
    let date: Date
    let style: TimeDisplayStyle
    let use24Hour: Bool
    let fontSize: CGFloat

    var body: some View {
        VStack(spacing: 2) {
            if use24Hour {
                Text(Self.formatTime(date, use24Hour: true, style: style))
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            } else {
                let parts = formattedParts()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(parts.time)
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)

                    if let period = parts.period {
                        Text(period)
                            .font(.system(size: fontSize * 0.4, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }

    private func formattedParts() -> (time: String, period: String?) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let timeString = String(format: "%d:%02d", displayHour, minute)
        let period = style == .minimal ? nil : (hour >= 12 ? "PM" : "AM")
        return (timeString, period)
    }

    static func formatTime(_ date: Date, use24Hour: Bool, style: TimeDisplayStyle) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        if use24Hour {
            let timeString = String(format: "%d:%02d", hour, minute)
            switch style {
            case .minimal:
                return timeString
            case .standard:
                return timeString
            case .verbose:
                let dayName = dayOfWeek(from: date)
                return "\(timeString) · \(dayName)"
            }
        } else {
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let period = hour >= 12 ? "PM" : "AM"
            let timeString = String(format: "%d:%02d", displayHour, minute)

            switch style {
            case .minimal:
                return timeString
            case .standard:
                return "\(timeString) \(period)"
            case .verbose:
                let dayName = dayOfWeek(from: date)
                return "\(timeString) \(period) · \(dayName)"
            }
        }
    }

    private static func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
