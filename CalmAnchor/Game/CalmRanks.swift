import SwiftUI

/// Anchor Pass cover tiers. The cover colour shows on the rank card, the
/// celebration and every shared card, so progress is visible at a glance.
enum CalmTier: Int, CaseIterable, Identifiable {
    case seaGlass, bronze, silver, gold, roseGold, pearl
    var id: Int { rawValue }

    static func forLevel(_ level: Int) -> CalmTier {
        switch level {
        case ..<4:   return .seaGlass
        case 4...6:  return .bronze
        case 7...10: return .silver
        case 11...14: return .gold
        case 15...17: return .roseGold
        default:     return .pearl
        }
    }

    var name: String {
        switch self {
        case .seaGlass: return String(localized: "Sea Glass")
        case .bronze:   return String(localized: "Bronze")
        case .silver:   return String(localized: "Silver")
        case .gold:     return String(localized: "Gold")
        case .roseGold: return String(localized: "Rose Gold")
        case .pearl:    return String(localized: "Pearl")
        }
    }

    var colors: [Color] {
        switch self {
        case .seaGlass: return [Color(hex: "B9E3CF"), Color(hex: "3E8A80")]
        case .bronze:   return [Color(hex: "E0A56A"), Color(hex: "7A4A22")]
        case .silver:   return [Color(hex: "EEF2F6"), Color(hex: "8C98A6")]
        case .gold:     return [Color(hex: "FFE08A"), Color(hex: "C8902A")]
        case .roseGold: return [Color(hex: "F9D2B8"), Color(hex: "B07A62")]
        case .pearl:    return [Color(hex: "FBFCFE"), Color(hex: "C7BCDB"), Color(hex: "EBC0A8")]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Text colour that stays legible on the cover.
    var ink: Color {
        switch self {
        case .bronze: return .white
        default:      return CalmBrand.midnight
        }
    }
}

/// Twenty levels on the existing XP curve (GameStats.xpThresholds), renamed
/// so the very first thing a user is called is encouraging, never "anxious".
enum CalmRanks {
    static let maxLevel = 20

    static func title(for level: Int) -> String {
        let titles = [
            String(localized: "First Breath"), String(localized: "Wave Watcher"),
            String(localized: "Tide Learner"), String(localized: "Steady Swimmer"),
            String(localized: "Harbor Seeker"), String(localized: "Calm Sailor"),
            String(localized: "Deep Breather"), String(localized: "Grounded"),
            String(localized: "Steady Keel"), String(localized: "Lighthouse Keeper"),
            String(localized: "Storm Walker"), String(localized: "Calm Captain"),
            String(localized: "Still Waters"), String(localized: "Safe Harbor"),
            String(localized: "Anchor Bearer"), String(localized: "True North"),
            String(localized: "Deep Calm"), String(localized: "Tide Master"),
            String(localized: "Anchor Sage"), String(localized: "Zen Anchor")
        ]
        return titles[max(0, min(level - 1, titles.count - 1))]
    }

    /// One warm line shown on the rank-up celebration.
    static func line(for level: Int) -> String {
        switch CalmTier.forLevel(level) {
        case .seaGlass: return String(localized: "Every calm breath counts. You're finding your rhythm.")
        case .bronze:   return String(localized: "You keep showing up. That's how calm becomes a habit.")
        case .silver:   return String(localized: "Waves still come. You know how to ride them now.")
        case .gold:     return String(localized: "Steady hands on the wheel. Look how far you've sailed.")
        case .roseGold: return String(localized: "Calm isn't luck anymore. It's a skill you've built.")
        case .pearl:    return String(localized: "Rare, hard-won and entirely yours.")
        }
    }
}

extension GameStats {
    var rankTitle: String { CalmRanks.title(for: currentLevel) }
    var tier: CalmTier { CalmTier.forLevel(currentLevel) }
    var nextRankTitle: String? {
        currentLevel < CalmRanks.maxLevel ? CalmRanks.title(for: currentLevel + 1) : nil
    }
}
