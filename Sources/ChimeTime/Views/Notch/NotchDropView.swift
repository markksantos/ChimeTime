import SwiftUI

struct NotchDropView: View {
    let date: Date
    let showDate: Bool
    let use24Hour: Bool
    let size: NotificationSize

    var body: some View {
        VStack(spacing: 6) {
            TimeDisplay(
                date: date,
                style: .standard,
                use24Hour: use24Hour,
                fontSize: size.fontSize
            )

            if showDate {
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
            Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 0.95))
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
