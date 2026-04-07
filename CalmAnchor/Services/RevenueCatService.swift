import Foundation
import RevenueCat

@MainActor
class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()
    // TODO: Replace with live key before App Store release
    static let apiKey = "test_AFpuFmRxwiYCSJV0rgzxFqKjZDa"
    static let entitlementID = "pro"

    @Published var isPremium = false
    @Published var offerings: Offerings?
    @Published var currentOffering: Offering?

    func configure() {
        Purchases.configure(withAPIKey: Self.apiKey)
        Purchases.shared.delegate = self

        Task {
            await checkSubscriptionStatus()
            await fetchOfferings()
        }
    }

    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            isPremium = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("RevenueCat: Error checking subscription: \(error)")
        }
    }

    func fetchOfferings() async {
        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            offerings = fetchedOfferings
            currentOffering = fetchedOfferings.current
        } catch {
            print("RevenueCat: Error fetching offerings: \(error)")
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
