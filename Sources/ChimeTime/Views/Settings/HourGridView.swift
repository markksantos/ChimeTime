import SwiftUI

struct HourGridView: View {
    @EnvironmentObject var settings: SettingsManager

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    private let hours = Array(0..<24)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle all
            HStack {
                Text("Active Hours")
                    .font(.headline)
                Spacer()
                Button(settings.disabledHours.isEmpty ? "Deselect All" : "Select All") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if settings.disabledHours.isEmpty {
                            settings.disabledHours = Set(0..<24)
                        } else {
                            settings.disabledHours = []
                        }
                    }
                }
                .buttonStyle(.borderless)
            }

            // 6×4 grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(hours, id: \.self) { hour in
                    HourCell(
                        hour: hour,
                        isActive: !settings.disabledHours.contains(hour),
                        accentColor: settings.accentColor.color,
                        reduceMotion: settings.effectiveReduceMotion
                    ) {
                        toggleHour(hour)
                    }
                }
            }

            // Quick presets
            HStack(spacing: 12) {
                Text("Presets:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Work Hours") {
                    applyPreset(activeHours: Set(9...16))
                }
                .buttonStyle(.borderless)

                Button("Waking Hours") {
                    applyPreset(activeHours: Set(7...22))
                }
                .buttonStyle(.borderless)

                Button("All Hours") {
                    applyPreset(activeHours: Set(0..<24))
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private func toggleHour(_ hour: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if settings.disabledHours.contains(hour) {
                settings.disabledHours.remove(hour)
            } else {
                settings.disabledHours.insert(hour)
            }
        }
    }

    private func applyPreset(activeHours: Set<Int>) {
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.disabledHours = Set(0..<24).subtracting(activeHours)
        }
    }
}

private struct HourCell: View {
    let hour: Int
    let isActive: Bool
    let accentColor: Color
    let reduceMotion: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            if !reduceMotion {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            }
            onTap()
        }) {
            Text(hourLabel)
                .font(.system(size: 11, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? accentColor.opacity(0.2) : Color.gray.opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isActive ? accentColor : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }

    private var hourLabel: String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}
