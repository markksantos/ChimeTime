import Foundation
import Combine

/// Holds whether the Pro unlock is currently owned.
///
/// Deliberately separate from `ProStore` so that gating logic is testable
/// without StoreKit: tests flip `isPro` directly, while in the real app only
/// `ProStore` writes to it after verifying a signed App Store transaction.
final class ProEntitlement: ObservableObject {
    @Published private(set) var isPro: Bool

    init(isPro: Bool = false) {
        self.isPro = isPro
    }

    /// Only `ProStore` (and tests) should call this. Kept internal rather than
    /// private so the store — which lives in another file — can update it, and
    /// so the gating matrix can be exercised in tests.
    func setPro(_ owned: Bool) {
        guard isPro != owned else { return }
        isPro = owned
    }
}
