import SwiftUI
import RevenueCat

// MARK: - Plan Model

struct PlanInfo {
    let packageType: PackageType
    let productID: String
    let name: String
    let price: String
    let priceSuffix: String
    let badge: String          // gold badge text
    let hasTrial: Bool
    let trialLabel: String
    let savingsNote: String    // e.g. "Save 58%"
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

    @EnvironmentObject private var revenueCat: RevenueCatService
    @State private var selectedIndex = 1          // default: Monthly
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var headerAppeared = false
    @State private var contentAppeared = false

    // MARK: Fallback plan data (used when RevenueCat products unavailable)
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

    // Sorted live packages from RevenueCat
    private var sortedPackages: [Package] {
        let order: [PackageType] = [.weekly, .monthly, .annual, .lifetime]
        return (revenueCat.currentOffering?.availablePackages ?? []).sorted {
            (order.firstIndex(of: $0.packageType) ?? 99) < (order.firstIndex(of: $1.packageType) ?? 99)
        }
    }

    // Whether we're using live packages or fallback
    private var useLive: Bool { !sortedPackages.isEmpty }

    private let features: [(String, String)] = [
        ("brain.head.profile",       "30-Day Peace Plan"),
        ("bolt.heart.fill",          "Instant Panic SOS"),
        ("chart.line.uptrend.xyaxis","Anxiety Tracking"),
        ("flame.fill",               "Healing Streaks")
    ]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // ── COMPACT HEADER ───────────────────────────────────────────
            compactHeader
                .padding(.top, 16)
                .padding(.bottom, 14)

