import SwiftUI
import RevenueCat

// MARK: - Plan Model

struct PlanInfo {
    let packageType: PackageType
    let productID: String
    let name: String
    let price: String
    let priceSuffix: String
    let badge: String
    let hasTrial: Bool
    let trialLabel: String
    let savingsNote: String
}

// MARK: - PaywallView

struct PaywallView: View {
    let calmName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    init(calmName: String, onContinue: @escaping () -> Void, onRestore: @escaping () -> Void) {
        self.calmName = calmName
        self.onContinue = onContinue
        self.onRestore = onRestore
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var revenueCat: RevenueCatService
    @State private var selectedIndex = 1
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var headerAppeared = false
    @State private var contentAppeared = false

    // MARK: Fallback plan data
    private let fallbackPlans: [PlanInfo] = [
        PlanInfo(packageType: .weekly,   productID: "com.clawdbonzo.calmanchor.weekly",
                 name: "Weekly",   price: "$4.99",  priceSuffix: "/wk",
                 badge: "",          hasTrial: false, trialLabel: "",
                 savingsNote: ""),
        PlanInfo(packageType: .monthly,  productID: "com.clawdbonzo.calmanchor.monthly",
                 name: "Monthly",  price: "$9.99",  priceSuffix: "/mo",
                 badge: "BEST VALUE", hasTrial: true,  trialLabel: "3-Day Free Trial",
                 savingsNote: ""),
        PlanInfo(packageType: .annual,   productID: "com.clawdbonzo.calmanchor.yearly",
                 name: "Yearly",   price: "$49.99", priceSuffix: "/yr",
                 badge: "Save 58%",  hasTrial: true,  trialLabel: "3-Day Free Trial",
                 savingsNote: "Save 58% vs monthly"),
        PlanInfo(packageType: .lifetime, productID: "com.clawdbonzo.calmanchor.lifetime",
                 name: "Lifetime", price: "$79.99", priceSuffix: "",
                 badge: "One-Time",  hasTrial: false, trialLabel: "",
                 savingsNote: "Pay once, use forever")
    ]

    private var sortedPackages: [Package] {
        let order: [PackageType] = [.weekly, .monthly, .annual, .lifetime]
        return (revenueCat.currentOffering?.availablePackages ?? []).sorted {
            (order.firstIndex(of: $0.packageType) ?? 99) < (order.firstIndex(of: $1.packageType) ?? 99)
        }
    }

    private var useLive: Bool { !sortedPackages.isEmpty }

    private let features: [(icon: String, text: String)] = [
        ("brain.head.profile",        "Personalized 30-Day Peace Plan"),
        ("bolt.heart.fill",           "Instant Panic SOS & breathing tools"),
        ("chart.line.uptrend.xyaxis", "Advanced mood & anxiety analytics"),
        ("flame.fill",                "Healing streaks & daily journal")
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark background — always dark regardless of system appearance
            LinearGradient(
                colors: [Color(hex: "080E1C"), Color(hex: "0F1A2E"), Color(hex: "0D2B3F")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── DISMISS (when presented as sheet) ───────────────
                HStack {
                    Spacer()
                    Button(action: { dismiss(); onContinue() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // ── HERO ────────────────────────────────────────────
                heroSection
                    .padding(.bottom, 20)

                // ── FEATURES ────────────────────────────────────────
                featureRows
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15), value: contentAppeared)

                // ── PLAN CARDS ──────────────────────────────────────
                planCards
                    .padding(.horizontal, 20)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 16)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.28), value: contentAppeared)

                // ── ERROR ───────────────────────────────────────────
                if let msg = errorMessage {
                    Text(msg)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppConstants.Colors.gentleCoral)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .transition(.opacity)
                }

                Spacer()

                // ── CTA BUTTON ──────────────────────────────────────
                ctaButton
                    .padding(.horizontal, 20)
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4), value: contentAppeared)

                // ── FOOTER ──────────────────────────────────────────
                footerSection
                    .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            headerAppeared = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                contentAppeared = true
            }
            if useLive {
                selectedIndex = sortedPackages.firstIndex(where: { $0.packageType == .monthly }) ?? 1
            } else {
                selectedIndex = 1
            }
        }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 10) {
            // Brand icon
            Image("BrandIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: AppConstants.Colors.electricTeal.opacity(0.4), radius: 16, y: 4)
            .scaleEffect(headerAppeared ? 1.0 : 0.5)
            .opacity(headerAppeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.68).delay(0.05), value: headerAppeared)

            VStack(spacing: 2) {
                Text("Unlock Your")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.electricTeal)
                Text("Full Calm")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.sunsetGold)
            }
            .multilineTextAlignment(.center)
            .opacity(headerAppeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.12), value: headerAppeared)
        }
    }

    // MARK: - Feature Rows

    @ViewBuilder
    private var featureRows: some View {
        VStack(spacing: 12) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: 14) {
                    // Icon in rounded rect
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(0.08))
                            .frame(width: 38, height: 38)
                        Image(systemName: feature.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.electricTeal)
                    }

                    Text(feature.text)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppConstants.Colors.electricTeal)
                }
            }
        }
    }

    // MARK: - Plan Cards

    @ViewBuilder
    private var planCards: some View {
        VStack(spacing: 8) {
            if useLive {
                ForEach(Array(sortedPackages.enumerated()), id: \.element.id) { i, pkg in
                    let info = liveInfo(for: pkg)
                    PremiumPlanCard(
                        index: i,
                        name: info.name,
                        price: pkg.localizedPriceString,
                        priceSuffix: info.priceSuffix,
                        badge: info.badge,
                        hasTrial: info.hasTrial,
                        trialLabel: info.trialLabel,
                        savingsNote: info.savingsNote,
                        isBestValue: pkg.packageType == .monthly,
                        isSelected: selectedIndex == i,
                        action: { selectedIndex = i }
                    )
                }
            } else {
                ForEach(Array(fallbackPlans.enumerated()), id: \.offset) { i, plan in
                    PremiumPlanCard(
                        index: i,
                        name: plan.name,
                        price: plan.price,
                        priceSuffix: plan.priceSuffix,
                        badge: plan.badge,
                        hasTrial: plan.hasTrial,
                        trialLabel: plan.trialLabel,
                        savingsNote: plan.savingsNote,
                        isBestValue: plan.packageType == .monthly,
                        isSelected: selectedIndex == i,
                        action: { selectedIndex = i }
                    )
                }
            }
        }
    }

    // MARK: - CTA Button

    @ViewBuilder
    private var ctaButton: some View {
        Button(action: { Task { await purchaseSelected() } }) {
            Group {
                if isPurchasing {
                    ProgressView().tint(.white).scaleEffect(1.1)
                } else {
                    HStack(spacing: 8) {
                        Text(ctaTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
            }
            .foregroundStyle(Color(hex: "0A1428"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppConstants.Colors.electricTeal)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: AppConstants.Colors.electricTeal.opacity(0.4), radius: 16, y: 5)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: 6) {
            if let sub = ctaSubtitle {
                Text(sub)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }

            HStack(spacing: 0) {
                Button("Restore Purchase") { Task { await restore() } }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)

                Text("·").foregroundStyle(.white.opacity(0.2))

                Button("Terms") {}
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)

                Text("·").foregroundStyle(.white.opacity(0.2))

                Button("Privacy") {}
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Purchase Logic

    private func purchaseSelected() async {
        guard !sortedPackages.isEmpty else { onContinue(); return }
        let pkg = sortedPackages[min(selectedIndex, sortedPackages.count - 1)]
        isPurchasing = true
        errorMessage = nil
        do {
            let success = try await revenueCat.purchase(pkg)
            isPurchasing = false
            if success { onContinue() }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        isPurchasing = true
        errorMessage = nil
        do {
            let success = try await revenueCat.restorePurchases()
            isPurchasing = false
            if success { onContinue() }
            else { errorMessage = "No active subscription found." }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - CTA Labels

    private var ctaTitle: String {
        let selectedPlan = useLive
            ? liveInfoOptional(for: sortedPackages[safe: selectedIndex])
            : fallbackPlans[safe: selectedIndex]

        if let plan = selectedPlan {
            if plan.hasTrial { return "Start Free Trial" }
            if plan.packageType == .lifetime { return "Get Lifetime Access" }
        }
        return "Subscribe Now"
    }

    private var ctaSubtitle: String? {
        let selectedPlan = useLive
            ? liveInfoOptional(for: sortedPackages[safe: selectedIndex])
            : fallbackPlans[safe: selectedIndex]

        guard let plan = selectedPlan else { return nil }

        if plan.hasTrial {
            let priceStr: String
            if useLive, let pkg = sortedPackages[safe: selectedIndex] {
                priceStr = pkg.localizedPriceString
            } else {
                priceStr = plan.price
            }
            return "3-day free trial, then \(priceStr)\(plan.priceSuffix). Cancel anytime."
        }
        return nil
    }

    // MARK: - Live Package Info Helpers

    private func liveInfoOptional(for pkg: Package?) -> PlanInfo? {
        guard let pkg = pkg else { return nil }
        return liveInfo(for: pkg)
    }

    private func liveInfo(for pkg: Package) -> PlanInfo {
        let rcHasTrial = pkg.storeProduct.introductoryDiscount != nil
        let rcTrialDays = pkg.storeProduct.introductoryDiscount.map { "\($0.subscriptionPeriod.value)-day free trial" }

        switch pkg.packageType {
        case .weekly:
            return PlanInfo(packageType: .weekly, productID: "com.clawdbonzo.calmanchor.weekly",
                            name: "Weekly", price: pkg.localizedPriceString, priceSuffix: "/wk",
                            badge: "", hasTrial: false, trialLabel: "",
                            savingsNote: "")
        case .monthly:
            let trial = rcHasTrial ? (rcTrialDays ?? "3-day free trial") : "3-day free trial"
            return PlanInfo(packageType: .monthly, productID: "com.clawdbonzo.calmanchor.monthly",
                            name: "Monthly", price: pkg.localizedPriceString, priceSuffix: "/mo",
                            badge: "BEST VALUE", hasTrial: true, trialLabel: trial,
                            savingsNote: "")
        case .annual:
            let trial = rcHasTrial ? (rcTrialDays ?? "3-day free trial") : "3-day free trial"
            return PlanInfo(packageType: .annual, productID: "com.clawdbonzo.calmanchor.yearly",
                            name: "Yearly", price: pkg.localizedPriceString, priceSuffix: "/yr",
                            badge: "Save 58%", hasTrial: true, trialLabel: trial,
                            savingsNote: "vs $119.88/yr billed monthly")
        case .lifetime:
            return PlanInfo(packageType: .lifetime, productID: "com.clawdbonzo.calmanchor.lifetime",
                            name: "Lifetime", price: pkg.localizedPriceString, priceSuffix: "",
                            badge: "One-Time", hasTrial: false, trialLabel: "",
                            savingsNote: "Pay once, use forever")
        default:
            return PlanInfo(packageType: pkg.packageType, productID: "",
                            name: pkg.storeProduct.localizedTitle, price: pkg.localizedPriceString, priceSuffix: "",
                            badge: "", hasTrial: rcHasTrial, trialLabel: rcTrialDays ?? "",
                            savingsNote: "")
        }
    }
}

// MARK: - Premium Plan Card

struct PremiumPlanCard: View {
    let index: Int
    let name: String
    let price: String
    let priceSuffix: String
    let badge: String
    let hasTrial: Bool
    let trialLabel: String
    let savingsNote: String
    let isBestValue: Bool
    let isSelected: Bool
    let action: () -> Void

    private var accentColor: Color {
        if isBestValue { return AppConstants.Colors.sunsetGold }
        return AppConstants.Colors.electricTeal
    }

    private var borderColor: Color {
        if isBestValue && isSelected { return AppConstants.Colors.sunsetGold }
        if isSelected { return AppConstants.Colors.electricTeal }
        return .white.opacity(0.1)
    }

    private var cardBackground: Color {
        if isBestValue && isSelected { return AppConstants.Colors.sunsetGold.opacity(0.10) }
        if isSelected { return AppConstants.Colors.electricTeal.opacity(0.08) }
        return .white.opacity(0.04)
    }

    private var badgeColor: Color {
        switch badge {
        case "BEST VALUE":  return AppConstants.Colors.sunsetGold
        case "Save 58%":    return Color(hex: "E8A545")
        case "One-Time":    return AppConstants.Colors.softLavender.opacity(0.85)
        default:            return AppConstants.Colors.stormGray
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Left: name + badge + trial
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                    }

                    if hasTrial && !trialLabel.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text(trialLabel)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(AppConstants.Colors.mintGreen)
                    } else if !savingsNote.isEmpty {
                        Text(savingsNote)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Spacer()

                // Right: price
                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(isBestValue && isSelected ? AppConstants.Colors.sunsetGold : .white)
                    if !priceSuffix.isEmpty {
                        Text(priceSuffix)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isBestValue ? 16 : 13)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: isSelected || isBestValue ? 2 : 1)
            )
            .shadow(
                color: isBestValue && isSelected ? AppConstants.Colors.sunsetGold.opacity(0.25) : .clear,
                radius: 10, y: 2
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isSelected)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel("\(name) plan, \(price)\(priceSuffix)\(hasTrial ? ", \(trialLabel)" : "")\(isBestValue ? ", Best Value" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
