import Foundation

/// Single source of truth for App Store identifiers.
///
/// ⚠️ BEFORE SUBMITTING: `proUnlockProductID` must exactly match the product
/// identifier of the non-consumable created in App Store Connect, and the
/// bundle identifier in `Info.plist` / `project.yml` must match the App ID
/// registered in the Developer portal. Both are placeholders today.
enum StoreConfiguration {
    /// Non-consumable that unlocks every Pro feature, forever, on all the
    /// user's Macs (App Store handles family sharing / re-download).
    static let proUnlockProductID = "com.nosleeplab.chimetime.pro"

    /// Price is *never* hardcoded in the UI — StoreKit returns a localized,
    /// tax-inclusive `displayPrice` per storefront. This is only the tier to
    /// select in App Store Connect.
    static let intendedPriceTierUSD = "4.99"
}
