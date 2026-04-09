import Foundation
import RevenueCat

@MainActor
final class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()

    // TODO: Replace with live appl_... key before App Store submission.
    // Generate it at app.revenuecat.com → Project Settings → API Keys.
    // Do NOT ship the test key (test_AFpuFmRxwiYCSJV0rgzxFqKjZDa) to production.
    static let apiKey = "appl_REPLACE_WITH_YOUR_LIVE_KEY"
    static let entitlementID = "pro"

    @Published var isPremium = false
    @Published var offerings: Offerings?
    @Published var currentOffering: Offering?

    func configure() {
        Purchases.logLevel = .warn          // suppress verbose sandbox logs in production
        Purchases.configure(withAPIKey: Self.apiKey)
        Purchases.shared.delegate = self

        Task { @MainActor in
            await checkSubscriptionStatus()
            await fetchOfferings()
        }
    }

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("RevenueCat: subscription check failed — \(error.localizedDescription)")
        }
    }

    func fetchOfferings() async {
        do {
            let fetched = try await Purchases.shared.offerings()
            offerings = fetched
            currentOffering = fetched.current
        } catch {
            print("RevenueCat: offerings fetch failed — \(error.localizedDescription)")
        }
    }

    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        isPremium = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
        return isPremium
    }

    func restorePurchases() async throws -> Bool {
        let customerInfo = try await Purchases.shared.restorePurchases()
        isPremium = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        return isPremium
    }
}

extension RevenueCatService: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            isPremium = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        }
    }
}