            // ── FEATURE CHIPS ────────────────────────────────────────────
            featureChips
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 10)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.15), value: contentAppeared)

            // ── PLAN CARDS ───────────────────────────────────────────────
            planCards
                .padding(.horizontal, 20)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.28), value: contentAppeared)

            // ── ERROR ────────────────────────────────────────────────────
            if let msg = errorMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.gentleCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .transition(.opacity)
            }

            Spacer(minLength: 10)

            // ── CTA BUTTON ───────────────────────────────────────────────
            ctaButton
                .padding(.horizontal, 20)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4), value: contentAppeared)

            // ── FOOTER ───────────────────────────────────────────────────
            footer

            Text("Cancel anytime · Subscriptions auto-renew · Terms & Privacy apply.")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.2))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.bottom, 14)
        }
        .onAppear {
            headerAppeared = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                contentAppeared = true
            }
            // Default selection: prefer monthly (index 1)
            if useLive {
                selectedIndex = sortedPackages.firstIndex(where: { $0.packageType == .monthly }) ?? 1
            } else {
                selectedIndex = 1
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var compactHeader: some View {
        HStack(spacing: 14) {
            // Compact circular image with glow
            ZStack {
                Circle()
                    .fill(AppConstants.Colors.sereneTeal.opacity(0.18))
                    .frame(width: 76, height: 76)
                Circle()
                    .fill(AppConstants.Colors.sereneTeal.opacity(0.08))
                    .frame(width: 96, height: 96)
                Image("Onboarding-5")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppConstants.Colors.sereneTeal, AppConstants.Colors.sunsetGold.opacity(0.8)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: AppConstants.Colors.sereneTeal.opacity(0.6), radius: 12, y: 2)
            }
            .frame(width: 64, height: 64)
            .scaleEffect(headerAppeared ? 1.0 : 0.5)
            .opacity(headerAppeared ? 1 : 0)
            .animation(.spring(response: 0.65, dampingFraction: 0.68).delay(0.05), value: headerAppeared)

            // Title stack
            VStack(alignment: .leading, spacing: 3) {
                Text("Unlock Your Calm")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Everything you need to heal, daily.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.softLavender)
                    .lineLimit(1)

                // Trust badge
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppConstants.Colors.mintGreen)
                    Text("Private · No ads · Cancel anytime")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 1)
            }
            .opacity(headerAppeared ? 1 : 0)
            .offset(x: headerAppeared ? 0 : -10)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.12), value: headerAppeared)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Feature Chips

    @ViewBuilder
    private var featureChips: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppConstants.Colors.mintGreen)
                        .frame(width: 16)
                    Text(text)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Plan Cards

    @ViewBuilder
    private var planCards: some View {
        VStack(spacing: 7) {
            if useLive {
                ForEach(Array(sortedPackages.enumerated()), id: \.element.id) { i, pkg in
                    let info = liveInfo(for: pkg)
                    PremiumPlanCard(
                        index: i,
                        name: info.name,
                        price: pkg.localizedPriceString + info.priceSuffix,
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
                        price: plan.price + plan.priceSuffix,
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
                    VStack(spacing: 2) {
                        Text(ctaTitle)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        if let sub = ctaSubtitle {
                            Text(sub)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .opacity(0.82)
                        }
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "4A90D9"), AppConstants.Colors.sereneTeal],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color(hex: "4A90D9").opacity(0.5), radius: 14, y: 5)
        }
        .disabled(isPurchasing)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        HStack(spacing: 0) {
            Button("Restore Purchase") { Task { await restore() } }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(width: 1, height: 11)

            Button("Skip for now") { onContinue() }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 9)
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
            if plan.hasTrial { return "Start 3-Day Free Trial" }
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
            // e.g. "Then $9.99/mo · Cancel anytime"
            let priceStr: String
            if useLive, let pkg = sortedPackages[safe: selectedIndex] {
                priceStr = pkg.localizedPriceString + plan.priceSuffix
            } else {
                priceStr = plan.price + plan.priceSuffix
            }
            return "Then \(priceStr) · Cancel anytime"
        }
        return nil
    }

    // MARK: - Live Package Info Helpers

    private func liveInfoOptional(for pkg: Package?) -> PlanInfo? {
        guard let pkg = pkg else { return nil }
        return liveInfo(for: pkg)
    }

    private func liveInfo(for pkg: Package) -> PlanInfo {
        // Check RevenueCat introductory discount first, then fall back to hardcoded rules
        let rcHasTrial = pkg.storeProduct.introductoryDiscount != nil
        let rcTrialDays = pkg.storeProduct.introductoryDiscount.map { "\($0.subscriptionPeriod.value)-Day Free Trial" }

        switch pkg.packageType {
        case .weekly:
            return PlanInfo(packageType: .weekly, productID: "com.clawdbonzo.calmanchor.weekly",
                            name: "Weekly", price: pkg.localizedPriceString, priceSuffix: "/wk",
                            badge: "Flexible", hasTrial: false, trialLabel: "",
                            savingsNote: "")
        case .monthly:
            let trial = rcHasTrial ? (rcTrialDays ?? "3-Day Free Trial") : "3-Day Free Trial"
            return PlanInfo(packageType: .monthly, productID: "com.clawdbonzo.calmanchor.monthly",
                            name: "Monthly", price: pkg.localizedPriceString, priceSuffix: "/mo",
                            badge: "BEST VALUE", hasTrial: true, trialLabel: trial,
                            savingsNote: "")
        case .annual:
            let trial = rcHasTrial ? (rcTrialDays ?? "3-Day Free Trial") : "3-Day Free Trial"
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
    let badge: String
    let hasTrial: Bool
    let trialLabel: String
    let savingsNote: String
    let isBestValue: Bool
    let isSelected: Bool
    let action: () -> Void

    // Best Value always glows teal; other selected cards glow blue
    private var borderColor: Color {
        if isBestValue { return AppConstants.Colors.sereneTeal }
        if isSelected  { return AppConstants.Colors.calmBlue }
        return .white.opacity(0.1)
    }
    private var borderWidth: CGFloat { (isBestValue || isSelected) ? 2 : 1 }

    private var cardBackground: Color {
        if isBestValue && isSelected { return AppConstants.Colors.sereneTeal.opacity(0.18) }
        if isBestValue               { return AppConstants.Colors.sereneTeal.opacity(0.10) }
        if isSelected                { return AppConstants.Colors.calmBlue.opacity(0.18) }
        return .white.opacity(0.05)
    }

    private var badgeColor: Color {
        switch badge {
        case "BEST VALUE":  return AppConstants.Colors.sunsetGold
        case "Save 58%":    return Color(hex: "E8A545")
        case "Flexible":    return AppConstants.Colors.calmBlue.opacity(0.85)
        case "One-Time":    return AppConstants.Colors.softLavender.opacity(0.85)
        default:            return AppConstants.Colors.stormGray
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? borderColor : .white.opacity(0.12))
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.62), value: isSelected)

                // Name + trial
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(badgeColor)
                                .clipShape(Capsule())
                        }
                    }

                    if hasTrial && !trialLabel.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text(trialLabel)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(AppConstants.Colors.mintGreen)
                    } else if !savingsNote.isEmpty {
                        Text(savingsNote)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                Spacer()

                // Price
                Text(price)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, isBestValue ? 13 : 11)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            // Glow effect for best value / selected
            .shadow(
                color: isBestValue ? AppConstants.Colors.sereneTeal.opacity(isSelected ? 0.35 : 0.18) : .clear,
                radius: 8, y: 2
            )
            .scaleEffect(isSelected ? 1.015 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.65), value: isSelected)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel("\(name) plan, \(price)\(hasTrial ? ", \(trialLabel)" : "")\(isBestValue ? ", Best Value" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Legacy stubs (compile compatibility)
struct TransformCard: View {
    let title: String; let items: [String]; let color: Color; let icon: String
    var body: some View { EmptyView() }
}
struct PaywallFeatureRow: View {
    let icon: String; let text: String
    var body: some View { EmptyView() }
}
struct PlanCard: View {
    let name: String; let price: String; let badge: String; let trial: String
    let isSelected: Bool; let action: () -> Void
    var body: some View { EmptyView() }
}
struct CompactPlanCard: View {
    let name: String; let price: String; let badge: String; let trial: String
    let isSelected: Bool; let action: () -> Void
    var body: some View { EmptyView() }
}
