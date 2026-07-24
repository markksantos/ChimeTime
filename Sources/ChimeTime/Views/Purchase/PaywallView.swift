import SwiftUI

struct PaywallView: View {
    @ObservedObject var store: ProStore
    @ObservedObject var entitlement: ProEntitlement
    let onDismiss: () -> Void

    private var isBusy: Bool {
        store.purchaseState == .purchasing || store.purchaseState == .restoring
    }

    var body: some View {
        VStack(spacing: 0) {
            if entitlement.isPro {
                unlockedState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        featureGrid
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 20)
                }
                Divider()
                purchaseBar
            }
        }
        // Tall enough that all twelve features fit without the last row being
        // clipped — a cut-off feature list reads as a rendering bug.
        .frame(width: 520, height: entitlement.isPro ? 320 : 700)
        .background(.background)
        .task {
            // Retry the product load here, not just at launch. If the first
            // attempt failed (offline at startup), the Buy button would
            // otherwise stay dead until the app was relaunched. `loadProduct`
            // no-ops once the product is cached.
            await store.loadProduct()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.bottom, 2)

            Text("ChimeTime Pro")
                .font(.system(size: 26, weight: .semibold, design: .rounded))

            Text("Unlock every sound, every schedule, and every way to make ChimeTime yours.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
        }
    }

    // MARK: - Features

    private var featureGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            alignment: .leading,
            spacing: 14
        ) {
            ForEach(ProFeature.paywallOrder) { feature in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 20, height: 18, alignment: .center)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 12, weight: .semibold))
                        Text(feature.summary)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    // MARK: - Purchase bar

    private var purchaseBar: some View {
        VStack(spacing: 10) {
            if case .failed(let message) = store.purchaseState, !message.isEmpty {
                statusRow(message, icon: "exclamationmark.triangle.fill", tint: .orange)
            }

            if store.purchaseState == .pendingApproval {
                statusRow(
                    "Waiting for approval. Pro unlocks automatically once the purchase is approved.",
                    icon: "clock.fill",
                    tint: .secondary
                )
            }

            Button(action: { Task { await store.purchase() } }) {
                HStack(spacing: 8) {
                    if store.purchaseState == .purchasing {
                        ProgressView().controlSize(.small)
                    }
                    Text(buyButtonTitle)
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isBusy || store.product == nil)

            Text("One-time purchase — not a subscription. Unlocks on every Mac using your Apple ID.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Restore Purchases") { Task { await store.restore() } }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .disabled(isBusy)

                Button("Not Now", action: onDismiss)
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
    }

    private var buyButtonTitle: String {
        switch store.purchaseState {
        case .purchasing: return "Purchasing…"
        case .restoring: return "Restoring…"
        default:
            if let price = store.displayPrice { return "Unlock Pro — \(price)" }
            return store.isLoadingProduct ? "Loading…" : "Unavailable"
        }
    }

    private func statusRow(_ message: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Unlocked

    private var unlockedState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("ChimeTime Pro is unlocked")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text("Thank you for supporting a small, independent app. Every Pro feature is now available in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
            Spacer()
            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            Spacer().frame(height: 8)
        }
        .padding(24)
    }
}
