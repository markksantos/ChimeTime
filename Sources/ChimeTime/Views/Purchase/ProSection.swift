import SwiftUI

/// Small "PRO" pill used to mark locked settings.
struct ProPill: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .accessibilityLabel("Requires ChimeTime Pro")
    }
}

/// A settings group whose controls are disabled until Pro is unlocked.
///
/// The header stays interactive on purpose — a locked section that swallows
/// every click leaves people with no idea why the control is dead. The
/// visible "Unlock" button gives the lock a cause and an exit.
struct ProSection<Content: View>: View {
    let feature: ProFeature
    let title: String
    let isLocked: Bool
    let onUnlock: () -> Void
    let content: Content

    init(
        _ feature: ProFeature,
        title: String? = nil,
        isLocked: Bool,
        onUnlock: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.feature = feature
        self.title = title ?? feature.title
        self.isLocked = isLocked
        self.onUnlock = onUnlock
        self.content = content()
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.body.weight(.medium))
                    if isLocked {
                        ProPill()
                    }
                    Spacer()
                    if isLocked {
                        Button("Unlock", action: onUnlock)
                            .buttonStyle(.borderless)
                            .font(.caption.weight(.semibold))
                    }
                }

                if isLocked {
                    Text(feature.summary)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                content
                    // Applied to the content only — the header above, including
                    // the Unlock button, stays clickable.
                    .allowsHitTesting(!isLocked)
                    .opacity(isLocked ? 0.4 : 1.0)
            }
            .padding(4)
        }
    }
}
