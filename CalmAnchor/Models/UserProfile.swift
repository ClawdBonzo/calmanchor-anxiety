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
    var notificationsEnabled: Bool = false
    var reminderTime: Date = UserProfile.defaultReminderTime
    var taskRemindersEnabled: Bool = true
    /// When the one-per-30-days streak grace day was last spent (nil = never).
    var lastGraceUsedDate: Date? = nil

    /// 8:00 PM today — only hour/minute are ever read when building triggers.
    static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }

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
