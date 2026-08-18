import Foundation
import RevenueCat

@MainActor
final class RevenueCatService: NSObject, ObservableObject {
    static let shared = RevenueCatService()

    static let apiKey = "appl_VMiYhGiOrGYXvqiXCXOLPeIRumH"
    static let entitlementID = "CalmAnchor Pro"

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
            #if DEBUG
            print("RevenueCat: subscription check failed — \(error.localizedDescription)")
            #endif
        }
    }

    func fetchOfferings() async {
        do {
            let fetched = try await Purchases.shared.offerings()
            offerings = fetched
            currentOffering = fetched.current
        } catch {
            #if DEBUG
            print("RevenueCat: offerings fetch failed — \(error.localizedDescription)")
            #endif
        }
    }

    func purchase(_ package: Package) async throws -> Bool {
        let result = try await Purchases.shared.purchase(package: package)
        isPremium = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true

        // If this purchase started a free trial, remind the user ~24h before it converts.
        if isPremium, let intro = package.storeProduct.introductoryDiscount,
           intro.paymentMode == .freeTrial {
            let unitSeconds: Double
            switch intro.subscriptionPeriod.unit {
            case .day:   unitSeconds = 86_400
            case .week:  unitSeconds = 604_800
            case .month: unitSeconds = 2_592_000
            case .year:  unitSeconds = 31_536_000
            @unknown default: unitSeconds = 86_400
            }
            let trialEnds = Date().addingTimeInterval(Double(intro.subscriptionPeriod.value) * unitSeconds)
            await NotificationService.shared.scheduleTrialEnding(trialEnds: trialEnds)
        }
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
