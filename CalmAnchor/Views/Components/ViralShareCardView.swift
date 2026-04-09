import SwiftUI

struct ViralShareCardView: View {
    let calmName: String
    let streakDays: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var cardAppeared = false
    @State private var glowPulse = false
    @State private var ringScale: CGFloat = 0.85

    // MARK: - Subview helpers (extracted to help type-checker)

    private static let ringOpacities: [Double] = [0.12, 0.10, 0.08, 0.06]
    private static let ringWidths: [CGFloat]   = [90, 122, 154, 186]
    private static let ringScaleOffsets: [CGFloat] = [0, 0.06, 0.12, 0.18]
    private static let ringDurations: [Double] = [2.5, 2.8, 3.1, 3.4]
    private static let ringDelays: [Double]    = [0, 0.4, 0.8, 1.2]

    @ViewBuilder
    private var anchorRings: some View {
        ForEach(0..<4) { i in
            let opacity = Self.ringOpacities[i]
            let width = Self.ringWidths[i]
            let scaleOffset = Self.ringScaleOffsets[i]
            let duration = Self.ringDurations[i]
            let delay = Self.ringDelays[i]
            Circle()
                .stroke(AppConstants.Colors.electricTeal.opacity(opacity), lineWidth: 1)
                .frame(width: width)
                .scaleEffect(glowPulse ? ringScale + scaleOffset : 1.0)
                .animation(
                    .easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay),
                    value: glowPulse
                )
        }
    }

    // Clean, shareable text — no odd Unicode characters
    private var shareText: String {
        if streakDays > 1 {
            return "I stayed calm today with CalmAnchor — Day \(streakDays) streak. My anchor is holding. #CalmAnchor"
        }
        return "I stayed calm today with CalmAnchor. My anchor is holding. #CalmAnchor"
    }

    var body: some View {
        ZStack {
            AnchorBackground()

            VStack(spacing: 0) {
                // ── Navigation bar ───────────────────────────────────────
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .accessibilityLabel("Close")

                    Spacer()
                    Text("Share Your Calm")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Color.clear.frame(width: 28, height: 28)   // balance the X button
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // ── Story card ───────────────────────────────────────────
                VStack(spacing: 28) {

                    // Anchor with pulsing rings
                    ZStack {
                        if !reduceMotion {
                            anchorRings
                        }

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppConstants.Colors.electricTeal.opacity(0.3),
                                        AppConstants.Colors.roseGold.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center, startRadius: 0, endRadius: 55
                                )
                            )
                            .frame(width: 110, height: 110)

                        Image(systemName: "anchor")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppConstants.Colors.electricTeal, AppConstants.Colors.roseGoldBright],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(cardAppeared ? 1.0 : (reduceMotion ? 1.0 : 0.5))
                    .opacity(cardAppeared ? 1 : (reduceMotion ? 1 : 0))
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.62).delay(0.1),
                        value: cardAppeared
                    )
                    .accessibilityLabel("Glowing anchor")
                    .accessibilityHidden(true)

                    // Text
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
                    .opacity(cardAppeared ? 1 : (reduceMotion ? 1 : 0))
                    .offset(y: cardAppeared ? 0 : (reduceMotion ? 0 : 18))
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7).delay(0.22),
                        value: cardAppeared
                    )

                    // Name dot
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppConstants.Colors.electricTeal.opacity(0.25))
                            .frame(width: 8, height: 8)
                        Text(calmName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .opacity(cardAppeared ? 1 : (reduceMotion ? 1 : 0))
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7).delay(0.32),
                        value: cardAppeared
                    )
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

                // ── Share + tagline ──────────────────────────────────────
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
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: AppConstants.Colors.electricTeal.opacity(0.4), radius: 14, y: 5)
                    }
                    .accessibilityLabel("Share your calm moment with others")

                    Text("Inspire others to find their anchor")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.28))
                }
                .padding(.horizontal, 28)
                .opacity(cardAppeared ? 1 : (reduceMotion ? 1 : 0))
                .animation(
                    reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7).delay(0.42),
                    value: cardAppeared
                )

                Spacer().frame(height: 48)
            }
        }
        .onAppear {
            cardAppeared = true
            if !reduceMotion { glowPulse = true }
        }
    }
}
