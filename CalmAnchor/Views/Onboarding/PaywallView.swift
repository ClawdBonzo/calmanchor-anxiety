import SwiftUI

struct PaywallView: View {
    let calmName: String
    let onContinue: () -> Void
    let onRestore: () -> Void

    @State private var selectedPlan = 1 // 0=weekly, 1=annual (highlighted), 2=monthly

    private let plans: [(String, String, String, String)] = [
        ("Weekly", "$4.99/wk", "Flexible", ""),
        ("Annual", "$39.99/yr", "Best Value", "3-Day Free Trial"),
        ("Monthly", "$9.99/mo", "Popular", "")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 50)

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

                // Plan selection
                VStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        PlanCard(
                            name: plans[index].0,
                            price: plans[index].1,
                            badge: plans[index].2,
                            trial: plans[index].3,
                            isSelected: selectedPlan == index,
                            action: { selectedPlan = index }
                        )
                    }
                }
                .padding(.horizontal, 24)

                // CTA
                Button(action: {
                    // TODO: RevenueCat purchase
                    onContinue()
                }) {
                    VStack(spacing: 4) {
                        Text(plans[selectedPlan].3.isEmpty ? "Continue" : "Start Free Trial")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        if !plans[selectedPlan].3.isEmpty {
                            Text("3 days free, then \(plans[selectedPlan].1)")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .opacity(0.8)
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
                .padding(.horizontal, 24)

                // Restore + skip
                HStack(spacing: 24) {
                    Button("Restore Purchase") { onRestore() }
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
