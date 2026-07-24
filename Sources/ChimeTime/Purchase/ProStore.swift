import Foundation
import StoreKit

/// Owns all StoreKit interaction for the one-time Pro unlock.
///
/// The unlock is a non-consumable, so entitlement is derived entirely from
/// `Transaction.currentEntitlements` — no server, no receipt parsing, and it
/// works offline because StoreKit caches the signed transaction on-device.
@MainActor
final class ProStore: ObservableObject {

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case restoring
        /// Purchase needs approval (Ask to Buy) — entitlement arrives later
        /// via the `Transaction.updates` listener.
        case pendingApproval
        case failed(String)
    }

    /// `nil` until the product loads. Stays `nil` in builds that aren't
    /// installed from the App Store (e.g. a local `swift build` run), which is
    /// why the paywall must handle an absent product gracefully.
    @Published private(set) var product: Product?
    @Published private(set) var purchaseState: PurchaseState = .idle
    @Published private(set) var isLoadingProduct = false

    let entitlement: ProEntitlement

    private var updatesTask: Task<Void, Never>?

    /// Localized, storefront-correct price. Never hardcode a currency string.
    var displayPrice: String? { product?.displayPrice }

    init(entitlement: ProEntitlement) {
        self.entitlement = entitlement

        // Start listening BEFORE anything else. This catches purchases that
        // completed outside the app (another Mac, Ask to Buy approval, or a
        // purchase interrupted by a crash) and is required for App Review.
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }

        Task { await refreshEntitlements() }
        Task { await loadProduct() }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Product loading

    func loadProduct() async {
        guard product == nil else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        do {
            let products = try await Product.products(for: [StoreConfiguration.proUnlockProductID])
            product = products.first
        } catch {
            // Offline, or not an App Store build. Leave `product` nil; the
            // paywall shows a "can't reach the App Store" state rather than a
            // dead Buy button.
            product = nil
        }
    }

    // MARK: - Entitlement

    /// Re-derives `isPro` from the transactions Apple says this Apple ID owns.
    func refreshEntitlements() async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "chimetime.debugForcePro") {
            entitlement.setPro(true)
            return
        }
        #endif

        var owned = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result) else { continue }
            if transaction.productID == StoreConfiguration.proUnlockProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        entitlement.setPro(owned)
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else {
            purchaseState = .failed("Couldn't reach the App Store. Check your connection and try again.")
            return
        }

        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                // Finishing is mandatory — an unfinished transaction is
                // re-delivered forever and fails App Review.
                await transaction.finish()
                await refreshEntitlements()
                purchaseState = .idle

            case .pending:
                // Ask to Buy / SCA. Entitlement will arrive via the updates
                // listener once approved.
                purchaseState = .pendingApproval

            case .userCancelled:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(Self.message(for: error))
        }
    }

    /// Required by App Review for any non-consumable.
    func restore() async {
        purchaseState = .restoring
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseState = entitlement.isPro
                ? .idle
                : .failed("No previous ChimeTime Pro purchase was found on this Apple ID.")
        } catch {
            purchaseState = .failed(Self.message(for: error))
        }
    }

    func clearError() {
        if case .failed = purchaseState { purchaseState = .idle }
    }

    // MARK: - Helpers

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard let transaction = try? verified(transactionResult) else { return }
        await transaction.finish()
        await refreshEntitlements()
        if entitlement.isPro, purchaseState == .pendingApproval {
            purchaseState = .idle
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    private static func message(for error: Error) -> String {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .userCancelled:
                return ""
            case .networkError:
                return "Couldn't reach the App Store. Check your connection and try again."
            case .notAvailableInStorefront:
                return "ChimeTime Pro isn't available in your region's App Store."
            case .notEntitled:
                return "This Apple ID isn't entitled to make this purchase."
            default:
                break
            }
        }
        return "Something went wrong with the purchase. Please try again."
    }
}
