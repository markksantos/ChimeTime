import SwiftUI

struct NotchDropView: View {
    let date: Date
    let showDate: Bool
    let use24Hour: Bool
    let size: NotificationSize
    let backgroundColor: NSColor
    let customLabel: String?

    init(date: Date, showDate: Bool, use24Hour: Bool, size: NotificationSize, backgroundColor: NSColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.95), customLabel: String? = nil) {
        self.date = date
        self.showDate = showDate
        self.use24Hour = use24Hour
        self.size = size
        self.backgroundColor = backgroundColor
        self.customLabel = customLabel
    }

    var body: some View {
        VStack(spacing: 6) {
            if let label = customLabel {
                Text(label)
                    .font(.system(size: size.fontSize * 0.6, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                TimeDisplay(
                    date: date,
                    style: .standard,
                    use24Hour: use24Hour,
                    fontSize: size.fontSize
                )
            }

            if showDate && customLabel == nil {
                Text(formattedDate())
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 28)
        .padding(.bottom, 16)
        .padding(.horizontal, 20)
        .frame(width: size.windowWidth)
        .background(
            Color(nsColor: backgroundColor)
        )
        .clipShape(NotchShape(cornerRadius: 20))
        .overlay(
            NotchShape(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}
