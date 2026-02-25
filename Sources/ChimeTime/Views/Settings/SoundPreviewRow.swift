import SwiftUI

struct SoundPreviewRow: View {
    let soundName: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    Text(soundName.capitalized)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onPreview) {
                Image(systemName: "speaker.wave.2")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}
