import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var calmName: String
    var triggers: [String]
    var baselineMood: Int
    var dailyMinutes: Int
    var createdAt: Date
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date?
    var totalSessions: Int
    var isPremium: Bool

    init(
        calmName: String = "",
        triggers: [String] = [],
        baselineMood: Int = 5,
        dailyMinutes: Int = 10,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalSessions: Int = 0,
        isPremium: Bool = false
    ) {
        self.id = UUID()
        self.calmName = calmName
        self.triggers = triggers
        self.baselineMood = baselineMood
        self.dailyMinutes = dailyMinutes
        self.createdAt = Date()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = nil
        self.totalSessions = totalSessions
        self.isPremium = isPremium
    }
}
