import SwiftUI

struct DurationSlider: View {
    @Binding var value: Double

    var range: ClosedRange<Double> = 1.0...10.0
    var step: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Display Duration")
                Spacer()
                Text(String(format: "%.1f seconds", value))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}
