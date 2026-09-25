import SwiftUI
import UIKit

// MARK: - Badge medallion

extension CalmMetric {
    /// Each family of badges has its own glaze, so the wall reads as a collection.
    var glaze: [Color] {
        switch self {
        case .sessions, .calmMinutes:           return [Color(hex: "F9D2B8"), Color(hex: "C09678"), Color(hex: "8A5A48")]
        case .bigDrops, .stormTamed:            return [Color(hex: "7FF3E6"), Color(hex: "00C9B7"), Color(hex: "0E6E73")]
        case .longestStreak:                    return [Color(hex: "FFD978"), Color(hex: "F59E4A"), Color(hex: "C2573A")]
        case .moods, .twiceADay, .triggers:     return [Color(hex: "9CCBF2"), Color(hex: "5B9BD5"), Color(hex: "2D5E93")]
        case .journals, .gratitudes:            return [Color(hex: "D8CCF0"), Color(hex: "9C88C9"), Color(hex: "5E4B8A")]
        case .planDays:                         return [Color(hex: "CDEBD9"), Color(hex: "7FBF9A"), Color(hex: "3F7D5C")]
        case .level, .shares:                   return [Color(hex: "FFF1B8"), Color(hex: "F5D76E"), Color(hex: "C8902A")]
        case .nightWatch, .earlyLight, .comeback, .graceSaved:
                                                return [Color(hex: "FBFCFE"), Color(hex: "C7BCDB"), Color(hex: "D99A8E")]
        }
    }
}

struct BadgeMedallion: View {
    let badge: CalmBadge
    let unlocked: Bool
    var progress: Double = 0
    var size: CGFloat = 64

    private var symbol: String {
        if !unlocked && badge.isSecret { return "questionmark" }
        return UIImage(systemName: badge.symbol) != nil ? badge.symbol : "star.fill"
    }

    var body: some View {
        ZStack {
            if unlocked {
                Circle()
                    .fill(LinearGradient(colors: badge.metric.glaze, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: badge.metric.glaze[1].opacity(0.55), radius: size * 0.18, y: size * 0.06)
                // Gloss
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)],
                                         startPoint: .top, endPoint: .center))
                    .padding(size * 0.06)
                    .blendMode(.screen)
                Circle().stroke(.white.opacity(0.85), lineWidth: max(1.5, size * 0.035))
                    .padding(size * 0.05)
                Image(systemName: symbol)
                    .font(.system(size: size * 0.40, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            } else {
                Circle().fill(Color.white.opacity(0.06))
                Circle().stroke(Color.white.opacity(0.10), lineWidth: size * 0.07)
                Circle()
                    .trim(from: 0, to: badge.isSecret ? 0 : progress)
                    .stroke(CalmBrand.accentGradient, style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: symbol)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(CalmBrand.mist.opacity(0.7))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(unlocked ? badge.title : (badge.isSecret ? String(localized: "Secret badge") : badge.title))
        .accessibilityValue(unlocked ? String(localized: "Unlocked") : String(localized: "Locked"))
    }
}

// MARK: - Anchor Pass (rank card)

struct AnchorPassCard: View {
    let stats: GameStats?
    let streak: Int
    let badgesUnlocked: Int
    let badgesTotal: Int
    var compact = false

    private var level: Int { stats?.currentLevel ?? 1 }
    private var tier: CalmTier { CalmTier.forLevel(level) }

    var body: some View {
        let progress = stats?.getXPProgressToNextLevel() ?? (current: 0, needed: 600, percentage: 0)
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: String(localized: "ANCHOR PASS · %@"), tier.name.uppercased()))
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(tier.ink.opacity(0.75))
                    Text(CalmRanks.title(for: level))
                        .font(.calmDisplay(compact ? 26 : 32, weight: .black))
                        .foregroundStyle(tier.ink)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                ZStack {
                    Circle().fill(tier.ink.opacity(0.10))
                    Image("BrandIcon").resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .padding(6)
                }
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(tier.ink.opacity(0.14))
                        Capsule().fill(tier.ink.opacity(0.85))
                            .frame(width: max(8, geo.size.width * progress.percentage))
                    }
                }
                .frame(height: 8)
                HStack {
                    Text(String(format: String(localized: "Level %lld · %lld XP"), level, stats?.totalXP ?? 0))
                    Spacer()
                    if let next = stats?.nextRankTitle {
                        Text(String(format: String(localized: "%lld XP to %@"), max(0, progress.needed - progress.current), next))
                    } else {
                        Text(String(localized: "Top rank"))
                    }
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(tier.ink.opacity(0.8))
                .monospacedDigit()
            }
            .accessibilityElement(children: .combine)

            if !compact {
                HStack(spacing: 8) {
                    if streak > 0 {
                        PassChip(icon: "flame.fill",
                                 text: String(format: String(localized: "%lld-day streak"), streak), ink: tier.ink)
                    }
                    PassChip(icon: "rosette",
                             text: String(format: String(localized: "%lld/%lld badges"), badgesUnlocked, badgesTotal),
                             ink: tier.ink)
                }
            }
        }
        .padding(compact ? 16 : 20)
        .background(
            ZStack {
                tier.gradient
                // Guilloché rings, like a real pass.
                Canvas { ctx, size in
                    let c = CGPoint(x: size.width * 0.92, y: size.height * 0.1)
                    for i in 1...14 {
                        let r = CGFloat(i) * 22
                        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                                   with: .color(.white.opacity(0.10)), lineWidth: 1)
                    }
                }
                LinearGradient(colors: [.white.opacity(0.28), .clear], startPoint: .topLeading, endPoint: .center)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.35), lineWidth: 1))
        .shadow(color: (tier.colors.last ?? .black).opacity(0.45), radius: 18, y: 8)
    }
}

private struct PassChip: View {
    let icon: String
    let text: String
    let ink: Color
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .heavy))
            Text(text).font(.system(size: 12, weight: .bold, design: .rounded)).monospacedDigit()
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(ink.opacity(0.12), in: Capsule())
    }
}

// MARK: - Buttons

struct CalmPrimaryButtonStyle: ButtonStyle {
    var colors: [Color] = CalmBrand.action
    var ink: Color = CalmBrand.midnight
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom), in: Capsule())
            .shadow(color: colors.last?.opacity(0.4) ?? .clear, radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
