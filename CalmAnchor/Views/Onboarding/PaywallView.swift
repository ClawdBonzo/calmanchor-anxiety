import SwiftUI
import RevenueCat

struct PaywallView: View {
    let calmName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    @EnvironmentObject private var revenueCat: RevenueCatService
    @State private var selectedIndex = 1 // default to monthly (BEST VALUE)
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var packages: [Package] {
        revenueCat.currentOffering?.availablePackages ?? []
    }

    private var sortedPackages: [Package] {
        let order: [PackageType] = [.weekly, .monthly, .annual, .lifetime]
        return packages.sorted { a, b in
            let ai = order.firstIndex(of: a.packageType) ?? 99
            let bi = order.firstIndex(of: b.packageType) ?? 99
            return ai < bi
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 30)

                // Paywall header illustration
                Image("Onboarding-5")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                // Before / After teaser
                VStack(spacing: 20) {
                    Text("Your Calm Transformation")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 20) {
                        TransformCard(
                            title: "Before",
                            items: ["Racing thoughts", "Panic attacks", "Sleepless nights", "Constant worry"],
                            color: AppConstants.Colors.gentleCoral,
                            icon: "cloud.rain.fill"
                        )

                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppConstants.Colors.sunsetGold)

                        TransformCard(
                            title: "After",
                            items: ["Inner peace", "Coping skills", "Restful sleep", "Confident calm"],
                            color: AppConstants.Colors.mintGreen,
                            icon: "sun.max.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                }

                // Features
                VStack(spacing: 12) {
                    PaywallFeatureRow(icon: "brain.head.profile", text: "Personalized 30-day Peace Plan")
                    PaywallFeatureRow(icon: "bolt.heart.fill", text: "Instant Panic SOS button")
                    PaywallFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Anxiety trend tracking")
                    PaywallFeatureRow(icon: "book.fill", text: "Unlimited journal entries")
                    PaywallFeatureRow(icon: "flame.fill", text: "Healing streaks & motivation")
                }
                .padding(.horizontal, 24)

                // Plan selection - live from RevenueCat
                VStack(spacing: 10) {
                    if sortedPackages.isEmpty {
                        // Fallback static plans while loading
                        ForEach(0..<4) { index in
                            let fallback = fallbackPlans[index]
                            PlanCard(
                                name: fallback.0,
                                price: fallback.1,
                                badge: fallback.2,
                                trial: fallback.3,
                                isSelected: selectedIndex == index,
                                action: { selectedIndex = index }
                            )
                        }
                    } else {
                        ForEach(Array(sortedPackages.enumerated()), id: \.element.id) { index, package in
                            PlanCard(
                                name: packageName(package),
                                price: package.localizedPriceString + priceSuffix(package),
                                badge: packageBadge(package),
                                trial: packageTrial(package),
                                isSelected: selectedIndex == index,
                                action: { selectedIndex = index }
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                // CTA
                Button(action: { Task { await purchaseSelected() } }) {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            VStack(spacing: 4) {
                                Text(ctaTitle)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                if let subtitle = ctaSubtitle {
                                    Text(subtitle)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .opacity(0.8)
                                }
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.Colors.calmBlue, AppConstants.Colors.sereneTeal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppConstants.Colors.calmBlue.opacity(0.4), radius: 12, y: 6)
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 24)

                // Restore + skip
                HStack(spacing: 24) {
                    Button("Restore Purchase") {
                        Task { await restore() }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                    Button("Skip for now") { onContinue() }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 20)

                Text("Cancel anytime. Terms & Privacy apply.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            // Default select monthly (index 1)
            if !sortedPackages.isEmpty {
                selectedIndex = sortedPackages.firstIndex(where: { $0.packageType == .monthly }) ?? 1
            }
        }
    }

    // MARK: - Purchase Logic

    private func purchaseSelected() async {
        guard !sortedPackages.isEmpty else {
            onContinue()
            return
        }
        let index = min(selectedIndex, sortedPackages.count - 1)
        let package = sortedPackages[index]
        isPurchasing = true
        errorMessage = nil

        do {
            let success = try await revenueCat.purchase(package)
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

    // MARK: - Helpers

    private let fallbackPlans: [(String, String, String, String)] = [
        ("Weekly", "$4.99/wk", "Flexible", ""),
        ("Monthly", "$9.99/mo", "BEST VALUE", "3-Day Free Trial"),
        ("Yearly", "$49.99/yr", "Save 58%", ""),
        ("Lifetime", "$79.99", "One-Time", "")
    ]

    private var ctaTitle: String {
        if sortedPackages.isEmpty { return "Continue" }
        let pkg = sortedPackages[min(selectedIndex, sortedPackages.count - 1)]
        if pkg.storeProduct.introductoryDiscount != nil { return "Start Free Trial" }
        return "Subscribe Now"
    }

    private var ctaSubtitle: String? {
        if sortedPackages.isEmpty { return nil }
        let pkg = sortedPackages[min(selectedIndex, sortedPackages.count - 1)]
        if let intro = pkg.storeProduct.introductoryDiscount {
            let days = intro.subscriptionPeriod.value
            return "\(days) days free, then \(pkg.localizedPriceString)\(priceSuffix(pkg))"
        }
        return nil
    }

    private func packageName(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        case .lifetime: return "Lifetime"
        default: return pkg.storeProduct.localizedTitle
        }
    }

    private func priceSuffix(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .weekly: return "/wk"
        case .monthly: return "/mo"
        case .annual: return "/yr"
        default: return ""
        }
    }

    private func packageBadge(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .monthly: return "BEST VALUE"
        case .annual: return "Save 58%"
        case .weekly: return "Flexible"
        case .lifetime: return "One-Time"
        default: return ""
        }
    }

    private func packageTrial(_ pkg: Package) -> String {
        if let intro = pkg.storeProduct.introductoryDiscount {
            return "\(intro.subscriptionPeriod.value)-Day Free Trial"
        }
        return ""
    }
}

struct TransformCard: View {
    let title: String
    let items: [String]
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(AppConstants.Colors.mintGreen)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}

struct PlanCard: View {
    let name: String
    let price: String
    let badge: String
    let trial: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppConstants.Colors.mintGreen : .white.opacity(0.3))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    AppConstants.Colors.sunsetGold.opacity(0.8)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    if !trial.isEmpty {
                        Text(trial)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppConstants.Colors.mintGreen)
                    }
                }

                Spacer()

                Text(price)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppConstants.Colors.calmBlue.opacity(0.2) : .white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppConstants.Colors.calmBlue : .white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
