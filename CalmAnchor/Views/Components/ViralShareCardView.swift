import SwiftUI

struct ViralShareCardView: View {
    let calmName: String
    let streakDays: Int
    @Environment(\.dismiss) private var dismiss

    @State private var cardAppeared = false
    @State private var glowPulse = false
    @State private var ringScale: CGFloat = 0.8

    private var shareText: String {
        let streak = streakDays > 1 ? " — Day \(streakDays) streak." : "."
        return "I stayed calm today with CalmAnchor\(streak) My anchor is holding. \u{1F9A0}"
    }

    var body: some View {
        ZStack {
            AnchorBackground()

            VStack(spacing: 0) {
                // Dismiss
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    Spacer()
                    Text("Share Your Calm")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // ── Story card ──────────────────────────────────────────
                VStack(spacing: 28) {

                    // Anchor bloom icon
                    ZStack {
                        // Ambient rings
                        ForEach(0..<4) { i in
                            Circle()
                                .stroke(
                                    AppConstants.Colors.electricTeal.opacity(0.12 - Double(i) * 0.02),
                                    lineWidth: 1
                                )
                                .frame(width: 90 + CGFloat(i) * 32)
                                .scaleEffect(glowPulse ? ringScale + CGFloat(i) * 0.06 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2.5 + Double(i) * 0.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.4),
                                    value: glowPulse
                                )
                        }

                        // Core anchor circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppConstants.Colors.electricTeal.opacity(0.3),
                                        AppConstants.Colors.roseGold.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 55
                                )
                            )
                            .frame(width: 110, height: 110)

                        Image(systemName: "anchor")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppConstants.Colors.electricTeal, AppConstants.Colors.roseGoldBright],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(cardAppeared ? 1.0 : 0.5)
                    .opacity(cardAppeared ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.62).delay(0.1), value: cardAppeared)

                    // Main text
                    VStack(spacing: 10) {
                        Text("I Stayed Calm Today")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        if streakDays > 1 {
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppConstants.Colors.sunsetGold)
                                Text("Day \(streakDays) streak")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppConstants.Colors.sunsetGold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppConstants.Colors.sunsetGold.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        Text("anchored in the storm")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .italic()
                    }
                    .opacity(cardAppeared ? 1 : 0)
                    .offset(y: cardAppeared ? 0 : 18)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.22), value: cardAppeared)

                    // Name badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppConstants.Colors.electricTeal.opacity(0.25))
                            .frame(width: 8, height: 8)
                        Text(calmName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .opacity(cardAppeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.32), value: cardAppeared)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 32)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(AppConstants.Colors.electricTeal.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: AppConstants.Colors.electricTeal.opacity(0.15), radius: 30, y: 10)
                .padding(.horizontal, 28)

                Spacer()

                // Share CTA
                VStack(spacing: 14) {
                    ShareLink(item: shareText) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share Your Calm")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppConstants.Colors.electricTeal, Color(hex: "4A90D9")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppConstants.Colors.electricTeal.opacity(0.4), radius: 14, y: 5)
                    }

                    Text("Inspire others to find their anchor")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.28))
                }
                .padding(.horizontal, 28)
                .opacity(cardAppeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.42), value: cardAppeared)

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            cardAppeared = true
            glowPulse = true
        }
    }
}
