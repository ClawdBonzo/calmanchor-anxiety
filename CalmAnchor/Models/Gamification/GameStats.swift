import Foundation
import SwiftData

@Model
final class GameStats {
    @Attribute(.unique) var id: UUID
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var totalXPEarned: Int = 0
    var levelUpHistory: [Date] = []
    var lastXPUpdate: Date = Date()
    var xpThresholds: [Int] = []

    init(id: UUID = UUID()) {
        self.id = id
        self.xpThresholds = Self.generateXPThresholds()
    }

    static func generateXPThresholds() -> [Int] {
        var thresholds: [Int] = [0]
        var current = 0
        for _ in 1..<7  { current += 600;  thresholds.append(current) }
        for _ in 7..<14 { current += 900;  thresholds.append(current) }
        for _ in 14..<20 { current += 1200; thresholds.append(current) }
        return thresholds
    }

    func getLevelName() -> String {
        let names = ["Anxious Beginner","Aware Adventurer","Curious Climber","Focus Friend",
                     "Feeling Fighter","Future Forger","Freedom Finder","Grounded Gardener",
                     "Growth Guide","Graceful Guardian","Harmony Healer","Heart Helper",
                     "Hope Holder","Horizon Hugger","Anchored Advocate","Anchor Artist",
                     "Ascended Ally","Anchor Awakener","Anchor Ambassador","Zen Master"]
        return names[min(currentLevel - 1, names.count - 1)]
    }

    func getLevelEmoji() -> String {
        switch currentLevel {
        case 1...7: return "🌊"
        case 8...14: return "⚓"
        default: return "✨"
        }
    }

    func getTierName() -> String {
        switch currentLevel {
        case 1...7: return "Anxious"
        case 8...14: return "Grounded"
        default: return "Anchored"
        }
    }

    func getXPForNextLevel() -> Int {
        guard currentLevel < 20 else { return xpThresholds.last ?? 0 }
        return xpThresholds[currentLevel]
    }

    func getXPProgressToNextLevel() -> (current: Int, needed: Int, percentage: Double) {
        let currentThreshold = currentLevel > 1 ? xpThresholds[currentLevel - 1] : 0
        let nextThreshold = getXPForNextLevel()
        let progressXP = totalXP - currentThreshold
        let neededXP = max(nextThreshold - currentThreshold, 1)
        let percentage = min(Double(progressXP) / Double(neededXP), 1.0)
        return (progressXP, neededXP, percentage)
    }
}
