import Foundation
import SwiftData

/// Result of awarding XP — used to drive level-up feedback in the UI.
struct XPAward {
    let xpGained: Int
    let didLevelUp: Bool
    let newLevel: Int
    let levelName: String
}

/// First real XP plumbing for the app. Lazily bootstraps `GameStats`
/// (previously only ever created by the DEBUG seeder), awards XP, logs an
/// `XPEvent` audit row, and recomputes the level from `xpThresholds`.
enum XPService {
    /// Fetch the singleton GameStats, creating it if it doesn't exist yet.
    @MainActor
    static func stats(in context: ModelContext) -> GameStats {
        if let existing = try? context.fetch(FetchDescriptor<GameStats>()).first {
            return existing
        }
        let stats = GameStats()
        context.insert(stats)
        return stats
    }

    @MainActor
    @discardableResult
    static func award(_ amount: Int, source: String, in context: ModelContext) -> XPAward {
        let stats = stats(in: context)
        context.insert(XPEvent(source: source, xpAmount: amount))

        let oldLevel = stats.currentLevel
        stats.totalXP += amount
        stats.totalXPEarned += amount
        stats.lastXPUpdate = Date()

        // xpThresholds[i] is the cumulative XP needed to reach level i+1.
        var level = stats.currentLevel
        while level < 20,
              level < stats.xpThresholds.count,
              stats.totalXP >= stats.xpThresholds[level] {
            level += 1
        }
        let leveledUp = level > oldLevel
        if leveledUp {
            stats.currentLevel = level
            stats.levelUpHistory.append(Date())
        }

        try? context.save()
        return XPAward(xpGained: amount,
                       didLevelUp: leveledUp,
                       newLevel: stats.currentLevel,
                       levelName: stats.getLevelName())
    }
}
