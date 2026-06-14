import Foundation
#if APPSTORE
import StoreKit
#endif

/// Asks for an App Store rating at a "moment of value" — after the user has
/// successfully fired a few shortcuts. Apple rate-limits the real prompt, and
/// we additionally cap it to once per app version. No-op outside the App Store
/// build (StoreKit's prompt does nothing for non-MAS distribution anyway).
enum ReviewPrompt {
    private static let countKey = "mackey.activationCount"
    private static let promptedVersionKey = "mackey.reviewPromptedVersion"
    private static let thresholds: Set<Int> = [8, 40]

    static func recordActivation() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        #if APPSTORE
        guard thresholds.contains(count) else { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard defaults.string(forKey: promptedVersionKey) != version else { return }
        defaults.set(version, forKey: promptedVersionKey)
        DispatchQueue.main.async {
            SKStoreReviewController.requestReview()
        }
        #endif
    }
}
