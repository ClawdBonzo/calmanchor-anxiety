import SwiftUI
import RevenueCat

struct PaywallView: View {
    let calmName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    @EnvironmentObject private var revenueCat: RevenueCatService
    @State private var selectedIndex = 1
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var anchorPulse = false
    @State private var headerAppeared = false
    @State private var contentAppeared = false
    @State private var plansAppeared = false

    private var sortedPackages: [Package] {
        let order: [PackageType] = [.weekly, .monthly, .annual, .lifetime]
        return (revenueCat.currentOffering?.availablePackages ?? []).sorted { a, b in
            (order.firstIndex(of: a.packageType) ?? 99) < (order.firstIndex(of: b.packageType) ?? 99)
        }
    }

    private let features: [(String, String)] = [
        ("brain.head.profile", "30-Day Peace Plan"),
        ("bolt.heart.fill", "Instant Panic SOS"),
        ("chart.line.uptrend.xyaxis", "Anxiety Tracking"),
        ("flame.fill", "Healing Streaks")
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── HEADER ──────────────────────────────────────────────────
            VStack(spacing: 6) {
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(AppConstants.Colors.sereneTeal.opacity(0.25 - Double(i) * 0.07), lineWidth: 1.5)
                            .frame(width: 54 + CGFloat(i) * 18)
                            .scaleEffect(anchorPulse ? 1.08 : 1.0)
                    }
                    Text("⚓")
                        .font(.system(size: 32))
                        .scaleEffect(anchorPulse ? 1.04 : 1.0)
                }
                .frame(height: 64)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: anchorPulse)

                Text("Unlock Your Calm")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Everything you need to manage anxiety — in one place.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppConstants.Colors.softLavender)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 20)
            .padding(.bottom, 14)
            .opacity(headerAppeared ? 1 : 0)
            .offset(y: headerAppeared ? 0 : -16)

            // ── FEATURE GRID ─────────────────────────────────────────────
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(features, id: \.0) { icon, text in
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppConstants.Colors.mintGreen)
                            .frame(width: 18)
                        Text(text)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer()
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 12)

            // ── PLAN CARDS ───────────────────────────────────────────────
            VStack(spacing: 7) {
                if sortedPackages.isEmpty {
                    ForEach(0..<4) { i in
                        let f = fallbackPlans[i]
                        CompactPlanCard(name: f.0, price: f.1, badge: f.2, trial: f.3,
                                        isSelected: selectedIndex == i,
                                        action: { selectedIndex = i })
                    }
                } else {
                    ForEach(Array(sortedPackages.enumerated()), id: \.element.id) { i, pkg in
                        CompactPlanCard(
                            name: packageName(pkg),
                            price: pkg.localizedPriceString + priceSuffix(pkg),
                            badge: packageBadge(pkg),
                            trial: packageTrial(pkg),
                            isSelected: selectedIndex == i,
                            action: { selectedIndex = i }
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .opacity(plansAppeared ? 1 : 0)
            .offset(y: plansAppeared ? 0 : 16)

            // ── ERROR ────────────────────────────────────────────────────
            if let msg = errorMessage {
                Text(msg)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.horizontal, 22)
                    .padding(.top, 6)
                    .transition(.opacity)
            }

            Spacer(minLength: 8)

            // ── CTA BUTTON ───────────────────────────────────────────────
            Button(action: { Task { await purchaseSelected() } }) {
                Group {
                    if isPurchasing {
                        ProgressView().tint(.white).scaleEffect(1.1)
                    } else {
                        VStack(spacing: 2) {
                            Text(ctaTitle)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            if let sub = ctaSubtitle {
                                Text(sub)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .opacity(0.8)
                            }
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppConstants.Colors.calmBlue, AppConstants.Colors.sereneTeal],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppConstants.Colors.calmBlue.opacity(0.5), radius: 12, y: 5)
            }
            .disabled(isPurchasing)
            .padding(.horizontal, 22)
            .opacity(plansAppeared ? 1 : 0)

            // ── FOOTER ───────────────────────────────────────────────────
            HStack(spacing: 20) {
                Button("Restore Purchase") { Task { await restore() } }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 12)
                Button("Skip for now") { onContinue() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.vertical, 10)

            Text("Cancel anytime · Terms & Privacy apply.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.22))
                .padding(.bottom, 14)
        }
        .onAppear {
            anchorPulse = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.05)) { headerAppeared = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2))  { contentAppeared = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.35)) { plansAppeared = true }
            if !sortedPackages.isEmpty {
                selectedIndex = sortedPackages.firstIndex(where: { $0.packageType == .monthly }) ?? 1
            }
        }
    }

    // MARK: - Purchase Logic

    private func purchaseSelected() async {
        guard !sortedPackages.isEmpty else { onContinue(); return }
        let pkg = sortedPackages[min(selectedIndex, sortedPackages.count - 1)]
        isPurchasing = true; errorMessage = nil
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
        isPurchasing = true; errorMessage = nil
        do {
            let success = try await revenueCat.restorePurchases()
            isPurchasing = false
            if success { onContinue() } else { errorMessage = "No active subscription found." }
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private let fallbackPlans: [(String, String, String, String)] = [
        ("Weekly",   "$4.99/wk",  "Flexible",  ""),
        ("Monthly",  "$9.99/mo",  "BEST VALUE","3-Day Free Trial"),
        ("Yearly",   "$49.99/yr", "Save 58%",  ""),
        ("Lifetime", "$79.99",    "One-Time",  "")
    ]

    private var ctaTitle: String {
        if sortedPackages.isEmpty { return "Continue" }
        let pkg = sortedPackages[min(selectedIndex, sortedPackages.count - 1)]
        return pkg.storeProduct.introductoryDiscount != nil ? "Start Free Trial" : "Subscribe Now"
    }

    private var ctaSubtitle: String? {
        if sortedPackages.isEmpty { return nil }
        let pkg = sortedPackages[min(selectedIndex, sortedPackages.count - 1)]
        if let intro = pkg.storeProduct.introductoryDiscount {
            return "\(intro.subscriptionPeriod.value) days free, then \(pkg.localizedPriceString)\(priceSuffix(pkg))"
        }
        return nil
    }

    private func packageName(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .weekly:   return "Weekly"
        case .monthly:  return "Monthly"
        case .annual:   return "Yearly"
        case .lifetime: return "Lifetime"
        default:        return pkg.storeProduct.localizedTitle
        }
    }

    private func priceSuffix(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .weekly:  return "/wk"
        case .monthly: return "/mo"
        case .annual:  return "/yr"
        default:       return ""
        }
    }

    private func packageBadge(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .monthly:  return "BEST VALUE"
        case .annual:   return "Save 58%"
        case .weekly:   return "Flexible"
        case .lifetime: return "One-Time"
        default:        return ""
        }
    }

    private func packageTrial(_ pkg: Package) -> String {
        if let intro = pkg.storeProduct.introductoryDiscount {
            return "\(intro.subscriptionPeriod.value)-Day Free Trial"
        }
        return ""
    }
}

// MARK: - Compact Plan Card

struct CompactPlanCard: View {
    let name: String
    let price: String
    let badge: String
    let trial: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppConstants.Colors.mintGreen : .white.opacity(0.3))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        if !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(AppConstants.Colors.sunsetGold.opacity(0.85))
                                .clipShape(Capsule())
                        }
                    }
                    if !trial.isEmpty {
                        Text(trial)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppConstants.Colors.mintGreen)
                    }
                }

                Spacer()

                Text(price)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppConstants.Colors.calmBlue.opacity(0.2) : .white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppConstants.Colors.calmBlue : .white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// Keep legacy subviews so they compile (used nowhere else now)
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
